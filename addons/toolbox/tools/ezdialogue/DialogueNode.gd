@tool
class_name DialogueNode
extends Resource

## Jeden node w DialogueGraph — tekst, choices, eventy lub kombinacja.

@export var id: String = ""
@export var speaker: String = ""
@export_multiline var text: String = ""
## ID następnego noda gdy brak choices. Puste = koniec dialogu.
@export var next: String = ""
## Wypisywane sygnałem `event` zanim tekst/choices się pokażą.
@export var events: Array[String] = []
## Jeśli niepuste — dialogue czeka na choose() zamiast advance().
@export var choices: Array[DialogueChoice] = []
