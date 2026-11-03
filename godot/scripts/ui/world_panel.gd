class_name WorldPanel
extends ModalPanel
## Pindah / buat world dengan kata kunci (paritas switchWorld HTML):
## regex ^[a-z0-9-]{3,20}$, biaya 1 WL untuk world baru, chips world terkunjungi.

var line: LineEdit


func _init(p_hud: CanvasLayer).(p_hud, "Pindah / Buat World", "Masukkan kata kunci world-mu. World baru otomatis dibuat dengan terrain unik dari namanya — seperti Minecraft & Growtopia.") -> void:
	pass


func _on_open() -> void:
	_rebuild()


func _rebuild() -> void:
	clear_content()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	line = LineEdit.new()
	line.max_length = 20
	line.placeholder_text = "misal: kebunfule, rumah-keren, naga123"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text_submitted.connect(func(_t): _submit())
	row.add_child(line)
	var go := Button.new()
	go.text = "Masuk"
	go.pressed.connect(func(): _submit())
	row.add_child(go)
	var head := Label.new()
	head.text = "World yang sudah kamu kunjungi"
	head.add_theme_color_override("font_color", Color("ffd77a"))
	content.add_child(head)
	var names: Array = GameState.worlds.keys()
	if names.is_empty():
		var empty := Label.new()
		empty.text = "Belum ada world lain."
		empty.add_theme_color_override("font_color", Color("b6c4b4"))
		content.add_child(empty)
	for n in names:
		var chip := Button.new()
		var current := String(n) == GameState.world
		chip.text = String(n) + ("  (di sini)" if current else "")
		chip.disabled = current
		if current:
			chip.modulate = Color("b5ef79")
		chip.pressed.connect(func(): _switch(String(n)))
		content.add_child(chip)
	var rules := Label.new()
	rules.text = "Aturan: huruf kecil a-z, angka 0-9, tanda \"-\", 3-20 karakter. Membuat world baru membutuhkan 1 WL. Terrain tiap world di-generate dari kata kuncinya (seed) dan progres tiap world tersimpan terpisah."
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.add_theme_font_size_override("font_size", 11)
	rules.add_theme_color_override("font_color", Color("b6c4b4"))
	content.add_child(rules)
	line.grab_focus()


func _submit() -> void:
	if line == null:
		return
	_switch(line.text)


func _switch(name_in: String) -> void:
	var ok: bool = hud.main.switch_world(name_in.strip_edges().to_lower())
	if ok:
		close()
	else:
		_rebuild()
