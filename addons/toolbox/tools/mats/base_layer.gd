@tool
class_name BaseLayer
extends Resource

@export var enabled: bool = true:
	set(v): enabled = v; emit_changed()
