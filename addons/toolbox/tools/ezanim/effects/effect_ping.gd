@tool
class_name EffectPing
extends AnimEffect

## Radar-style ping: szybki scale-out z SPRING, jakby wysyłanie sygnału.
@export_range(1.05, 1.5) var peak_scale: float = 1.12

func apply(node: Node) -> Tween:
	if node is Control:
		var c := node as Control
		c.pivot_offset = c.size / 2.0
		var s0 := c.scale
		var tw := _tw(c, Tween.TRANS_SPRING, Tween.EASE_OUT)
		if delay > 0.0: tw.tween_interval(delay)
		var prop := _curve(tw.tween_property(c, "scale", s0 * peak_scale, duration * 0.3).from(s0))
		if delay > 0.0: prop.set_delay(delay)
		tw.tween_property(c, "scale", s0, duration * 0.7)
		tw.finished.connect(func(): if is_instance_valid(c): c.scale = s0)
		return tw

	if node is Node2D:
		var s := node as Node2D
		var s0 := s.scale
		var tw := _tw(s, Tween.TRANS_SPRING, Tween.EASE_OUT)
		if delay > 0.0: tw.tween_interval(delay)
		var prop := _curve(tw.tween_property(s, "scale", s0 * peak_scale, duration * 0.3).from(s0))
		if delay > 0.0: prop.set_delay(delay)
		tw.tween_property(s, "scale", s0, duration * 0.7)
		tw.finished.connect(func(): if is_instance_valid(s): s.scale = s0)
		return tw

	if node is Node3D:
		var s3 := node as Node3D
		var s0 := s3.scale
		var tw := _tw(s3, Tween.TRANS_SPRING, Tween.EASE_OUT)
		if delay > 0.0: tw.tween_interval(delay)
		tw.tween_property(s3, "scale", s0 * peak_scale, duration * 0.3).from(s0)
		tw.tween_property(s3, "scale", s0, duration * 0.7)
		tw.finished.connect(func(): if is_instance_valid(s3): s3.scale = s0)
		return tw

	push_warning("EffectPing: nieobsługiwany typ: " + node.get_class())
	return null
