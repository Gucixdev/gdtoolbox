@tool
class_name EffectWarn
extends AnimEffect

func apply(node: Node) -> Tween:
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size / 2.0
		var s0 := c.scale
		var m0 := c.modulate
		var tw := _tw(c, Tween.TRANS_CIRC)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_parallel(true)
		tw.tween_property(c, "modulate", Color(3.3, 0.0, 0.0, 1.0), duration * 0.1)
		tw.tween_property(c, "scale", s0 + Vector2(0.1, 0.1), duration * 0.3)
		tw.set_parallel(false)
		tw.tween_property(c, "scale", s0, duration * 0.7)
		tw.tween_property(c, "modulate", m0, duration * 0.7)
		tw.finished.connect(func():
			if is_instance_valid(c):
				c.scale = s0
				c.modulate = m0
		)
		return tw

	if node is Node2D:
		var s := node as Node2D
		var s0 := s.scale
		var m0 := s.modulate
		var tw := _tw(s, Tween.TRANS_CIRC)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_parallel(true)
		tw.tween_property(s, "modulate", Color(3.3, 0.0, 0.0, 1.0), duration * 0.1)
		tw.tween_property(s, "scale", s0 * 1.15, duration * 0.3)
		tw.set_parallel(false)
		tw.tween_property(s, "scale", s0, duration * 0.7)
		tw.tween_property(s, "modulate", m0, duration * 0.7)
		tw.finished.connect(func():
			if is_instance_valid(s):
				s.scale = s0
				s.modulate = m0
		)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var s0 := s.scale
		var tw := _tw(s, Tween.TRANS_CIRC)
		if delay > 0.0: tw.tween_interval(delay)
		tw.tween_property(s, "scale", s0 * 1.15, duration * 0.3)
		tw.tween_property(s, "scale", s0,         duration * 0.7)
		tw.finished.connect(func(): if is_instance_valid(s): s.scale = s0)
		return tw

	push_warning("EffectWarn: nieobsługiwany typ: " + node.get_class())
	return null
