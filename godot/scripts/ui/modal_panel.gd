class_name ModalPanel
extends PanelContainer
## Dasar semua panel modal (toko, ransel, world, lock, chat, analisis, bantuan).
## Konten dibangun ulang lewat _on_open() setiap kali dibuka.

var hud: CanvasLayer
var content: VBoxContainer
var sub_label: Label


func _init(p_hud: CanvasLayer, title: String, subtitle: String) -> void:
	hud = p_hud
	custom_minimum_size = Vector2(540, 0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", hud.panel_style_dark())
	var vb := VBoxContainer.new()
	add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	var tb := VBoxContainer.new()
	tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tb)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 18)
	tb.add_child(t)
	sub_label = Label.new()
	sub_label.text = subtitle
	sub_label.add_theme_font_size_override("font_size", 12)
	sub_label.add_theme_color_override("font_color", Color("b6c4b4"))
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tb.add_child(sub_label)
	var close_btn := Button.new()
	var close_tex := IconSet.tex("close")
	if close_tex != null:
		close_btn.icon = close_tex
		close_btn.expand_icon = true
		close_btn.custom_minimum_size = Vector2(34, 34)
	else:
		close_btn.text = "X"
	close_btn.pressed.connect(close)
	head.add_child(close_btn)
	content = VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
	vb.add_child(content)
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	visible = false


func open() -> void:
	visible = true
	hud.push_panel(self)
	_on_open()


func close() -> void:
	visible = false
	hud.pop_panel(self)


func _on_open() -> void:
	pass


func clear_content() -> void:
	for c in content.get_children():
		c.queue_free()
