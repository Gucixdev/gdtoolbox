@tool
class_name Ez9Panel
extends Ez9Control

## Statyczny panel — NinePatchRect z pass-through na input.
## Dodaj children jako content.

func _ready() -> void:
	super._ready()
	mouse_filter = MOUSE_FILTER_IGNORE
