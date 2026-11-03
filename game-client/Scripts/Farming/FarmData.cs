using Godot;
using System.Collections.Generic;

namespace GrowCraft.Client.Farming;

/// <summary>Definisi seed (client copy — sumber kebenaran reward tetap di server).</summary>
public record SeedDef(
    string Id, string Name, string Rarity, int RarityScore,
    int GrowthSeconds, int GemMin, int GemMax, int SeedMin, int SeedMax, int Price,
    Color Foliage, Color Fruit);

/// <summary>Tier rarity berdasarkan skor 1-100 (terinspirasi skala seed Growtopia, data orisinal).</summary>
public record RarityTier(string Id, string Name, int Min, int Max, string ColorHex);

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

    public static readonly RarityTier[] Tiers =
    {
        new("common", "Umum", 1, 12, "9ca3af"),
        new("uncommon", "Tidak Umum", 13, 24, "4ade80"),
        new("rare", "Langka", 25, 40, "60a5fa"),
        new("epic", "Epik", 41, 60, "c084fc"),
        new("legendary", "Legendaris", 61, 80, "fbbf24"),
        new("mythic", "Mistis", 81, 100, "fb7185")
    };

    public static RarityTier TierOf(int score) =>
        System.Array.Find(Tiers, t => score >= t.Min && score <= t.Max) ?? Tiers[0];

    public static readonly Dictionary<string, SeedDef> Seeds = new()
    {
        ["door"]      = new("door", "Pohon Pintu", "common", 2, 300, 3, 8, 1, 2, 5, new Color("6dba4b"), new Color("ffca28")),
        ["grass"]     = new("grass", "Pohon Rumput", "common", 5, 420, 4, 10, 1, 2, 8, new Color("86c05a"), new Color("c5e1a5")),
        ["apple"]     = new("apple", "Pohon Apel", "uncommon", 15, 900, 10, 20, 1, 3, 25, new Color("65b84b"), new Color("e53935")),
        ["pine"]      = new("pine", "Pohon Pinus", "uncommon", 17, 1200, 12, 26, 1, 3, 30, new Color("278c58"), new Color("a5d6a7")),
        ["orange"]    = new("orange", "Pohon Jeruk", "uncommon", 19, 1500, 14, 30, 1, 3, 40, new Color("e08a2e"), new Color("ffb74d")),
        ["cactus"]    = new("cactus", "Kaktus Emas", "uncommon", 21, 1800, 18, 38, 2, 3, 55, new Color("3f9e4f"), new Color("ffd54f")),
        ["coral"]     = new("coral", "Terumbu Karang", "rare", 25, 2700, 30, 60, 2, 4, 80, new Color("e06a8a"), new Color("f8bbd0")),
        ["crystal"]   = new("crystal", "Pohon Kristal", "rare", 33, 3600, 40, 70, 2, 4, 120, new Color("54d8d1"), new Color("e1f5fe")),
        ["manggis"]   = new("manggis", "Pohon Manggis", "epic", 41, 5400, 90, 180, 3, 5, 220, new Color("7a5fb8"), new Color("d1c4e9")),
        ["diamond"]   = new("diamond", "Pohon Berlian", "epic", 52, 10800, 120, 250, 3, 5, 350, new Color("5aa6e8"), new Color("ffffff")),
        ["durian"]    = new("durian", "Pohon Durian", "epic", 58, 14400, 200, 420, 4, 6, 500, new Color("9aa632"), new Color("e6ce8a")),
        ["legendary"] = new("legendary", "Pohon Legendaris", "legendary", 72, 43200, 400, 900, 5, 9, 1200, new Color("e6c76b"), new Color("ffd740")),
        ["naga"]      = new("naga", "Pohon Naga", "mythic", 88, 86400, 800, 2000, 6, 10, 2500, new Color("d05a5a"), new Color("ff8a80")),
    };

    public static readonly string[] Order =
    {
        "door", "grass", "apple", "pine", "orange", "cactus",
        "coral", "crystal", "manggis", "diamond", "durian", "legendary", "naga"
    };
}
