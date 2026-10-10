@tool
class_name DialogueGraph
extends Resource

## Jeden plik Resource = jedna rozmowa (npc/entity). Zbiór DialogueNode + start_node.

@export var start_node: String = "start"
@export var nodes: Array[DialogueNode] = []

func get_node_by_id(id: String) -> DialogueNode:
	for n in nodes:
		if n != null and n.id == id:
			return n
	return null
