class_name IconSet
extends RefCounted
## Kumpulan ikon UI (res://assets/icons/*.svg) — digambar putih lalu di-tint
## lewat modulate, jadi fleksibel untuk semua warna item/chip.
## Offline-safe: tidak ada CDN/fetch runtime; semua ikon diimpor editor Godot.

const DIR := "res://assets/icons/"

static var _cache := {}


static func tex(icon_name: String) -> Texture2D:
	if _cache.has(icon_name):
		return _cache[icon_name]
	var path := DIR + icon_name + ".svg"
	if not ResourceLoader.exists(path):
		push_warning("Ikon tidak ditemukan: %s" % path)
		return null
	var t: Texture2D = load(path)
	if t == null:
		push_warning("Ikon gagal dimuat: %s" % path)
		return null
	_cache[icon_name] = t
	return t


static func icon_rect(icon_name: String, size_px: int, tint: Color = Color(1, 1, 1)) -> TextureRect:
	## TextureRect siap pakai. Kalau SVG hilang/gagal, fallback kotak polos putih
	## (tetap bisa di-tint) supaya layout tidak rusak.
	var rect := TextureRect.new()
	rect.custom_minimum_size = Vector2(size_px, size_px)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.modulate = tint
	var t := tex(icon_name)
	if t == null:
		var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		t = ImageTexture.create_from_image(img)
	rect.texture = t
	return rect
