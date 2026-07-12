@tool
class_name EzParallaxBg
extends Node

## Generyczny parallax — działa i w 2D, i w 3D, bo sam nie tworzy żadnej
## geometrii/sprite'ów. Dodajesz WŁASNE dzieci (Sprite2D, MeshInstance3D,
## całe poddrzewa, cokolwiek) normalnie w edytorze, a w `layers` wskazujesz
## który child (przez EzParallaxLayerEntry.target) ma jak mocno (`shift`)
## reagować na ruch kamery. Node sam wykrywa aktywną kamerę (2D albo 3D,
## cokolwiek akurat jest w viewport) i przesuwa każdą warstwę względem jej
## pozycji STARTOWEJ — nie mieszaj warstw 2D i 3D pod jednym EzParallaxBg,
## bo kamera jest jedna na scenę.

@export var layers: Array[EzParallaxLayerEntry] = []

var _base_positions: Dictionary = {}  # Node -> pozycja startowa (Vector2 albo Vector3)
var _base_cam_pos = null  # typ dopasowuje się do pierwszej znalezionej kamery

func _ready() -> void:
	_base_positions.clear()
	_base_cam_pos = null
	for entry in layers:
		if entry == null:
			continue
		var node := get_node_or_null(entry.target)
		if node:
			_base_positions[node] = node.position

func _process(_delta: float) -> void:
	var cam_pos = _get_camera_position()
	if cam_pos == null:
		return
	if _base_cam_pos == null:
		_base_cam_pos = cam_pos
	var cam_delta = cam_pos - _base_cam_pos

	for entry in layers:
		if entry == null:
			continue
		var node := get_node_or_null(entry.target)
		if node == null or not _base_positions.has(node):
			continue
		node.position = _base_positions[node] + cam_delta * entry.shift

func _get_camera_position():
	var vp := get_viewport()
	if vp == null:
		return null
	var cam2d := vp.get_camera_2d()
	if cam2d:
		return cam2d.global_position
	var cam3d := vp.get_camera_3d()
	if cam3d:
		return cam3d.global_position
	return null
