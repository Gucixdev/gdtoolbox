@tool
class_name EzBaseLayer
extends Resource

@export var enabled: bool = true:
	set(v): enabled = v; emit_changed()
