extends Node3D
const SIZE := 28
const WATER_SCENE := preload("res://scenes/environment/Water.tscn")
const LAVA_SCENE := preload("res://scenes/environment/Lava.tscn")
func _ready() -> void:
    _environment()
    _generate_voxel_layers()
    _place_water()
    _place_lava()
    _decoration()
func _material(color: Color, glow := false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
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
    env.ambient_light_color = Color(0.72, 0.82, 0.95)
    env.ambient_light_energy = 0.8
    world_env.environment = env
    add_child(world_env)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-52, -35, 0)
    sun.light_energy = 1.25
    add_child(sun)
func _generate_voxel_layers() -> void:
    var layers := [
        _material(Color("#252b31")),
        _material(Color("#424b56")),
        _material(Color("#777e83")),
        _material(Color("#8a5a35")),
        _material(Color("#62b84b"))
    ]
    for x in range(SIZE):
        for z in range(SIZE):
            for layer in range(3):
                _cube(Vector3(x, -0.5 + layer, z), Vector3.ONE, layers[layer])
            var pool := x >= 18 and z >= 3 and z <= 11
            var magma := x >= 2 and x <= 12 and z >= 17
            if not pool and not magma:
                _cube(Vector3(x, 2.5, z), Vector3.ONE, layers[3])
                _cube(Vector3(x, 3.5, z), Vector3.ONE, layers[4])
    var wall := _material(Color("#53616a"))
    for i in range(SIZE):
        _cube(Vector3(i, 5, -1), Vector3(1, 5, 1), wall)
        _cube(Vector3(i, 5, SIZE), Vector3(1, 5, 1), wall)
        _cube(Vector3(-1, 5, i), Vector3(1, 5, 1), wall)
        _cube(Vector3(SIZE, 5, i), Vector3(1, 5, 1), wall)
func _place_water() -> void:
    var water := WATER_SCENE.instantiate()
    water.position = Vector3(21, 3.5, 7)
    add_child(water)
    _cube(Vector3(21, 2.85, 7), Vector3(7, 0.12, 9), _material(Color("#d9c78b")))
func _place_lava() -> void:
    var lava := LAVA_SCENE.instantiate()
    lava.position = Vector3(7, 3.5, 21)
    add_child(lava)
    var rock := _material(Color("#353238"))
    for i in range(7):
        _cube(Vector3(2 + i * 1.5, 2.2, 16), Vector3(1.4, 0.7, 1.4), rock)
func _decoration() -> void:
    var grass := _material(Color("#62b84b"))
    var dirt := _material(Color("#8a5a35"))
    for i in range(5):
        var x := 5 + i * 4
        _cube(Vector3(x, 6.0 + (i % 2), 7), Vector3(3, 1, 3), grass)
        _cube(Vector3(x, 5.0 + (i % 2), 7), Vector3(3, 1, 3), dirt)
