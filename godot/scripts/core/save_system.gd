extends Node
## SaveSystem — save/load JSON di user:// dengan struktur kompatibel dengan
## format save HTML "growmax-world-v2". Autosave 20 detik + recovery file rusak.

const SAVE_PATH := "user://growmax_save_v2.json"
const AUTOSAVE_INTERVAL := 20.0


func _ready() -> void:
	load_game()
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)


func save_game() -> void:
	var main := get_tree().get_first_node_in_group("growmax_main")
	if main != null:
		main.capture_player_pos()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: gagal menulis save (%s)" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var raw := file.get_as_text()
	file.close()
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		_backup_corrupt(raw)
		push_error("SaveSystem: file save rusak, salinan disimpan dan mulai dari awal.")
		return false
	GameState.from_dict(data)
	return true


func _backup_corrupt(raw: String) -> void:
	var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "_").replace(" ", "")
	var path := "user://save_corrupt_%s.json" % stamp
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(raw)
		f.close()


func reset_game() -> void:
	var dir := DirAccess.open("user://")
	if dir != null and FileAccess.file_exists(SAVE_PATH):
		dir.remove(SAVE_PATH.get_file())
	GameState.reset_defaults()
	get_tree().reload_current_scene()
