@tool
class_name EzParallaxBg
extends Node2D

## Wielowarstwowe przewijane tło dla platformówek 2D (i topdown) — zamiast
## ręcznie stawiać Parallax2D + Sprite2D na każdą warstwę i osobno ustawiać
## scroll_scale/repeat_size, wypełniasz JEDNĄ tablicę `layers` (tekstura +
## prędkość przewijania, patrz EzParallaxLayerEntry.gd) w Inspektorze — node
## buduje Parallax2D/Sprite2D dzieci sam.
##
## Bazuje na Parallax2D (następca przestarzałego ParallaxBackground/
## ParallaxLayer w Godocie 4) — silnik i tak robi przewijanie poprawnie, to
## tylko wygodniejszy sposób ustawienia wielu warstw naraz.

@export var layers: Array[EzParallaxLayerEntry] = []:
	set(v):
		layers = v
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	for c in get_children():
		remove_child(c)
		c.queue_free()

	for entry in layers:
		if entry == null or entry.texture == null:
			continue
		var layer := Parallax2D.new()
		layer.scroll_scale = entry.scroll_scale
		if entry.mirror_horizontally:
			layer.repeat_size = Vector2(entry.texture.get_width(), 0.0)
			layer.repeat_times = 2
		add_child(layer)

		var sprite := Sprite2D.new()
		sprite.texture = entry.texture
		sprite.centered = false
		sprite.z_index = entry.z_index
		layer.add_child(sprite)
