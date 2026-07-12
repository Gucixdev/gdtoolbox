@tool
class_name EffectFade
extends AnimEffect

enum Direction { IN, OUT }
@export var direction: Direction = Direction.IN

func apply(node: Node) -> Tween:
	var fade_in := direction == Direction.IN
	var ease_mode := Tween.EASE_OUT if fade_in else Tween.EASE_IN

	if node is Control or node is Node2D:
		var tw := _tw(node, Tween.TRANS_CUBIC, ease_mode)
		var prop := _curve(tw.tween_property(node, "modulate:a", 1.0 if fade_in else 0.0, duration))
		if fade_in: prop.from(0.0)
		if delay > 0.0: prop.set_delay(delay)
		return tw

	if node is VisualInstance3D:
		var tw := _tw(node, Tween.TRANS_CUBIC, ease_mode)
		if fade_in: (node as VisualInstance3D).transparency = 1.0
		var prop := _curve(tw.tween_property(node, "transparency", 0.0 if fade_in else 1.0, duration))
		if delay > 0.0: prop.set_delay(delay)
		return tw

	if node is Node3D:
		node.visible = fade_in
		return null

	push_warning("EffectFade: nieobsługiwany typ: " + node.get_class())
	return null
