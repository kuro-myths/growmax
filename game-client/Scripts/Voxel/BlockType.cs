using Godot;

namespace GrowCraft.Client.Voxel;

/// <summary>Jenis blok dunia — sama urutannya dengan backend (world_blocks.block_type).</summary>
public enum BlockType : byte
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

/// <summary>Warna voxel — disamakan dengan konsep visual (rumput hijau, tanah, batu, floating island).</summary>
public static class BlockStyle
{
    public static Color Top(BlockType t) => t switch
    {
        BlockType.Grass => new Color("5cbb3c"),
        BlockType.Dirt => new Color("8a5a33"),
        BlockType.Stone => new Color("8d8d8d"),
        BlockType.Bedrock => new Color("333333"),
        BlockType.Wood => new Color("a0743c"),
        BlockType.Sand => new Color("e7d492"),
        BlockType.FarmSoil => new Color("5a3a1e"),
        _ => new Color(1, 0, 1)
    };

    public static Color Side(BlockType t) => t switch
    {
        BlockType.Grass => new Color("4a8f2f"),
        BlockType.Dirt => new Color("6e4626"),
        BlockType.Stone => new Color("6f6f6f"),
        BlockType.Bedrock => new Color("262626"),
        BlockType.Wood => new Color("7d5a2e"),
        BlockType.Sand => new Color("c4b074"),
        BlockType.FarmSoil => new Color("4a2f18"),
        _ => new Color(1, 0, 1)
    };

    public static string ItemId(BlockType t) => $"block_{t.ToString().ToLowerInvariant()}";
}
