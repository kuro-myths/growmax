using Godot;
using System.Collections.Generic;
using GrowCraft.Client.Farming;

namespace GrowCraft.Client.Voxel;

/// <summary>
/// Dunia voxel 3D: terrain berlapis (bedrock → stone → dirt → grass) + floating islands,
/// sesuai konsep visual. Kolom dirender hanya jika selnya terekspos (culling sederhana).
/// Satu StaticBody3D per solid-run memberi collision yang benar (bisa berjalan di bawah pulau).
/// </summary>
public partial class VoxelWorld : Node3D
{
    public const int W = 24, D = 24, H = 12; // terrain 6 lapis + ruang untuk floating islands
    private const int TerrainH = 6;

    private readonly byte[,,] _blocks = new byte[W, D, H];
    private readonly Dictionary<(int x, int z), Node3D> _columns = new();
    private readonly Dictionary<(int x, int z), PlantNode> _plants = new();

    private BoxMesh _box = new();
    private MeshInstance3D? _highlight;
    private readonly Dictionary<BlockType, StandardMaterial3D> _mats = new();

    public bool InBounds(int x, int z) => x >= 0 && x < W && z >= 0 && z < D;

    public override void _Ready()
    {
        _box = new BoxMesh { Size = Vector3.One };
        foreach (BlockType t in System.Enum.GetValues(typeof(BlockType)))
        {
            if (t == BlockType.Air) continue;
            _mats[t] = new StandardMaterial3D { AlbedoColor = BlockStyle.Top(t) };
        }
        _highlight = new MeshInstance3D
        {
            Mesh = new BoxMesh { Size = new Vector3(1.02f, 0.08f, 1.02f) },
            MaterialOverride = new StandardMaterial3D
            {
                AlbedoColor = new Color("ffd166"),
                Transparency = BaseMaterial3D.TransparencyEnum.Alpha,
                AlbedoColorAlpha = 0.5f,
                ShadingMode = BaseMaterial3D.ShadingModeEnum.Unshaded
            },
            Visible = false
        };
        AddChild(_highlight);
        Generate();
    }

    /// <summary>Generasi terrain awal — struktur layer sama seperti POST /api/worlds di backend.</summary>
    public void Generate()
    {
        for (var x = 0; x < W; x++)
        for (var z = 0; z < D; z++)
        for (var y = 0; y < TerrainH; y++)
        {
            var type = y switch
            {
                0 => BlockType.Bedrock,
                < 3 => BlockType.Stone,
                < 5 => BlockType.Dirt,
                _ => (x < 2 ? BlockType.Sand : BlockType.Grass)
            };
            SetCell(x, y, z, type);
        }

        // Floating islands (sesuai gambar konsep)
        MakeIsland(6, 8, 10);
        MakeIsland(17, 8, 7);
        MakeIsland(11, 10, 17);

        for (var x = 0; x < W; x++)
        for (var z = 0; z < D; z++)
            RebuildColumn(x, z);
    }

    private void MakeIsland(int cx, int grassY, int cz)
    {
        for (var dx = -2; dx <= 2; dx++)
        for (var dz = -2; dz <= 2; dz++)
        {
            if (System.Math.Abs(dx) == 2 && System.Math.Abs(dz) == 2) continue; // sudut dibulatkan
            var x = cx + dx; var z = cz + dz;
            if (!InBounds(x, z)) continue;
            if (grassY >= H) continue;
            SetCell(x, grassY, z, BlockType.Grass);
            if (grassY - 1 >= 0) SetCell(x, grassY - 1, z, BlockType.Dirt);
        }
    }

    private BlockType GetCell(int x, int y, int z) => (BlockType)_blocks[x, z, y];
    private void SetCell(int x, int y, int z, BlockType t) => _blocks[x, z, y] = (byte)t;

    public int TopY(int x, int z)
    {
        for (var y = H - 1; y >= 0; y--)
            if (GetCell(x, y, z) != BlockType.Air) return y;
        return -1;
    }

    public float SurfaceY(int x, int z) => TopY(x, z) + 1f;
    public BlockType TopBlock(int x, int z) => TopY(x, z) < 0 ? BlockType.Air : GetCell(x, TopY(x, z), z);

    // ---------- interaksi blok ----------
    public bool Till(int x, int z)
    {
        var y = TopY(x, z);
        if (y < 0 || GetCell(x, y, z) != BlockType.Grass) return false;
        SetCell(x, y, z, BlockType.FarmSoil);
        RebuildColumn(x, z);
        return true;
    }

    /// <summary>Hancurkan blok teratas. Bedrock tidak bisa. Return tipe yang diambil (Air = gagal).</summary>
    public BlockType BreakTop(int x, int z)
    {
        var y = TopY(x, z);
        if (y < 0) return BlockType.Air;
        var type = GetCell(x, y, z);
        if (type == BlockType.Bedrock) return BlockType.Air;
        SetCell(x, y, z, BlockType.Air);
        RebuildColumn(x, z);
        return type;
    }

    public bool PlaceTop(int x, int z, BlockType type)
    {
        var y = TopY(x, z) + 1;
        if (y >= H || !InBounds(x, z)) return false;
        SetCell(x, y, z, type);
        RebuildColumn(x, z);
        return true;
    }

    // ---------- farming ----------
    public PlantNode? GetPlant(int x, int z) => _plants.GetValueOrDefault((x, z));

    public PlantNode? PlantSeed(int x, int z, SeedDef def, long plantedUnix)
    {
        if (!InBounds(x, z)) return null;
        if (TopBlock(x, z) != BlockType.FarmSoil) return null;
        if (_plants.ContainsKey((x, z))) return null;

        var node = new PlantNode(def, plantedUnix)
        {
            Position = new Vector3(x + 0.5f, SurfaceY(x, z), z + 0.5f)
        };
        AddChild(node);
        _plants[(x, z)] = node;
        return node;
    }

    public void RemovePlant(int x, int z)
    {
        if (_plants.Remove((x, z), out var node))
            node.QueueFree();
    }

    // ---------- rendering per kolom ----------
    private void RebuildColumn(int x, int z)
    {
        if (_columns.TryGetValue((x, z), out var old))
        {
            old.QueueFree();
            _columns.Remove((x, z));
        }

        var column = new Node3D { Name = $"col_{x}_{z}" };
        AddChild(column);
        _columns[(x, z)] = column;

        // blok terekspos: atas udara / bawah udara / tepi depan-kiri (tampilan potongan layer)
        for (var y = 0; y < H; y++)
        {
            var t = GetCell(x, y, z);
            if (t == BlockType.Air) continue;
            var above = y + 1 >= H || GetCell(x, y + 1, z) == BlockType.Air;
            var below = y - 1 < 0 || GetCell(x, y - 1, z) == BlockType.Air;
            var edge = z == D - 1 || x == 0;
            if (!above && !below && !edge) continue;

            var mi = new MeshInstance3D
            {
                Mesh = _box,
                MaterialOverride = _mats[t],
                Position = new Vector3(x + 0.5f, y + 0.5f, z + 0.5f)
            };
            column.AddChild(mi);
        }

        // collision: satu StaticBody3D per solid-run
        var runStart = -1;
        for (var y = 0; y <= H; y++)
        {
            var solid = y < H && GetCell(x, y, z) != BlockType.Air;
            if (solid && runStart < 0) runStart = y;
            if (!solid && runStart >= 0)
            {
                AddRunBody(column, x, z, runStart, y - 1);
                runStart = -1;
            }
        }
    }

    private void AddRunBody(Node3D column, int x, int z, int y0, int y1)
    {
        var height = y1 - y0 + 1;
        var body = new StaticBody3D();
        var shape = new CollisionShape3D
        {
            Shape = new BoxShape3D { Size = new Vector3(1f, height, 1f) },
            Position = new Vector3(x + 0.5f, y0 + height / 2f, z + 0.5f)
        };
        body.AddChild(shape);
        column.AddChild(body);
    }

    // ---------- highlight tile target ----------
    public void ShowHighlight(int x, int z, bool visible)
    {
        if (_highlight is null) return;
        _highlight.Visible = visible && InBounds(x, z);
        if (_highlight.Visible)
            _highlight.Position = new Vector3(x + 0.5f, SurfaceY(x, z) + 0.05f, z + 0.5f);
    }
}
