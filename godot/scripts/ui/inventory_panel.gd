class_name InventoryPanel
extends ModalPanel
## Ransel — tab Benih / Blok / Alat / Statistik. Tombol Pakai memilih slot
## hotbar, Jual menukar item dengan setengah harga toko.

var tab := "seeds"


func _init(p_hud: CanvasLayer).(p_hud, "Ransel", "") -> void:
	pass


func _on_open() -> void:
	_rebuild()


func _rebuild() -> void:
	clear_content()
	var total_seeds := 0
	for s in Catalog.SEEDS:
		total_seeds += GameState.seed_count(String(s["id"]))
	var total_blocks := 0
	for b in Catalog.BLOCKS:
		total_blocks += GameState.block_count(String(b["id"]))
	sub_label.text = "%d gems · %d seed · %d blok · %d panen" % [GameState.gems, total_seeds, total_blocks, GameState.harvests]
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 5)
	content.add_child(tabs)
	var ids := ["seeds", "blocks", "tools", "stats"]
	var names := {"seeds": "Benih", "blocks": "Blok", "tools": "Alat", "stats": "Statistik"}
	for id in ids:
		var b := Button.new()
		b.text = String(names[id])
		b.toggle_mode = true
		b.button_pressed = tab == id
		b.pressed.connect(func():
			tab = id
			_rebuild())
		tabs.add_child(b)
	if tab == "seeds":
		_build_seeds()
	elif tab == "blocks":
		_build_blocks()
	elif tab == "tools":
		_build_tools()
	else:
		_build_stats()


func _build_seeds() -> void:
	var owned_count := 0
	for s in Catalog.SEEDS:
		if GameState.seed_count(String(s["id"])) > 0:
			owned_count += 1
	if owned_count == 0:
		var e := Label.new()
		e.text = "Kamu belum punya seed. Panen atau beli di toko [B]."
		e.add_theme_color_override("font_color", Color("b6c4b4"))
		content.add_child(e)
	for s in Catalog.SEEDS:
		var count := GameState.seed_count(String(s["id"]))
		if count <= 0:
			continue
		var t := Catalog.tier_of(int(s["rarity"]))
		var row := HBoxContainer.new()
		content.add_child(row)
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.color = Color(String(s["color"]))
		row.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_l := Label.new()
		name_l.text = "%s x%d  [%s · %d]" % [String(s["name"]), count, String(t["name"]), int(s["rarity"])]
		name_l.add_theme_color_override("font_color", Color(String(t["color"])))
		info.add_child(name_l)
		var detail := Label.new()
		detail.text = "Tumbuh %s · reward %d-%d gems · jual %d gems" % [
			Catalog.fmt_grow(float(s["time"])), int(s["gems"][0]), int(s["gems"][1]), int(s["price"]) / 2]
		detail.add_theme_font_size_override("font_size", 11)
		detail.add_theme_color_override("font_color", Color("b6c4b4"))
		info.add_child(detail)
		var acts := HBoxContainer.new()
		acts.add_theme_constant_override("separation", 6)
		row.add_child(acts)
		var use_btn := Button.new()
		use_btn.text = "Pakai"
		use_btn.pressed.connect(func():
			GameState.selected = Catalog.seed_index(String(s["id"]))
			GameState.state_changed.emit()
			GameState.notify("%s dipilih — tekan E di tanah garap." % String(s["name"])))
		acts.add_child(use_btn)
		var sell_btn := Button.new()
		var sell_price := int(s["price"]) / 2
		sell_btn.text = "Jual %d" % sell_price
		sell_btn.pressed.connect(func(): _sell_seed(s, sell_price))
		acts.add_child(sell_btn)


func _sell_seed(s: Dictionary, sell_price: int) -> void:
	if not GameState.take_seed(String(s["id"]), 1):
		return
	GameState.add_gems(sell_price)
	GameState.notify("Terjual! +%d gems" % sell_price)
	SaveSystem.save_game()
	_rebuild()


func _build_blocks() -> void:
	for b in Catalog.BLOCKS:
		var count := GameState.block_count(String(b["id"]))
		if count <= 0:
			continue
		var row := HBoxContainer.new()
		content.add_child(row)
		var icon := ColorRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.color = Color(String(b["color"]))
		if bool(b["glass"]):
			icon.color = Color(String(b["color"]), 0.5)
		row.add_child(icon)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_l := Label.new()
		name_l.text = "%s x%d" % [String(b["name"]), count]
		info.add_child(name_l)
		var detail := Label.new()
		detail.text = "Bahan bangunan (maks 6 tingkat/petak) · jual %d gems" % (int(b["price"]) / 2)
		detail.add_theme_font_size_override("font_size", 11)
		detail.add_theme_color_override("font_color", Color("b6c4b4"))
		info.add_child(detail)
		var acts := HBoxContainer.new()
		acts.add_theme_constant_override("separation", 6)
		row.add_child(acts)
		var use_btn := Button.new()
		use_btn.text = "Pakai"
		use_btn.pressed.connect(func():
			GameState.selected = Catalog.SEEDS.size() + Catalog.block_index(String(b["id"]))
			GameState.state_changed.emit()
			GameState.notify("%s dipilih — arahkan crosshair, tekan E untuk memasang." % String(b["name"])))
		acts.add_child(use_btn)
		var sell_btn := Button.new()
		var sell_price := int(b["price"]) / 2
		sell_btn.text = "Jual %d" % sell_price
		sell_btn.pressed.connect(func(): _sell_block(b, sell_price))
		acts.add_child(sell_btn)


func _sell_block(b: Dictionary, sell_price: int) -> void:
	if not GameState.take_block(String(b["id"]), 1):
		return
	GameState.add_gems(sell_price)
	GameState.notify("Terjual! +%d gems" % sell_price)
	SaveSystem.save_game()
	_rebuild()


func _build_tools() -> void:
	var tools := [
		{"name": "Tinju Dasar", "desc": "Klik kiri: garap rumput, panen tanaman, atau hancurkan blok (dikembalikan ke ransel)."},
		{"name": "Kaleng Penyiram", "desc": "Tekan Q di depan tanaman untuk menyiram — +25% gem saat dipanen."},
		{"name": "Palu Bangun", "desc": "Pilih blok di hotbar lalu tekan E / klik kanan untuk memasang. Bangun rumahmu sendiri!"},
	]
	for t in tools:
		var row := HBoxContainer.new()
		content.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_l := Label.new()
		name_l.text = String(t["name"])
		info.add_child(name_l)
		var detail := Label.new()
		detail.text = String(t["desc"])
		detail.add_theme_font_size_override("font_size", 11)
		detail.add_theme_color_override("font_color", Color("b6c4b4"))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(detail)
		var owned := Label.new()
		owned.text = "Dimiliki"
		owned.add_theme_color_override("font_color", Color("b5ef79"))
		row.add_child(owned)


func _build_stats() -> void:
	var world_count := GameState.worlds.size()
	var total_blocks := 0
	for b in Catalog.BLOCKS:
		total_blocks += GameState.block_count(String(b["id"]))
	var discovered := 0
	for s in Catalog.SEEDS:
		if GameState.seed_count(String(s["id"])) > 0:
			discovered += 1
	var lines := [
		"Level %d — %d / %d XP" % [GameState.level, int(GameState.xp), int(GameState.xp_needed())],
		"Ditanam: %d · Dipanen: %d" % [GameState.planted, GameState.harvests],
		"Gems: %d · total dikumpulkan: %d" % [GameState.gems, GameState.gems_earned],
		"World dibuat/dikunjungi: %d · blok dimiliki: %d" % [world_count, total_blocks],
		"Total XP: %d · seed ditemukan: %d/%d" % [int(GameState.xp_total), discovered, Catalog.SEEDS.size()],
	]
	for l in lines:
		var lbl := Label.new()
		lbl.text = String(l)
		content.add_child(lbl)
