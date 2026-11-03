namespace GrowCraft.Domain;

/// <summary>Blok dunia. Urutan sesuai world_blocks.block_type di database.</summary>
public enum BlockType : short
{
    Air = 0,
    Grass = 1,
    Dirt = 2,
    Stone = 3,
    Bedrock = 4,
    Wood = 5,
    Sand = 6,
    FarmSoil = 7
}

public enum PlantStatus { Growing, ReadyToHarvest }

public static class Rarity
{
    public const string Common = "common";
    public const string Uncommon = "uncommon";
    public const string Rare = "rare";
    public const string Epic = "epic";
    public const string Legendary = "legendary";
}

/// <summary>
/// Konfigurasi reward harvest (data-driven, lihat
/// content/behavior_packs/economy/harvest_config.json — master prompt M/N).
/// </summary>
public static class HarvestConfig
{
    public const double LevelBonusPerLevel = 0.03;
    public const int WaterBonusThreshold = 60;
    public const double WaterBonusMultiplier = 1.25;
    public const int MinimumSeedsOnHarvest = 1;
    public const double WaterDecayPerSecond = 0.2;
    public const double WaterAmountPerWatering = 40;
}
