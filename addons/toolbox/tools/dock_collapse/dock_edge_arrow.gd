@tool
extends Button

## Mała, pusta strzałka przyklejona do krawędzi centralnego viewportu.
## Woła .close()/.open() na poszczególnych dockach (EditorDock, Godot 4.7).
## Oba przyciski (lewy/prawy) dzielą tę samą listę docków i ten sam stan
## collapsed (przekazywany jako jednoelementowa tablica — "box" — żeby
## kliknięcie jednego przycisku aktualizowało też drugi).

var target_docks: Array = []
var _center: Control
var _is_left: bool = true
var _shared_collapsed: Array = [false]

func setup(docks: Array, center: Control, is_left: bool, shared_collapsed: Array) -> void:
	target_docks = docks
	_center = center
	_is_left = is_left
	_shared_collapsed = shared_collapsed
	text = ""
	custom_minimum_size = Vector2(14, 48)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 200
	pressed.connect(_on_pressed)

func _process(_delta: float) -> void:
	if not is_instance_valid(_center):
		visible = false
		return
	visible = true
	var center_rect := _center.get_global_rect()
	var y := center_rect.position.y + center_rect.size.y * 0.5 - size.y * 0.5
	var x := center_rect.position.x - size.x if _is_left else center_rect.position.x + center_rect.size.x
	global_position = Vector2(x, y)

# UWAGA: która dokładnie zakładka staje się aktywna po ponownym otwarciu
# grupy nie jest kontrolowalna stąd — próby (kolejność wywołań, wymuszanie
# open() na wcześniej aktywnej) nie dały efektu. Zaakceptowana niedoskonałość.
func _on_pressed() -> void:
	var new_collapsed: bool = not _shared_collapsed[0]
	_shared_collapsed[0] = new_collapsed
	if new_collapsed:
		for d in target_docks:
			if is_instance_valid(d):
				d.close()
	else:
		var docks_reversed := target_docks.duplicate()
		docks_reversed.reverse()
		for d in docks_reversed:
			if is_instance_valid(d):
				d.open()
