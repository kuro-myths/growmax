extends Node3D
const WORLD_SCENE := preload("res://scenes/world/World.tscn")
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
var player: CharacterBody3D
var hud: CanvasLayer
func _ready() -> void:
    var world := WORLD_SCENE.instantiate()
    world.name = "VoxelWorld"
    add_child(world)
    player = PLAYER_SCENE.instantiate()
    player.position = Vector3(14, 7, 14)
    add_child(player)
    hud = HUD_SCENE.instantiate()
    add_child(hud)
    player.health_changed.connect(hud.set_health)
    player.environment_changed.connect(hud.set_status)
