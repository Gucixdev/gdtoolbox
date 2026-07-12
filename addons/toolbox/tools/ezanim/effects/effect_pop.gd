@tool
class_name EffectPop
extends AnimEffect

enum Direction { IN, OUT }
@export var direction: Direction = Direction.IN

func apply(node: Node) -> Tween:
	var pop_in := direction == Direction.IN
	var ease_mode := Tween.EASE_OUT if pop_in else Tween.EASE_IN

	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size / 2.0
		if pop_in: c.modulate.a = 1.0
		var tw := _tw(c, Tween.TRANS_BACK, ease_mode)
		if pop_in:
			var prop := _curve(tw.tween_property(c, "scale", Vector2.ONE, duration).from(Vector2.ZERO))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var s0 := c.scale
			var prop := _curve(tw.tween_property(c, "scale", Vector2.ZERO, duration))
			if delay > 0.0: prop.set_delay(delay)
			tw.finished.connect(func(): if is_instance_valid(c): c.scale = s0)
		return tw

	if node is Node2D:
		var s := node as Node2D
		if pop_in: s.modulate.a = 1.0
		var tw := _tw(s, Tween.TRANS_BACK, ease_mode)
		if pop_in:
			var prop := _curve(tw.tween_property(s, "scale", Vector2.ONE, duration).from(Vector2.ZERO))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var s0 := s.scale
			var prop := _curve(tw.tween_property(s, "scale", Vector2.ZERO, duration))
			if delay > 0.0: prop.set_delay(delay)
			tw.finished.connect(func(): if is_instance_valid(s): s.scale = s0)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var tw := _tw(s, Tween.TRANS_BACK, ease_mode)
		if pop_in:
			var prop := _curve(tw.tween_property(s, "scale", Vector3.ONE, duration).from(Vector3.ZERO))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var s0 := s.scale
			var prop := _curve(tw.tween_property(s, "scale", Vector3.ZERO, duration))
			if delay > 0.0: prop.set_delay(delay)
			tw.finished.connect(func(): if is_instance_valid(s): s.scale = s0)
		return tw

	push_warning("EffectPop: nieobsługiwany typ: " + node.get_class())
	return null
