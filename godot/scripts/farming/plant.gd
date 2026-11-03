class_name PlantNode
extends Node3D
## Tanaman — tumbuh berdasarkan timestamp sehingga progres tetap berjalan
## saat game ditutup (paritas HTML: growth() memakai Date.now()-plantedAt).

var data := {}
var planted_at := 0
var watered_at := 0
var crown: MeshInstance3D
var is_ready := false

var _crown_mat: StandardMaterial3D


func setup(id: String, p_planted_at: int, p_watered_at: int) -> void:
	data = Catalog.seed_by_id(id)
	planted_at = p_planted_at
	watered_at = p_watered_at


func _ready() -> void:
	var box := BoxMesh.new()
	var trunk := MeshInstance3D.new()
	trunk.mesh = box
	trunk.position = Vector3(0, 0.55, 0)
	trunk.scale = Vector3(0.22, 1.1, 0.22)
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color("9a693a")
	trunk.material_override = tm
	add_child(trunk)
	crown = MeshInstance3D.new()
	crown.mesh = box
	_crown_mat = StandardMaterial3D.new()
	_crown_mat.albedo_color = Color(String(data["color"]))
	crown.material_override = _crown_mat
	crown.position = Vector3(0, 1.2, 0)
	crown.scale = Vector3.ONE * 0.225
	add_child(crown)


## Sisa waktu tumbuh (detik). Demo 60x = 60x lebih cepat.
func growth_left() -> float:
	var mult := 1.0
	if GameState.accelerated:
		mult = 60.0
	var left := float(data["time"]) - (GameState.now_ms() - planted_at) / 1000.0 * mult
	return maxf(0.0, left)


func progress() -> float:
	var total := float(data["time"])
	if total <= 0.0:
		return 1.0
	return clampf(1.0 - growth_left() / total, 0.0, 1.0)


func _process(_delta: float) -> void:
	if crown == null:
		return
	var p := progress()
	var s := 0.9 * (0.25 + 0.75 * p)
	crown.scale = Vector3(s, s, s)
	crown.position.y = 1.2 + p * 0.45
	if not is_ready and growth_left() <= 0.0:
		is_ready = true
		_crown_mat.emission_enabled = true
		_crown_mat.emission = Color(String(data["color"]))
		_crown_mat.emission_energy_multiplier = 0.35
