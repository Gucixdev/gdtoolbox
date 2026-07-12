@tool
class_name EffectBounce
extends AnimEffect

enum Direction { IN, OUT }
@export var direction: Direction = Direction.IN
@export var height: float = 100.0

func apply(node: Node) -> Tween:
	var bounce_in := direction == Direction.IN

	if node is Control:
		var c := node as Control
		var o := c.position
		var tw := _tw(c, Tween.TRANS_BOUNCE, Tween.EASE_OUT if bounce_in else Tween.EASE_IN)
		if bounce_in:
			c.position = o + Vector2(0.0, -height)
			var prop := _curve(tw.tween_property(c, "position", o, duration))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var prop := _curve(tw.tween_property(c, "position", o + Vector2(0.0, -height), duration))
			if delay > 0.0: prop.set_delay(delay)
			tw.finished.connect(func(): if is_instance_valid(c): c.position = o)
		return tw

	if node is Node2D:
		var s := node as Node2D
		var o := s.position
		var tw := _tw(s, Tween.TRANS_BOUNCE, Tween.EASE_OUT if bounce_in else Tween.EASE_IN)
		if bounce_in:
			s.position = o + Vector2(0.0, -height)
			var prop := _curve(tw.tween_property(s, "position", o, duration))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var prop := _curve(tw.tween_property(s, "position", o + Vector2(0.0, -height), duration))
			if delay > 0.0: prop.set_delay(delay)
			tw.finished.connect(func(): if is_instance_valid(s): s.position = o)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var o := s.position
		var tw := _tw(s, Tween.TRANS_BOUNCE, Tween.EASE_OUT if bounce_in else Tween.EASE_IN)
		if bounce_in:
			s.position = o + Vector3(0.0, height * 0.01, 0.0)
			var prop := _curve(tw.tween_property(s, "position", o, duration))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var prop := _curve(tw.tween_property(s, "position", o + Vector3(0.0, height * 0.01, 0.0), duration))
			if delay > 0.0: prop.set_delay(delay)
			tw.finished.connect(func(): if is_instance_valid(s): s.position = o)
		return tw

	push_warning("EffectBounce: nieobsługiwany typ: " + node.get_class())
	return null
