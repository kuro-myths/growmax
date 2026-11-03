class_name WorldGen
## World generation seeded — deterministik dari kata kunci world.
## Port hashSeed()/mulberry32() dari prototipe Three.js, plus kolam lava
## (ekstensi Godot). Urutan panggilan RNG mengikuti prototipe HTML agar
## gaya layout konsisten (penambahan lava menggeser stream RNG sedikit).

const SIZE := 24


func _imul(x: int, y: int) -> int:
	return (x * y) & 0xFFFFFFFF


func hash_seed(s: String) -> int:
	var h := 2166136261
	var lower := s.to_lower()
	for i in lower.length():
		h = (h ^ lower.unicode_at(i)) & 0xFFFFFFFF
		h = _imul(h, 16777619)
	return h


func mulberry32(seed: int) -> Callable:
	var a := seed
	return func() -> float:
		a = (a + 0x6D2B79F5) & 0xFFFFFFFF
		var t := a
		t = _imul(t ^ (t >> 15), t | 1)
		var u := _imul(t ^ (t >> 7), t | 61)
		t = ((t + u) & 0xFFFFFFFF) ^ t
		return float((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296.0


func generate(world_name: String) -> Dictionary:
	var rand := mulberry32(hash_seed(world_name))
	var types := {}
	for x in SIZE:
		for z in SIZE:
			var beach := x < 2 or z < 2 or x > 21 or z > 21
			var k := "%d,%d" % [x, z]
			if beach:
				types[k] = "sand"
			else:
				types[k] = "grass"
	var out := {"types": types, "water": {}, "lava": {}, "trees": [], "rocks": [], "islands": []}
	var pal: Array = Catalog.PALETTES[int(rand.call() * float(Catalog.PALETTES.size()))]
	out["palette"] = pal
	# kolam air (seeded, urutan RNG sama dengan HTML)
	if rand.call() > 0.25:
		var px := 4 + int(rand.call() * 16.0)
		var pz := 4 + int(rand.call() * 16.0)
		var pr := 1 + int(rand.call() * 2.0)
		for dx in range(-pr, pr + 1):
			for dz in range(-pr, pr + 1):
				if absi(dx) + absi(dz) > pr:
					continue
				var wx := px + dx
				var wz := pz + dz
				if wx < 0 or wx > 23 or wz < 0 or wz > 23:
					continue
				var wk := "%d,%d" % [wx, wz]
				if types[wk] == "grass":
					types[wk] = "water"
		out["water"] = {"has": true, "x": px, "z": pz, "r": pr}
	# kolam lava — hazard langka (ekstensi Godot, tetap seeded)
	if rand.call() < 0.18:
		var lx := 3 + int(rand.call() * 18.0)
		var lz := 3 + int(rand.call() * 18.0)
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				if absi(dx) + absi(dz) > 1:
					continue
				var vx := lx + dx
				var vz := lz + dz
				if vx < 0 or vx > 23 or vz < 0 or vz > 23:
					continue
				var vk := "%d,%d" % [vx, vz]
				if types[vk] == "grass":
					types[vk] = "lava"
		out["lava"] = {"has": true, "x": lx, "z": lz}
	# pohon dekor (seeded, hindari area farm tengah)
	var tree_count := 9 + int(rand.call() * 12.0)
	for i in tree_count:
		var tx := 2 + int(rand.call() * 20.0)
		var tz := 2 + int(rand.call() * 20.0)
		var tk := "%d,%d" % [tx, tz]
		if types[tk] != "grass":
			continue
		if tx > 8 and tx < 16 and tz > 8 and tz < 19:
			continue
		out["trees"].append({"x": tx, "z": tz, "scale": 0.68 + rand.call() * 0.4})
	# batu (seeded)
	var rock_count := 3 + int(rand.call() * 5.0)
	for i in rock_count:
		var rx := 3 + int(rand.call() * 18.0)
		var rz := 3 + int(rand.call() * 18.0)
		var rk := "%d,%d" % [rx, rz]
		if types[rk] != "grass":
			continue
		out["rocks"].append({"x": rx, "z": rz, "h": 0.35 + rand.call() * 0.5})
	# pulau melayang (seeded)
	var isl_count := 1 + int(rand.call() * 3.0)
	for i in isl_count:
		out["islands"].append({
			"x": 3 + int(rand.call() * 15.0),
			"z": 2 + int(rand.call() * 15.0),
			"y": 9 + int(rand.call() * 2.0),
		})
	return out
