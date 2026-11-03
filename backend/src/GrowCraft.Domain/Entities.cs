namespace GrowCraft.Domain;

public class User
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Username { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public string Role { get; set; } = "player";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public PlayerProfile? Profile { get; set; }
}

public class PlayerProfile
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User? User { get; set; }

    public string DisplayName { get; set; } = "";
    public int Level { get; set; } = 1;
    public int Xp { get; set; }
    public long Gems { get; set; } = 20;
    public int HarvestedCount { get; set; }
    public int PlantedCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public List<InventoryItem> Inventory { get; set; } = new();
}

public class ItemDefinition
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Category { get; set; } = "";
    public string Rarity { get; set; } = "common";
}

/// <summary>Definisi seed — sumber kebenaran waktu tumbuh & reward (master prompt E.1).</summary>
public class SeedDefinition
{
    public string Id { get; set; } = "";
    public string Name { get; set; } = "";
    public string Rarity { get; set; } = "common";
    public int GrowthSeconds { get; set; }
    public int GemMin { get; set; }
    public int GemMax { get; set; }
    public int SeedMin { get; set; }
    public int SeedMax { get; set; }
    public int Price { get; set; }
}

public class World
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = "";
    public Guid? OwnerId { get; set; }
    public PlayerProfile? Owner { get; set; }
    public bool IsPublic { get; set; } = true;
    public int Width { get; set; } = 24;
    public int Depth { get; set; } = 24;
    public int Height { get; set; } = 6;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class WorldBlock
{
    public long Id { get; set; }
    public Guid WorldId { get; set; }
    public World? World { get; set; }
    public int X { get; set; }
    public int Y { get; set; }
    public int Z { get; set; }
    public BlockType BlockType { get; set; }
}

/// <summary>Tanaman. Growth = now - planted_at (UTC) — jalan terus walau offline.</summary>
public class Plant
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid WorldId { get; set; }
    public int X { get; set; }
    public int Y { get; set; }
    public int Z { get; set; }
    public string SeedId { get; set; } = "";
    public SeedDefinition? Seed { get; set; }
    public DateTime PlantedAt { get; set; } = DateTime.UtcNow;
    public int Water { get; set; } = 100;
    public DateTime WateredAt { get; set; } = DateTime.UtcNow;
    public bool Harvested { get; set; }

    public double Progress(int growthSeconds)
        => Math.Clamp((DateTime.UtcNow - PlantedAt).TotalSeconds / growthSeconds, 0, 1);

    public int RemainingSeconds(int growthSeconds)
        => Math.Max(0, growthSeconds - (int)(DateTime.UtcNow - PlantedAt).TotalSeconds);

    public PlantStatus Status(int growthSeconds)
        => RemainingSeconds(growthSeconds) <= 0 ? PlantStatus.ReadyToHarvest : PlantStatus.Growing;

    public int DecayedWater()
    {
        var decayed = Water - (int)((DateTime.UtcNow - WateredAt).TotalSeconds * HarvestConfig.WaterDecayPerSecond);
        return Math.Max(0, decayed);
    }
}

public class InventoryItem
{
    public long Id { get; set; }
    public Guid PlayerId { get; set; }
    public PlayerProfile? Player { get; set; }
    public string ItemId { get; set; } = "";
    public int Quantity { get; set; }
}

public class HarvestLog
{
    public long Id { get; set; }
    public Guid PlayerId { get; set; }
    public Guid? PlantId { get; set; }
    public string SeedId { get; set; } = "";
    public int SeedsGained { get; set; }
    public long GemsGained { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
