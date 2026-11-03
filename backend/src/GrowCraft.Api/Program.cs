// ============================================================
// GrowCraft 3D — API server-authoritative
// Auth JWT + PBKDF2, worlds, farming (plant/water/harvest),
// inventory. Reward panen SELALU seed + gem (rarity + level).
// ============================================================
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using GrowCraft.Domain;
using GrowCraft.Infrastructure;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

var conn = Environment.GetEnvironmentVariable("DATABASE_URL")
           ?? builder.Configuration.GetConnectionString("Default")
           ?? "Host=localhost;Port=5432;Database=growcraft;Username=growcraft;Password=growcraft";

builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseNpgsql(conn, npg => npg.UseSnakeCaseNamingConvention()));

var jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
             ?? builder.Configuration["Jwt:Key"] ?? "dev-secret-ganti-di-produksi-min-32-char";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o => o.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    });
builder.Services.AddAuthorization();

var app = builder.Build();
app.UseAuthentication();
app.UseAuthorization();

// ---------- Helpers ----------
static Guid UserId(HttpContext ctx) =>
    Guid.Parse(ctx.User.FindFirstValue(ClaimTypes.NameIdentifier)
               ?? throw new UnauthorizedAccessException());

static Results Ok(object o) => Results.Json(o);

string CreateToken(User user, PlayerProfile profile) =>
    new JwtSecurityTokenHandler().WriteToken(new JwtSecurityToken(
        claims: new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim("profileId", profile.Id.ToString())
        },
        expires: DateTime.UtcNow.AddMinutes(
            builder.Configuration.GetValue("Jwt:ExpiresMinutes", 720)),
        signingCredentials: new SigningCredentials(
            new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            SecurityAlgorithms.HmacSha256)));

// ---------- DTO ----------
record RegisterDto(string Username, string Password);
record LoginDto(string Username, string Password);
record WorldDto(string Name, bool IsPublic);
record TillDto(Guid WorldId, int X, int Z);
record PlantDto(Guid WorldId, int X, int Z, string SeedId);
record WaterDto(Guid PlantId);
record HarvestDto(Guid PlantId);
record BuyDto(string SeedId, int Quantity);

// ============================================================
// AUTH
// ============================================================
app.MapPost("/api/auth/register", async (RegisterDto dto, AppDbContext db) =>
{
    var u = dto.Username.Trim().ToLowerInvariant();
    if (u.Length < 3 || u.Length > 32) return Results.BadRequest(new { error = "Username 3-32 karakter." });
    if (string.IsNullOrEmpty(dto.Password) || dto.Password.Length < 6)
        return Results.BadRequest(new { error = "Password minimal 6 karakter." });
    if (await db.Users.AnyAsync(x => x.Username == u))
        return Results.Conflict(new { error = "Username sudah dipakai." });

    var user = new User { Username = u, PasswordHash = PasswordHasher.Hash(dto.Password) };
    var profile = new PlayerProfile { UserId = user.Id, DisplayName = dto.Username.Trim() };
    db.Users.Add(user);
    db.PlayerProfiles.Add(profile);
    db.Inventory.Add(new InventoryItem { PlayerId = profile.Id, ItemId = "seed_door", Quantity = 1 });
    await db.SaveChangesAsync();
    return Ok(new { token = CreateToken(user, profile), username = user.Username });
});

app.MapPost("/api/auth/login", async (LoginDto dto, AppDbContext db) =>
{
    var user = await db.Users.Include(x => x.Profile)
        .FirstOrDefaultAsync(x => x.Username == dto.Username.Trim().ToLowerInvariant());
    if (user is null || !PasswordHasher.Verify(dto.Password, user.PasswordHash))
        return Results.Unauthorized();
    return Ok(new { token = CreateToken(user, user.Profile!) });
});

// ============================================================
// PLAYERS & INVENTORY
// ============================================================
app.MapGet("/api/players/me", async (HttpContext ctx, AppDbContext db) =>
{
    var p = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    return Ok(new
    {
        p.DisplayName, p.Level, p.Xp, p.Gems, p.HarvestedCount, p.PlantedCount,
        xpToNext = p.Level * 100
    });
});

app.MapGet("/api/inventory", async (HttpContext ctx, AppDbContext db) =>
{
    var profile = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var items = await db.Inventory.Where(i => i.PlayerId == profile.Id).ToListAsync();
    return Ok(items.Select(i => new { i.ItemId, i.Quantity }));
});

// ============================================================
// WORLDS
// ============================================================
app.MapGet("/api/worlds", async (AppDbContext db) =>
{
    var list = await db.Worlds.OrderByDescending(w => w.CreatedAt).Take(50).ToListAsync();
    return Ok(list.Select(w => new { w.Id, w.Name, w.IsPublic, w.Width, w.Depth, w.Height }));
});

app.MapPost("/api/worlds", async (HttpContext ctx, WorldDto dto, AppDbContext db) =>
{
    var profile = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var name = dto.Name.Trim().Length > 0 ? dto.Name.Trim() : $"world-{Guid.NewGuid().ToString()[..8]}";
    if (await db.Worlds.AnyAsync(w => w.Name == name))
        return Results.Conflict(new { error = "Nama world sudah dipakai." });

    var world = new World { Name = name, OwnerId = profile.Id, IsPublic = dto.IsPublic };
    db.Worlds.Add(world);

    // Terrain generasi: bedrock(0) -> stone(1-2) -> dirt(3-4) -> grass(5)
    for (var x = 0; x < world.Width; x++)
    for (var z = 0; z < world.Depth; z++)
    for (var y = 0; y < world.Height; y++)
    {
        var type = y switch
        {
            0 => BlockType.Bedrock,
            < 3 => BlockType.Stone,
            < 5 => BlockType.Dirt,
            _ => (x < 2 ? BlockType.Sand : BlockType.Grass)
        };
        db.WorldBlocks.Add(new WorldBlock { WorldId = world.Id, X = x, Y = y, Z = z, BlockType = type });
    }
    await db.SaveChangesAsync();
    return Ok(new { world.Id, world.Name, world.IsPublic, world.Width, world.Depth, world.Height });
});

app.MapGet("/api/worlds/{id:guid}", async (Guid id, AppDbContext db) =>
{
    var w = await db.Worlds.FindAsync(id);
    if (w is null) return Results.NotFound();
    return Ok(new { w.Id, w.Name, w.IsPublic, w.Width, w.Depth, w.Height });
});

// ============================================================
// FARMING — server-authoritative (master prompt E & reward system)
// ============================================================
app.MapPost("/api/farming/till", async (HttpContext ctx, TillDto dto, AppDbContext db) =>
{
    var profile = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var block = await db.WorldBlocks
        .Where(b => b.WorldId == dto.WorldId && b.X == dto.X && b.Z == dto.Z && b.BlockType == BlockType.Grass)
        .OrderByDescending(b => b.Y).FirstOrDefaultAsync();
    if (block is null) return Results.BadRequest(new { error = "Hanya rumput permukaan yang bisa digarap." });

    block.BlockType = BlockType.FarmSoil;
    await db.SaveChangesAsync();
    return Ok(new { x = block.X, y = block.Y, z = block.Z, blockType = (short)BlockType.FarmSoil });
});

app.MapPost("/api/farming/plant", async (HttpContext ctx, PlantDto dto, AppDbContext db) =>
{
    var profile = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var seedItem = $"seed_{dto.SeedId}";

    var seed = await db.SeedDefinitions.FindAsync(dto.SeedId);
    if (seed is null) return Results.BadRequest(new { error = "Seed tidak dikenal." });

    var inv = await db.Inventory
        .FirstOrDefaultAsync(i => i.PlayerId == profile.Id && i.ItemId == seedItem);
    if (inv is null || inv.Quantity < 1)
        return Results.BadRequest(new { error = $"Tidak punya {seed.Name} Seed. Beli di toko." });

    var soil = await db.WorldBlocks
        .Where(b => b.WorldId == dto.WorldId && b.X == dto.X && b.Z == dto.Z && b.BlockType == BlockType.FarmSoil)
        .OrderByDescending(b => b.Y).FirstOrDefaultAsync();
    if (soil is null) return Results.BadRequest(new { error = "Tanam hanya di Tanah Garap." });

    if (await db.Plants.AnyAsync(p => p.WorldId == dto.WorldId && p.X == dto.X && p.Z == dto.Z && !p.Harvested))
        return Results.Conflict(new { error = "Petak sudah ditanami." });

    inv.Quantity -= 1;
    if (inv.Quantity <= 0) db.Inventory.Remove(inv);

    var plant = new Plant
    {
        WorldId = dto.WorldId, X = dto.X, Y = soil.Y + 1, Z = dto.Z,
        SeedId = seed.Id, PlantedAt = DateTime.UtcNow,
        Water = 100, WateredAt = DateTime.UtcNow
    };
    db.Plants.Add(plant);
    profile.PlantedCount++;
    await db.SaveChangesAsync();

    return Ok(new
    {
        plant.Id, plant.X, plant.Y, plant.Z, seedId = seed.Id, seed.Name,
        plantedAt = plant.PlantedAt, growthSeconds = seed.GrowthSeconds,
        status = nameof(PlantStatus.Growing)
    });
});

app.MapPost("/api/farming/water", async (HttpContext ctx, WaterDto dto, AppDbContext db) =>
{
    _ = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var plant = await db.Plants.Include(p => p.Seed).FirstOrDefaultAsync(p => p.Id == dto.PlantId && !p.Harvested);
    if (plant is null) return Results.NotFound();

    var water = Math.Min(100, plant.DecayedWater() + (int)HarvestConfig.WaterAmountPerWatering);
    plant.Water = water;
    plant.WateredAt = DateTime.UtcNow;
    await db.SaveChangesAsync();
    return Ok(new { plant.Id, water });
});

app.MapGet("/api/farming/plants/{worldId:guid}", async (Guid worldId, AppDbContext db) =>
{
    var plants = await db.Plants
        .Where(p => p.WorldId == worldId && !p.Harvested)
        .Include(p => p.Seed).ToListAsync();
    return Ok(plants.Select(p => new
    {
        p.Id, p.X, p.Y, p.Z, seedId = p.SeedId, p.Seed!.Name, p.Seed.Rarity,
        plantedAt = p.PlantedAt, growthSeconds = p.Seed.GrowthSeconds,
        remainingSeconds = p.RemainingSeconds(p.Seed.GrowthSeconds),
        water = p.DecayedWater(),
        status = p.Status(p.Seed.GrowthSeconds).ToString()
    }));
});

// ---------- REWARD ENGINE: panen SELALU dapat seed + gem ----------
app.MapPost("/api/farming/harvest", async (HttpContext ctx, HarvestDto dto, AppDbContext db) =>
{
    var profile = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var plant = await db.Plants.Include(p => p.Seed)
        .FirstOrDefaultAsync(p => p.Id == dto.PlantId && !p.Harvested);
    if (plant is null) return Results.NotFound();

    var seed = plant.Seed!;
    var remaining = plant.RemainingSeconds(seed.GrowthSeconds);
    if (remaining > 0)
        return Results.BadRequest(new { error = "Belum matang.", remainingSeconds = remaining });

    // rumus reward (master prompt — harvest reward system):
    //   level bonus +3%/lvl, air >= 60% => gem +25%
    var rng = Random.Shared;
    var lvlBonus = 1 + (profile.Level - 1) * HarvestConfig.LevelBonusPerLevel;
    var water = plant.DecayedWater();
    var seedsGained = Math.Max(HarvestConfig.MinimumSeedsOnHarvest,
        (int)Math.Round(rng.Next(seed.SeedMin, seed.SeedMax + 1) * lvlBonus));
    var gemsGained = (long)Math.Round(
        rng.Next(seed.GemMin, seed.GemMax + 1) * lvlBonus
        * (water >= HarvestConfig.WaterBonusThreshold ? HarvestConfig.WaterBonusMultiplier : 1));

    // inventory seed kembali
    var invItem = await db.Inventory
        .FirstOrDefaultAsync(i => i.PlayerId == profile.Id && i.ItemId == $"seed_{seed.Id}");
    if (invItem is null)
        db.Inventory.Add(new InventoryItem { PlayerId = profile.Id, ItemId = $"seed_{seed.Id}", Quantity = seedsGained });
    else invItem.Quantity += seedsGained;

    // gems + xp + level up
    profile.Gems += gemsGained;
    profile.HarvestedCount++;
    profile.Xp += (int)(gemsGained * 0.25) + 5;
    while (profile.Xp >= profile.Level * 100)
    {
        profile.Xp -= profile.Level * 100;
        profile.Level++;
    }

    db.HarvestLogs.Add(new HarvestLog
    {
        PlayerId = profile.Id, PlantId = plant.Id, SeedId = seed.Id,
        SeedsGained = seedsGained, GemsGained = gemsGained
    });
    plant.Harvested = true;
    db.Plants.Remove(plant);
    await db.SaveChangesAsync();

    return Ok(new
    {
        seedsGained, gemsGained, waterBonus = water >= HarvestConfig.WaterBonusThreshold,
        profile.Level, profile.Xp, profile.Gems
    });
});

// ---------- STORE: beli seed dengan gem ----------
app.MapGet("/api/store/seeds", async (AppDbContext db) =>
{
    var seeds = await db.SeedDefinitions.OrderBy(s => s.Price).ToListAsync();
    return Ok(seeds.Select(s => new { s.Id, s.Name, s.Rarity, s.Price, s.GrowthSeconds, gem = new[] { s.GemMin, s.GemMax } }));
});

app.MapPost("/api/store/buy", async (HttpContext ctx, BuyDto dto, AppDbContext db) =>
{
    var profile = await db.PlayerProfiles.FirstAsync(x => x.UserId == UserId(ctx));
    var seed = await db.SeedDefinitions.FindAsync(dto.SeedId);
    if (seed is null) return Results.BadRequest(new { error = "Seed tidak dikenal." });
    var qty = Math.Max(1, Math.Min(99, dto.Quantity));
    var cost = (long)seed.Price * qty;
    if (profile.Gems < cost)
        return Results.BadRequest(new { error = "Gem tidak cukup.", needed = cost, have = profile.Gems });

    profile.Gems -= cost;
    var invItem = await db.Inventory
        .FirstOrDefaultAsync(i => i.PlayerId == profile.Id && i.ItemId == $"seed_{seed.Id}");
    if (invItem is null)
        db.Inventory.Add(new InventoryItem { PlayerId = profile.Id, ItemId = $"seed_{seed.Id}", Quantity = qty });
    else invItem.Quantity += qty;
    await db.SaveChangesAsync();
    return Ok(new { bought = seed.Name, quantity = qty, spent = cost, profile.Gems });
});

app.MapGet("/health", () => Ok(new { status = "ok", time = DateTime.UtcNow }));

app.Run();

// ============================================================
// Password hashing PBKDF2 (tanpa package eksternal; ganti Argon2id di produksi)
// ============================================================
public static class PasswordHasher
{
    private const int Iterations = 100_000, SaltSize = 16, HashSize = 32;

    public static string Hash(string password)
    {
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var hash = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, HashAlgorithmName.SHA256, HashSize);
        return $"{Iterations}.{Convert.ToBase64String(salt)}.{Convert.ToBase64String(hash)}";
    }

    public static bool Verify(string password, string stored)
    {
        var parts = stored.Split('.');
        if (parts.Length != 3) return false;
        var salt = Convert.FromBase64String(parts[1]);
        var hash = Convert.FromBase64String(parts[2]);
        var test = Rfc2898DeriveBytes.Pbkdf2(password, salt, int.Parse(parts[0]), HashAlgorithmName.SHA256, hash.Length);
        return CryptographicOperations.FixedTimeEquals(hash, test);
    }
}
