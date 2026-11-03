extends Node3D

const SIZE := 28
const WATER_SCENE := preload("res://scenes/environment/Water.tscn")
const LAVA_SCENE := preload("res://scenes/environment/Lava.tscn")

var materials: Dictionary = {}

func _ready() -> void:
    _environment()
    _create_materials()
    _generate_voxel_layers()
    _place_water()
    _place_lava()
    _decoration()

func _create_materials() -> void:
    materials = {
        "bedrock": _material(Color("#303943")),
        "stone": _material(Color("#697783")),
        "deep": _material(Color("#87939a")),
        "dirt": _material(Color("#95613e")),
        "grass": _material(Color("#68bd55")),
        "sand": _material(Color("#e6d69a")),
        "edge": _material(Color("#43515d"))
    }

func _material(color: Color, glow := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.92
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.5
    return m

func _cube(pos: Vector3, size: Vector3, material: Material, solid := true) -> void:
    var mesh := MeshInstance3D.new()
    var shape_mesh := BoxMesh.new()
    shape_mesh.size = size
    mesh.mesh = shape_mesh
    mesh.material_override = material
    mesh.position = pos
    add_child(mesh)
    if solid:
        var body := StaticBody3D.new()
        body.position = pos
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collider.shape = shape
        body.add_child(collider)
        add_child(body)

func _environment() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d8e8f5")
    env.ambient_light_energy = 0.9
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -35, 0)
    sun.light_energy = 1.15
    sun.shadow_enabled = true
    add_child(sun)

func _generate_voxel_layers() -> void:
    for x in range(SIZE):
        for z in range(SIZE):
            _cube(Vector3(x, -1.5, z), Vector3.ONE, materials.bedrock)
            _cube(Vector3(x, -0.5, z), Vector3.ONE, materials.stone)
            _cube(Vector3(x, 0.5, z), Vector3.ONE, materials.deep)

            var pool := x >= 18 and z >= 3 and z <= 11
            var magma := x >= 2 and x <= 12 and z >= 17
            if pool:
                _cube(Vector3(x, 1.5, z), Vector3.ONE, materials.sand)
            elif magma:
                _cube(Vector3(x, 1.5, z), Vector3.ONE, materials.edge)
            else:
                _cube(Vector3(x, 1.5, z), Vector3.ONE, materials.dirt)
                _cube(Vector3(x, 2.5, z), Vector3.ONE, materials.grass)

    # Low perimeter trim replaces the oversized walls that previously blocked the view.
    for i in range(SIZE):
        _cube(Vector3(i, 2.7, -0.35), Vector3(1, 0.35, 0.35), materials.edge, false)
        _cube(Vector3(i, 2.7, SIZE - 0.65), Vector3(1, 0.35, 0.35), materials.edge, false)
        _cube(Vector3(-0.35, 2.7, i), Vector3(0.35, 0.35, 1), materials.edge, false)
        _cube(Vector3(SIZE - 0.65, 2.7, i), Vector3(0.35, 0.35, 1), materials.edge, false)

func _place_water() -> void:
    var water := WATER_SCENE.instantiate()
    water.position = Vector3(21, 2.75, 7)
    add_child(water)

func _place_lava() -> void:
    var lava := LAVA_SCENE.instantiate()
    lava.position = Vector3(7, 2.75, 21)
    add_child(lava)

func _decoration() -> void:
    var trunk := _material(Color("#765039"))
    var leaf := _material(Color("#348b54"))
    var stone := _material(Color("#a5b0b5"))
    for p in [Vector2i(4, 5), Vector2i(11, 10), Vector2i(15, 20), Vector2i(24, 16)]:
        _cube(Vector3(p.x, 3.25, p.y), Vector3(0.38, 1.1, 0.38), trunk, false)
        _cube(Vector3(p.x, 4.05, p.y), Vector3(1.5, 1.25, 1.5), leaf, false)
    for p in [Vector2i(3, 13), Vector2i(14, 5), Vector2i(25, 23), Vector2i(16, 15)]:
        _cube(Vector3(p.x, 3.0, p.y), Vector3(0.65, 0.35, 0.65), stone, false)
