@tool
class_name DialogueSystem
extends Node

## Odtwarza dialogue z Resource DialogueGraph.
##
## Użycie:
##   start()           → zaczyna od `start_node`
##   advance()         → przejście do następnego noda (po emitowaniu `line`)
##   choose(index)     → wybór opcji (po emitowaniu `choices`)
##
## Format: patrz addons/ezdialogue/test/dialogue_test.tres
##
## Flagi stanu gry (`requires` w choices) są wbudowane — wspólne dla wszystkich
## DialogueSystem, zapisywane razem z grą przez SaveSystem (autoload `Saves`):
##   DialogueSystem.set_flag("met_bob", true)
##   DialogueSystem.get_flag("gold", 0)
## Zastępuje dawny autoload DialogueBus. Globalne sygnały: `DialogueSystem.bus`.

signal started
signal ended
signal line(speaker: String, text: String)
signal choices(options: Array)   ## Array[Dictionary] — {text, index, available, next}
signal event(event_name: String)

## Globalne sygnały ze wszystkich dialogów (HUD, questy, achievementy).
static var bus := DialogueBus.new()
static var flags: Dictionary = {}

static func set_flag(key: String, value: Variant) -> void:
	flags[key] = value
	bus.flag_changed.emit(key, value)

static func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)

static func has_flag(key: String) -> bool:
	return flags.has(key)

static func clear_flags() -> void:
	flags.clear()

@export var dialogue: DialogueGraph
## Nadpisuje dialogue.start_node gdy niepuste.
@export var start_node: String = ""
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

var _current_node_id: String = ""
var _current_choices: Array = []

func _ready() -> void:
	if Engine.is_editor_hint(): return
	var saves := get_node_or_null("/root/Saves")
	if saves and saves.has_method("register_provider"):
		saves.register_provider("dialogue_flags",
			func(): return DialogueSystem.flags,
			func(d): DialogueSystem.flags = d)
	if auto_start: start()

func _should_print() -> bool:
	return print_to_console or Engine.is_editor_hint()

## Startuje dialogue od podanego noda (domyślnie `start_node` / dialogue.start_node).
func start(node_id: String = "") -> void:
	if not dialogue:
		push_error(name + ": brak przypisanego DialogueGraph (pole 'dialogue')")
		return
	if node_id.is_empty(): node_id = start_node if not start_node.is_empty() else dialogue.start_node
	_current_node_id = ""
	_current_choices.clear()
	if _should_print(): print("[DialogueSystem] ▶ START: ", dialogue.resource_path)
	started.emit()
	_bus_call(&"dialogue_started", dialogue.resource_path)
	_go_to(node_id)

## Przechodzi do następnego noda. Wywołaj po odebraniu sygnału `line`.
func advance() -> void:
	if not _current_choices.is_empty():
		push_warning(name + ": są aktywne choices — użyj choose(index)")
		if _should_print():
			print("[DialogueSystem] ! są choices, ustaw 'pick' i naciśnij ▶ Choose")
		return
	if _current_node_id.is_empty():
		push_warning(name + ": dialogue nie jest aktywny — wywołaj start() najpierw")
		return
	var n := dialogue.get_node_by_id(_current_node_id)
	if n: _step_next(n)

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
	if _should_print(): print("[DialogueSystem] → wybrałeś [%d] %s" % [index, ch["text"]])
	_current_choices.clear()
	var next: String = ch.get("next", "")
	if next.is_empty():
		_end()
	else:
		_go_to(next)

func _go_to(node_id: String) -> void:
	var n := dialogue.get_node_by_id(node_id)
	if not n:
		push_error(name + ": nie znaleziono noda '" + node_id + "' w: " + dialogue.resource_path)
		_end()
		return
	_current_node_id = node_id

	# Eventy zawsze najpierw
	for ev in n.events:
		if _should_print(): print("[DialogueSystem] event: ", ev)
		event.emit(ev)
		_bus_call(&"event_fired", ev)

	# Choices — czekaj na choose()
	if not n.choices.is_empty():
		_emit_choices(n.choices)
		return

	# Tekst — czekaj na advance()
	if not n.text.is_empty():
		if _should_print():
			var prefix := "[%s] " % n.speaker if not n.speaker.is_empty() else ""
			print("[DialogueSystem] ", prefix, n.text)
			if Engine.is_editor_hint():
				print("[DialogueSystem] (naciśnij ▶ Advance żeby kontynuować)")
		line.emit(n.speaker, n.text)
		_bus_call_two(&"line_spoken", n.speaker, n.text)
		return

	# Pusty node / tylko eventy — auto-advance
	_step_next(n)

func _emit_choices(raw: Array[DialogueChoice]) -> void:
	var db := _get_bus()
	var out: Array = []
	for i in raw.size():
		var ch := raw[i]
		var available := true
		for key in ch.requires:
			var expected = ch.requires[key]
			var actual = flags.get(str(key), null)
			if actual != expected:
				available = false
				break
		out.append({
			"text":      ch.text,
			"index":     i,
			"next":      ch.next,
			"available": available,
		})
	_current_choices = out
	if _should_print():
		print("[DialogueSystem] choices:")
		for c in out:
			var avail := "" if c["available"] else " [locked]"
			print("  [%d] %s%s" % [c["index"], c["text"], avail])
		if Engine.is_editor_hint():
			print("[DialogueSystem] (ustaw 'pick' = index i naciśnij ▶ Choose)")
	choices.emit(out)
	if db: db.choices_available.emit(out)

func _step_next(n: DialogueNode) -> void:
	if n.next.is_empty():
		_end()
	else:
		_go_to(n.next)

func _end() -> void:
	_current_node_id = ""
	_current_choices.clear()
	if _should_print(): print("[DialogueSystem] ■ END")
	ended.emit()
	_bus_call(&"dialogue_ended", dialogue.resource_path if dialogue else "")

func _get_bus() -> DialogueBus:
	return null if Engine.is_editor_hint() else bus

func _bus_call(method: StringName, arg: Variant) -> void:
	var db := _get_bus()
	if db: db.emit_signal(method, arg)

func _bus_call_two(method: StringName, a: Variant, b: Variant) -> void:
	var db := _get_bus()
	if db: db.emit_signal(method, a, b)
