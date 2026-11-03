extends CanvasLayer

var hp_label: Label
var status_label: Label
var chat_panel: PanelContainer
var chat_input: LineEdit
var chat_log: RichTextLabel
var chat_toggle: Button

func _ready() -> void:
    var panel := PanelContainer.new()
    panel.position = Vector2(16, 16)
    panel.custom_minimum_size = Vector2(340, 116)
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

    chat_toggle = Button.new()
    chat_toggle.text = "💬 Chat World  [Enter]"
    chat_toggle.position = Vector2(16, 144)
    chat_toggle.size = Vector2(180, 36)
    add_child(chat_toggle)
    chat_toggle.pressed.connect(_toggle_chat)

    _build_chat_panel()

func _build_chat_panel() -> void:
    chat_panel = PanelContainer.new()
    chat_panel.position = Vector2(16, 190)
    chat_panel.custom_minimum_size = Vector2(360, 260)
    chat_panel.size = Vector2(360, 260)
    chat_panel.visible = false
    add_child(chat_panel)

    var layout := VBoxContainer.new()
    chat_panel.add_child(layout)

    var heading := Label.new()
    heading.text = "💬 CHAT WORLD"
    heading.add_theme_font_size_override("font_size", 18)
    layout.add_child(heading)

    chat_log = RichTextLabel.new()
    chat_log.custom_minimum_size = Vector2(330, 170)
    chat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
    chat_log.bbcode_enabled = true
    chat_log.scroll_following = true
    chat_log.text = "[color=#9bc6a0]Mode lokal — pesan belum terkirim ke pemain lain.[/color]"
    layout.add_child(chat_log)

    chat_input = LineEdit.new()
    chat_input.placeholder_text = "Ketik pesan atau /help..."
    chat_input.max_length = 180
    chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    layout.add_child(chat_input)
    chat_input.text_submitted.connect(_send_chat)

    var send := Button.new()
    send.text = "Kirim"
    send.pressed.connect(func(): _send_chat(chat_input.text))
    layout.add_child(send)

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
        if chat_panel.visible:
            if not chat_input.has_focus():
                chat_input.grab_focus()
            else:
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
    hp_label.text = "HP: %d" % value

func set_status(value: String) -> void:
    status_label.text = value
