extends Node
## Main — orchestrator Growmax (port dari web/index.html).
## Menghubungkan WorldManager + Player + HUD, validasi kata kunci world,
## dan perpindahan/pembuatan world dengan biaya 1 WL (paritas HTML).

const WORLD_NAME_PATTERN := "^[a-z0-9-]{3,20}$"

var world: WorldManager
var player: Player
var _name_regex: RegEx


func _ready() -> void:
	add_to_group("growmax_main")
	_name_regex = RegEx.new()
	_name_regex.compile(WORLD_NAME_PATTERN)
	world = $World as WorldManager
	player = $Player as Player
	GameState.world_manager = world
	player.world_manager = world
	player.main = self
	var wd := GameState.current_world_data()
	world.setup(GameState.world, wd)
	var pp: Dictionary = wd.get("player", {})
	if pp.is_empty():
		player.spawn_pos = Vector3(12.0, 6.0, 15.0)
	else:
		player.spawn_pos = Vector3(float(pp.get("x", 12.0)), 6.0, float(pp.get("z", 15.0)))
	player.global_position = player.spawn_pos
	player.velocity = Vector3.ZERO
	GameState.state_changed.emit()


func capture_player_pos() -> void:
	var wd := GameState.current_world_data()
	wd["player"] = {"x": player.global_position.x, "z": player.global_position.z}


func is_valid_world_name(wname: String) -> bool:
	return _name_regex.search(wname) != null


func switch_world(name_in: String) -> bool:
	var wname := name_in.to_lower().strip_edges()
	if not is_valid_world_name(wname):
		GameState.notify("Kata kunci world: 3-20 karakter, huruf kecil a-z, angka, atau \"-\".")
		return false
	if wname == GameState.world:
		GameState.notify("Kamu sudah di world \"%s\"." % wname)
		return false
	var is_new := not GameState.worlds.has(wname)
	if is_new and GameState.wl < 1:
		GameState.notify("Membuat world baru membutuhkan 1 WL untuk menguncinya.")
		return false
	capture_player_pos()
	if is_new:
		GameState.wl -= 1
		GameState.worlds[wname] = {
			"tiles": {},
			"player": {"x": 12.0, "z": 15.0},
			"created": GameState.now_ms(),
			"locked": true,
			"owner": GameState.player_name,
			"access": [GameState.player_name],
		}
	GameState.world = wname
	var wd := GameState.current_world_data()
	world.setup(wname, wd)
	var pp: Dictionary = wd.get("player", {})
	player.spawn_pos = Vector3(float(pp.get("x", 12.0)), 6.0, float(pp.get("z", 15.0)))
	player.global_position = player.spawn_pos
	player.velocity = Vector3.ZERO
	GameState.state_changed.emit()
	SaveSystem.save_game()
	GameState.notify("World \"%s\" %s! Terrain di-generate khusus dari kata kuncinya." % [wname, "dibuat" if is_new else "dimasuki kembali"])
	return true
