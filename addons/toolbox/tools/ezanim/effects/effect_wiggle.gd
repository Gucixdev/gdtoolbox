@tool
class_name EffectWiggle
extends AnimEffect

func apply(node: Node) -> Tween:
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size / 2.0
		var base := c.rotation_degrees
		var tw := _tw(c, Tween.TRANS_SINE)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_loops(2)
		tw.tween_property(c, "rotation_degrees",  2.5, duration * 0.25)
		tw.tween_property(c, "rotation_degrees", -2.5, duration * 0.5)
		tw.tween_property(c, "rotation_degrees",  0.0, duration * 0.25)
		tw.finished.connect(func(): if is_instance_valid(c): c.rotation_degrees = base)
		return tw

	if node is Node2D:
		var s := node as Node2D
		var base := s.rotation_degrees
		var tw := _tw(s, Tween.TRANS_SINE)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_loops(2)
		tw.tween_property(s, "rotation_degrees",  5.0, duration * 0.25)
		tw.tween_property(s, "rotation_degrees", -5.0, duration * 0.5)
		tw.tween_property(s, "rotation_degrees",  0.0, duration * 0.25)
		tw.finished.connect(func(): if is_instance_valid(s): s.rotation_degrees = base)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var base := s.rotation_degrees
		var tw := _tw(s, Tween.TRANS_SINE)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_loops(2)
		tw.tween_property(s, "rotation_degrees", base + Vector3(0,  5.0, 0), duration * 0.25)
		tw.tween_property(s, "rotation_degrees", base + Vector3(0, -5.0, 0), duration * 0.5)
		tw.tween_property(s, "rotation_degrees", base,                        duration * 0.25)
		tw.finished.connect(func(): if is_instance_valid(s): s.rotation_degrees = base)
		return tw

	push_warning("EffectWiggle: nieobsługiwany typ: " + node.get_class())
	return null
