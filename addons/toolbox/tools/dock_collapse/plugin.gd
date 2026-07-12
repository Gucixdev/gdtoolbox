@tool
extends EditorPlugin

# Wewnętrzne, nieudokumentowane node'y edytora (Godot 4.7 dock rework).
# Nazwy mogą się zmienić w przyszłych wersjach Godota — jeśli find_child()
# nic nie znajdzie, przyciski po prostu się nie pojawiają (bez crasha).
const LEFT_DOCK_NAMES := ["DockVSplitLeftL", "DockVSplitLeftR"]
const RIGHT_DOCK_NAMES := ["DockVSplitRightL", "DockVSplitRightR"]
const CENTER_NAME := "DockVSplitCenter"
const DockEdgeArrowScript := preload("res://addons/toolbox/tools/dock_collapse/dock_edge_arrow.gd")

# FileSystem pomijamy zawsze — bywa ręcznie przenoszony w różne miejsca
# i strukturalnie zostaje "dzieckiem" lewego/prawego splitu, przez co
# generyczny collapse łapał go tam gdzie użytkownik go nie oczekiwał.
const EXCLUDED_DOCK_NAMES := ["FileSystem"]

var _left_docks: Array = []
var _right_docks: Array = []
var _left_arrow: Control
var _right_arrow: Control

func _enter_tree() -> void:
	call_deferred("_setup_dock_collapse")

# Sprawdzone empirycznie w tej sesji (kilka podejść, po kolei):
# - Control.visible = false na kontenerze splitu -> Godot resetuje z powrotem.
# - DockSplitContainer.set_collapsed() -> rusza ~18px, nie realny collapse.
# - split_offsets ustawiane bezpośrednio -> silnik sam je przycina/nadpisuje.
# - symulacja przeciągnięcia myszką po splitterze -> też nie zadziałało.
# Jedyne co realnie działa i trzyma się: .close()/.open() na pojedynczych
# dockach (EditorDock, Godot 4.7) w środku danej kolumny. To zamyka zakładki
# jedna po drugiej, a nie zwija cały panel naraz — ale to jedyna sprawdzona,
# działająca opcja z pięciu wypróbowanych.
func _setup_dock_collapse() -> void:
	var base := EditorInterface.get_base_control()
	for n in LEFT_DOCK_NAMES:
		var found := base.find_child(n, true, false)
		if found:
			_collect_closable_docks(found, _left_docks)
	for n in RIGHT_DOCK_NAMES:
		var found := base.find_child(n, true, false)
		if found:
			_collect_closable_docks(found, _right_docks)
	var center := base.find_child(CENTER_NAME, true, false)
	if center == null or not center is Control:
		push_warning("dock_collapse: nie znaleziono " + CENTER_NAME + " — strzałki collapse pominięte")
		return

	print("[dock_collapse] docki po lewej: ", _left_docks.map(func(d): return String(d.name)))
	print("[dock_collapse] docki po prawej: ", _right_docks.map(func(d): return String(d.name)))

	# Oba przyciski robią to samo (zamykają/otwierają WSZYSTKIE zebrane docki
	# naraz, lewe i prawe razem) — stoją po obu stronach ekranu dla wygody,
	# nie po to żeby kontrolować osobno swoją stronę. Omija to całkowicie
	# problem z myleniem która strzałka rusza który dock.
	var all_docks: Array = _left_docks + _right_docks
	var shared_collapsed: Array = [false]

	if not all_docks.is_empty():
		_left_arrow = DockEdgeArrowScript.new()
		base.add_child(_left_arrow)
		_left_arrow.setup(all_docks, center, true, shared_collapsed)

		_right_arrow = DockEdgeArrowScript.new()
		base.add_child(_right_arrow)
		_right_arrow.setup(all_docks, center, false, shared_collapsed)

# Zbiera rekurencyjnie wszystkie docki mające .close()/.open() (EditorDock,
# Godot 4.7) wewnątrz danego node'a. Pomija node'y z nazwą zaczynającą się
# od "@" (anonimowe wrappery tworzone dla docków ze starego
# add_control_to_dock() — np. SettingsDock z godot_3d_cursor). Sprawdzone
# empirycznie: ich close() sypie błędem "Cannot open unknown dock", a nawet
# .visible bezpośrednio na wrapperze jest przechwytywane/ignorowane przez
# EditorDock (własny setter powiązany z systemem zakładek) — nie da się ich
# kontrolować żadnym znalezionym sposobem, więc pomijamy je całkowicie.
func _collect_closable_docks(n: Node, out: Array) -> void:
	if n.has_method("close") and n.has_method("open"):
		var nm := String(n.name)
		if not nm.begins_with("@") and not nm in EXCLUDED_DOCK_NAMES:
			out.append(n)
		return
	for c in n.get_children():
		_collect_closable_docks(c, out)

func _exit_tree() -> void:
	for d in _left_docks + _right_docks:
		if is_instance_valid(d):
			d.open()
	_left_docks.clear()
	_right_docks.clear()
	if _left_arrow:
		_left_arrow.queue_free()
		_left_arrow = null
	if _right_arrow:
		_right_arrow.queue_free()
		_right_arrow = null
