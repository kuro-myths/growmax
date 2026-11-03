extends Area3D
@export var size := Vector3(7, 3, 9)
@export var surface_color := Color(0.12, 0.52, 0.86, 0.62)
func _ready() -> void:
    name = "WaterVolume"
    monitoring = true
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collider.shape = shape
    add_child(collider)
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    var surface := MeshInstance3D.new()
    var plane := BoxMesh.new()
    plane.size = Vector3(size.x, 0.12, size.z)
    surface.mesh = plane
    var material := StandardMaterial3D.new()
    material.albedo_color = surface_color
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.roughness = 0.18
    material.metallic = 0.12
    surface.material_override = material
    surface.position.y = size.y * 0.5 - 0.15
    add_child(surface)
func _on_body_entered(body: Node3D) -> void:
    if body.has_method("enter_water"):
        body.enter_water()
func _on_body_exited(body: Node3D) -> void:
    if body.has_method("exit_water"):
        body.exit_water()
