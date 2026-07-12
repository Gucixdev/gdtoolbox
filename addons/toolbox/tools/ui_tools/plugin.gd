@tool
extends EditorPlugin

# Klasy auto-odkrywane przez Godot (class_name w plikach w tym katalogu):
#   RadialMenu, ProgressBar3D, CollapsibleContainer, UIAnim — widoczne w "Add Node" bez plugin
# Węzły inspector-first (dodajesz do drzewa, konfigurujesz parametry):
#   juicee (JuiceePlayer + JuiceeSequence), gremlins_toolbox (2D/3D/UI komponenty)
# Osobne (za duże):
#   menusystem (C#)

var _sub_plugins: Array = []
var _collapsible_inspector: EditorInspectorPlugin

func _enter_tree() -> void:
	_add_sub("toolbox/tools/ui_tools/tnowe_extra_controls/tnowe_extra_controls.gd")
	_collapsible_inspector = load("res://addons/toolbox/tools/ui_tools/collapsible_elements/collapsible_container_inspector_plugin.gd").new()
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
		push_warning("ui_tools: failed to load sub-plugin: " + path)
		return
	var plugin = script.new()
	add_child(plugin)
	_sub_plugins.append(plugin)
