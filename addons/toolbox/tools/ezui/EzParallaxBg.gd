@tool
class_name EzParallaxBg
extends ParallaxBackground

## Wielowarstwowe przewijane tło dla platformówek 2D (i topdown) — zamiast
## ręcznie stawiać ParallaxLayer + Sprite2D na każdą warstwę i osobno ustawiać
## motion_scale/motion_mirroring, wypełniasz JEDNĄ tablicę `layers`
## (tekstura + prędkość przewijania, patrz EzParallaxLayerEntry.gd) w
## Inspektorze — node buduje ParallaxLayer/Sprite2D dzieci sam.
##
## Bazuje na wbudowanym w Godota ParallaxBackground/ParallaxLayer (nie własna
## implementacja przewijania za kamerą) — silnik i tak robi to poprawnie,
## to tylko wygodniejszy sposób ustawienia wielu warstw naraz.

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
		var layer := ParallaxLayer.new()
		layer.motion_scale = entry.scroll_scale
		if entry.mirror_horizontally:
			layer.motion_mirroring = Vector2(entry.texture.get_width(), 0.0)
		add_child(layer)

		var sprite := Sprite2D.new()
		sprite.texture = entry.texture
		sprite.centered = false
		sprite.z_index = entry.z_index
		layer.add_child(sprite)
