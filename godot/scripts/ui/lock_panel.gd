class_name LockPanel
extends ModalPanel
## World Lock — kunci world dengan 1 WL, atur pemilik & daftar akses.
## Validasi izin build ada di WorldManager._can_build().


func _init(p_hud: CanvasLayer).(p_hud, "World Lock", "Kunci world dan atur akses edit. Satu WL mengunci satu world.") -> void:
	pass


func _on_open() -> void:
	_rebuild()


func _rebuild() -> void:
	clear_content()
	var wd := GameState.current_world_data()
	var locked := bool(wd.get("locked", false))
	var info := Label.new()
	info.text = "World: %s\nStatus: %s\nPemilik: %s\nWL tersedia: %d · DL: %d · BGL: %d" % [
		GameState.world.to_upper(),
		"Terkunci" if locked else "Tidak terkunci",
		String(wd.get("owner", "Belum ada")),
		GameState.wl, GameState.dl, GameState.bgl]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(info)
	var toggle := Button.new()
	toggle.text = "Lepas kunci" if locked else "Pasang 1 WL"
	toggle.pressed.connect(func(): _toggle_lock())
	content.add_child(toggle)
	var note := Label.new()
	note.text = "Prototipe lokal: daftar izin belum tersinkron antar pemain. World terkunci hanya bisa diedit oleh pemilik / pemain yang diizinkan."
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", Color("b6c4b4"))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)


func _toggle_lock() -> void:
	var wd := GameState.current_world_data()
	var locked := bool(wd.get("locked", false))
	if locked:
		wd["locked"] = false
		wd["owner"] = ""
		wd["access"] = []
		GameState.notify("World dibuka.")
	else:
		if GameState.wl < 1:
			GameState.notify("WL tidak cukup.")
			return
		GameState.wl -= 1
		wd["locked"] = true
		wd["owner"] = GameState.player_name
		wd["access"] = [GameState.player_name]
		GameState.notify("World berhasil dikunci (-1 WL).")
	GameState.state_changed.emit()
	SaveSystem.save_game()
	_rebuild()
