extends CanvasLayer

var hp_label: Label
var status_label: Label
var chat_panel: PanelContainer
var chat_input: LineEdit
var chat_log: RichTextLabel
var chat_toggle: Button

func _ready() -> void:
    _build_theme()
    _build_status_panel()
    _build_chat_button()
    _build_chat_panel()

func _build_theme() -> void:
    var theme := Theme.new()
    theme.default_font_size = 16
    theme.set_color("font_color", "Label", Color("#f4f7f1"))
    theme.set_color("font_shadow_color", "Label", Color("#172b27"))
    theme.set_constant("shadow_offset_x", "Label", 1)
    theme.set_constant("shadow_offset_y", "Label", 1)
    theme.set_color("font_color", "Button", Color("#f5fff6"))
    theme.set_color("font_hover_color", "Button", Color.WHITE)
    theme.set_color("font_pressed_color", "Button", Color.WHITE)
    var button_style := StyleBoxFlat.new()
    button_style.bg_color = Color("#214e45")
    button_style.border_color = Color("#78c879")
    button_style.set_border_width_all(2)
    button_style.set_corner_radius_all(8)
    button_style.content_margin_left = 14
    button_style.content_margin_right = 14
    button_style.content_margin_top = 8
    button_style.content_margin_bottom = 8
    theme.set_stylebox("normal", "Button", button_style)
    var hover_style := button_style.duplicate()
    hover_style.bg_color = Color("#2d705b")
    theme.set_stylebox("hover", "Button", hover_style)
    var panel_style := StyleBoxFlat.new()
    panel_style.bg_color = Color("#173b35e8")
    panel_style.border_color = Color("#82c77d")
    panel_style.set_border_width_all(2)
    panel_style.set_corner_radius_all(12)
    panel_style.content_margin_left = 14
    panel_style.content_margin_right = 14
    panel_style.content_margin_top = 12
    panel_style.content_margin_bottom = 12
    theme.set_stylebox("panel", "PanelContainer", panel_style)
    self.theme = theme

func _build_status_panel() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(22, 22)
    panel.custom_minimum_size = Vector2(360, 0)
    add_child(panel)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 5)
    panel.add_child(column)

    var title := Label.new()
    title.text = "GROWMAX  /  WORLD STARTER"
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color("#b8f49b"))
    column.add_child(title)

    hp_label = Label.new()
    hp_label.text = "♥  HP 100 / 100"
    column.add_child(hp_label)

    status_label = Label.new()
    status_label.text = "WASD / ↑↓←→ bergerak   •   SPACE lompat"
    column.add_child(status_label)

    var controls := Label.new()
    controls.text = "AIR: berenang     LAVA: mengurangi HP"
    controls.add_theme_color_override("font_color", Color("#b9e5ef"))
    column.add_child(controls)

func _build_chat_button() -> void:
    chat_toggle = Button.new()
    chat_toggle.text = "✉  CHAT WORLD   [ENTER]"
    chat_toggle.position = Vector2(22, 174)
    chat_toggle.custom_minimum_size = Vector2(210, 44)
    add_child(chat_toggle)
    chat_toggle.pressed.connect(_toggle_chat)

func _build_chat_panel() -> void:
    chat_panel = PanelContainer.new()
    chat_panel.position = Vector2(22, 230)
    chat_panel.custom_minimum_size = Vector2(390, 310)
    chat_panel.size = Vector2(390, 310)
    chat_panel.visible = false
    add_child(chat_panel)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 9)
    chat_panel.add_child(layout)

    var heading := Label.new()
    heading.text = "CHAT WORLD"
    heading.add_theme_font_size_override("font_size", 19)
    heading.add_theme_color_override("font_color", Color("#b8f49b"))
    layout.add_child(heading)

    chat_log = RichTextLabel.new()
    chat_log.custom_minimum_size = Vector2(350, 205)
    chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    chat_log.bbcode_enabled = true
    chat_log.scroll_following = true
    chat_log.text = "[color=#a9d7a5]Mode lokal — pesan belum terkirim ke pemain lain.[/color]"
    layout.add_child(chat_log)

    chat_input = LineEdit.new()
    chat_input.placeholder_text = "Ketik pesan atau /help..."
    chat_input.max_length = 180
    chat_input.custom_minimum_size.y = 40
    chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(chat_input)
    chat_input.text_submitted.connect(_send_chat)

    var send := Button.new()
    send.text = "KIRIM PESAN"
    send.custom_minimum_size.y = 42
    send.pressed.connect(func(): _send_chat(chat_input.text))
    layout.add_child(send)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
        if chat_panel.visible:
            if not chat_input.has_focus():
                chat_input.grab_focus()
            elif not chat_input.text.is_empty():
                _send_chat(chat_input.text)
        else:
            _toggle_chat()
        get_viewport().set_input_as_handled()

func _toggle_chat() -> void:
    chat_panel.visible = not chat_panel.visible
    if chat_panel.visible:
        chat_input.grab_focus()
    else:
        chat_input.release_focus()

func _send_chat(raw_text: String) -> void:
    var message := raw_text.strip_edges()
    if message.is_empty():
        chat_input.grab_focus()
        return
    if message.begins_with("/"):
        _chat_command(message.to_lower())
    else:
        _append_chat("[color=#8ed6ff]You[/color]: " + message)
    chat_input.clear()
    chat_input.grab_focus()

func _chat_command(command: String) -> void:
    match command:
        "/help":
            _append_chat("[color=#e8cf83]Perintah: /help, /who, /world[/color]")
        "/who":
            _append_chat("[color=#e8cf83]Pemain online: 1 (kamu, mode lokal)[/color]")
        "/world":
            _append_chat("[color=#e8cf83]World aktif: STARTER[/color]")
        _:
            _append_chat("[color=#ff9b91]Perintah tidak dikenal. Ketik /help[/color]")

func _append_chat(message: String) -> void:
    chat_log.append_text("\n" + message)

func set_health(value: int) -> void:
    hp_label.text = "♥  HP %d / 100" % value

func set_status(value: String) -> void:
    status_label.text = value
