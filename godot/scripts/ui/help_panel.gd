class_name HelpPanel
extends ModalPanel
## Bantuan & Kontrol.


func _init(p_hud: CanvasLayer).(p_hud, "Bantuan", "Kontrol Growmax.") -> void:
	pass


func _on_open() -> void:
	clear_content()
	var lines := [
		"WASD / tombol panah — jalan",
		"SPACE — lompat (bisa naik ke atas blok)",
		"Tahan klik kanan + gerakkan mouse — putar kamera · scroll — zoom",
		"Klik kiri — punch: garap rumput / panen / hancurkan blok",
		"E atau klik kanan — tanam seed / pasang blok yang dipilih",
		"Q — siram tanaman (+25% gem saat panen)",
		"1-9 — pilih hotbar · P — pindah world · B — toko · I — ransel",
		"F — demo 60x (tanaman tumbuh cepat, untuk testing)",
		"R — respawn ke titik awal · Enter — buka chat · Escape — tutup panel",
		"Bangun rumah: pilih blok (Kayu/Bata/Batu/Pasir/Kaca) di hotbar, arahkan crosshair, tekan E. Bisa ditumpuk sampai 6 tingkat & kamu bisa berdiri di atasnya!",
		"Awas lava — HP turun saat diinjak; HP pulih perlahan setelah 5 detik.",
		"Saat mengetik di chat/kotak teks, WASD tidak menggerakkan karakter.",
	]
	for l in lines:
		var lbl := Label.new()
		lbl.text = "- " + String(l)
		lbl.add_theme_font_size_override("font_size", 13)
		content.add_child(lbl)
