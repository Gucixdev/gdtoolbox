@tool
extends VBoxContainer

const MAX_LOG_LINES := 200

var _status_label: Label
var _clients_label: Label
var _cancel_button: Button
var _log_text: RichTextLabel
var _clear_button: Button
var _log_lines: PackedStringArray = []

func _ready() -> void:
	custom_minimum_size.y = 160

	var top_row := HBoxContainer.new()
	add_child(top_row)

	_status_label = Label.new()
	_status_label.text = "MCP: Offline"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(_status_label)

	_clients_label = Label.new()
	_clients_label.text = "Clients: 0"
	top_row.add_child(_clients_label)

	_cancel_button = Button.new()
	_cancel_button.text = "Cancel"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_on_cancel_pressed)
	top_row.add_child(_cancel_button)

	_clear_button = Button.new()
	_clear_button.text = "Clear"
	_clear_button.pressed.connect(_on_clear_pressed)
	top_row.add_child(_clear_button)

	add_child(HSeparator.new())

	_log_text = RichTextLabel.new()
	_log_text.bbcode_enabled = true
	_log_text.scroll_following = true
	_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_text.selection_enabled = true
	add_child(_log_text)

func update_status(text: String) -> void:
	if _status_label:
		_status_label.text = text

func set_client_count(count: int) -> void:
	if _clients_label:
		_clients_label.text = "Clients: %d" % count

func set_operation_active(active: bool) -> void:
	if _cancel_button:
		_cancel_button.disabled = not active

func log_message(text: String, color: String = "white") -> void:
	var timestamp := Time.get_time_string_from_system()
	var line := "[color=gray]%s[/color] [color=%s]%s[/color]" % [timestamp, color, text]
	_log_lines.append(line)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines = _log_lines.slice(_log_lines.size() - MAX_LOG_LINES)
	if _log_text:
		_log_text.clear()
		for l in _log_lines:
			_log_text.append_text(l + "\n")

func log_cmd(method: String, ok: bool) -> void:
	var color := "green" if ok else "red"
	var icon := "✓" if ok else "✗"
	log_message("%s %s" % [icon, method], color)

func log_connected(port: int) -> void:
	log_message("● Server started on :%d" % port, "cyan")

func log_client(connected: bool, peer_id: int) -> void:
	if connected:
		log_message("→ Client #%d connected" % peer_id, "yellow")
	else:
		log_message("← Client #%d disconnected" % peer_id, "gray")

func _on_cancel_pressed() -> void:
	var server := _find_server()
	if server and server.has_method("cancel_current_operation"):
		server.cancel_current_operation()

func _on_clear_pressed() -> void:
	_log_lines.clear()
	if _log_text:
		_log_text.clear()

func _find_server() -> Node:
	var root := get_tree().get_root() if get_tree() else null
	if root == null:
		return null
	return root.find_child("MCPServer", true, false)
