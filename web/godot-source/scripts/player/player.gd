extends CharacterBody3D
signal health_changed(value: int)
signal environment_changed(message: String)
const SPEED := 5.0
const SWIM_SPEED := 3.0
const JUMP_VELOCITY := 7.0
var health := 100
var in_water := false
var safe_spawn := Vector3(14, 7, 14)
var body_mesh: MeshInstance3D

func _ready() -> void:
    name = "Player"
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.38
    capsule.height = 1.8
    var collider := CollisionShape3D.new()
    collider.shape = capsule
    collider.position.y = 0.9
    add_child(collider)
    body_mesh = MeshInstance3D.new()
    var body := BoxMesh.new()
    body.size = Vector3(0.65, 0.9, 0.42)
    body_mesh.mesh = body
    body_mesh.position.y = 1.0
    body_mesh.material_override = _material(Color("#398ee8"))
    add_child(body_mesh)
    var head := MeshInstance3D.new()
    var head_mesh := BoxMesh.new()
    head_mesh.size = Vector3(0.48, 0.48, 0.48)
    head.mesh = head_mesh
    head.position.y = 1.7
    head.material_override = _material(Color("#ffd0a1"))
    add_child(head)
    var camera := Camera3D.new()
    camera.position = Vector3(0, 7.7, 8.5)
    camera.rotation_degrees.x = -38
    camera.current = true
    add_child(camera)

func _material(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    return material

func _physics_process(delta: float) -> void:
    var axis := Vector2.ZERO
    axis.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
    axis.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
    axis = axis.normalized() if axis.length() > 1.0 else axis
    var speed := SWIM_SPEED if in_water else SPEED
    velocity.x = axis.x * speed
    velocity.z = axis.y * speed
    if not is_on_floor():
        velocity.y -= (5.0 if in_water else 22.0) * delta
    elif Input.is_key_pressed(KEY_SPACE):
        velocity.y = 2.0 if in_water else JUMP_VELOCITY
    else:
        velocity.y = 0.0
    if in_water:
        velocity.y = maxf(velocity.y, -1.2)
    move_and_slide()
    global_position.x = clampf(global_position.x, 0.5, 27.5)
    global_position.z = clampf(global_position.z, 0.5, 27.5)
    if Input.is_key_pressed(KEY_R):
        respawn()

func enter_water() -> void:
    in_water = true
    environment_changed.emit("Berenang · kecepatan berkurang")

func exit_water() -> void:
    in_water = false
    environment_changed.emit("Keluar dari air")

func take_damage(amount: int) -> void:
    health = maxi(0, health - amount)
    health_changed.emit(health)
    if health <= 0:
        respawn()

func respawn() -> void:
    global_position = safe_spawn
    velocity = Vector3.ZERO
    in_water = false
    environment_changed.emit("Respawn di titik aman · HP %d" % health)
