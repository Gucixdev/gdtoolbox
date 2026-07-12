@tool
extends EditorPlugin

# UWAGA / WARNING: sub-pluginy które wołają add_control_to_dock() razem z sub-pluginami
# wołającymi add_node_3d_gizmo_plugin() pod tym samym meta-loaderem powodują SIGSEGV
# (patrz addons/editor_tools/plugin.gd). Zanim włączysz nowy tool z konfigu / wrzucisz
# nowy folder do tools/, sprawdź czy nie łączy obu API naraz z czymś już włączonym.
# Znane bezpieczne (tylko add_inspector_plugin): inspector_tabs, mesh_inspector.

const TOOLS_DIR := "res://addons/toolbox/tools/"
const CONFIG_PATH := "res://addons/toolbox/tools_config.cfg"
const RESCAN_INTERVAL := 3.0
const ManagerPanelScript := preload("res://addons/toolbox/manager/toolbox_manager_panel.gd")

# folder_name -> { cfg_path: String, display_name: String, instance: Node }
var _tools: Dictionary = {}
var _config := ConfigFile.new()
var _rescan_timer: Timer
var _manager_panel: Control

func _enter_tree() -> void:
	_config.load(CONFIG_PATH) # brak pliku = OK, po prostu wszystko domyślnie enabled
	_setup_manager_panel()
	_rescan_tools()

	_rescan_timer = Timer.new()
	_rescan_timer.wait_time = RESCAN_INTERVAL
	_rescan_timer.autostart = true
	add_child(_rescan_timer)
	_rescan_timer.timeout.connect(_rescan_tools)

func _setup_manager_panel() -> void:
	_manager_panel = ManagerPanelScript.new()
	_manager_panel.tool_toggled.connect(_on_tool_toggled)
	add_dock(_manager_panel)

func _on_tool_toggled(tool_name: String, enabled: bool) -> void:
	set_tool_enabled(tool_name, enabled)

func is_tool_enabled(tool_name: String) -> bool:
	return _config.get_value("tools", tool_name, true)

func set_tool_enabled(tool_name: String, enabled: bool) -> void:
	if not _tools.has(tool_name):
		return
	_config.set_value("tools", tool_name, enabled)
	_config.save(CONFIG_PATH)
	var info: Dictionary = _tools[tool_name]
	if enabled and info.instance == null:
		_load_tool_instance(tool_name)
	elif not enabled and info.instance != null:
		_unload_tool_instance(tool_name)
	if _manager_panel:
		_manager_panel.refresh(_tools)

# Skanuje TOOLS_DIR na bieżąco (wołane od razu i co RESCAN_INTERVAL sekund) —
# nowy folder z plugin.cfg wskoczy do configu i (jeśli enabled) załaduje się
# bez restartu edytora; usunięty folder odładowuje się i znika z configu.
func _rescan_tools() -> void:
	var found := _scan_tool_folders()
	var changed := false

	var names := found.keys()
	names.sort()
	for tool_name in names:
		if _tools.has(tool_name):
			continue
		var cfg_path: String = found[tool_name]
		var cfg := ConfigFile.new()
		var display_name: String = tool_name
		if cfg.load(cfg_path) == OK:
			display_name = cfg.get_value("plugin", "name", tool_name)
		_tools[tool_name] = {
			"cfg_path": cfg_path,
			"display_name": display_name,
			"instance": null,
		}
		changed = true
		print("[toolbox] wykryto nowy tool: %s" % tool_name)
		# Zapisz aktualny stan (domyślnie enabled=true) do configu od razu,
		# żeby plik na bieżąco odzwierciedlał realną listę pluginów w tools/.
		var enabled := is_tool_enabled(tool_name)
		_config.set_value("tools", tool_name, enabled)
		if enabled:
			_load_tool_instance(tool_name)

	for tool_name in _tools.keys().duplicate():
		if not found.has(tool_name):
			print("[toolbox] tool zniknął z dysku: %s" % tool_name)
			_unload_tool_instance(tool_name)
			_tools.erase(tool_name)
			if _config.has_section_key("tools", tool_name):
				_config.erase_section_key("tools", tool_name)
			changed = true

	if changed:
		_config.save(CONFIG_PATH)
		if _manager_panel:
			_manager_panel.refresh(_tools)

func _scan_tool_folders() -> Dictionary:
	var found := {}
	var dir := DirAccess.open(TOOLS_DIR)
	if dir == null:
		push_warning("toolbox: nie można otworzyć " + TOOLS_DIR)
		return found
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if dir.current_is_dir() and not f.begins_with("."):
			var cfg_path := TOOLS_DIR + f + "/plugin.cfg"
			if FileAccess.file_exists(cfg_path):
				found[f] = cfg_path
		f = dir.get_next()
	dir.list_dir_end()
	return found

func _load_tool_instance(tool_name: String) -> void:
	var info: Dictionary = _tools[tool_name]
	if info.instance != null:
		return
	var cfg := ConfigFile.new()
	if cfg.load(info.cfg_path) != OK:
		push_warning("toolbox: nie udało się wczytać " + info.cfg_path)
		return
	var script_rel: String = cfg.get_value("plugin", "script", "")
	if script_rel == "":
		push_warning("toolbox: brak [plugin] script= w " + info.cfg_path)
		return
	var folder_path: String = String(info.cfg_path).get_base_dir() + "/"
	var script := load(folder_path + script_rel)
	if script == null:
		push_warning("toolbox: nie udało się załadować skryptu dla " + info.cfg_path)
		return
	var instance = script.new()
	add_child(instance)
	info.instance = instance
	print("[toolbox] auto-loaded: %s (%s)" % [info.display_name, info.cfg_path])

func _unload_tool_instance(tool_name: String) -> void:
	var info: Dictionary = _tools[tool_name]
	if info.instance == null:
		return
	if info.instance.is_inside_tree():
		remove_child(info.instance)
	info.instance.free()
	info.instance = null

func _enable_plugin() -> void:
	for tool_name in _tools:
		var instance = _tools[tool_name].instance
		if instance and instance.has_method("_enable_plugin"):
			instance._enable_plugin()

func _disable_plugin() -> void:
	for tool_name in _tools:
		var instance = _tools[tool_name].instance
		if instance and instance.has_method("_disable_plugin"):
			instance._disable_plugin()

func _exit_tree() -> void:
	if _rescan_timer:
		_rescan_timer.queue_free()
		_rescan_timer = null
	if _manager_panel:
		remove_dock(_manager_panel)
		_manager_panel.queue_free()
		_manager_panel = null
	for tool_name in _tools.keys().duplicate():
		_unload_tool_instance(tool_name)
	_tools.clear()
