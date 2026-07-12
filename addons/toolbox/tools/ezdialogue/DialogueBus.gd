extends Node

## Globalny bus dialogów. Emituje sygnały z każdego aktywnego EzDialogue.
## Dostępny jako autoload "/root/DialogueBus".
##
## Flagi: prosta baza stanu gry (has_item, quest_started, itp.).
## EzDialogue używa ich do sprawdzania `requires` w choices.

signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal line_spoken(speaker: String, text: String)
signal choices_available(choices: Array)
signal event_fired(event_name: String)
signal flag_changed(key: String, value: Variant)

var _flags: Dictionary = {}

func set_flag(key: String, value: Variant) -> void:
	_flags[key] = value
	flag_changed.emit(key, value)

func get_flag(key: String, default: Variant = null) -> Variant:
	return _flags.get(key, default)

func has_flag(key: String) -> bool:
	return _flags.has(key)

func clear_flags() -> void:
	_flags.clear()
