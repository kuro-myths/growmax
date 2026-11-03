using Godot;
using GrowCraft.Client.Farming;

namespace GrowCraft.Client.Farming;

/// <summary>
/// Tanaman 3D dengan tahap growth + timer Label3D (sesuai gambar konsep:
/// seed → sprout → growing → siap panen dengan countdown).
/// Pertumbuhan dihitung dari unix time → tetap jalan saat game ditutup (server-parity).
/// </summary>
public partial class PlantNode : Node3D
{
    private SeedDef _def = FarmData.Seeds["door"];
    private long _plantedUnix;
    private int _water = 100;

    private MeshInstance3D _trunk = new();
    private MeshInstance3D _leaves = new();
    private Label3D _label = new();
    private int _stage = -1;

    /// <summary>Skala demo (F di game): 1 = realtime penuh, 60 = 60x lebih cepat.</summary>
    public static float TimeScale = 1f;

    public PlantNode() { }
    public PlantNode(SeedDef def, long plantedUnix)
    {
        _def = def;
        _plantedUnix = plantedUnix;
    }

    public SeedDef Def => _def;
    public int Water => _water;

    public double EffectiveGrowthSeconds => _def.GrowthSeconds / (double)TimeScale;

    public double Elapsed => Time.GetUnixTimeFromSystem() - _plantedUnix;
    public double Progress => System.Math.Clamp(Elapsed / EffectiveGrowthSeconds, 0, 1);
    public int RemainingSeconds => System.Math.Max(0, (int)System.Math.Ceiling(EffectiveGrowthSeconds - Elapsed));
    public bool IsReady => RemainingSeconds <= 0;

    public void AddWater(int amount)
    {
        _water = System.Math.Min(100, _water + amount);
    }

    public string RemainingText()
    {
        var s = RemainingSeconds;
        var h = s / 3600; var m = (s % 3600) / 60; var sec = s % 60;
        return h > 0
            ? $"{h:00}:{m:00}:{sec:00}"
            : $"{m:00}:{sec:00}";
    }

    public override void _Ready()
    {
        _trunk = new MeshInstance3D
        {
            Mesh = new BoxMesh { Size = new Vector3(0.18f, 1f, 0.18f) },
            MaterialOverride = new StandardMaterial3D { AlbedoColor = new Color("5d4037") }
        };
        _leaves = new MeshInstance3D
        {
            Mesh = new BoxMesh { Size = Vector3.One },
            MaterialOverride = new StandardMaterial3D
            {
                AlbedoColor = _def.Foliage,
                EmissionEnabled = false,
                Emission = _def.Fruit
            }
        };
        _label = new Label3D
        {
            Billboard = BaseMaterial3D.BillboardMode.Enabled,
            PixelSize = 0.01f,
            Modulate = new Color(1, 1, 1),
            OutlineSize = 8,
            FontSize = 32
        };
        AddChild(_trunk);
        AddChild(_leaves);
        AddChild(_label);
        UpdateVisuals();
    }

    public override void _Process(double delta)
    {
        // kelembapan turun per detik (visual; validasi asli di server)
        _water = System.Math.Max(0, _water - (int)(FarmData.WaterDecayPerSecond * delta));
        UpdateVisuals();
    }

    private void UpdateVisuals()
    {
        var stage = System.Math.Clamp((int)(Progress * 5), 0, 5); // 0..4 tumbuh, 5 siap
        if (stage != _stage)
        {
            _stage = stage;
            var trunkH = 0.2f + stage * 0.55f;
            _trunk.Scale = new Vector3(1, trunkH, 1);
            _trunk.Position = new Vector3(0, trunkH / 2f, 0);

            var leafSize = 0.15f + stage * 0.28f;
            _leaves.Scale = new Vector3(leafSize, leafSize, leafSize);
            _leaves.Position = new Vector3(0, trunkH + leafSize / 2f, 0);

            var mat = (StandardMaterial3D)_leaves.MaterialOverride;
            mat.EmissionEnabled = IsReady;
        }

        _label.Position = new Vector3(0, (_trunk.Scale.Y + _leaves.Scale.Y + 0.4f), 0);
        _label.Text = IsReady
            ? $"[b]{_def.Name} — SIAP PANEN! (punch)[/b]\n💧{_water}%"
            : $"{_def.Name} [{_def.Rarity}]\n{RemainingText()} · 💧{_water}%";
        _label.Modulate = IsReady
            ? new Color("ffe082")
            : new Color(1, 1, 1, 0.9f);
    }
}
