extends CanvasLayer
## HUD — brand, stats (gems/WL/DL/BGL/level/XP/HP/panen), panel samping,
## hotbar 18 slot (13 seed + 5 blok), toast, menu, dan semua panel modal.
## Ikon memakai SVG putih dari assets/icons (IconSet) lalu di-tint warna —
## offline-safe, tanpa CDN/fetch runtime, tanpa glyph emoji.

const MODAL_SCRIPTS := {
	"world": "res://scripts/ui/world_panel.gd",
	"lock": "res://scripts/ui/lock_panel.gd",
	"chat": "res://scripts/ui/chat_panel.gd",
	"shop": "res://scripts/ui/shop_panel.gd",
	"inventory": "res://scripts/ui/inventory_panel.gd",
	"analysis": "res://scripts/ui/analysis_panel.gd",
	"help": "res://scripts/ui/help_panel.gd",
}

var main: Node
var panels := {}
var panel_stack: Array = []
var toast_label: Label
var toast_timer := 0.0
var menu_panel: PanelContainer
var demo_label: Label
var world_label: Label
var stat_labels := {}
var xp_bar: ProgressBar
var hp_bar: ProgressBar
var slot_panels: Array = []
var slot_labels: Array = []
var root: Control


func _ready() -> void:
	layer = 10
	main = get_parent()
	_build()
	GameState.state_changed.connect(_refresh)
	GameState.toast_requested.connect(show_toast)
	_refresh()


func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_label.modulate.a = 0.0
	hp_bar.value = GameState.hp
	xp_bar.value = clampf(GameState.xp / GameState.xp_needed() * 100.0, 0.0, 100.0)


# ---------- GAYA ----------

func panel_style_dark() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("14251b", 0.96)
	sb.border_color = Color("57734e")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(14)
	return sb


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("122019", 0.88)
	sb.border_color = Color("ffffff", 0.16)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(10)
	return sb


func _slot_style(active: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if active:
		sb.bg_color = Color("b5ef79", 0.14)
		sb.border_color = Color("b5ef79")
		sb.set_border_width_all(2)
	else:
		sb.bg_color = Color("ffffff", 0.05)
		sb.border_color = Color("ffffff", 0.15)
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(4)
	return sb


# ---------- BUILD ----------

func _build() -> void:
	root = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var brand := Label.new()
	brand.text = "GROWMAX — 3D WORLD"
	brand.set_anchors_preset(Control.PRESET_TOP_LEFT)
	brand.offset_left = 14
	brand.offset_top = 12
	brand.add_theme_font_size_override("font_size", 16)
	brand.add_theme_color_override("font_color", Color("dff3d2"))
	root.add_child(brand)

	var stats := HBoxContainer.new()
	stats.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stats.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	stats.offset_right = -14
	stats.offset_top = 12
	stats.add_theme_constant_override("separation", 6)
	root.add_child(stats)
	_mk_chip(stats, "gems", "Gems: 20", "gem", Color("7de3ff"))
	_mk_chip(stats, "cur", "WL 1 · DL 0 · BGL 0", "coin", Color("ffd77a"))
	_mk_level_chip(stats)
	_mk_chip(stats, "hvt", "Panen: 0", "sprout", Color("b5ef79"))
	_mk_hp_chip(stats)

	var side := PanelContainer.new()
	side.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	side.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	side.offset_right = -14
	side.offset_top = 120
	side.custom_minimum_size = Vector2(196, 0)
	side.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(side)
	var sv := VBoxContainer.new()
	side.add_child(sv)
	world_label = Label.new()
	world_label.add_theme_color_override("font_color", Color("b5ef79"))
	sv.add_child(world_label)
	_mk_side_button(sv, "globe", "Pindah / Buat World [P]", func(): toggle_panel("world"))
	_mk_side_button(sv, "lock", "World Lock", func(): toggle_panel("lock"))
	_mk_side_button(sv, "chat", "Chat World", func(): toggle_panel("chat"))
	_mk_side_button(sv, "cart", "Toko [B]", func(): toggle_panel("shop"))
	_mk_side_button(sv, "bag", "Ransel [I]", func(): toggle_panel("inventory"))
	_mk_side_button(sv, "chart", "Analisis Level", func(): toggle_panel("analysis"))
	_mk_side_button(sv, "menu", "Menu", func(): _toggle_menu())
	var sub := Label.new()
	sub.text = "Mode lokal · progres tersimpan otomatis"
	sub.add_theme_font_size_override("font_size", 10)
	sub.add_theme_color_override("font_color", Color("c1d0bf"))
	sv.add_child(sub)

	menu_panel = PanelContainer.new()
	menu_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	menu_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	menu_panel.offset_right = -14
	menu_panel.offset_top = 430
	menu_panel.custom_minimum_size = Vector2(196, 0)
	menu_panel.visible = false
	menu_panel.add_theme_stylebox_override("panel", panel_style_dark())
	root.add_child(menu_panel)
	var mv := VBoxContainer.new()
	menu_panel.add_child(mv)
	_mk_side_button(mv, "save", "Simpan Progres", func():
		SaveSystem.save_game()
		GameState.notify("Progres disimpan.")
		_toggle_menu())
	demo_label = Label.new()
	mv.add_child(demo_label)
	_mk_side_button(mv, "bolt", "Toggle Demo 60x [F]", func(): toggle_demo())
	_mk_side_button(mv, "help", "Bantuan & Kontrol", func():
		_toggle_menu()
		toggle_panel("help"))
	_mk_side_button(mv, "trash", "Reset Progres", func(): _confirm_reset())

	var ch := Label.new()
	ch.text = "+"
	ch.set_anchors_preset(Control.PRESET_CENTER)
	ch.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ch.grow_vertical = Control.GROW_DIRECTION_BOTH
	ch.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	root.add_child(ch)

	toast_label = Label.new()
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_label.offset_top = 90
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.custom_minimum_size = Vector2(440, 0)
	toast_label.modulate.a = 0.0
	toast_label.add_theme_font_size_override("font_size", 14)
	root.add_child(toast_label)

	var hb_panel := PanelContainer.new()
	hb_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hb_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hb_panel.offset_bottom = -16
	hb_panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(hb_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	hb_panel.add_child(hb)
	var items := Catalog.hotbar()
	for i in items.size():
		_mk_slot(hb, i, items[i])


func _mk_chip(parent: Control, key: String, text: String, icon_name := "", tint: Color = Color(1, 1, 1)) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(p)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	p.add_child(hb)
	if icon_name != "":
		hb.add_child(IconSet.icon_rect(icon_name, 14, tint))
	var l := Label.new()
	l.text = text
	hb.add_child(l)
	stat_labels[key] = l


func _mk_level_chip(parent: Control) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	row.add_child(IconSet.icon_rect("star", 14, Color("ffd77a")))
	var l := Label.new()
	l.text = "Lv 1"
	row.add_child(l)
	stat_labels["lvl"] = l
	xp_bar = ProgressBar.new()
	xp_bar.min_value = 0.0
	xp_bar.max_value = 100.0
	xp_bar.show_percentage = false
	xp_bar.custom_minimum_size = Vector2(100, 6)
	v.add_child(xp_bar)


func _mk_hp_chip(parent: Control) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	v.add_child(row)
	row.add_child(IconSet.icon_rect("heart", 14, Color("ff7d7d")))
	var l := Label.new()
	l.text = "HP"
	row.add_child(l)
	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0.0
	hp_bar.max_value = GameState.MAX_HP
	hp_bar.show_percentage = false
	hp_bar.custom_minimum_size = Vector2(100, 6)
	v.add_child(hp_bar)


func _mk_side_button(parent: Control, icon_name: String, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	var t := IconSet.tex(icon_name)
	if t != null:
		b.icon = t
		b.add_theme_constant_override("icon_max_width", 16)
	b.pressed.connect(cb)
	parent.add_child(b)


func _mk_slot(parent: Control, index: int, it: Dictionary) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(52, 58)
	p.add_theme_stylebox_override("panel", _slot_style(false))
	p.gui_input.connect(func(ev): _slot_clicked(ev, index))
	parent.add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var icon_name := "sprout" if String(it["kind"]) == "seed" else "cube"
	var icon := IconSet.icon_rect(icon_name, 22)
	v.add_child(icon)
	var name_l := Label.new()
	name_l.add_theme_font_size_override("font_size", 8)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_l)
	var count_l := Label.new()
	count_l.add_theme_font_size_override("font_size", 10)
	count_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_l.add_theme_color_override("font_color", Color("ffd77a"))
	v.add_child(count_l)
	slot_panels.push_back(p)
	slot_labels.push_back({"icon": icon, "name": name_l, "count": count_l})


func _slot_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		GameState.selected = index
		GameState.state_changed.emit()


# ---------- REFRESH ----------

func _refresh() -> void:
	if stat_labels.is_empty():
		return
	stat_labels["gems"].text = "Gems: %d" % GameState.gems
	stat_labels["cur"].text = "WL %d · DL %d · BGL %d" % [GameState.wl, GameState.dl, GameState.bgl]
	stat_labels["lvl"].text = "Lv %d" % GameState.level
	stat_labels["hvt"].text = "Panen: %d" % GameState.harvests
	world_label.text = "WORLD: %s" % GameState.world.to_upper()
	demo_label.text = "Mode Demo 60x: " + ("AKTIF" if GameState.accelerated else "MATI")
	var items := Catalog.hotbar()
	for i in items.size():
		var it: Dictionary = items[i]
		var s: Dictionary = slot_labels[i]
		var ref: Dictionary = it["ref"]
		var col := Color(String(ref["color"]))
		if bool(ref.get("glass", false)):
			col = Color(String(ref["color"]), 0.5)
		s["icon"].modulate = col
		var nm := String(ref["name"])
		if String(it["kind"]) == "seed":
			nm = nm.replace("Pohon ", "")
			s["count"].text = "%d" % GameState.seed_count(String(ref["id"]))
			slot_panels[i].tooltip_text = "%s · %s (%d)" % [String(ref["name"]), String(Catalog.tier_of(int(ref["rarity"]))["name"]), int(ref["rarity"])]
		else:
			nm = nm.replace("Blok ", "")
			s["count"].text = "%d" % GameState.block_count(String(ref["id"]))
			slot_panels[i].tooltip_text = String(ref["name"]) + " — E / klik kanan untuk pasang"
		s["name"].text = nm
		slot_panels[i].add_theme_stylebox_override("panel", _slot_style(GameState.selected == i))


func show_toast(message: String) -> void:
	toast_label.text = message
	toast_label.modulate.a = 1.0
	toast_timer = 2.8


# ---------- PANEL ----------

func toggle_panel(id: String) -> void:
	if panels.has(id):
		var p: ModalPanel = panels[id]
		if p.visible:
			p.close()
		else:
			p.open()
		return
	if not MODAL_SCRIPTS.has(id):
		return
	var script: GDScript = load(MODAL_SCRIPTS[id])
	var np: ModalPanel = script.new(self)
	panels[id] = np
	root.add_child(np)
	np.open()


func push_panel(p: Control) -> void:
	if not panel_stack.has(p):
		panel_stack.push_back(p)
	GameState.ui_open = panel_stack.size()


func pop_panel(p: Control) -> void:
	panel_stack.erase(p)
	GameState.ui_open = panel_stack.size()
	var fo := get_viewport().gui_get_focus_owner()
	if fo != null and p is Node and p.is_ancestor_of(fo):
		fo.release_focus()


func _toggle_menu() -> void:
	var on := not menu_panel.visible
	menu_panel.visible = on
	if on:
		push_panel(menu_panel)
	else:
		pop_panel(menu_panel)


func toggle_demo() -> void:
	GameState.accelerated = not GameState.accelerated
	if GameState.accelerated:
		GameState.notify("Mode demo 60x AKTIF — tanaman tumbuh 60x lebih cepat.")
	else:
		GameState.notify("Mode realtime aktif.")
	demo_label.text = "Mode Demo 60x: " + ("AKTIF" if GameState.accelerated else "MATI")


func _confirm_reset() -> void:
	var dlg := ConfirmationDialog.new()
	dlg.dialog_text = "Hapus SEMUA progres (semua world)? Tidak bisa dibatalkan."
	dlg.ok_button_text = "Hapus"
	dlg.cancel_button_text = "Batal"
	dlg.confirmed.connect(func(): SaveSystem.reset_game())
	root.add_child(dlg)
	dlg.popup_centered()


func _open_or_focus_chat() -> void:
	if panels.has("chat") and panels["chat"].visible:
		var cp: ChatPanel = panels["chat"]
		cp.grab_focus_input()
	else:
		toggle_panel("chat")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if panel_stack.size() > 0:
			var top: Control = panel_stack.back()
			if top == menu_panel:
				_toggle_menu()
			else:
				top.close()
			get_viewport().set_input_as_handled()
		return
	if get_viewport().gui_get_focus_owner() != null:
		return
	if event.is_action_pressed("world_menu"):
		toggle_panel("world")
	elif event.is_action_pressed("shop"):
		toggle_panel("shop")
	elif event.is_action_pressed("inventory"):
		toggle_panel("inventory")
	elif event.is_action_pressed("demo_toggle"):
		toggle_demo()
	elif event.is_action_pressed("chat_toggle"):
		_open_or_focus_chat()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			GameState.selected = event.keycode - KEY_1
			GameState.state_changed.emit()
