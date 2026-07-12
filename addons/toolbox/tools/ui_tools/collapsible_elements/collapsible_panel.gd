@tool
@icon("res://addons/toolbox/tools/ui_tools/collapsible_elements/collapsible_container.svg")
class_name CollapsiblePanel
extends CollapsibleContainer

## Uproszczona wersja CollapsibleContainer.
##
## Użycie:
##   1. Dodaj CollapsiblePanel do sceny.
##   2. Dodaj dowolny Control node jako dziecko (np. VBoxContainer).
##   3. Podłącz przycisk: button.pressed.connect(panel.toggle_tween).
##
## Pierwsze dziecko Control jest automatycznie wykrywane jako sizing_node.
## Nie trzeba niczego konfigurować w inspektorze.

@export_group("CollapsiblePanel")
## Automatycznie wykryj pierwsze dziecko Control jako sizing_node.
@export var auto_detect_child: bool = true

func _ready() -> void:
	if auto_detect_child and sizing_node == NodePath(""):
		for child in get_children():
			if child is Control:
				sizing_node = get_path_to(child)
				break
	super._ready()
