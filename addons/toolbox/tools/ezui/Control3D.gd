@tool
@icon("res://addons/toolbox/tools/ezui/assets/progress_bar_3d.svg")
class_name Control3D
extends Node3D

## Wstawia dowolny Control (ProgressBar, Label, cały HUD...) do świata 3D.
## Dziecko Control3D to zwykły Control — po starcie gry jest przenoszone do
## wewnętrznego SubViewport, którego tekstura wisi na billboardzie w 3D.
##
##   Control3D
##   └── ProgressBar               <- pasek HP nad głową wroga
##
##   $Control3D.content.value = hp / max_hp
##
## UWAGA: po starcie dzieci Control są pod wewnętrznym viewportem, więc
## `$Control3D/Bar` przestaje działać — użyj `content` (pierwszy Control)
## albo `viewport.get_node("Bar")`.

## Rozdzielczość wewnętrznego viewportu w pikselach.
@export var viewport_size := Vector2i(256, 32):
	set(v):
		viewport_size = Vector2i(maxi(v.x, 1), maxi(v.y, 1))
		_sync()
## Rozmiar jednego piksela w jednostkach świata (rozmiar w 3D = viewport_size * pixel_size).
@export var pixel_size := 0.004:
	set(v):
		pixel_size = v
		_sync()
@export var billboard := true:
	set(v):
		billboard = v
		_sync()
## Rysuje na wierzchu (bez testu głębi), np. pasek widoczny przez ściany.
@export var on_top := false:
	set(v):
		on_top = v
		_sync()
## Rozciąga każde dziecko Control na cały viewport.
@export var fit_children := true

var viewport: SubViewport
var content: Control

var _sprite: Sprite3D

func _ready() -> void:
	if Engine.is_editor_hint():
		return  # w edytorze dzieci zostają w drzewie — nie psujemy zapisu sceny
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport, false, Node.INTERNAL_MODE_FRONT)
	_sprite = Sprite3D.new()
	_sprite.shaded = false
	_sprite.double_sided = true
	_sprite.texture = viewport.get_texture()
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	add_child(_sprite, false, Node.INTERNAL_MODE_FRONT)
	_sync()
	for c in get_children():
		_adopt(c)
	child_entered_tree.connect(func(c: Node): _adopt.call_deferred(c))

func _adopt(c: Node) -> void:
	if not is_instance_valid(c) or c.get_parent() != self or not c is CanvasItem:
		return
	c.reparent(viewport, false)
	if c is Control:
		if fit_children:
			(c as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if content == null:
			content = c

func _sync() -> void:
	if viewport == null:
		return
	viewport.size = viewport_size
	_sprite.pixel_size = pixel_size
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	_sprite.no_depth_test = on_top
	_sprite.render_priority = 1 if on_top else 0
