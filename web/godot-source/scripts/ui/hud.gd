extends CanvasLayer
var hp_label: Label
var status_label: Label
func _ready() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(320, 108)
    add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var title := Label.new()
    title.text = "GROWMAX"
    title.add_theme_font_size_override("font_size", 22)
    column.add_child(title)
    hp_label = Label.new()
    hp_label.text = "HP: 100"
    column.add_child(hp_label)
    status_label = Label.new()
    status_label.text = "WASD bergerak · Space lompat · R respawn"
    column.add_child(status_label)
    var controls := Label.new()
    controls.text = "WATER: berenang  |  LAVA: mengurangi HP"
    column.add_child(controls)
func set_health(value: int) -> void:
    hp_label.text = "HP: %d" % value
func set_status(value: String) -> void:
    status_label.text = value
