class_name Player
extends CharacterBody3D
## Player — gerak WASD/panah relatif kamera, lompat, kamera orbit third-person
## (tahan klik kanan untuk memutar, scroll untuk zoom), interaksi klik kiri/
## klik kanan/E/Q, HP + hazard lava + regen + respawn [R].
## Input gameplay otomatis mati saat sedang mengetik (fokus GUI).

const SPEED := 5.0
const JUMP_VELOCITY := 7.5
const GRAVITY := 20.0
const REGEN_AFTER := 5.0
const REGEN_RATE := 2.0
const LAVA_DPS := 10.0
const REACH := 45.0

var world_manager: WorldManager
var main: Node
var spawn_pos := Vector3(12.0, 6.0, 15.0)
var camera: Camera3D
var yaw := 0.0
var pitch := 0.6
var cam_dist := 10.0
var cached_aim := {}

var _last_hurt := -100.0
var _visual: Node3D


func _ready() -> void:
	_build_visual()
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)
	camera = Camera3D.new()
	camera.set_as_top_level(true)
	add_child(camera)
	_update_camera(true)


func _build_visual() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_add_box(_visual, Vector3(0, 1, 0), Vector3(0.65, 0.95, 0.42), "368de0")
	_add_box(_visual, Vector3(0, 1.72, 0), Vector3(0.52, 0.52, 0.52), "ffc98a")
	_add_box(_visual, Vector3(-0.14, 1.78, 0.27), Vector3(0.07, 0.07, 0.03), "262a2e")
	_add_box(_visual, Vector3(0.14, 1.78, 0.27), Vector3(0.07, 0.07, 0.03), "262a2e")


func _add_box(parent: Node3D, pos: Vector3, sizev: Vector3, color: String) -> void:
	var m := MeshInstance3D.new()
	m.mesh = BoxMesh.new()
	m.position = pos
	m.scale = sizev
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color)
	m.material_override = mat
	parent.add_child(m)


## True kalau input gameplay harus diabaikan (sedang mengetik / ada panel terbuka).
func _gui_blocks_input() -> bool:
	if GameState.ui_open > 0:
		return true
	return get_viewport().gui_get_focus_owner() != null


func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if not _gui_blocks_input():
		var v := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		dir = fwd * -v.y + right * v.x
		if dir.length() > 0.001:
			dir = dir.normalized()
			_visual.rotation.y = atan2(dir.x, dir.z)
	if is_on_floor():
		if not _gui_blocks_input() and Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= GRAVITY * delta
	velocity.x = dir.x * SPEED
	velocity.z = dir.z * SPEED
	move_and_slide()
	global_position.x = clampf(global_position.x, 0.5, 23.5)
	global_position.z = clampf(global_position.z, 0.5, 23.5)
	_apply_hazards(delta)
	_update_camera(false)
	_update_aim()


func _apply_hazards(delta: float) -> void:
	if world_manager == null:
		return
	var now := float(Time.get_ticks_msec()) / 1000.0
	var t := world_manager.tile_type(int(floor(global_position.x)), int(floor(global_position.z)))
	if t == "lava":
		GameState.hp -= LAVA_DPS * delta
		_last_hurt = now
		if GameState.hp <= 0.0:
			GameState.notify("Kamu pingsan di lava! Kembali ke titik spawn.")
			respawn()
	elif now - _last_hurt > REGEN_AFTER and GameState.hp < GameState.MAX_HP:
		GameState.hp = minf(GameState.MAX_HP, GameState.hp + REGEN_RATE * delta)


func respawn() -> void:
	global_position = spawn_pos
	velocity = Vector3.ZERO
	GameState.hp = GameState.MAX_HP
	_last_hurt = -100.0


func _update_camera(instant: bool) -> void:
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * cam_dist
	var target := global_position + offset
	if instant:
		camera.global_position = target
	else:
		camera.global_position = camera.global_position.lerp(target, 0.15)
	if camera.global_position.distance_to(global_position) > 0.001:
		camera.look_at(global_position + Vector3(0, 1, 0), Vector3.UP)


## Raycast dari kamera melalui posisi mouse ke tile/blok (paritas aimTile HTML,
## dengan fallback petak di depan pemain).
func _update_aim() -> void:
	if world_manager == null:
		return
	if _gui_blocks_input() or get_viewport().gui_get_hovering_control() != null:
		cached_aim = {}
		world_manager.set_highlight(cached_aim)
		return
	var mp := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mp)
	var dirn := camera.project_ray_normal(mp)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dirn * REACH)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var meta = hit["collider"].get_meta("tile", null)
		if meta != null:
			cached_aim = meta
			world_manager.set_highlight(cached_aim)
			return
	cached_aim = _front_fallback()
	world_manager.set_highlight(cached_aim)


func _front_fallback() -> Dictionary:
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var pos := global_position + fwd * 1.6
	return {"x": int(floor(pos.x)), "z": int(floor(pos.z))}


func _unhandled_input(event: InputEvent) -> void:
	if world_manager == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if _gui_blocks_input():
			return
		var idx := event.button_index
		if idx == MOUSE_BUTTON_LEFT:
			world_manager.handle_punch(cached_aim)
		elif idx == MOUSE_BUTTON_RIGHT:
			world_manager.handle_place(cached_aim)
		elif idx == MOUSE_BUTTON_WHEEL_UP:
			cam_dist = clampf(cam_dist - 1.0, 5.0, 16.0)
		elif idx == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist = clampf(cam_dist + 1.0, 5.0, 16.0)
		return
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		yaw -= event.relative.x * 0.005
		pitch = clampf(pitch + event.relative.y * 0.004, 0.15, 1.25)
		return
	if _gui_blocks_input():
		return
	if event.is_action_pressed("interact"):
		world_manager.handle_place(cached_aim)
	elif event.is_action_pressed("water"):
		world_manager.handle_water(cached_aim)
	elif event.is_action_pressed("respawn"):
		respawn()
