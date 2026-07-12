@tool
class_name EffectFadeSlide
extends AnimEffect

enum Direction { IN, OUT }
@export var direction: Direction = Direction.IN
@export var slide_dir: Vector3 = Vector3.LEFT
@export var distance: float = 100.0

func apply(node: Node) -> Tween:
	var fade_in := direction == Direction.IN
	var ease_mode := Tween.EASE_OUT if fade_in else Tween.EASE_IN

	if node is Control:
		var c := node as Control
		var dir2 := _dir2(slide_dir)
		var o := c.position
		var offset := dir2 * distance
		var tw := _tw(c, Tween.TRANS_BACK, ease_mode)
		tw.set_parallel(true)
		if fade_in:
			var pa := _curve(tw.tween_property(c, "modulate:a", 1.0, duration).from(0.0))
			var pp := _curve(tw.tween_property(c, "position", o, duration).from(o + offset))
			if delay > 0.0: pa.set_delay(delay); pp.set_delay(delay)
		else:
			var pa := _curve(tw.tween_property(c, "modulate:a", 0.0, duration))
			var pp := _curve(tw.tween_property(c, "position", o + offset, duration))
			if delay > 0.0: pa.set_delay(delay); pp.set_delay(delay)
		return tw

	if node is Node2D:
		var s := node as Node2D
		var dir2 := _dir2(slide_dir)
		var o := s.position
		var offset := dir2 * distance
		var tw := _tw(s, Tween.TRANS_BACK, ease_mode)
		tw.set_parallel(true)
		if fade_in:
			var pa := _curve(tw.tween_property(s, "modulate:a", 1.0, duration).from(0.0))
			var pp := _curve(tw.tween_property(s, "position", o, duration).from(o + offset))
			if delay > 0.0: pa.set_delay(delay); pp.set_delay(delay)
		else:
			var pa := _curve(tw.tween_property(s, "modulate:a", 0.0, duration))
			var pp := _curve(tw.tween_property(s, "position", o + offset, duration))
			if delay > 0.0: pa.set_delay(delay); pp.set_delay(delay)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var dir3 := slide_dir.normalized()
		var o := s.position
		var tw := _tw(s, Tween.TRANS_BACK, ease_mode)
		tw.set_parallel(true)
		if node is VisualInstance3D:
			if fade_in: (node as VisualInstance3D).transparency = 1.0
			var pt := _curve(tw.tween_property(s, "transparency", 0.0 if fade_in else 1.0, duration))
			if delay > 0.0: pt.set_delay(delay)
		if fade_in:
			var pp := _curve(tw.tween_property(s, "position", o, duration).from(o + dir3 * distance))
			if delay > 0.0: pp.set_delay(delay)
		else:
			var pp := _curve(tw.tween_property(s, "position", o + dir3 * distance, duration))
			if delay > 0.0: pp.set_delay(delay)
		return tw

	push_warning("EffectFadeSlide: nieobsługiwany typ: " + node.get_class())
	return null
