@tool
class_name Ez9Bar
extends Ez9Control

## Pasek postępu. Fill używa TEJ SAMEJ tekstury co tło (self.texture) — jedna
## grafika wystarczy, fill_color/modulate odróżnia fill od tła kolorem (dawniej
## był osobny fill_texture/bar_fill.png, zbędne skoro to i tak ten sam kształt
## nine-patch). Fill renderuje zawsze w pełnym rozmiarze i jest przycinany
## przez clip container — brak zniekształceń NinePatch przy małych wartościach.

signal value_changed(v: float)

const _D_BG := "res://addons/toolbox/tools/ezui/assets/bar_bg.png"

@export_group("Fill")
@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		_refresh_fill()
		value_changed.emit(value)

@export var fill_color: Color = Color.WHITE:
	set(v): fill_color = v; _refresh_fill()

@export_enum("Left→Right", "Right→Left", "Bottom→Top", "Top→Bottom") var fill_direction: int = 0:
	set(v): fill_direction = v; _refresh_fill()

var _clip: Control
var _fill: NinePatchRect

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if not texture:
		texture = load(_D_BG) if ResourceLoader.exists(_D_BG) else Ez9Control._get_default_tex()
		patch_margin_left   = 10
		patch_margin_right  = 10
		patch_margin_top    = 10
		patch_margin_bottom = 10
	mouse_filter = MOUSE_FILTER_IGNORE
	_rebuild_fill()
	resized.connect(_refresh_fill)

func _rebuild_fill() -> void:
	if is_instance_valid(_clip):
		remove_child(_clip)
		_clip.queue_free()

	_clip = Control.new()
	_clip.name = "_clip"
	_clip.clip_contents = true
	_clip.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_clip, false, Node.INTERNAL_MODE_FRONT)

	_fill = NinePatchRect.new()
	_fill.name = "_fill"
	_fill.texture = texture
	_fill.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_fill.patch_margin_left   = patch_margin_left
	_fill.patch_margin_right  = patch_margin_right
	_fill.patch_margin_top    = patch_margin_top
	_fill.patch_margin_bottom = patch_margin_bottom
	_fill.mouse_filter = MOUSE_FILTER_IGNORE
	_clip.add_child(_fill)
	_refresh_fill()

func _refresh_fill() -> void:
	if not is_instance_valid(_clip) or not is_instance_valid(_fill): return
	_fill.modulate = fill_color

	var w := size.x
	var h := size.y
	if w == 0.0 or h == 0.0: return

	# _fill zawsze pełny rozmiar baru, _clip go przycina
	match fill_direction:
		0:  # Left→Right
			_clip.position = Vector2.ZERO
			_clip.size     = Vector2(w * value, h)
			_fill.position = Vector2.ZERO
			_fill.size     = Vector2(w, h)
		1:  # Right→Left
			var cw := w * value
			_clip.position = Vector2(w - cw, 0.0)
			_clip.size     = Vector2(cw, h)
			_fill.position = Vector2(-(w - cw), 0.0)
			_fill.size     = Vector2(w, h)
		2:  # Bottom→Top
			var ch := h * value
			_clip.position = Vector2(0.0, h - ch)
			_clip.size     = Vector2(w, ch)
			_fill.position = Vector2(0.0, -(h - ch))
			_fill.size     = Vector2(w, h)
		3:  # Top→Bottom
			_clip.position = Vector2.ZERO
			_clip.size     = Vector2(w, h * value)
			_fill.position = Vector2.ZERO
			_fill.size     = Vector2(w, h)
