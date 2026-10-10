## Preprocess — post-processing effects node.
##
## Drag onto Camera2D, WorldEnvironment, or any node in the scene.
## Effects apply as a full-screen CanvasLayer overlay — works with gl_compatibility renderer.
##
## Usage:
##   Add Preprocess as a child of any node (Camera2D recommended for 2D games).
##   Toggle effects and tweak values in the inspector. Changes apply at runtime immediately.
@tool
class_name Preprocess extends Node

@export_group("Vignette")
@export_range(0.0, 1.0, 0.01) var vignette_intensity: float = 0.0:
	set(v): vignette_intensity = v; _set_param("vignette_intensity", v)
@export_range(0.01, 1.0, 0.01) var vignette_softness: float = 0.45:
	set(v): vignette_softness = v; _set_param("vignette_softness", v)
@export var vignette_color: Color = Color.BLACK:
	set(v): vignette_color = v; _set_param("vignette_color", v)

@export_group("Chromatic Aberration")
@export_range(0.0, 0.02, 0.0005) var chromatic_amount: float = 0.0:
	set(v): chromatic_amount = v; _set_param("chromatic_amount", v)

@export_group("Film Grain")
@export_range(0.0, 1.0, 0.01) var grain_intensity: float = 0.0:
	set(v): grain_intensity = v; _set_param("grain_intensity", v)

@export_group("Scanlines")
@export_range(0.0, 1.0, 0.01) var scanlines_intensity: float = 0.0:
	set(v): scanlines_intensity = v; _set_param("scanlines_intensity", v)
@export_range(50.0, 800.0, 10.0) var scanlines_count: float = 300.0:
	set(v): scanlines_count = v; _set_param("scanlines_count", v)

@export_group("Color Grading")
@export_range(0.0, 3.0, 0.01) var brightness: float = 1.0:
	set(v): brightness = v; _set_param("brightness", v)
@export_range(0.0, 3.0, 0.01) var contrast: float = 1.0:
	set(v): contrast = v; _set_param("contrast", v)
@export_range(0.0, 3.0, 0.01) var saturation: float = 1.0:
	set(v): saturation = v; _set_param("saturation", v)

var _canvas_layer: CanvasLayer
var _rect: ColorRect
var _mat: ShaderMaterial
var _grain_timer: float = 0.0

func _ready() -> void:
	_build_overlay()
	_sync_all()

func _process(delta: float) -> void:
	if grain_intensity > 0.0 and _mat:
		_grain_timer += delta * 30.0
		_mat.set_shader_parameter("grain_time", _grain_timer)

func _build_overlay() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 126
	_canvas_layer.name = "PreprocessOverlay"
	add_child(_canvas_layer)

	_rect = ColorRect.new()
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_rect)

	var shader := load("res://addons/toolbox/tools/ezui/utils/preprocess.gdshader") as Shader
	if shader == null:
		push_warning("Preprocess: shader not found at res://addons/toolbox/tools/ezui/utils/preprocess.gdshader")
		return
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_rect.material = _mat

func _sync_all() -> void:
	_set_param("vignette_intensity", vignette_intensity)
	_set_param("vignette_softness", vignette_softness)
	_set_param("vignette_color", vignette_color)
	_set_param("chromatic_amount", chromatic_amount)
	_set_param("grain_intensity", grain_intensity)
	_set_param("scanlines_intensity", scanlines_intensity)
	_set_param("scanlines_count", scanlines_count)
	_set_param("brightness", brightness)
	_set_param("contrast", contrast)
	_set_param("saturation", saturation)

func _set_param(param: String, value: Variant) -> void:
	if _mat:
		_mat.set_shader_parameter(param, value)

func _exit_tree() -> void:
	if is_instance_valid(_canvas_layer):
		_canvas_layer.queue_free()
