extends Node
## ChatSystem — chat world mode lokal (paritas prototipe HTML).
## Perintah: /help, /who, /world. Chat online butuh server multiplayer —
## arsitektur dibuat agar tiap pesan berbentuk entri yang mudah disinkronkan.

signal chat_changed

const MAX_LEN := 180
const MAX_HISTORY := 200

var history: Array = []


func send(raw: String) -> Dictionary:
	var text_msg := raw.strip_edges(true, true)
	if text_msg == "":
		return {}
	if text_msg.length() > MAX_LEN:
		text_msg = text_msg.substr(0, MAX_LEN)
	if text_msg == "/help":
		text_msg = "Perintah: /help, /who, /world"
	elif text_msg == "/who":
		text_msg = "Mode lokal: hanya kamu yang berada di world ini."
	elif text_msg == "/world":
		text_msg = "World saat ini: " + GameState.world
	var entry := {"from": GameState.player_name, "text": text_msg, "time": GameState.now_ms()}
	history.push_back(entry)
	while history.size() > MAX_HISTORY:
		history.pop_front()
	chat_changed.emit()
	return entry


func render_line(e: Dictionary) -> String:
	var dt := Time.get_time_dict_from_system()
	return "[%02d:%02d] %s: %s" % [int(dt["hour"]), int(dt["minute"]), String(e["from"]), String(e["text"])]
