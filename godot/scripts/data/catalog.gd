extends Node
## Katalog data Growmax — dipindahkan 1:1 dari web/index.html (prototipe Three.js).
## Skala rarity 1-100 terinspirasi skala angka seed Growtopia; nama & aset orisinal.
## Emoji dipertahankan sebagai data (paritas dengan HTML), tapi UI Godot memakai
## ikon warna agar aman di ekspor web (font bawaan tidak memuat glyph emoji).

const RARITY_TIERS := [
	{"id": "common", "name": "Umum", "min": 1, "max": 12, "color": "9ca3af"},
	{"id": "uncommon", "name": "Tidak Umum", "min": 13, "max": 24, "color": "4ade80"},
	{"id": "rare", "name": "Langka", "min": 25, "max": 40, "color": "60a5fa"},
	{"id": "epic", "name": "Epik", "min": 41, "max": 60, "color": "c084fc"},
	{"id": "legendary", "name": "Legendaris", "min": 61, "max": 80, "color": "fbbf24"},
	{"id": "mythic", "name": "Mistis", "min": 81, "max": 100, "color": "fb7185"},
]

const SEEDS := [
	{"id": "door", "name": "Pohon Pintu", "emoji": "U+1F6AA", "rarity": 2, "time": 300.0, "gems": [3, 8], "seeds": [1, 2], "price": 5, "color": "6dba4b"},
	{"id": "grass", "name": "Pohon Rumput", "emoji": "U+1F33C", "rarity": 5, "time": 420.0, "gems": [4, 10], "seeds": [1, 2], "price": 8, "color": "86c05a"},
	{"id": "apple", "name": "Pohon Apel", "emoji": "U+1F34E", "rarity": 15, "time": 900.0, "gems": [10, 20], "seeds": [1, 3], "price": 25, "color": "65b84b"},
	{"id": "pine", "name": "Pohon Pinus", "emoji": "U+1F332", "rarity": 17, "time": 1200.0, "gems": [12, 26], "seeds": [1, 3], "price": 30, "color": "278c58"},
	{"id": "orange", "name": "Pohon Jeruk", "emoji": "U+1F34A", "rarity": 19, "time": 1500.0, "gems": [14, 30], "seeds": [1, 3], "price": 40, "color": "e08a2e"},
	{"id": "cactus", "name": "Kaktus Emas", "emoji": "U+1F335", "rarity": 21, "time": 1800.0, "gems": [18, 38], "seeds": [2, 3], "price": 55, "color": "3f9e4f"},
	{"id": "coral", "name": "Terumbu Karang", "emoji": "U+1FAB8", "rarity": 25, "time": 2700.0, "gems": [30, 60], "seeds": [2, 4], "price": 80, "color": "e06a8a"},
	{"id": "crystal", "name": "Pohon Kristal", "emoji": "U+1F48E", "rarity": 33, "time": 3600.0, "gems": [40, 70], "seeds": [2, 4], "price": 120, "color": "54d8d1"},
	{"id": "manggis", "name": "Pohon Manggis", "emoji": "U+1FAD0", "rarity": 41, "time": 5400.0, "gems": [90, 180], "seeds": [3, 5], "price": 220, "color": "7a5fb8"},
	{"id": "diamond", "name": "Pohon Berlian", "emoji": "U+1F4A0", "rarity": 52, "time": 10800.0, "gems": [120, 250], "seeds": [3, 5], "price": 350, "color": "5aa6e8"},
	{"id": "durian", "name": "Pohon Durian", "emoji": "U+1F330", "rarity": 58, "time": 14400.0, "gems": [200, 420], "seeds": [4, 6], "price": 500, "color": "9aa632"},
	{"id": "legendary", "name": "Pohon Legendaris", "emoji": "U+2728", "rarity": 72, "time": 43200.0, "gems": [400, 900], "seeds": [5, 9], "price": 1200, "color": "e6c76b"},
	{"id": "naga", "name": "Pohon Naga", "emoji": "U+1F409", "rarity": 88, "time": 86400.0, "gems": [800, 2000], "seeds": [6, 10], "price": 2500, "color": "d05a5a"},
]

const BLOCKS := [
	{"id": "wood", "name": "Blok Kayu", "emoji": "U+1F7EB", "color": "9a693a", "price": 8, "glass": false},
	{"id": "brick", "name": "Blok Bata", "emoji": "U+1F7E5", "color": "b5563f", "price": 15, "glass": false},
	{"id": "stone", "name": "Blok Batu", "emoji": "U+2B1C", "color": "8a8f8f", "price": 12, "glass": false},
	{"id": "sand", "name": "Blok Pasir", "emoji": "U+1F7E8", "color": "d9c27e", "price": 6, "glass": false},
	{"id": "glass", "name": "Blok Kaca", "emoji": "U+1F537", "color": "aad4e0", "price": 20, "glass": true},
]

const ZONES := [
	{"name": "Permukaan", "lv": 1},
	{"name": "Bawah Tanah", "lv": 6},
	{"name": "Gua", "lv": 11},
	{"name": "Gua Dalam", "lv": 21},
	{"name": "Magma", "lv": 31},
]

const PALETTES := [
	["7fc653", "398d46"],
	["6db84a", "2e7d3a"],
	["8fcf5e", "4a9e4f"],
	["5fae4d", "2a8040"],
	["a8d06a", "55a54a"],
	["74c96b", "378a52"],
]

const WORLD_NAME_PATTERN := "^[a-z0-9-]{3,20}$"


func tier_of(rarity: int) -> Dictionary:
	for t in RARITY_TIERS:
		if rarity >= int(t["min"]) and rarity <= int(t["max"]):
			return t
	return RARITY_TIERS[0]


func tier_by_id(id: String) -> Dictionary:
	for t in RARITY_TIERS:
		if String(t["id"]) == id:
			return t
	return RARITY_TIERS[0]


func seed_by_id(id: String) -> Dictionary:
	for s in SEEDS:
		if String(s["id"]) == id:
			return s
	return SEEDS[0]


func block_by_id(id: String) -> Dictionary:
	for b in BLOCKS:
		if String(b["id"]) == id:
			return b
	return BLOCKS[0]


func seed_index(id: String) -> int:
	for i in SEEDS.size():
		if String(SEEDS[i]["id"]) == id:
			return i
	return 0


func block_index(id: String) -> int:
	for i in BLOCKS.size():
		if String(BLOCKS[i]["id"]) == id:
			return i
	return 0


## Hotbar gabungan: 13 seed lalu 5 blok (paritas dengan HTML).
func hotbar() -> Array:
	var out: Array = []
	for s in SEEDS:
		out.append({"kind": "seed", "ref": s})
	for b in BLOCKS:
		out.append({"kind": "block", "ref": b})
	return out


func fmt_grow(seconds: float) -> String:
	var m := seconds / 60.0
	if m < 60.0:
		return "%d mnt" % int(round(m))
	if m < 1440.0:
		return "%d jam" % int(round(m / 60.0))
	return "%d hari" % int(round(m / 1440.0))
