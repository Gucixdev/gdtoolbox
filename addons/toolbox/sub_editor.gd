@tool
extends EditorPlugin

var _panel: Control

func has_main_screen() -> bool:
	return true

func get_plugin_name() -> String:
	return "SubEditor"

func get_plugin_icon() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.7, 1.0, 1.0))
	return ImageTexture.create_from_image(img)

func _enter_tree() -> void:
	_panel = _build_panel()
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_panel.hide()

func _exit_tree() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null

func make_visible(visible: bool) -> void:
	if is_instance_valid(_panel):
		if visible:
			_panel.show()
		else:
			_panel.hide()

func _build_panel() -> Control:
	var root := VBoxContainer.new()
	root.name = "SubEditorPanel"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.text = "SubEditor"
	title.add_theme_font_size_override("font_size", 14)
	root.add_child(title)

	root.add_child(HSeparator.new())

	var info := Label.new()
	info.text = "Uruchamia drugą instancję edytora Godot dla tego projektu.\nPrzydatne do podglądu scen 2D/3D podczas edycji kodu."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	root.add_child(info)

	root.add_child(HSeparator.new())

	var launch_btn := Button.new()
	launch_btn.text = "Otwórz nowy edytor (ten sam projekt)"
	launch_btn.pressed.connect(_launch_editor)
	root.add_child(launch_btn)

	var launch_scene_btn := Button.new()
	launch_scene_btn.text = "Otwórz aktywną scenę w nowym edytorze"
	launch_scene_btn.pressed.connect(_launch_editor_with_scene)
	root.add_child(launch_scene_btn)

	root.add_child(HSeparator.new())

	var note := Label.new()
	note.text = "Tip: drugi edytor ładuje się z tym samym projektem.\nZmiany w plikach są współdzielone (hot-reload)."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	note.add_theme_font_size_override("font_size", 11)
	root.add_child(note)

	return root

func _launch_editor() -> void:
	var project_path := ProjectSettings.globalize_path("res://")
	var godot_exe := OS.get_executable_path()
	var pid := OS.create_process(godot_exe, ["--editor", "--path", project_path])
	if pid > 0:
		print("[SubEditor] Uruchomiono edytor (PID: %d)" % pid)
	else:
		push_error("[SubEditor] Nie udało się uruchomić edytora")

func _launch_editor_with_scene() -> void:
	var project_path := ProjectSettings.globalize_path("res://")
	var godot_exe := OS.get_executable_path()
	var scene := EditorInterface.get_edited_scene_root()
	var args := ["--editor", "--path", project_path]
	if scene:
		var scene_path := scene.scene_file_path
		if scene_path != "":
			args.append(scene_path)
	var pid := OS.create_process(godot_exe, args)
	if pid > 0:
		print("[SubEditor] Uruchomiono edytor z sceną (PID: %d)" % pid)
	else:
		push_error("[SubEditor] Nie udało się uruchomić edytora")
