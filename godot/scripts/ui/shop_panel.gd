class_name ShopPanel
extends ModalPanel
## Toko — beli seed (filter rarity) & blok bangunan. Validasi saldo via
## GameState.spend_gems (tidak bisa saldo negatif / transaksi ganda).

var filter := "all"


func _init(p_hud: CanvasLayer).(p_hud, "Toko", "Beli benih & blok bangunan dengan gems.") -> void:
	pass


func _on_open() -> void:
	_rebuild()


func _rebuild() -> void:
	clear_content()
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", 5)
	content.add_child(frow)
	var ids := ["all"]
	for t in Catalog.RARITY_TIERS:
		ids.append(String(t["id"]))
	for id in ids:
		var b := Button.new()
		var label := "Semua"
		if id != "all":
			label = String(Catalog.tier_by_id(id)["name"])
		b.text = label
		b.toggle_mode = true
		b.button_pressed = filter == id
		b.pressed.connect(func():
			filter = id
			_rebuild())
		if id != "all":
			b.add_theme_color_override("font_color", Color(String(Catalog.tier_by_id(id)["color"])))
		frow.add_child(b)
	for s in Catalog.SEEDS:
		if filter != "all" and String(Catalog.tier_of(int(s["rarity"]))["id"]) != filter:
			continue
		_add_seed_row(s)
	var head := Label.new()
	head.text = "Blok Bangunan"
	head.add_theme_color_override("font_color", Color("ffd77a"))
	content.add_child(head)
	for blk in Catalog.BLOCKS:
		_add_block_row(blk)


func _add_seed_row(s: Dictionary) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var t := Catalog.tier_of(int(s["rarity"]))
	var name_l := Label.new()
	name_l.text = "%s  [%s · %d]" % [String(s["name"]), String(t["name"]), int(s["rarity"])]
	name_l.add_theme_color_override("font_color", Color(String(t["color"])))
	info.add_child(name_l)
	var detail := Label.new()
	detail.text = "Tumbuh %s · reward %d-%d gems · seed kembali %d-%d" % [
		Catalog.fmt_grow(float(s["time"])), int(s["gems"][0]), int(s["gems"][1]),
		int(s["seeds"][0]), int(s["seeds"][1])]
	detail.add_theme_font_size_override("font_size", 11)
	detail.add_theme_color_override("font_color", Color("b6c4b4"))
	info.add_child(detail)
	var buy := Button.new()
	var price := int(s["price"])
	buy.text = "%d gems" % price
	buy.disabled = GameState.gems < price
	buy.pressed.connect(func(): _buy_seed(s, price))
	row.add_child(buy)


func _buy_seed(s: Dictionary, price: int) -> void:
	if not GameState.spend_gems(price):
		GameState.notify("Gems tidak cukup — butuh %d, punya %d." % [price, GameState.gems])
		return
	GameState.add_seed(String(s["id"]), 1)
	GameState.notify("%s dibeli! (%s)" % [String(s["name"]), String(Catalog.tier_of(int(s["rarity"]))["name"])])
	SaveSystem.save_game()
	_rebuild()


func _add_block_row(b: Dictionary) -> void:
	var row := HBoxContainer.new()
	content.add_child(row)
	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(22, 22)
	icon.color = Color(String(b["color"]))
	if bool(b["glass"]):
		icon.color = Color(String(b["color"]), 0.5)
	row.add_child(icon)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var name_l := Label.new()
	name_l.text = String(b["name"])
	info.add_child(name_l)
	var detail := Label.new()
	detail.text = "Bahan bangunan — pasang dengan E / klik kanan. Punya: %d" % GameState.block_count(String(b["id"]))
	detail.add_theme_font_size_override("font_size", 11)
	detail.add_theme_color_override("font_color", Color("b6c4b4"))
	info.add_child(detail)
	var buy := Button.new()
	var price := int(b["price"])
	buy.text = "%d gems" % price
	buy.disabled = GameState.gems < price
	buy.pressed.connect(func(): _buy_block(b, price))
	row.add_child(buy)


func _buy_block(b: Dictionary, price: int) -> void:
	if not GameState.spend_gems(price):
		GameState.notify("Gems tidak cukup.")
		return
	GameState.add_block(String(b["id"]), 1)
	GameState.notify("%s dibeli!" % String(b["name"]))
	SaveSystem.save_game()
	_rebuild()
