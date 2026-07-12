@tool
extends EditorPlugin

const AUTOLOAD_NAME := "DialogueBus"

func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/toolbox/tools/ezdialogue/DialogueBus.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
