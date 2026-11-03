class_name WorldManager
extends Node3D
## WorldManager — terrain seeded, tile (rumput/tanah/pasir/air/lava), pohon,
## batu, pulau melayang, blok bangunan (pasang/hancurkan), tanam/panen/siram.
## Semua aturan paritas dengan performPunch/interact/water di web/index.html.

const SIZE := 24
const MAX_STACK := 6

var world_name := "starter"
var tiles := {}
var tile_nodes := {}
var plant_nodes := {}
var stack_nodes := {}
var gen_data := {}

var _terrain: Node3D
var _selection: MeshInstance3D
var _materials := {}
var _grass_top: StandardMaterial3D
var _leaf_color := Color("398d46")
var _box: BoxMesh
var _unit_shape: BoxShape3D
var _gen := WorldGen.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_box = BoxMesh.new()
	_unit_shape = BoxShape3D.new()
	_unit_shape.size = Vector3.ONE
	_make_materials()
	_setup_environment()
	_make_selection_box()


func _make_materials() -> void:
	_materials["bedrock"] = _solid("30363a")
	_materials["stone"] = _solid("777c7c")
	_materials["dirt"] = _solid("8b633c")
	_materials["soil"] = _solid("68472e")
	_materials["sand"] = _solid("d9c27e")
	_materials["water"] = _trans("3dadd4", 0.55)
	_materials["lava"] = _lava()
	_materials["wood"] = _solid("9a693a")
	for b in Catalog.BLOCKS:
		if bool(b["glass"]):
			_materials["blk_" + String(b["id"])] = _trans(String(b["color"]), 0.55)
		else:
			_materials["blk_" + String(b["id"])] = _solid(String(b["color"]))
	_grass_top = _solid("7fc653")


func _solid(color: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.roughness = 1.0
	return m


func _trans(color: String, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.alpha = alpha
	m.roughness = 0.1
	return m


func _lava() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("d0531f")
	m.emission_enabled = true
	m.emission = Color("ff5a1f")
	m.emission_energy_multiplier = 0.8
	return m


func _setup_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("4f9fe8")
	sky_mat.sky_horizon_color = Color("b8dcf5")
	sky_mat.ground_bottom_color = Color("5b7b47")
	sky_mat.ground_horizon_color = Color("a8c66a")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color("8dc6ee")
	env.fog_density = 0.012
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.position = Vector3(-18, 30, 16)
	sun.look_at(Vector3.ZERO, Vector3.UP)
	sun.shadow_enabled = true
	add_child(sun)


func _make_selection_box() -> void:
	_selection = MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(1.04, 1.04, 1.04)
	_selection.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection.material_override = mat
	_selection.visible = false
	add_child(_selection)


# ---------- SETUP & BUILD ----------

func setup(p_name: String, world_data: Dictionary) -> void:
	world_name = p_name
	tiles = world_data.get("tiles", {})
	world_data["tiles"] = tiles
	_rebuild()


func _rebuild() -> void:
	if _terrain != null:
		_terrain.queue_free()
	tile_nodes.clear()
	plant_nodes.clear()
	stack_nodes.clear()
	gen_data = _gen.generate(world_name)
	_leaf_color = Color(String(gen_data["palette"][1]))
	_grass_top = _solid(String(gen_data["palette"][0]))
	_terrain = Node3D.new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	_build_terrain()
	_build_features()
	_apply_saved_tiles()


func _build_terrain() -> void:
	_add_visual_box(Vector3(11.5, -0.5, 11.5), Vector3(SIZE, 1, SIZE), _materials["bedrock"])
	_add_visual_box(Vector3(11.5, 0.5, 11.5), Vector3(SIZE, 1, SIZE), _materials["stone"])
	_add_visual_box(Vector3(11.5, 1.5, 11.5), Vector3(SIZE, 1, SIZE), _materials["dirt"])
	_add_visual_box(Vector3(11.5, 2.5, 11.5), Vector3(SIZE, 1, SIZE), _materials["dirt"])
	var base := StaticBody3D.new()
	base.name = "GroundBase"
	base.position = Vector3(11.5, 1.75, 11.5)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(SIZE, 3.5, SIZE)
	cs.shape = shape
	base.add_child(cs)
	_terrain.add_child(base)
	var types: Dictionary = gen_data["types"]
	for x in SIZE:
		for z in SIZE:
			var k := "%d,%d" % [x, z]
			_make_tile(x, z, String(types[k]))


func _make_tile(x: int, z: int, type: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _box
	mesh.position = Vector3(x, 3.5, z)
	mesh.material_override = _material_for(type)
	_terrain.add_child(mesh)
	var body := StaticBody3D.new()
	body.position = Vector3(x, 3.5, z)
	var cs := CollisionShape3D.new()
	cs.shape = _unit_shape
	body.add_child(cs)
	body.set_meta("tile", {"x": x, "z": z})
	_terrain.add_child(body)
	tile_nodes[_k(x, z)] = {"mesh": mesh, "body": body, "type": type}


func _material_for(type: String) -> StandardMaterial3D:
	match type:
		"grass":
			return _grass_top
		"sand":
			return _materials["sand"]
		"soil":
			return _materials["soil"]
		"water":
			return _materials["water"]
		"lava":
			return _materials["lava"]
	return _materials["dirt"]


func _add_visual_box(pos: Vector3, sizev: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _box
	mesh.position = pos
	mesh.scale = sizev
	mesh.material_override = mat
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_terrain.add_child(mesh)
	return mesh


func _add_solid_box(pos: Vector3, sizev: Vector3, mat: Material) -> void:
	_add_visual_box(pos, sizev, mat)
	var body := StaticBody3D.new()
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = sizev
	cs.shape = shape
	body.add_child(cs)
	_terrain.add_child(body)


func _build_features() -> void:
	for t in gen_data["trees"]:
		_make_tree(int(t["x"]), int(t["z"]), float(t["scale"]))
	for r in gen_data["rocks"]:
		_add_solid_box(Vector3(int(r["x"]), 4.15, int(r["z"])), Vector3(0.8, float(r["h"]), 0.8), _materials["stone"])
	for isl in gen_data["islands"]:
		var ix := int(isl["x"])
		var iz := int(isl["z"])
		var iy := int(isl["y"])
		for a in 3:
			for b in 3:
				_add_solid_box(Vector3(ix + a, iy, iz + b), Vector3.ONE, _materials["dirt"])
				_add_visual_box(Vector3(ix + a, iy + 0.55, iz + b), Vector3.ONE, _grass_top)


func _make_tree(x: int, z: int, scale: float) -> void:
	var g := Node3D.new()
	g.position = Vector3(x, 4, z)
	_terrain.add_child(g)
	var trunk_size := Vector3(0.38 * scale, 2 * scale, 0.38 * scale)
	var trunk := MeshInstance3D.new()
	trunk.mesh = _box
	trunk.position = Vector3(0, scale, 0)
	trunk.scale = trunk_size
	trunk.material_override = _materials["wood"]
	g.add_child(trunk)
	var body := StaticBody3D.new()
	body.position = Vector3(0, scale, 0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = trunk_size
	cs.shape = shape
	body.add_child(cs)
	g.add_child(body)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = _leaf_color
	_add_child_box(g, Vector3(0, 2.35 * scale, 0), Vector3(1.5 * scale, 1.1 * scale, 1.5 * scale), leaf)
	_add_child_box(g, Vector3(-0.45 * scale, 2.85 * scale, 0), Vector3(0.85 * scale, 0.8 * scale, 0.85 * scale), leaf)
	_add_child_box(g, Vector3(0.45 * scale, 2.85 * scale, 0.1 * scale), Vector3(0.8 * scale, 0.8 * scale, 0.8 * scale), leaf)


func _add_child_box(parent: Node3D, pos: Vector3, sizev: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _box
	mesh.position = pos
	mesh.scale = sizev
	mesh.material_override = mat
	parent.add_child(mesh)


func _apply_saved_tiles() -> void:
	for k in tiles.keys():
		var parts := String(k).split(",")
		var x := int(parts[0])
		var z := int(parts[1])
		if not tile_nodes.has(k):
			continue
		var entry: Dictionary = tiles[k]
		var t := String(entry.get("type", ""))
		if t == "soil":
			_set_tile_type(x, z, "soil")
		elif t == "water":
			_set_tile_type(x, z, "water")
		elif t == "lava":
			_set_tile_type(x, z, "lava")
		if t == "plant":
			_spawn_plant(x, z, String(entry.get("id", "door")), int(entry.get("planted_at", GameState.now_ms())), int(entry.get("watered", 0)))
		var st: Array = entry.get("stack", [])
		if st.size() > 0:
			var arr: Array = []
			stack_nodes[k] = arr
			for bid in st:
				arr.append(_spawn_block(x, z, arr.size(), String(bid)))


func _set_tile_type(x: int, z: int, type: String) -> void:
	var k := _k(x, z)
	if not tile_nodes.has(k):
		return
	var t: Dictionary = tile_nodes[k]
	t["type"] = type
	t["mesh"].material_override = _material_for(type)


# ---------- QUERI ----------

func _k(x: int, z: int) -> String:
	return "%d,%d" % [x, z]


func tile_type(x: int, z: int) -> String:
	var t: Dictionary = tile_nodes.get(_k(x, z), {})
	if t.is_empty():
		return ""
	return String(t["type"])


func stack_height(x: int, z: int) -> int:
	var arr: Array = stack_nodes.get(_k(x, z), [])
	return arr.size()


func set_highlight(aim: Dictionary) -> void:
	if aim.is_empty():
		_selection.visible = false
		return
	var x := int(aim["x"])
	var z := int(aim["z"])
	var y := 3.5
	var arr: Array = stack_nodes.get(_k(x, z), [])
	if arr.size() > 0:
		y = 4.5 + (arr.size() - 1)
	_selection.visible = true
	_selection.position = Vector3(x, y, z)


# ---------- PERIZINAN (World Lock) ----------

func _can_build() -> bool:
	var wd: Dictionary = GameState.current_world_data()
	if bool(wd.get("locked", false)):
		var owner := String(wd.get("owner", ""))
		var access: Array = wd.get("access", [])
		if owner != GameState.player_name and not access.has(GameState.player_name):
			GameState.notify("World ini terkunci — kamu tidak punya izin membangun.")
			return false
	return true


# ---------- INTERAKSI (paritas performPunch/interact/water HTML) ----------

func handle_punch(aim: Dictionary) -> void:
	if aim.is_empty():
		return
	var x := int(aim["x"])
	var z := int(aim["z"])
	if aim.has("idx"):
		_punch_block(x, z)
		return
	var k := _k(x, z)
	if plant_nodes.has(k):
		_harvest(x, z)
		return
	match tile_type(x, z):
		"grass":
			_till(x, z)
		"sand":
			GameState.notify("Pasir pantai tidak bisa digarap. (Bisa dipasangi blok!)")
		"water":
			GameState.notify("Kolam air. Bisa ditimbun dengan blok!")
		"lava":
			GameState.notify("Lava panas! Jangan diinjak terlalu lama.")
		"soil":
			GameState.notify("Petak sudah digarap — tekan E untuk menanam.")


func handle_place(aim: Dictionary) -> void:
	if aim.is_empty():
		return
	var it: Dictionary = GameState.hotbar_item()
	var x := int(aim["x"])
	var z := int(aim["z"])
	if String(it["kind"]) == "seed":
		_plant_seed(x, z, it["ref"])
	else:
		_place_block(x, z, it["ref"])


func handle_water(aim: Dictionary) -> void:
	if aim.is_empty():
		return
	var k := _k(int(aim["x"]), int(aim["z"]))
	var p: PlantNode = plant_nodes.get(k, null)
	if p == null:
		GameState.notify("Tidak ada tanaman di depanmu.")
		return
	p.watered_at = GameState.now_ms()
	_write_tile(k, {"watered": p.watered_at})
	SaveSystem.save_game()
	GameState.notify("%s disiram — panen mendapat bonus 25%% gem!" % String(p.data["name"]))


# ---------- AKSI TILE ----------

func _write_tile(k: String, patch: Dictionary) -> void:
	var base: Dictionary = tiles.get(k, {})
	for key in patch:
		base[key] = patch[key]
	tiles[k] = base


func _till(x: int, z: int) -> void:
	if not _can_build():
		return
	_set_tile_type(x, z, "soil")
	_write_tile(_k(x, z), {"type": "soil"})
	GameState.add_xp(2.0, "Menggarap tanah")
	GameState.notify("Tanah digarap — pilih seed lalu tekan E untuk menanam.")
	SaveSystem.save_game()


func _plant_seed(x: int, z: int, s: Dictionary) -> void:
	var k := _k(x, z)
	var t: Dictionary = tile_nodes.get(k, {})
	if t.is_empty():
		return
	if String(t["type"]) != "soil":
		GameState.notify("Garap rumput dulu (klik kiri), lalu tekan E di tanah garap.")
		return
	if plant_nodes.has(k):
		GameState.notify("Petak sudah ditanami.")
		return
	if not _can_build():
		return
	var sid := String(s["id"])
	if not GameState.take_seed(sid, 1):
		GameState.notify("Seed %s habis. Beli di toko [B]." % String(s["name"]))
		return
	var now := GameState.now_ms()
	_spawn_plant(x, z, sid, now, 0)
	_write_tile(k, {"type": "plant", "id": sid, "planted_at": now, "watered": 0})
	GameState.planted += 1
	GameState.state_changed.emit()
	SaveSystem.save_game()
	GameState.notify("%s ditanam! Tumbuh %s — tetap tumbuh walau game ditutup." % [String(s["name"]), Catalog.fmt_grow(float(s["time"]))])


func _harvest(x: int, z: int) -> void:
	var k := _k(x, z)
	var p: PlantNode = plant_nodes[k]
	var s: Dictionary = p.data
	if p.growth_left() > 0.0:
		GameState.notify("%s belum matang — sisa %s. Tekan F untuk demo 60x." % [String(s["name"]), Catalog.fmt_grow(p.growth_left())])
		return
	var wet := p.watered_at > 0
	var raw_gems := _rng.randi_range(int(s["gems"][0]), int(s["gems"][1]))
	var gem := int(round(raw_gems * GameState.level_bonus() * (1.25 if wet else 1.0)))
	var raw_seeds := _rng.randi_range(int(s["seeds"][0]), int(s["seeds"][1]))
	var seed_count := maxi(1, int(round(raw_seeds * GameState.level_bonus())))
	GameState.gems += gem
	GameState.gems_earned += gem
	GameState.harvests += 1
	GameState.add_seed(String(s["id"]), seed_count)
	var src := "Panen " + String(s["name"])
	if wet:
		src += " (disiram, +25%)"
	GameState.add_xp(gem * 0.25 + 5.0, src)
	p.queue_free()
	plant_nodes.erase(k)
	var base: Dictionary = tiles.get(k, {})
	base.erase("type")
	base.erase("id")
	base.erase("planted_at")
	base.erase("watered")
	if base.is_empty():
		tiles.erase(k)
	else:
		tiles[k] = base
	SaveSystem.save_game()
	var msg := "Panen %s! +%d gems (+%d seed)" % [String(s["name"]), gem, seed_count]
	if wet:
		msg += " — bonus siram 25%"
	GameState.notify(msg)


# ---------- BLOK BANGUNAN ----------

func _spawn_plant(x: int, z: int, id: String, planted_at: int, watered_at: int) -> PlantNode:
	var p := PlantNode.new()
	p.setup(id, planted_at, watered_at)
	p.position = Vector3(x, 4, z)
	_terrain.add_child(p)
	plant_nodes[_k(x, z)] = p
	return p


func _spawn_block(x: int, z: int, idx: int, block_id: String) -> Dictionary:
	var mesh := MeshInstance3D.new()
	mesh.mesh = _box
	mesh.position = Vector3(x, 4.5 + idx, z)
	mesh.material_override = _materials["blk_" + block_id]
	_terrain.add_child(mesh)
	var body := StaticBody3D.new()
	body.position = Vector3(x, 4.5 + idx, z)
	var cs := CollisionShape3D.new()
	cs.shape = _unit_shape
	body.add_child(cs)
	body.set_meta("tile", {"x": x, "z": z, "idx": idx})
	_terrain.add_child(body)
	return {"id": block_id, "mesh": mesh, "body": body}


func _place_block(x: int, z: int, b: Dictionary) -> void:
	if not _can_build():
		return
	var k := _k(x, z)
	var t: Dictionary = tile_nodes.get(k, {})
	if t.is_empty():
		return
	if plant_nodes.has(k):
		GameState.notify("Petak ada tanamannya — panen dulu sebelum membangun.")
		return
	var arr: Array = stack_nodes.get(k, [])
	if arr.size() >= MAX_STACK:
		GameState.notify("Maksimal %d blok per petak." % MAX_STACK)
		return
	var bid := String(b["id"])
	if not GameState.take_block(bid, 1):
		GameState.notify("%s habis. Beli di toko [B]." % String(b["name"]))
		return
	arr.append(_spawn_block(x, z, arr.size(), bid))
	stack_nodes[k] = arr
	var ids: Array = []
	for e in arr:
		ids.append(e["id"])
	_write_tile(k, {"type": String(t["type"]), "stack": ids})
	GameState.notify("%s dipasang — bisa ditumpuk & berdiri di atasnya!" % String(b["name"]))
	SaveSystem.save_game()


func _punch_block(x: int, z: int) -> void:
	if not _can_build():
		return
	var k := _k(x, z)
	var arr: Array = stack_nodes.get(k, [])
	if arr.is_empty():
		return
	var top: Dictionary = arr.back()
	top["mesh"].queue_free()
	top["body"].queue_free()
	arr.pop_back()
	var bid := String(top["id"])
	GameState.add_block(bid, 1)
	GameState.add_xp(1.0, "Menghancurkan " + String(Catalog.block_by_id(bid)["name"]))
	if arr.is_empty():
		stack_nodes.erase(k)
		var base: Dictionary = tiles.get(k, {})
		base.erase("stack")
		if base.is_empty():
			tiles.erase(k)
		else:
			tiles[k] = base
	else:
		var ids: Array = []
		for e in arr:
			ids.append(e["id"])
		_write_tile(k, {"stack": ids})
	GameState.notify(String(Catalog.block_by_id(bid)["name"]) + " diambil kembali (+1)")
	SaveSystem.save_game()
