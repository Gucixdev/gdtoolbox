@tool
class_name EzDialogue
extends Node

## Odtwarza dialogue z pliku JSON.
##
## Użycie:
##   start()           → zaczyna od `start_node`
##   advance()         → przejście do następnego noda (po emitowaniu `line`)
##   choose(index)     → wybór opcji (po emitowaniu `choices`)
##
## Format JSON: patrz addons/ezdialogue/test/dialogue_test.json
##
## Sygnały przechodzą też przez /root/DialogueBus (jeśli plugin włączony).

signal started
signal ended
signal line(speaker: String, text: String)
signal choices(options: Array)   ## Array[Dictionary] — {text, index, available, next}
signal event(event_name: String)

@export_file("*.json") var dialogue_file: String = ""
@export var start_node: String = "start"
@export var auto_start: bool = false
## Wypisuje linie dialogu, choices i eventy w panelu Output Godota.
## W edytorze zawsze aktywne niezależnie od tej flagi.
@export var print_to_console: bool = false

@export_group("Editor Controls")
@export_tool_button("▶ Start") var _btn_start = func(): start()
@export_tool_button("▶ Advance") var _btn_advance = func(): advance()
## Index opcji do wybrania przyciskiem ▶ Choose
@export var pick: int = 0
@export_tool_button("▶ Choose") var _btn_choose = func(): choose(pick)

var _data: Dictionary = {}
var _loaded_file: String = ""
var _current_node_id: String = ""
var _current_choices: Array = []

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if auto_start: start()

func _should_print() -> bool:
	return print_to_console or Engine.is_editor_hint()

## Startuje dialogue od podanego noda (domyślnie `start_node`).
func start(node_id: String = "") -> void:
	if node_id.is_empty(): node_id = start_node
	if not _load_data(): return
	_current_node_id = ""
	_current_choices.clear()
	if _should_print(): print("[EzDialogue] ▶ START: ", _loaded_file)
	started.emit()
	_bus_call(&"dialogue_started", _loaded_file)
	_go_to(node_id)

## Przechodzi do następnego noda. Wywołaj po odebraniu sygnału `line`.
func advance() -> void:
	if not _current_choices.is_empty():
		push_warning(name + ": są aktywne choices — użyj choose(index)")
		if _should_print():
			print("[EzDialogue] ! są choices, ustaw 'pick' i naciśnij ▶ Choose")
		return
	if _current_node_id.is_empty():
		push_warning(name + ": dialogue nie jest aktywny — wywołaj start() najpierw")
		return
	var n: Dictionary = _data.get("nodes", {}).get(_current_node_id, {})
	_step_next(n)

## Wybiera opcję z aktualnych choices. `index` odpowiada polu `index` w Array z sygnału `choices`.
func choose(index: int) -> void:
	if _current_choices.is_empty():
		push_warning(name + ": brak aktywnych choices — poczekaj na sygnał 'choices'")
		return
	if index < 0 or index >= _current_choices.size():
		push_error(name + ": nieprawidłowy index: " + str(index) + " (max: " + str(_current_choices.size() - 1) + ")")
		return
	var ch: Dictionary = _current_choices[index]
	if not ch.get("available", true):
		push_warning(name + ": choice [" + str(index) + "] niedostępny (requires nie spełniony)")
		return
	if _should_print(): print("[EzDialogue] → wybrałeś [%d] %s" % [index, ch["text"]])
	_current_choices.clear()
	var next = ch.get("next", null)
	if _is_null_or_empty(next):
		_end()
	else:
		_go_to(str(next))

func _go_to(node_id: String) -> void:
	if not _data.has("nodes"):
		push_error(name + ": brak klucza 'nodes' w JSON: " + _loaded_file)
		_end()
		return
	var nodes: Dictionary = _data["nodes"]
	if not nodes.has(node_id):
		push_error(name + ": nie znaleziono noda '" + node_id + "' w: " + _loaded_file)
		_end()
		return
	_current_node_id = node_id
	var n: Dictionary = nodes[node_id]

	# Eventy zawsze najpierw
	if n.has("events"):
		for ev in n["events"]:
			var ev_str := str(ev)
			if _should_print(): print("[EzDialogue] event: ", ev_str)
			event.emit(ev_str)
			_bus_call(&"event_fired", ev_str)

	# Choices — czekaj na choose()
	if n.has("choices"):
		_emit_choices(n["choices"])
		return

	# Tekst — czekaj na advance()
	if n.has("text"):
		var speaker := str(n.get("speaker", ""))
		var text := str(n["text"])
		if _should_print():
			var prefix := "[%s] " % speaker if not speaker.is_empty() else ""
			print("[EzDialogue] ", prefix, text)
			if Engine.is_editor_hint():
				print("[EzDialogue] (naciśnij ▶ Advance żeby kontynuować)")
		line.emit(speaker, text)
		_bus_call_two(&"line_spoken", speaker, text)
		return

	# Pusty node / tylko eventy — auto-advance
	_step_next(n)

func _emit_choices(raw: Array) -> void:
	var db := _get_bus()
	var out: Array = []
	for i in raw.size():
		var ch: Dictionary = raw[i]
		var available := true
		if ch.has("requires"):
			var req: Dictionary = ch["requires"]
			for key in req:
				var expected = req[key]
				var actual = db.call("get_flag", str(key)) if db else null
				if actual != expected:
					available = false
					break
		out.append({
			"text":      ch.get("text", ""),
			"index":     i,
			"next":      ch.get("next", null),
			"available": available,
		})
	_current_choices = out
	if _should_print():
		print("[EzDialogue] choices:")
		for c in out:
			var avail := "" if c["available"] else " [locked]"
			print("  [%d] %s%s" % [c["index"], c["text"], avail])
		if Engine.is_editor_hint():
			print("[EzDialogue] (ustaw 'pick' = index i naciśnij ▶ Choose)")
	choices.emit(out)
	if db: db.choices_available.emit(out)

func _step_next(n: Dictionary) -> void:
	var next = n.get("next", null)
	if _is_null_or_empty(next):
		_end()
	else:
		_go_to(str(next))

func _end() -> void:
	_current_node_id = ""
	_current_choices.clear()
	if _should_print(): print("[EzDialogue] ■ END")
	ended.emit()
	_bus_call(&"dialogue_ended", _loaded_file)

func _load_data() -> bool:
	if dialogue_file.is_empty():
		push_warning(name + ": dialogue_file nie ustawiony")
		return false
	if _loaded_file == dialogue_file and not _data.is_empty():
		return true
	if not FileAccess.file_exists(dialogue_file):
		push_error(name + ": plik nie istnieje: " + dialogue_file)
		return false
	var f := FileAccess.open(dialogue_file, FileAccess.READ)
	if not f:
		push_error(name + ": nie można otworzyć: " + dialogue_file + " (err: " + str(FileAccess.get_open_error()) + ")")
		return false
	var raw := f.get_as_text()
	f.close()
	var json := JSON.new()
	var err := json.parse(raw)
	if err != OK:
		push_error(name + ": błąd JSON (linia " + str(json.get_error_line()) + "): " + json.get_error_message())
		return false
	if not json.data is Dictionary:
		push_error(name + ": JSON musi być obiektem {}, nie tablicą")
		return false
	_data = json.data
	_loaded_file = dialogue_file
	return true

func _get_bus() -> Node:
	if Engine.is_editor_hint(): return null
	return get_node_or_null("/root/DialogueBus")

func _bus_call(method: StringName, arg: Variant) -> void:
	var db := _get_bus()
	if db: db.emit_signal(method, arg)

func _bus_call_two(method: StringName, a: Variant, b: Variant) -> void:
	var db := _get_bus()
	if db: db.emit_signal(method, a, b)

func _is_null_or_empty(v: Variant) -> bool:
	if v == null: return true
	if v is String: return (v as String).is_empty()
	return false
