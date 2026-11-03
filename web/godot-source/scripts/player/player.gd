extends CharacterBody3D

signal health_changed(value: int)
signal environment_changed(message: String)

const SPEED := 5.0
const SWIM_SPEED := 3.0
const JUMP_VELOCITY := 7.0

var health := 100
var in_water := false
var safe_spawn := Vector3(14, 4.2, 14)
var body_mesh: MeshInstance3D
var camera: Camera3D

func _ready() -> void:
    name = "Player"
    _build_character()
    _build_camera()

func _build_character() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.34
    capsule.height = 1.7
    var collider := CollisionShape3D.new()
    collider.shape = capsule
    collider.position.y = 0.85
    add_child(collider)

    body_mesh = MeshInstance3D.new()
    var body := BoxMesh.new()
    body.size = Vector3(0.62, 0.88, 0.42)
    body_mesh.mesh = body
    body_mesh.position.y = 0.94
    body_mesh.material_override = _material(Color("#287bd8"))
    add_child(body_mesh)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.27
    head_mesh.height = 0.54
    head.mesh = head_mesh
    head.position.y = 1.62
    head.material_override = _material(Color("#ffd1a6"))
    add_child(head)

    var hair := MeshInstance3D.new()
    var hair_mesh := SphereMesh.new()
    hair_mesh.radius = 0.275
    hair_mesh.height = 0.25
    hair.mesh = hair_mesh
    hair.position = Vector3(0, 1.82, 0)
    hair.material_override = _material(Color("#45352f"))
    add_child(hair)

func _build_camera() -> void:
    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.position = Vector3(0, 19, 19)
    camera.rotation_degrees = Vector3(-45, 0, 0)
    camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    camera.size = 27.5
    camera.current = true
    camera.far = 150.0
    add_child(camera)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.85
    return material

# Keyboard input must never drive the character while a chat or other text
# control owns GUI focus. Input.is_key_pressed() alone ignores that distinction.
func _is_text_entry_focused() -> bool:
    var focused := get_viewport().gui_get_focus_owner()
    return focused is LineEdit or focused is TextEdit or focused is CodeEdit

func _physics_process(delta: float) -> void:
    var typing := _is_text_entry_focused()
    var axis := Vector2.ZERO
    if not typing:
        axis.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
        axis.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    axis = axis.normalized() if axis.length() > 1.0 else axis

    var speed := SWIM_SPEED if in_water else SPEED
    velocity.x = axis.x * speed
    velocity.z = axis.y * speed

    if not is_on_floor():
        velocity.y -= (5.0 if in_water else 22.0) * delta
    elif not typing and Input.is_key_pressed(KEY_SPACE):
        velocity.y = 2.0 if in_water else JUMP_VELOCITY
    elif is_on_floor():
        velocity.y = 0.0

    if in_water:
        velocity.y = maxf(velocity.y, -1.2)

    move_and_slide()
    global_position.x = clampf(global_position.x, 0.5, 27.5)
    global_position.z = clampf(global_position.z, 0.5, 27.5)
    if not typing and Input.is_key_pressed(KEY_R):
        respawn()

func enter_water() -> void:
    in_water = true
    environment_changed.emit("BERENANG · tekan SPACE untuk naik")

func exit_water() -> void:
    in_water = false
    environment_changed.emit("MENJELAJAH · WASD untuk bergerak")

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    health_changed.emit(health)
    if health <= 0:
        respawn()

func respawn() -> void:
    global_position = safe_spawn
    velocity = Vector3.ZERO
    in_water = false
    environment_changed.emit("RESPAWN · kembali ke titik aman")
