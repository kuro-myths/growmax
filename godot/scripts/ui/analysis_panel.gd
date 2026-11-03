class_name AnalysisPanel
extends ModalPanel
## Analisis Level — progres XP, sumber XP terakhir, dan zona yang terbuka.


func _init(p_hud: CanvasLayer).(p_hud, "Analisis Level", "Progres, sumber XP, dan zona yang terbuka.") -> void:
	pass


func _on_open() -> void:
	clear_content()
	var title := Label.new()
	title.text = "LEVEL %d — %d / %d XP" % [GameState.level, int(GameState.xp), int(GameState.xp_needed())]
	title.add_theme_font_size_override("font_size", 15)
	content.add_child(title)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = clampf(GameState.xp / GameState.xp_needed() * 100.0, 0.0, 100.0)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	content.add_child(bar)
	var h1 := Label.new()
	h1.text = "Sumber XP terakhir"
	h1.add_theme_color_override("font_color", Color("ffd77a"))
	content.add_child(h1)
	var logs: Array = GameState.xp_log.slice(0, 8)
	if logs.is_empty():
		var e := Label.new()
		e.text = "Belum ada aktivitas. Garap tanah (+2 XP), hancurkan blok (+1), atau panen."
		e.add_theme_color_override("font_color", Color("b6c4b4"))
		content.add_child(e)
	for l in logs:
		var lbl := Label.new()
		lbl.text = String(l)
		lbl.add_theme_font_size_override("font_size", 12)
		content.add_child(lbl)
	var h2 := Label.new()
	h2.text = "Zona dunia"
	h2.add_theme_color_override("font_color", Color("ffd77a"))
	content.add_child(h2)
	for z in Catalog.ZONES:
		var zl := Label.new()
		var unlocked := GameState.zone_unlocked(z)
		if unlocked:
			zl.text = "%s — terbuka" % String(z["name"])
			zl.add_theme_color_override("font_color", Color("b5ef79"))
		else:
			zl.text = "%s — terkunci (Lv %d)" % [String(z["name"]), int(z["lv"])]
			zl.add_theme_color_override("font_color", Color("9ca3af"))
		content.add_child(zl)
	var hint := Label.new()
	hint.text = "Reward level berikutnya: buka zona baru + bonus panen +3% per level."
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color("b6c4b4"))
	content.add_child(hint)
