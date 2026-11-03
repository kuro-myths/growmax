using Godot;
using System.Collections.Generic;

namespace GrowCraft.Client.Farming;

/// <summary>Definisi seed (client copy — sumber kebenaran reward tetap di server).</summary>
public record SeedDef(
    string Id, string Name, string Rarity,
    int GrowthSeconds, int GemMin, int GemMax, int SeedMin, int SeedMax, int Price,
    Color Foliage, Color Fruit);

/// <summary>
/// Balancing farming — identik dengan database/init/02_seed_data.sql dan
/// content/behavior_packs/economy/harvest_config.json (data-driven, master prompt E.1).
/// </summary>
public static class FarmData
{
    public const double LevelBonusPerLevel = 0.03;
    public const int WaterBonusThreshold = 60;
    public const double WaterBonusMultiplier = 1.25;
    public const int MinimumSeedsOnHarvest = 1;
    public const double WaterDecayPerSecond = 0.2;
    public const double WaterAmountPerWatering = 40;

    public static readonly Dictionary<string, SeedDef> Seeds = new()
    {
        ["door"]      = new("door", "Door Tree", "common", 300, 3, 8, 1, 2, 5, new Color("8d6e63"), new Color("ffca28")),
        ["apple"]     = new("apple", "Apple Tree", "uncommon", 900, 10, 20, 1, 3, 25, new Color("66bb6a"), new Color("e53935")),
        ["pine"]      = new("pine", "Pine Tree", "uncommon", 1200, 12, 26, 1, 3, 30, new Color("2e7d32"), new Color("a5d6a7")),
        ["crystal"]   = new("crystal", "Crystal Tree", "rare", 3600, 40, 70, 2, 4, 80, new Color("4dd0e1"), new Color("e1f5fe")),
        ["diamond"]   = new("diamond", "Diamond Tree", "epic", 10800, 120, 250, 3, 5, 250, new Color("80deea"), new Color("ffffff")),
        ["legendary"] = new("legendary", "Legendary Tree", "legendary", 86400, 400, 900, 5, 9, 800, new Color("ffca28"), new Color("ffd740")),
    };

    public static readonly string[] Order = { "door", "apple", "pine", "crystal", "diamond", "legendary" };

    public static string RarityColor(string rarity) => rarity switch
    {
        "common" => "9ca3af",
        "uncommon" => "4ade80",
        "rare" => "60a5fa",
        "epic" => "c084fc",
        "legendary" => "fbbf24",
        _ => "ffffff"
    };
}
