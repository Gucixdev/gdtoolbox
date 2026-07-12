@tool
class_name Ez9Button
extends Ez9Control

## NinePatchRect + button. Domyślnie Breeze btn_normal/hover/pressed.
## Wstaw własne tekstury w States żeby podmienić.

signal pressed
signal hovered(is_hovered: bool)

const _D_NORMAL  := "res://addons/toolbox/tools/ezui/assets/btn_normal.svg"
const _D_HOVER   := "res://addons/toolbox/tools/ezui/assets/btn_hover.svg"
const _D_PRESSED := "res://addons/toolbox/tools/ezui/assets/btn_pressed.svg"

static var _def_n: Texture2D
static var _def_h: Texture2D
static var _def_p: Texture2D

@export_group("States")
@export var texture_normal: Texture2D:
	set(v): texture_normal = v; if is_node_ready(): _apply_state(current_state)
@export var texture_hover: Texture2D:
	set(v): texture_hover = v;  if is_node_ready(): _apply_state(current_state)
@export var texture_pressed: Texture2D:
	set(v): texture_pressed = v; if is_node_ready(): _apply_state(current_state)

var current_state: StringName = &"normal"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_load_defs()
	patch_margin_left   = 12
	patch_margin_right  = 12
	patch_margin_top    = 12
	patch_margin_bottom = 12
	mouse_filter = MOUSE_FILTER_STOP
	_apply_state(&"normal")
	if Engine.is_editor_hint(): return
	mouse_entered.connect(func(): _apply_state(&"hover");  hovered.emit(true))
	mouse_exited.connect( func(): _apply_state(&"normal"); hovered.emit(false))

func _gui_input(ev: InputEvent) -> void:
	if Engine.is_editor_hint(): return
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_apply_state(&"pressed")
		else:
			if current_state == &"pressed": pressed.emit()
			_apply_state(&"hover")

func _apply_state(state: StringName) -> void:
	current_state = state
	match state:
		&"normal":  texture = texture_normal  if texture_normal  else _def_n
		&"hover":   texture = texture_hover   if texture_hover   else (texture_normal if texture_normal else _def_h)
		&"pressed": texture = texture_pressed if texture_pressed else (texture_normal if texture_normal else _def_p)

static func _load_defs() -> void:
	if not _def_n:
		_def_n = load(_D_NORMAL)  if ResourceLoader.exists(_D_NORMAL)  else Ez9Control._get_default_tex()
	if not _def_h:
		_def_h = load(_D_HOVER)   if ResourceLoader.exists(_D_HOVER)   else _def_n
	if not _def_p:
		_def_p = load(_D_PRESSED) if ResourceLoader.exists(_D_PRESSED) else _def_n
