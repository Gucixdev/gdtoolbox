@tool
class_name EffectGlitch
extends AnimEffect

## Shader glitch: scanline displacement + RGB chromatic aberration.
## Control → ColorRect overlay z hint_screen_texture.
## Sprite2D / TextureRect → material na nodzie z UV-based shader.

const _SHADER_OVERLAY := preload("glitch_overlay.gdshader")
const _SHADER_SPRITE  := preload("glitch_sprite.gdshader")

@export_range(0.0, 1.0) var intensity: float = 0.35
@export_range(0.0, 0.05) var chroma_strength: float = 0.012
@export_range(4, 64) var strip_count: int = 20

func apply(node: Node) -> Tween:
	if node is Control:
		return _apply_overlay(node as Control)
	if node is Sprite2D or node is TextureRect or node is AnimatedSprite2D:
		return _apply_sprite(node as CanvasItem)
	push_warning("EffectGlitch: wymaga Control lub Sprite2D/TextureRect, nie: " + node.get_class())
	return null

func _make_mat(shader: Shader) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("chroma_strength", chroma_strength)
	mat.set_shader_parameter("strip_count", strip_count)
	return mat

func _drive(mat: ShaderMaterial, node: Node) -> Tween:
	var tw := _tw(node, Tween.TRANS_LINEAR)
	if delay > 0.0: tw.tween_interval(delay)
	tw.tween_method(func(t: float):
		if is_instance_valid(mat): mat.set_shader_parameter("time_val", t)
	, 0.0, 1.0, duration)
	return tw

func _apply_overlay(c: Control) -> Tween:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.color = Color(0, 0, 0, 0)  # transparent base — shader wypełnia piksele
	var mat := _make_mat(_SHADER_OVERLAY)
	overlay.material = mat
	c.add_child(overlay)
	var tw := _drive(mat, c)
	tw.finished.connect(func(): if is_instance_valid(overlay): overlay.queue_free())
	return tw

func _apply_sprite(ci: CanvasItem) -> Tween:
	var old_mat := ci.material
	var mat := _make_mat(_SHADER_SPRITE)
	ci.material = mat
	var tw := _drive(mat, ci)
	tw.finished.connect(func(): if is_instance_valid(ci): ci.material = old_mat)
	return tw
