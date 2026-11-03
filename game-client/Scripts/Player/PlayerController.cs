using Godot;
using GrowCraft.Client.Voxel;

namespace GrowCraft.Client.Player;

/// <summary>
/// Karakter voxel 3D (sesuai konsep: blocky character) — third-person camera,
/// WASD jalan, Space lompat, klik kiri punch, E interaksi/tanam, Q siram.
/// </summary>
public partial class PlayerController : CharacterBody3D
{
    private float _punchCd;
    private MeshInstance3D _body = new();
    private MeshInstance3D _head = new();

    /// <summary>Arah hadap di bidang XZ (unit vector).</summary>
    public Vector3 Facing = new(0, 0, -1);

    public VoxelWorld? World { get; set; }

    /// <summary>Klik kiri (punch): garap / hancurkan / panen. Game yang memproses.</summary>
    public event Action? PunchPressed;
    /// <summary>E (interact): tanam seed / pasang blok.</summary>
    public event Action? InteractPressed;
    /// <summary>Q (water): siram tanaman di tile target.</summary>
    public event Action? WaterPressed;

    public (int x, int z) TargetTile()
    {
        var t = GlobalPosition + Facing * 1.5f;
        return ((int)Mathf.Floor(t.X), (int)Mathf.Floor(t.Z));
    }

    public override void _Ready()
    {
        var shape = new CollisionShape3D
        {
            Shape = new CapsuleShape3D { Radius = 0.35f, Height = 1.8f },
            Position = new Vector3(0, 0.9f, 0)
        };
        AddChild(shape);

        _body = new MeshInstance3D
        {
            Mesh = new BoxMesh { Size = new Vector3(0.6f, 0.9f, 0.4f) },
            MaterialOverride = new StandardMaterial3D { AlbedoColor = new Color("42a5f5") },
            Position = new Vector3(0, 1.0f, 0)
        };
        _head = new MeshInstance3D
        {
            Mesh = new BoxMesh { Size = new Vector3(0.5f, 0.5f, 0.5f) },
            MaterialOverride = new StandardMaterial3D { AlbedoColor = new Color("ffcc80") },
            Position = new Vector3(0, 1.7f, 0)
        };
        AddChild(_body);
        AddChild(_head);

        var camera = new Camera3D
        {
            Position = new Vector3(0, 6.5f, 8.5f),
            Rotation = new Vector3(Mathf.DegToRad(-32), 0, 0),
            Current = true,
            Fov = 60
        };
        AddChild(camera);
    }

    public override void _PhysicsProcess(double delta)
    {
        var input = Input.GetVector("move_left", "move_right", "move_forward", "move_back");
        var dir = new Vector3(input.X, 0, input.Y);

        var velocity = Velocity;
        if (dir.LengthSquared() > 0.001f)
        {
            Facing = dir.Normalized();
            velocity.X = dir.X * 4.5f;
            velocity.Z = dir.Y * 4.5f;
            _body.Rotation = new Vector3(Mathf.Sin(Time.GetTicksMsec() / 90.0f) * 0.05f, 0, 0);
        }
        else
        {
            velocity.X = Mathf.MoveToward(velocity.X, 0, 12f * (float)delta);
            velocity.Z = Mathf.MoveToward(velocity.Z, 0, 12f * (float)delta);
        }

        velocity.Y -= 22f * (float)delta;
        if (IsOnFloor() && Input.IsActionJustPressed("jump"))
            velocity.Y = 8.5f;

        Velocity = velocity;
        MoveAndSlide();

        // jaga tetap di dalam dunia
        if (World != null)
        {
            var p = GlobalPosition;
            GlobalPosition = new Vector3(
                Mathf.Clamp(p.X, 0.6f, VoxelWorld.W - 0.6f), p.Y,
                Mathf.Clamp(p.Z, 0.6f, VoxelWorld.D - 0.6f));
        }

        _punchCd -= (float)delta;
        if (Input.IsMouseButtonPressed(MouseButton.Left) && _punchCd <= 0)
        {
            _punchCd = 0.3f;
            PunchPressed?.Invoke();
        }
        if (Input.IsActionJustPressed("interact")) InteractPressed?.Invoke();
        if (Input.IsActionJustPressed("water")) WaterPressed?.Invoke();
    }
}
