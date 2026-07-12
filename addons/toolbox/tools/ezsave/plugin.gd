@tool
extends EditorPlugin

const AUTOLOAD_NAME := "SaveSystem"

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/toolbox/tools/ezsave/save_system.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
