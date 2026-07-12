@tool
class_name EzHealthBar3D
extends Node3D

## Pasek HP w przestrzeni 3D (np. nad głową wroga/NPC) — dwa płaskie quady
## (tło + fill). Billboard robiony przez kopiowanie bazy transformu aktywnej
## kamery na CAŁY ten Node3D (nie przez material billboard_mode osobno na
## każdym quadzie) — dzięki temu tło i fill mają IDENTYCZNĄ rotację i nigdy
## się nie rozjadą przy patrzeniu pod kątem.
##
## Ustaw `value` (0..1) z kodu, np. `healthbar.value = health / max_health`.

@export var bar_width: float = 0.8
@export var bar_height: float = 0.1
@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		_refresh()

@export var color_full: Color = Color(0.2, 0.85, 0.25)
@export var color_empty: Color = Color(0.85, 0.15, 0.15)
@export var bg_color: Color = Color(0.05, 0.05, 0.05, 0.85)

var _bg: MeshInstance3D
var _fill: MeshInstance3D
var _fill_mat: StandardMaterial3D

func _ready() -> void:
	_build()
	_refresh()

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam:
		global_transform.basis = cam.global_transform.basis

func _build() -> void:
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(bar_width, bar_height)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = bg_color
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.no_depth_test = true
	_bg = MeshInstance3D.new()
	_bg.mesh = bg_mesh
	_bg.material_override = bg_mat
	add_child(_bg)

	_fill_mat = StandardMaterial3D.new()
	_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fill_mat.no_depth_test = true
	_fill = MeshInstance3D.new()
	_fill.mesh = QuadMesh.new()
	_fill.material_override = _fill_mat
	# lekko przed tłem na lokalnym Z, żeby nie z-fightowało
	_fill.position = Vector3(0, 0, 0.001)
	add_child(_fill)

func _refresh() -> void:
	if _fill == null:
		return
	var fw: float = bar_width * value
	var fill_mesh := _fill.mesh as QuadMesh
	fill_mesh.size = Vector2(maxf(fw, 0.001), bar_height * 0.7)
	# fill rośnie od lewej krawędzi tła, nie od środka
	_fill.position.x = -(bar_width - fw) * 0.5
	_fill_mat.albedo_color = color_empty.lerp(color_full, value)
	visible = value > 0.0
