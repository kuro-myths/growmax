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
        "bedrock": _material(Color("#253b4a")),
        "stone": _material(Color("#687985")),
        "deep": _material(Color("#8a684d")),
        "dirt": _material(Color("#94603b")),
        "grass": _material(Color("#70bd50")),
        "grass_alt": _material(Color("#7acb59")),
        "sand": _material(Color("#e9d39a")),
        "edge": _material(Color("#3d5360")),
        "path": _material(Color("#b58b5b")),
        "leaf": _material(Color("#318b4d")),
        "leaf_light": _material(Color("#57b85a")),
        "wood": _material(Color("#795039")),
        "rock": _material(Color("#87959a"))
    }

func _material(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.9
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
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color("#4b9ed0")
    sky_mat.sky_horizon_color = Color("#b9e5f2")
    sky_mat.ground_bottom_color = Color("#41647a")
    sky_mat.ground_horizon_color = Color("#9ccbd9")
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color("#d8e8f5")
    env.ambient_light_energy = 0.85
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -35, 0)
    sun.light_energy = 1.25
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
                _cube(Vector3(x, 1.5, z), Vector3.ONE, materials.deep)
            else:
                var grass_material: Material = materials.grass_alt if (x + z) % 2 == 0 else materials.grass
                _cube(Vector3(x, 1.5, z), Vector3.ONE, materials.dirt)
                _cube(Vector3(x, 2.5, z), Vector3.ONE, grass_material)

    # Decorative stepping-stone path makes the playable surface easier to read.
    for i in range(5, 23):
        if i % 2 == 0:
            _cube(Vector3(i, 3.015, 14), Vector3(0.72, 0.035, 0.72), materials.path, false)

    # Low perimeter curb, not tall walls.
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

func _tree(x: float, z: float, scale: float = 1.0) -> void:
    _cube(Vector3(x, 3.25 * scale, z), Vector3(0.42, 1.25, 0.42) * scale, materials.wood, false)
    _cube(Vector3(x, 4.05 * scale, z), Vector3(1.65, 1.2, 1.65) * scale, materials.leaf, false)
    _cube(Vector3(x - 0.42 * scale, 4.35 * scale, z), Vector3(0.8, 0.75, 0.8) * scale, materials.leaf_light, false)
    _cube(Vector3(x + 0.38 * scale, 3.95 * scale, z + 0.32 * scale), Vector3(0.85, 0.8, 0.85) * scale, materials.leaf_light, false)

func _decoration() -> void:
    for p in [Vector2i(4, 5), Vector2i(11, 10), Vector2i(15, 20), Vector2i(24, 16), Vector2i(5, 24), Vector2i(24, 4)]:
        _tree(p.x, p.y, 0.9)
    for p in [Vector2i(3, 13), Vector2i(14, 5), Vector2i(25, 23), Vector2i(16, 15), Vector2i(19, 15), Vector2i(9, 8)]:
        _cube(Vector3(p.x, 3.0, p.y), Vector3(0.65, 0.35, 0.65), materials.rock, false)
