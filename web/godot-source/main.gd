extends Node3D

const WORLD_SIZE := 28
const WATER_LEVEL := 2.25
const SAFE_SPAWN := Vector3(14.0, 7.0, 14.0)

var player: CharacterBody3D
var camera_pivot: Node3D
var hp := 100
var swim_speed := 3.0
var walk_speed := 5.0
var status_label: Label
var hp_label: Label
var in_water := false
var in_lava := false
var blocks: Array[MeshInstance3D] = []

func _ready() -> void:
    _build_environment()
    _build_terrain()
    _build_water()
    _build_lava()
    _build_player()
    _build_hud()
    _toast("WASD bergerak · Space lompat · Dekati air untuk berenang · Hindari lava")

func _build_environment() -> void:
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
    sun.shadow_enabled = true
    add_child(sun)

func _mat(color: Color, roughness := 0.9, emission := Color.BLACK) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = roughness
    if emission != Color.BLACK:
        m.emission_enabled = true
        m.emission = emission
        m.emission_energy_multiplier = 1.8
    return m

func _cube(parent: Node3D, pos: Vector3, size: Vector3, material: Material, collision := false) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.material_override = material
    node.position = pos
    parent.add_child(node)
    if collision:
        var body := StaticBody3D.new()
        body.position = pos
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        body.add_child(shape)
        parent.add_child(body)
    return node

func _build_terrain() -> void:
    var grass := _mat(Color("#62b84b"))
    var dirt := _mat(Color("#8a5a35"))
    var stone := _mat(Color("#777e83"))
    var deep := _mat(Color("#424b56"))
    var bedrock := _mat(Color("#252b31"))
    for x in range(WORLD_SIZE):
        for z in range(WORLD_SIZE):
            _cube(self, Vector3(x, -0.5, z), Vector3.ONE, bedrock, true)
            _cube(self, Vector3(x, 0.5, z), Vector3.ONE, deep, true)
            _cube(self, Vector3(x, 1.5, z), Vector3.ONE, stone, true)
            _cube(self, Vector3(x, 2.5, z), Vector3.ONE, dirt, true)
            _cube(self, Vector3(x, 3.5, z), Vector3.ONE, grass, true)
    # Dekorasi pulau bertingkat
    for i in range(5):
        var x := 5 + i * 4
        _cube(self, Vector3(x, 6.0 + (i % 2), 7), Vector3(3, 1, 3), grass, true)
        _cube(self, Vector3(x, 5.0 + (i % 2), 7), Vector3(3, 1, 3), dirt, true)
    # Dinding batas dunia
    var wall := _mat(Color("#53616a"))
    for i in range(WORLD_SIZE):
        _cube(self, Vector3(i, 5, -1), Vector3(1, 5, 1), wall, true)
        _cube(self, Vector3(i, 5, WORLD_SIZE), Vector3(1, 5, 1), wall, true)
        _cube(self, Vector3(-1, 5, i), Vector3(1, 5, 1), wall, true)
        _cube(self, Vector3(WORLD_SIZE, 5, i), Vector3(1, 5, 1), wall, true)

func _build_water() -> void:
    var water := _mat(Color(0.12, 0.52, 0.86, 0.62), 0.18)
    water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water.metallic = 0.12
    # Kolam dangkal di sisi timur; area trigger menggunakan Area3D.
    _cube(self, Vector3(21, 2.05, 7), Vector3(7, 0.12, 9), water)
    var area := Area3D.new()
    area.name = "WaterVolume"
    area.position = Vector3(21, 2.9, 7)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(7, 2.2, 9)
    shape.shape = box
    area.add_child(shape)
    area.body_entered.connect(_on_water_enter)
    area.body_exited.connect(_on_water_exit)
    add_child(area)
    var shore := _mat(Color("#d9c78b"))
    _cube(self, Vector3(21, 2.0, 2), Vector3(8, 0.25, 1), shore)

func _build_lava() -> void:
    var lava := _mat(Color("#ff5a16"), 0.35, Color("#ff3b08"))
    _cube(self, Vector3(7, 1.08, 21), Vector3(10, 0.18, 8), lava)
    var area := Area3D.new()
    area.name = "LavaHazard"
    area.position = Vector3(7, 1.8, 21)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(10, 2.0, 8)
    shape.shape = box
    area.add_child(shape)
    area.body_entered.connect(_on_lava_enter)
    area.body_exited.connect(_on_lava_exit)
    add_child(area)
    var rock := _mat(Color("#353238"))
    for i in range(7):
        _cube(self, Vector3(2 + i * 1.5, 1.5, 16), Vector3(1.4, 0.7, 1.4), rock, true)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = SAFE_SPAWN
    var shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    shape.shape = capsule
    shape.position.y = 0.9
    player.add_child(shape)
    var body := MeshInstance3D.new()
    var body_mesh := BoxMesh.new()
    body_mesh.size = Vector3(0.65, 0.9, 0.42)
    body.mesh = body_mesh
    body.material_override = _mat(Color("#398ee8"))
    body.position.y = 1.0
    player.add_child(body)
    var head := MeshInstance3D.new()
    var head_mesh := BoxMesh.new()
    head_mesh.size = Vector3(0.48, 0.48, 0.48)
    head.mesh = head_mesh
    head.material_override = _mat(Color("#ffd0a1"))
    head.position.y = 1.7
    player.add_child(head)
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 2.2, 0)
    player.add_child(camera_pivot)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 5.5, 8.5)
    camera.rotation_degrees.x = -28
    camera.current = true
    camera_pivot.add_child(camera)
    add_child(player)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(310, 90)
    layer.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var title := Label.new()
    title.text = "GROWMAX  ·  GODOT WEB"
    title.add_theme_font_size_override("font_size", 18)
    column.add_child(title)
    hp_label = Label.new()
    hp_label.text = "HP: 100"
    column.add_child(hp_label)
    status_label = Label.new()
    status_label.text = "Zona aman · WASD / Space"
    column.add_child(status_label)
    var help := Label.new()
    help.text = "Kolam: timur  |  Lava: barat daya  |  R: respawn"
    column.add_child(help)

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var speed := swim_speed if in_water else walk_speed
    var velocity := player.velocity
    velocity.x = input.x * speed
    velocity.z = input.y * speed
    if player.is_on_floor():
        velocity.y = 2.0 if in_water else (7.0 if Input.is_action_just_pressed("jump") else 0.0)
    else:
        velocity.y -= (5.0 if in_water else 22.0) * delta
    if in_water:
        velocity.y = maxf(velocity.y, -1.2)
    player.velocity = velocity
    player.move_and_slide()
    player.position.x = clampf(player.position.x, 0.5, WORLD_SIZE - 0.5)
    player.position.z = clampf(player.position.z, 0.5, WORLD_SIZE - 0.5)
    if Input.is_key_pressed(KEY_R):
        _respawn()

func _on_water_enter(body: Node3D) -> void:
    if body == player:
        in_water = true
        status_label.text = "Dalam air · berenang lebih lambat"

func _on_water_exit(body: Node3D) -> void:
    if body == player:
        in_water = false
        status_label.text = "Keluar dari air · zona aman"

func _on_lava_enter(body: Node3D) -> void:
    if body == player:
        in_lava = true
        hp = maxi(0, hp - 35)
        hp_label.text = "HP: %d" % hp
        if hp == 0:
            _respawn()
        else:
            _toast("LAVA! -35 HP · Segera menjauh")
            _respawn()

func _on_lava_exit(body: Node3D) -> void:
    if body == player:
        in_lava = false

func _respawn() -> void:
    player.global_position = SAFE_SPAWN
    player.velocity = Vector3.ZERO
    in_water = false
    in_lava = false
    _toast("Respawn di titik aman · HP %d" % hp)

func _toast(message: String) -> void:
    if status_label:
        status_label.text = message
