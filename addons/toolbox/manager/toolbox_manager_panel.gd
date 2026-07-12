@tool
extends EditorDock

# Dock z listą wszystkich toolów wykrytych przez toolbox/plugin.gd w tools/ —
# jeden checkbox na tool. Lista jest odświeżana przez wołający kod (plugin.gd)
# po każdym rescanie (nowy/usunięty folder) i po każdym toggle.
#
# extends EditorDock (nie PanelContainer/add_control_to_dock) celowo — tylko
# prawdziwe EditorDock node'y mają działające .close()/.open(), więc tylko
# one łapią się w toolbox/plugin.gd::_collect_closable_docks() i reagują na
# strzałki collapse z dock_collapse/. Control dodany przez add_control_to_dock()
# ląduje w anonimowym wrapperze ("@...") którego nie da się zwinąć (patrz
# komentarz przy _collect_closable_docks w plugin.gd).

signal tool_toggled(tool_name: String, enabled: bool)

var _list: VBoxContainer

func _init() -> void:
	name = "Toolbox"
	title = "Toolbox"
	closable = true
	# Bez tego dock ląduje z default_slot=-1 (DOCK_SLOT_NONE) i nie wpada w żaden
	# z kontenerów DockVSplit* skanowanych przez dock_collapse — strzałki go
	# ignorują. InstanceDock (który już się łapie) ma ten sam slot ustawiony
	# w swojej .tscn (default_slot=3).
	default_slot = EditorDock.DOCK_SLOT_LEFT_BR
	custom_minimum_size = Vector2(200, 0)

	var root := VBoxContainer.new()
	add_child(root)

	var title_label := Label.new()
	title_label.text = "Toolbox — aktywne narzędzia"
	root.add_child(title_label)
	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

func refresh(tools: Dictionary) -> void:
	for c in _list.get_children():
		c.queue_free()

	var names := tools.keys()
	names.sort()
	for tool_name in names:
		var info: Dictionary = tools[tool_name]
		var cb := CheckBox.new()
		cb.text = "%s (%s)" % [info.get("display_name", tool_name), tool_name]
		cb.button_pressed = info.get("instance") != null
		cb.toggled.connect(_on_checkbox_toggled.bind(tool_name))
		_list.add_child(cb)

func _on_checkbox_toggled(pressed: bool, tool_name: String) -> void:
	tool_toggled.emit(tool_name, pressed)
