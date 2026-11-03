extends Node
## GameState — state global pemain (gems, WL/DL/BGL, level/XP, inventory, world).
## Struktur data kompatibel dengan format save HTML "growmax-world-v2" agar
## save lama bisa dimigrasi dan format tetap konsisten.

signal state_changed
signal leveled_up(new_level: int, zone_name: String)
signal toast_requested(message: String)

const MAX_HP := 100.0
const XP_PER_LEVEL := 100.0
const DEFAULT_BLOCK_INV := {"wood": 60, "brick": 30, "stone": 40, "sand": 20, "glass": 20}

var gems := 20
var wl := 1
var dl := 0
var bgl := 0
var level := 1
var xp := 0.0
var xp_total := 0.0
var harvests := 0
var planted := 0
var gems_earned := 0
var selected := 0
var accelerated := false
var ui_open := 0
var player_name := "Kamu"
var hp := MAX_HP
var inventory := {"door": 1}
var block_inv := {}
var xp_log: Array = []
var world := "starter"
var worlds := {}
var world_manager = null


func _ready() -> void:
	block_inv = {}
	for k in DEFAULT_BLOCK_INV:
		block_inv[k] = int(DEFAULT_BLOCK_INV[k])
	worlds = {"starter": new_world_data()}


func new_world_data() -> Dictionary:
	return {
		"tiles": {},
		"player": {"x": 12.0, "z": 15.0},
		"created": now_ms(),
		"locked": false,
		"owner": "",
		"access": [],
	}


func now_ms() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)


func current_world_data() -> Dictionary:
	if not worlds.has(world):
		worlds[world] = new_world_data()
	return worlds[world]


func xp_needed() -> float:
	return level * XP_PER_LEVEL


## Bonus hasil panen: +3% per level (paritas HTML: 1+(level-1)*0.03).
func level_bonus() -> float:
	return 1.0 + (level - 1) * 0.03


func notify(message: String) -> void:
	toast_requested.emit(message)


func add_xp(n: float, source: String) -> void:
	xp += n
	xp_total += n
	xp_log.push_front("+%d XP — %s" % [int(round(n)), source])
	while xp_log.size() > 25:
		xp_log.pop_back()
	var leveled := false
	var zone := ""
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		leveled = true
		for z in Catalog.ZONES:
			if int(z["lv"]) == level:
				zone = String(z["name"])
	if leveled:
		leveled_up.emit(level, zone)
		var msg := "Naik ke Level %d!" % level
		if zone != "":
			msg += " Zona \"%s\" terbuka!" % zone
		notify(msg)
	state_changed.emit()


func spend_gems(n: int) -> bool:
	if n <= 0 or gems < n:
		return false
	gems -= n
	state_changed.emit()
	return true


func add_gems(n: int) -> void:
	if n <= 0:
		return
	gems += n
	state_changed.emit()


func seed_count(id: String) -> int:
	return int(inventory.get(id, 0))


func block_count(id: String) -> int:
	return int(block_inv.get(id, 0))


func add_seed(id: String, n: int) -> void:
	inventory[id] = seed_count(id) + n
	state_changed.emit()


func take_seed(id: String, n: int) -> bool:
	if seed_count(id) < n:
		return false
	inventory[id] = seed_count(id) - n
	state_changed.emit()
	return true


func add_block(id: String, n: int) -> void:
	block_inv[id] = block_count(id) + n
	state_changed.emit()


func take_block(id: String, n: int) -> bool:
	if block_count(id) < n:
		return false
	block_inv[id] = block_count(id) - n
	state_changed.emit()
	return true


func zone_unlocked(z: Dictionary) -> bool:
	return level >= int(z["lv"])


func hotbar_item() -> Dictionary:
	var items := Catalog.hotbar()
	if selected < 0 or selected >= items.size():
		selected = 0
	return items[selected]


func to_dict() -> Dictionary:
	return {
		"version": 2,
		"gems": gems,
		"wl": wl,
		"dl": dl,
		"bgl": bgl,
		"level": level,
		"xp": xp,
		"xpTotal": xp_total,
		"harvests": harvests,
		"planted": planted,
		"gemsEarned": gems_earned,
		"selected": selected,
		"inventory": inventory,
		"blockInv": block_inv,
		"xpLog": xp_log,
		"world": world,
		"worlds": worlds,
		"hp": hp,
		"player_name": player_name,
	}


func from_dict(d: Dictionary) -> void:
	gems = maxi(0, int(d.get("gems", 20)))
	wl = maxi(0, int(d.get("wl", 1)))
	dl = maxi(0, int(d.get("dl", 0)))
	bgl = maxi(0, int(d.get("bgl", 0)))
	level = maxi(1, int(d.get("level", 1)))
	xp = maxf(0.0, float(d.get("xp", 0.0)))
	xp_total = maxf(0.0, float(d.get("xpTotal", 0.0)))
	harvests = maxi(0, int(d.get("harvests", 0)))
	planted = maxi(0, int(d.get("planted", 0)))
	gems_earned = maxi(0, int(d.get("gemsEarned", 0)))
	selected = clampi(int(d.get("selected", 0)), 0, Catalog.hotbar().size() - 1)
	hp = clampf(float(d.get("hp", MAX_HP)), 1.0, MAX_HP)
	player_name = String(d.get("player_name", "Kamu"))

	var inv: Dictionary = d.get("inventory", {})
	inventory = {}
	for s in Catalog.SEEDS:
		inventory[String(s["id"])] = int(inv.get(String(s["id"]), 0))
	for k in inv:
		if not inventory.has(String(k)):
			inventory[String(k)] = int(inv[k])

	var binv: Dictionary = d.get("blockInv", {})
	block_inv = {}
	for b in Catalog.BLOCKS:
		var bid := String(b["id"])
		block_inv[bid] = int(binv.get(bid, int(DEFAULT_BLOCK_INV.get(bid, 0))))
	for k in binv:
		if not block_inv.has(String(k)):
			block_inv[String(k)] = int(binv[k])

	xp_log = []
	var logs: Array = d.get("xpLog", [])
	for l in logs:
		xp_log.append(String(l))

	var loaded_worlds = d.get("worlds", {})
	if not (loaded_worlds is Dictionary) or loaded_worlds.is_empty():
		# Migrasi save format HTML lama: tiles ada di root, bukan di worlds.
		if d.has("tiles"):
			var t: Dictionary = d.get("tiles", {})
			worlds = {
				"starter": {
					"tiles": t,
					"player": d.get("player", {"x": 12.0, "z": 15.0}),
					"created": now_ms(),
					"locked": false,
					"owner": "",
					"access": [],
				},
			}
		else:
			worlds = {"starter": new_world_data()}
	else:
		worlds = loaded_worlds

	world = String(d.get("world", "starter"))
	if not worlds.has(world):
		worlds[world] = new_world_data()
	for k in worlds:
		var w: Dictionary = worlds[k]
		if not w.has("tiles") or not (w["tiles"] is Dictionary):
			w["tiles"] = {}
		if not w.has("player") or not (w["player"] is Dictionary):
			w["player"] = {"x": 12.0, "z": 15.0}
		if not w.has("created"):
			w["created"] = now_ms()
		if not w.has("locked"):
			w["locked"] = false
		if not w.has("owner"):
			w["owner"] = ""
		if not w.has("access") or not (w["access"] is Array):
			w["access"] = []
	state_changed.emit()


func reset_defaults() -> void:
	gems = 20
	wl = 1
	dl = 0
	bgl = 0
	level = 1
	xp = 0.0
	xp_total = 0.0
	harvests = 0
	planted = 0
	gems_earned = 0
	selected = 0
	accelerated = false
	hp = MAX_HP
	inventory = {"door": 1}
	block_inv = {}
	for k in DEFAULT_BLOCK_INV:
		block_inv[k] = int(DEFAULT_BLOCK_INV[k])
	xp_log = []
	world = "starter"
	worlds = {"starter": new_world_data()}
	state_changed.emit()
