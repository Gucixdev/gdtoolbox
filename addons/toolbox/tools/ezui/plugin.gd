@tool
extends EditorPlugin

# Klasy auto-odkrywane przez Godot (class_name w plikach w tym katalogu):
#   Control3D, UIDynamics, RadialMenu,
#   CollapsibleContainer, EzParallax, EzEquipment — widoczne w
#   "Add Node" bez żadnej rejestracji tutaj.
# Sub-pluginy (potrzebują EditorPlugin lifecycle, więc doczepione jako dzieci):
#   tnowe_extra_controls, collapsible inspector plugin.

var _sub_plugins: Array = []
var _collapsible_inspector: EditorInspectorPlugin

func _enter_tree() -> void:
	_add_sub("toolbox/tools/ezui/utils/tnowe_extra_controls.gd")
	_collapsible_inspector = load("res://addons/toolbox/tools/ezui/utils/collapsible_container_inspector_plugin.gd").new()
	add_inspector_plugin(_collapsible_inspector)

func _enable_plugin() -> void:
	for p in _sub_plugins:
		if p.has_method("_enable_plugin"):
			p._enable_plugin()

func _disable_plugin() -> void:
	for p in _sub_plugins:
		if p.has_method("_disable_plugin"):
			p._disable_plugin()

func _exit_tree() -> void:
	remove_inspector_plugin(_collapsible_inspector)
	for p in _sub_plugins:
		if p.is_inside_tree():
			remove_child(p)
		p.free()
	_sub_plugins.clear()

func _add_sub(path: String) -> void:
	var script = load("res://addons/" + path)
	if script == null:
		push_warning("ezui: failed to load sub-plugin: " + path)
		return
	var plugin = script.new()
	add_child(plugin)
	_sub_plugins.append(plugin)
