@tool
class_name EffectPulse
extends AnimEffect

func apply(node: Node) -> Tween:
	if node is Control or node is Node2D:
		var ci := node as CanvasItem
		var base := ci.modulate.a
		var tw := _tw(node, Tween.TRANS_SINE)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_loops(2)
		tw.tween_property(node, "modulate:a", 0.4, duration * 0.5)
		tw.tween_property(node, "modulate:a", 1.0, duration * 0.5)
		tw.finished.connect(func(): if is_instance_valid(ci): ci.modulate.a = base)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var s0 := s.scale
		var tw := _tw(s, Tween.TRANS_SINE)
		if delay > 0.0: tw.tween_interval(delay)
		tw.set_loops(2)
		tw.tween_property(s, "scale", s0 * 0.85, duration * 0.5)
		tw.tween_property(s, "scale", s0,         duration * 0.5)
		tw.finished.connect(func(): if is_instance_valid(s): s.scale = s0)
		return tw

	push_warning("EffectPulse: nieobsługiwany typ: " + node.get_class())
	return null
