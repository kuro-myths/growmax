class_name ChatPanel
extends ModalPanel
## Chat World mode lokal — riwayat, perintah /help /who /world, Enter kirim,
## Escape menutup. Saat input chat fokus, WASD tidak menggerakkan karakter
## (dicek lewat gui_get_focus_owner() di Player).

var log_label: RichTextLabel
var line: LineEdit


func _init(p_hud: CanvasLayer).(p_hud, "Chat World", "Mode lokal — pesan belum terkirim ke pemain lain.") -> void:
	pass


func _on_open() -> void:
	if log_label == null:
		_build()
		ChatSystem.chat_changed.connect(func(): _refresh_log())
	_refresh_log()
	line.grab_focus()


func _build() -> void:
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = false
	log_label.scroll_following = true
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.custom_minimum_size = Vector2(0, 160)
	content.add_child(log_label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	content.add_child(row)
	line = LineEdit.new()
	line.max_length = 180
	line.placeholder_text = "Ketik pesan atau /help"
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text_submitted.connect(func(_t): _send())
	row.add_child(line)
	var send := Button.new()
	send.text = "Kirim"
	send.pressed.connect(func(): _send())
	row.add_child(send)
	var note := Label.new()
	note.text = "Perintah: /help, /who, /world. Enter mengirim, Escape menutup. Chat online memerlukan server multiplayer."
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", Color("b6c4b4"))
	content.add_child(note)


func _send() -> void:
	if line == null:
		return
	var txt := line.text
	line.clear()
	ChatSystem.send(txt)
	_refresh_log()


func _refresh_log() -> void:
	if log_label == null:
		return
	var lines: Array = []
	for e in ChatSystem.history:
		lines.append(ChatSystem.render_line(e))
	log_label.text = "\n".join(lines)


func grab_focus_input() -> void:
	if line != null:
		line.grab_focus()
