@tool
class_name DialogueChoice
extends Resource

## Jedna opcja wyboru w DialogueNode.

@export var text: String = ""
## ID noda docelowego (patrz DialogueGraph.get_node_by_id). Puste = koniec dialogu.
@export var next: String = ""
## Warunki dostępności: {flag_key: expected_value}, sprawdzane przez DialogueBus.get_flag().
@export var requires: Dictionary = {}
