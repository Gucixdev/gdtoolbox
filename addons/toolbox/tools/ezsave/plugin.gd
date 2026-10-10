@tool
extends EditorPlugin

## Rejestruje autoload `Saves` (SaveSystem) — dostępny w grze jako Saves.save_game() itd.
const AUTOLOAD_NAME := "Saves"
const SCRIPT := "res://addons/toolbox/tools/ezsave/save_system.gd"

func _enter_tree() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, SCRIPT)

func _disable_plugin() -> void:
	if ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		remove_autoload_singleton(AUTOLOAD_NAME)
