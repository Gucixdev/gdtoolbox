class_name SaveSystem
extends Node

## Zapis gry jak w Skyrim / Wiedźminie. Autoload `Saves` (rejestruje go plugin),
## zero setupu w scenach.
##
## Co zapisać — dwa sposoby:
##   • w edytorze: dodaj node do grupy "save" i ustaw w Inspektorze
##     Metadata `save_props` (PackedStringArray: "position", "hp"…)
##   • z kodu:     Saves.track($Player, ["position", "hp"])
##   • dane bez node'a (flagi questów itd.): Saves.globals["quest_wolf"] = 2
##
## Sloty:
##   Saves.save_game()            # nowy ręczny slot (manual_1, manual_2…)
##   Saves.save_game(&"manual_3") # konkretny slot
##   Saves.quicksave() / quickload()   # F5 / F9 (akcje tworzone same)
##   Saves.autosave()             # rotacja auto_1..auto_N, najstarszy nadpisany
##   Saves.load_latest()          # przycisk "Continue"
##   Saves.list_saves()           # dla menu: slot, label, time, playtime, scene, thumbnail
##
## Pliki: user://saves/<slot>.sav (+ .bak poprzedniej wersji, + .jpg miniatura).
## Zapis idzie na wątku (autosave nie przycina gry), jest atomowy i ma kopię
## .bak — uszkodzony plik nie kasuje ostatniego dobrego stanu.

signal saved(slot: StringName)
signal autosaved(slot: StringName)
signal loaded(slot: StringName)
signal load_failed(slot: StringName)

const SAVE_DIR := "user://saves/"
const EXT := ".sav"
const FORMAT_VERSION := 1

@export_group("Autosave")
## Autozapis co N minut (0 = wyłączony).
@export_range(0.0, 120.0, 0.5, "suffix:min") var autosave_every_minutes: float = 5.0
@export var autosave_on_scene_change: bool = true
@export var autosave_on_exit: bool = true
@export_range(1, 20) var max_autosaves: int = 3
@export_group("Quick")
@export var quicksave_action: StringName = &"quicksave"
@export var quickload_action: StringName = &"quickload"
@export_group("Misc")
## Wczytaj ostatni zapis zaraz po starcie gry.
@export var load_latest_on_start: bool = false
@export var thumbnail_width: int = 256
## Wpisywane do metadanych — przydatne przy migracji zapisów.
@export var game_version: String = "1.0"

## Dane gry bez node'a (flagi, ekwipunek jako Dictionary…). Zapisywane w całości.
var globals: Dictionary = {}
## Czas gry w sekundach — liczony i przywracany automatycznie.
var playtime: float = 0.0
## Ustaw true w cutscenkach/walce/menu, żeby zablokować zapis (jak w Skyrim).
var save_blocked: bool = false

var _providers: Dictionary = {}   # key -> [Callable get, Callable set]
var _autosave_timer := 0.0
var _last_scene: Node
var _scene_cooldown := 0.0
var _writing: Dictionary = {}   # slot -> task id (zapisy w toku)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.is_editor_hint(): return
	_ensure_action(quicksave_action, KEY_F5)
	_ensure_action(quickload_action, KEY_F9)
	get_tree().auto_accept_quit = not autosave_on_exit
	if load_latest_on_start and has_any_save():
		load_latest.call_deferred()

func _process(delta: float) -> void:
	if get_tree().paused: return
	playtime += delta
	_scene_cooldown = maxf(_scene_cooldown - delta, 0.0)
	if autosave_every_minutes > 0.0:
		_autosave_timer += delta
		if _autosave_timer >= autosave_every_minutes * 60.0:
			autosave()
	var cur := get_tree().current_scene
	if cur != _last_scene:
		var first := _last_scene == null
		_last_scene = cur
		if autosave_on_scene_change and not first and _scene_cooldown <= 0.0:
			_scene_cooldown = 5.0
			autosave.call_deferred()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed(quicksave_action):
		quicksave()
	elif ev.is_action_pressed(quickload_action):
		quickload()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and autosave_on_exit and not Engine.is_editor_hint():
		_write_slot(_next_autosave_slot(), "auto", "", true)
		get_tree().quit()

# ── zapis ────────────────────────────────────────────────────────────────────

func save_game(slot: StringName = &"", label: String = "") -> StringName:
	if slot == &"":
		slot = _next_manual_slot()
	return _write_slot(slot, "quick" if slot == &"quick" else ("auto" if String(slot).begins_with("auto_") else "manual"), label, false)

func quicksave() -> StringName:
	return _write_slot(&"quick", "quick", "Quicksave", false)

func autosave() -> StringName:
	_autosave_timer = 0.0
	var s := _write_slot(_next_autosave_slot(), "auto", "Autosave", false)
	if s != &"": autosaved.emit(s)
	return s

## Rejestruje node do zapisu z kodu (zamiast ręcznego grupowania w edytorze).
func track(node: Node, props: PackedStringArray) -> void:
	node.add_to_group(&"save")
	node.set_meta(&"save_props", props)

## Dane spoza drzewa sceny. Przykład: DialogueSystem rejestruje swoje flagi.
func register_provider(key: String, getter: Callable, setter: Callable) -> void:
	_providers[key] = [getter, setter]

# ── odczyt ───────────────────────────────────────────────────────────────────

func load_game(slot: StringName) -> bool:
	var file := _read(slot)
	if file.is_empty():
		load_failed.emit(slot)
		return false
	var meta: Dictionary = file.get("meta", {})
	playtime = float(meta.get("playtime", 0.0))
	globals = file.get("globals", {})
	for key in file.get("providers", {}):
		if _providers.has(key):
			(_providers[key][1] as Callable).call(file["providers"][key])
	var scene: String = meta.get("scene", "")
	if scene != "" and get_tree().current_scene != null and get_tree().current_scene.scene_file_path != scene:
		get_tree().change_scene_to_file(scene)
		await get_tree().process_frame
		await get_tree().process_frame
	_apply_nodes(file.get("nodes", {}))
	loaded.emit(slot)
	return true

func quickload() -> bool:
	return await load_game(&"quick")

## "Continue" — wczytuje najnowszy zapis (ręczny, quick albo auto).
func load_latest() -> bool:
	var l := list_saves()
	return false if l.is_empty() else await load_game(l[0]["slot"])

# ── zarządzanie ──────────────────────────────────────────────────────────────

func has_any_save() -> bool:
	return not list_saves().is_empty()

func has_save(slot: StringName) -> bool:
	return FileAccess.file_exists(_path(slot)) or FileAccess.file_exists(_path(slot) + ".bak")

func delete_save(slot: StringName) -> void:
	for p in [_path(slot), _path(slot) + ".bak", _thumb_path(slot)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

## Metadane wszystkich zapisów, najnowsze pierwsze:
## {slot, kind, label, time, playtime, scene, game_version, thumbnail}
func list_saves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null: return out
	for f in dir.get_files():
		if not f.ends_with(EXT): continue
		var slot := StringName(f.trim_suffix(EXT))
		var file := _read(slot)
		if file.is_empty(): continue
		var m: Dictionary = (file.get("meta", {}) as Dictionary).duplicate()
		m["slot"] = slot
		m["thumbnail"] = _thumb_path(slot) if FileAccess.file_exists(_thumb_path(slot)) else ""
		out.append(m)
	out.sort_custom(func(a, b): return a.get("time", 0) > b.get("time", 0))
	return out

# ── internals ────────────────────────────────────────────────────────────────

static func _path(slot: StringName) -> String:
	return SAVE_DIR + String(slot) + EXT

static func _thumb_path(slot: StringName) -> String:
	return SAVE_DIR + String(slot) + ".jpg"

func _next_manual_slot() -> StringName:
	var n := 1
	while FileAccess.file_exists(_path(StringName("manual_%d" % n))):
		n += 1
	return StringName("manual_%d" % n)

func _next_autosave_slot() -> StringName:
	# pierwszy wolny, a gdy wszystkie zajęte — najstarszy
	var oldest := &"auto_1"
	var oldest_t := INF
	for i in range(1, max_autosaves + 1):
		var s := StringName("auto_%d" % i)
		if _writing.has(s):
			continue
		if not FileAccess.file_exists(_path(s)):
			return s
		var t := FileAccess.get_modified_time(_path(s))
		if t < oldest_t:
			oldest_t = t
			oldest = s
	return oldest

func _snapshot_nodes() -> Dictionary:
	var out := {}
	for n in get_tree().get_nodes_in_group(&"save"):
		var props: PackedStringArray = n.get_meta(&"save_props", PackedStringArray())
		var d := {}
		for p in props:
			d[p] = n.get(p)
		if not d.is_empty():
			out[str(n.get_path())] = d
	return out

func _apply_nodes(nodes: Dictionary) -> void:
	for path in nodes:
		var n := get_node_or_null(NodePath(path))
		if n == null: continue
		for p in nodes[path]:
			n.set(p, nodes[path][p])

func _write_slot(slot: StringName, kind: String, label: String, sync: bool) -> StringName:
	if save_blocked or Engine.is_editor_hint():
		return &""
	if _writing.has(slot):
		push_warning("SaveSystem: slot '%s' jest właśnie zapisywany" % slot)
		return &""
	var providers := {}
	for key in _providers:
		providers[key] = (_providers[key][0] as Callable).call()
	var scene := get_tree().current_scene
	var meta := {
		"kind": kind,
		"label": label if label != "" else String(slot),
		"time": Time.get_unix_time_from_system(),
		"playtime": playtime,
		"scene": scene.scene_file_path if scene else "",
		"game_version": game_version,
	}
	var file := {"v": FORMAT_VERSION, "meta": meta, "globals": globals.duplicate(true),
		"providers": providers, "nodes": _snapshot_nodes()}
	var thumb: Image = null
	var tex := get_viewport().get_texture()
	if tex != null and DisplayServer.get_name() != "headless":
		thumb = tex.get_image()
		if thumb != null and thumb.get_width() > 0:
			thumb.resize(thumbnail_width, int(thumbnail_width * thumb.get_height() / float(thumb.get_width())))
	if sync:
		var ok := _write_file(slot, file, thumb)
		if ok: saved.emit(slot)
		return slot if ok else &""
	_writing[slot] = -1
	var task := WorkerThreadPool.add_task(func():
		var ok := _write_file(slot, file, thumb)
		_on_written.call_deferred(slot, ok))
	_writing[slot] = task
	return slot

func _on_written(slot: StringName, ok: bool) -> void:
	var task: int = _writing.get(slot, -1)
	if task >= 0:
		WorkerThreadPool.wait_for_task_completion(task)
	_writing.erase(slot)
	if ok:
		saved.emit(slot)
	else:
		push_error("SaveSystem: zapis slotu '%s' nie powiódł się" % slot)

static func _write_file(slot: StringName, file: Dictionary, thumb: Image) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var final_path := _path(slot)
	var tmp := final_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: nie mogę otworzyć %s (%s)" % [tmp, error_string(FileAccess.get_open_error())])
		return false
	f.store_var(file)
	f.close()
	if FileAccess.file_exists(final_path):
		DirAccess.rename_absolute(final_path, final_path + ".bak")
	if DirAccess.rename_absolute(tmp, final_path) != OK:
		return false
	if thumb != null:
		thumb.save_jpg(_thumb_path(slot), 0.85)
	return true

static func _read(slot: StringName) -> Dictionary:
	for p in [_path(slot), _path(slot) + ".bak"]:
		if not FileAccess.file_exists(p): continue
		var f := FileAccess.open(p, FileAccess.READ)
		if f == null: continue
		var v = f.get_var()   # allow_objects=false — bezpieczne dla cudzych plików
		if v is Dictionary and (v as Dictionary).has("meta"):
			return v
	return {}

static func _ensure_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action): return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
