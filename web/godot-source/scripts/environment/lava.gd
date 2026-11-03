extends Area3D
@export var size := Vector3(10, 3, 8)
@export var damage := 35
@export var damage_cooldown := 1.0
var can_damage := true
func _ready() -> void:
    name = "LavaHazard"
    monitoring = true
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    add_child(collider)
    body_entered.connect(_on_body_entered)
    var surface := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(size.x, 0.18, size.z)
    surface.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("#ff5a16")
    material.emission_enabled = true
    material.emission = Color("#ff3b08")
    material.emission_energy_multiplier = 2.2
    material.roughness = 0.35
    surface.material_override = material
    surface.position.y = -size.y * 0.5 + 0.15
    add_child(surface)
func _on_body_entered(body: Node3D) -> void:
    if body.has_method("take_damage") and can_damage:
        can_damage = false
        body.take_damage(damage)
        await get_tree().create_timer(damage_cooldown).timeout
        can_damage = true
