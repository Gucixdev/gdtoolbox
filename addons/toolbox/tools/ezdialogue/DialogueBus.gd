class_name DialogueBus
extends RefCounted

## Globalne sygnały dialogów — dostępne jako `DialogueSystem.bus`.
## (Dawniej autoload; teraz zwykły obiekt, flagi żyją w DialogueSystem.)

signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal line_spoken(speaker: String, text: String)
signal choices_available(choices: Array)
signal event_fired(event_name: String)
signal flag_changed(key: String, value: Variant)
