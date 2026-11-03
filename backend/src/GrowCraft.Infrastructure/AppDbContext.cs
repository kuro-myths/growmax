using GrowCraft.Domain;
using Microsoft.EntityFrameworkCore;

namespace GrowCraft.Infrastructure;

/// <summary>
/// EF Core context — PostgreSQL dengan snake_case naming convention,
/// mapping 1:1 ke database/init/01_schema.sql.
/// </summary>
public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<PlayerProfile> PlayerProfiles => Set<PlayerProfile>();
    public DbSet<ItemDefinition> ItemDefinitions => Set<ItemDefinition>();
    public DbSet<SeedDefinition> SeedDefinitions => Set<SeedDefinition>();
    public DbSet<World> Worlds => Set<World>();
    public DbSet<WorldBlock> WorldBlocks => Set<WorldBlock>();
    public DbSet<Plant> Plants => Set<Plant>();
    public DbSet<InventoryItem> Inventory => Set<InventoryItem>();
    public DbSet<HarvestLog> HarvestLogs => Set<HarvestLog>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        mb.Entity<User>(e => {
            e.ToTable("users");
            e.Property(x => x.Username).HasMaxLength(32);
        });

        mb.Entity<PlayerProfile>(e => {
            e.ToTable("player_profiles");
            e.HasOne(x => x.User).WithOne(u => u.Profile)
              .HasForeignKey<PlayerProfile>(x => x.UserId)
              .OnDelete(DeleteBehavior.Cascade);
        });

        mb.Entity<ItemDefinition>(e => {
            e.ToTable("item_definitions");
        });

        mb.Entity<SeedDefinition>(e => {
            e.ToTable("seed_definitions");
        });

        mb.Entity<World>(e => {
            e.ToTable("worlds");
            e.HasOne(x => x.Owner).WithMany()
              .HasForeignKey(x => x.OwnerId).OnDelete(DeleteBehavior.SetNull);
        });

        mb.Entity<WorldBlock>(e => {
            e.ToTable("world_blocks");
            e.HasIndex(x => new { x.WorldId, x.X, x.Y, x.Z }).IsUnique();
        });

        mb.Entity<Plant>(e => {
            e.ToTable("plants");
            e.HasOne(x => x.Seed).WithMany()
              .HasForeignKey(x => x.SeedId);
            e.HasIndex(x => new { x.WorldId, x.X, x.Z }).IsUnique();
        });

        mb.Entity<InventoryItem>(e => {
            e.ToTable("player_inventory");
            e.HasIndex(x => new { x.PlayerId, x.ItemId }).IsUnique();
        });

        mb.Entity<HarvestLog>(e => {
            e.ToTable("harvest_logs");
        });
    }
}
