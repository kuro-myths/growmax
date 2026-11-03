using Godot;
using System.Collections.Generic;
using GrowCraft.Client.Farming;
using GrowCraft.Client.Networking;
using GrowCraft.Client.Player;
using GrowCraft.Client.Voxel;

namespace GrowCraft.Client.Core;

/// <summary>
/// GrowCraft 3D — entry point game (script root scene Main).
/// Orkestrasi: dunia voxel, player, farming, HUD, reward (seed + gem selalu),
/// day/night cycle, dan koneksi opsional ke API server.
/// </summary>
public partial class Game : Node3D
{
    private VoxelWorld _world = new();
    private PlayerController _player = new();
    private ApiClient? _api;

    // ---------- progres pemain (sim lokal Phase 1; server-authoritative di Phase 5) ----------
    private readonly Dictionary<string, int> _inventory = new()
    {
        ["seed_door"] = 1, ["block_grass"] = 20, ["block_wood"] = 20, ["block_sand"] = 10
    };
    private long _gems = 20;
    private int _level = 1, _xp, _harvested, _planted;

    // ---------- hotbar ----------
    private record Slot(string Kind, string ItemId, string Label);
    private readonly List<Slot> _slots = new()
    {
        new Slot("seed", "seed_door", "🌱 Door"),
        new Slot("seed", "seed_apple", "🌱 Apple"),
        new Slot("seed", "seed_pine", "🌱 Pine"),
        new Slot("seed", "seed_crystal", "🌱 Crystal"),
        new Slot("seed", "seed_diamond", "🌱 Diamond"),
        new Slot("seed", "seed_legendary", "🌱 Legend"),
        new Slot("block", "block_grass", "🟩 Grass"),
        new Slot("block", "block_wood", "🟧 Wood"),
    };
    private int _selected;

    // ---------- HUD ----------
    private Label _hud = new();
    private Label _status = new();
    private Label _info = new();
    private Label _toast = new();
    private HBoxContainer _hotbar = new();
    private readonly List<Button> _hotbarButtons = new();
    private double _toastTimer;
    private double _dayTime; // 0..1 siklus 4 menit

    private static readonly System.Random Rng = new();

    public override void _Ready()
    {
        BuildEnvironment();
        AddChild(_world);
        _world.Generate();

        _player = new PlayerController
        {
            World = _world,
            Position = new Vector3(12, 7.2f, 12)
        };
        AddChild(_player);
        _player.PunchPressed += OnPunch;
        _player.InteractPressed += OnInteract;
        _player.WaterPressed += OnWater;

        BuildHud();

        _api = new ApiClient("http://localhost:5000");
        _ = _api.PingAsync().ContinueWith(t =>
            _status.CallDeferred("set_text",
                t.Result ? "🟢 API online (localhost:5000)" : "⚪ API offline — mode local"));

        ShowToast("Selamat datang di GrowCraft 3D! Punch rumput → garap 🟤, E → tanam 🌱");
    }

    private void BuildEnvironment()
    {
        var sky = new ProceduralSkyMaterial
        {
            SkyTopColor = new Color("4a90d9"),
            SkyHorizonColor = new Color("aee3f5"),
            GroundBottomColor = new Color("28344a")
        };
        var env = new Environment
        {
            BackgroundMode = Environment.BGMode.Sky,
            Sky = new Sky { SkyMaterial = sky },
            AmbientLightSource = Environment.AmbientSource.Sky,
            AmbientLightEnergy = 1.0f,
            Tonemap = Environment.ToneMapper.Filmic
        };
        AddChild(new WorldEnvironment { Environment = env });

        var sun = new DirectionalLight3D
        {
            Name = "Sun",
            Rotation = new Vector3(Mathf.DegToRad(-55), Mathf.DegToRad(-35), 0),
            ShadowEnabled = true,
            LightEnergy = 1.15f
        };
        AddChild(sun);
    }

    // ============================================================
    // INPUT ACTIONS (punch / interact / water datang dari player)
    // ============================================================
    public override void _UnhandledKeyInput(InputEvent @event)
    {
        if (@event is not InputEventKey { Pressed: true } key) return;
        var c = (char)key.Unicode;
        if (c >= '1' && c <= '8')
        {
            _selected = c - '1';
            if (_selected < _slots.Count) RefreshHotbar();
        }
        else if (c == 'b' || c == 'B') ToggleStore();
        else if (c == 'f' || c == 'F')
        {
            PlantNode.TimeScale = PlantNode.TimeScale > 1f ? 1f : 60f;
            ShowToast(PlantNode.TimeScale > 1f
                ? "⏩ Demo 60x ON (tanaman tumbuh 60x lebih cepat)"
                : "⏱ Realtime mode");
        }
    }

    // ============================================================
    // AKSI: PUNCH — panen / garap / hancurkan
    // ============================================================
    private void OnPunch()
    {
        var (x, z) = _player.TargetTile();
        if (!_world.InBounds(x, z)) return;

        var plant = _world.GetPlant(x, z);
        if (plant != null)
        {
            if (plant.IsReady) HarvestPlant(x, z, plant);
            else ShowToast($"{plant.Def.Name}: matang dalam {plant.RemainingText()}");
            return;
        }

        var top = _world.TopBlock(x, z);
        switch (top)
        {
            case BlockType.Grass:
                if (_world.Till(x, z))
                {
                    AddItem(BlockStyle.ItemId(BlockType.FarmSoil), 1);
                    ShowToast("Tanah digarap 🟤 — sekarang tekan E untuk menanam");
                }
                break;
            case BlockType.Bedrock:
                ShowToast("Bedrock tidak bisa dihancurkan!");
                break;
            case BlockType.Air:
                break;
            default:
                var removed = _world.BreakTop(x, z);
                if (removed != BlockType.Air)
                {
                    AddItem(BlockStyle.ItemId(removed), 1);
                    ShowToast($"Dapat {removed}");
                }
                break;
        }
    }

    // ============================================================
    // AKSI: INTERACT (E) — tanam seed / pasang blok
    // ============================================================
    private void OnInteract()
    {
        var (x, z) = _player.TargetTile();
        if (!_world.InBounds(x, z)) return;

        var slot = _slots[_selected];
        if (_world.GetPlant(x, z) != null) { ShowToast("Petak ini sudah ditanami!"); return; }

        if (slot.Kind == "seed")
        {
            if (_world.TopBlock(x, z) != BlockType.FarmSoil)
            {
                ShowToast("Tanam hanya di Tanah Garap 🟤 (punch rumput dulu)");
                return;
            }
            if ((_inventory.GetValueOrDefault(slot.ItemId)) <= 0)
            {
                ShowToast("Seed habis! Beli di toko (B)");
                return;
            }
            var def = FarmData.Seeds[slot.ItemId["seed_".Length..]];
            _inventory[slot.ItemId] -= 1;
            _planted++;
            _world.PlantSeed(x, z, def, (long)Time.GetUnixTimeFromSystem());
            ShowToast($"🌱 Ditanam: {def.Name} ({plant_time_text(def)})");
        }
        else
        {
            if (_inventory.GetValueOrDefault(slot.ItemId) <= 0)
            {
                ShowToast("Block habis!");
                return;
            }
            var type = slot.ItemId == "block_wood" ? BlockType.Wood
                : slot.ItemId == "block_sand" ? BlockType.Sand
                : BlockType.Grass;
            if (_world.PlaceTop(x, z, type))
            {
                _inventory[slot.ItemId] -= 1;
                ShowToast($"Blok {type} dipasang");
            }
        }
        RefreshHotbar();
    }

    private static string plant_time_text(SeedDef def)
    {
        var s = PlantNode.TimeScale > 1f ? def.GrowthSeconds / (int)PlantNode.TimeScale : def.GrowthSeconds;
        var h = s / 3600; var m = (s % 3600) / 60;
        return h > 0 ? $"{h}j{m}m" : m > 0 ? $"{m}m" : $"{s}s";
    }

    // ============================================================
    // AKSI: WATER (Q)
    // ============================================================
    private void OnWater()
    {
        var (x, z) = _player.TargetTile();
        if (!_world.InBounds(x, z)) return;
        var plant = _world.GetPlant(x, z);
        if (plant == null) { ShowToast("Tidak ada tanaman di tile itu"); return; }

        plant.AddWater((int)FarmData.WaterAmountPerWatering);
        ShowToast($"💧 Disiram! Air {plant.Water}% — air ≥{FarmData.WaterBonusThreshold}% saat panen = +25% gem");
    }

    // ============================================================
    // REWARD ENGINE — selalu dapat seed + gem (rumus identik server)
    // ============================================================
    private void HarvestPlant(int x, int z, PlantNode plant)
    {
        var def = plant.Def;
        var lvlBonus = 1 + (_level - 1) * FarmData.LevelBonusPerLevel;
        var wet = plant.Water >= FarmData.WaterBonusThreshold;

        var seedsGained = System.Math.Max(FarmData.MinimumSeedsOnHarvest,
            (int)System.Math.Round(Rng.Next(def.SeedMin, def.SeedMax + 1) * lvlBonus));
        var gemsGained = (long)System.Math.Round(
            Rng.Next(def.GemMin, def.GemMax + 1) * lvlBonus
            * (wet ? FarmData.WaterBonusMultiplier : 1));

        AddItem($"seed_{def.Id}", seedsGained);
        _gems += gemsGained;
        _harvested++;
        AddXp((int)(gemsGained * 0.25) + 5);

        _world.RemovePlant(x, z);
        ShowToast($"🎉 Panen {def.Name}! +{seedsGained} seed, +{gemsGained} 💎{(wet ? " (💧 bonus +25%)" : "")}");
        RefreshHotbar();
        UpdateHud();
    }

    private void AddXp(int n)
    {
        _xp += n;
        var leveled = false;
        while (_xp >= _level * 100) { _xp -= _level * 100; _level++; leveled = true; }
        if (leveled) ShowToast($"⬆️ Level {_level}! Bonus panen +3%/lvl");
    }

    private void AddItem(string itemId, int n)
    {
        _inventory[itemId] = _inventory.GetValueOrDefault(itemId) + n;
        RefreshHotbar();
    }

    // ============================================================
    // TOKO SEDERHANA (B) — beli seed pakai gem (full store = Phase 8)
    // ============================================================
    private bool _storeOpen;
    private PopupMenu? _storeMenu;

    private void ToggleStore()
    {
        if (!_storeOpen)
        {
            _storeMenu = new PopupMenu();
            foreach (var id in FarmData.Order)
            {
                var def = FarmData.Seeds[id];
                _storeMenu.AddItem($"{def.Name} [{def.Rarity}] — 💎{def.Price}", FarmData.Order.ToList().IndexOf(id));
            }
            _storeMenu.IndexPressed += idx => BuySeed(FarmData.Order[idx]);
            AddChild(_storeMenu);
            var vp = GetViewport().GetVisibleRect();
            _storeMenu.Position = new Vector2I((int)(vp.Size.X / 2 - 150), (int)(vp.Size.Y / 2 - 100));
            _storeMenu.Size = new Vector2I(300, 0);
            _storeMenu.PopupCentered();
            _storeOpen = true;
        }
        else
        {
            _storeMenu?.QueueFree();
            _storeMenu = null;
            _storeOpen = false;
        }
    }

    private void BuySeed(string seedId)
    {
        var def = FarmData.Seeds[seedId];
        if (_gems < def.Price)
        {
            ShowToast($"💎 tidak cukup! Butuh {def.Price}, punya {_gems}. Panen dulu!");
            return;
        }
        _gems -= def.Price;
        AddItem($"seed_{def.Id}", 1);
        ShowToast($"Beli {def.Name} Seed! Sisa 💎{_gems}");
        UpdateHud();
        ToggleStore();
    }

    // ============================================================
    // HUD
    // ============================================================
    private void BuildHud()
    {
        var layer = new CanvasLayer();
        AddChild(layer);

        var panel = new PanelContainer
        {
            AnchorsPreset = (int)Control.LayoutPreset.TopLeft,
            OffsetLeft = 12, OffsetTop = 12
        };
        var vbox = new VBoxContainer();
        _hud = new Label();
        _status = new Label { Modulate = new Color(1, 1, 1, 0.8f) };
        vbox.AddChild(_hud);
        vbox.AddChild(_status);
        panel.AddChild(vbox);
        layer.AddChild(panel);

        _toast = new Label
        {
            AnchorsPreset = (int)Control.LayoutPreset.CenterTop,
            OffsetTop = 60,
            HorizontalAlignment = HorizontalAlignment.Center
        };
        _toast.AddThemeFontSizeOverride("font_size", 18);
        layer.AddChild(_toast);

        var hotbarPanel = new PanelContainer
        {
            AnchorsPreset = (int)Control.LayoutPreset.CenterBottom,
            OffsetBottom = -14
        };
        _hotbar = new HBoxContainer { Separation = 6 };
        hotbarPanel.AddChild(_hotbar);
        layer.AddChild(hotbarPanel);

        _info = new Label
        {
            AnchorsPreset = (int)Control.LayoutPreset.CenterBottom,
            OffsetBottom = -76,
            HorizontalAlignment = HorizontalAlignment.Center
        };
        layer.AddChild(_info);

        RefreshHotbar();
        UpdateHud();
    }

    private void RefreshHotbar()
    {
        foreach (var child in _hotbar.GetChildren()) child.QueueFree();
        _hotbarButtons.Clear();

        for (var i = 0; i < _slots.Count; i++)
        {
            var idx = i;
            var slot = _slots[i];
            var qty = _inventory.GetValueOrDefault(slot.ItemId);
            var btn = new Button
            {
                Text = $"{i + 1}\n{slot.Label}\n{qty}",
                CustomMinimumSize = new Vector2(74, 0),
                ToggleMode = true,
                ButtonPressed = i == _selected
            };
            btn.Pressed += () => { _selected = idx; RefreshHotbar(); };
            _hotbar.AddChild(btn);
            _hotbarButtons.Add(btn);
        }
    }

    private void UpdateHud()
    {
        _hud.Text = $"💎 {_gems}   Lv.{_level} ({_xp}/{_level * 100})   🌾 {_harvested} panen   🌱 {_planted} tanam";
    }

    private void ShowToast(string msg)
    {
        _toast.Text = msg;
        _toastTimer = 2.6;
    }

    // ============================================================
    // DAY / NIGHT CYCLE (4 menit = 1 hari) + info tile target
    // ============================================================
    public override void _Process(double delta)
    {
        _dayTime += delta / 240.0;
        if (_dayTime > 1) _dayTime -= 1;

        if (GetNodeOrNull<DirectionalLight3D>("Sun") is { } sun)
        {
            var ang = _dayTime * Mathf.Tau;
            sun.Rotation = new Vector3(Mathf.DegToRad(-55), Mathf.DegToRad(-35) + ang, 0);
            sun.LightEnergy = 0.25f + 0.9f * Mathf.Max(0, Mathf.Sin(Mathf.Pi * _dayTime));
        }

        if (_toastTimer > 0)
        {
            _toastTimer -= delta;
            _toast.Modulate = new Color(1, 1, 1, (float)System.Math.Clamp(_toastTimer / 0.6, 0, 1));
        }
        else _toast.Modulate = new Color(1, 1, 1, 0);

        var (x, z) = _player.TargetTile();
        _world.ShowHighlight(x, z, _world.InBounds(x, z));
        if (_world.InBounds(x, z))
        {
            var plant = _world.GetPlant(x, z);
            _info.Text = plant != null
                ? $"{plant.Def.Name} [{plant.Def.Rarity}] · {plant.RemainingText()} · 💧{plant.Water}%"
                : $"Tile ({x},{z}) · klik kiri: garap/panen · E: tanam/pasang · Q: siram";
        }
        else _info.Text = "";
    }
}
