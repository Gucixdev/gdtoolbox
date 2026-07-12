@tool
class_name EffectSlide
extends AnimEffect

enum Direction { IN, OUT }
@export var direction: Direction = Direction.IN
@export var slide_dir: Vector3 = Vector3.LEFT
@export var distance: float = 100.0

func apply(node: Node) -> Tween:
	var slide_in := direction == Direction.IN
	var ease_mode := Tween.EASE_OUT if slide_in else Tween.EASE_IN

	if node is Control:
		var c := node as Control
		var dir2 := _dir2(slide_dir)
		var o := c.position
		var tw := _tw(c, Tween.TRANS_BACK, ease_mode)
		if slide_in:
			c.position = o + dir2 * distance
			var prop := _curve(tw.tween_property(c, "position", o, duration))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var prop := _curve(tw.tween_property(c, "position", o + dir2 * distance, duration))
			if delay > 0.0: prop.set_delay(delay)
		return tw

	if node is Node2D:
		var s := node as Node2D
		var dir2 := _dir2(slide_dir)
		var o := s.position
		var tw := _tw(s, Tween.TRANS_BACK, ease_mode)
		if slide_in:
			s.position = o + dir2 * distance
			var prop := _curve(tw.tween_property(s, "position", o, duration))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var prop := _curve(tw.tween_property(s, "position", o + dir2 * distance, duration))
			if delay > 0.0: prop.set_delay(delay)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var dir3 := slide_dir.normalized()
		var o := s.position
		var tw := _tw(s, Tween.TRANS_BACK, ease_mode)
		if slide_in:
			s.position = o + dir3 * distance
			var prop := _curve(tw.tween_property(s, "position", o, duration))
			if delay > 0.0: prop.set_delay(delay)
		else:
			var prop := _curve(tw.tween_property(s, "position", o + dir3 * distance, duration))
			if delay > 0.0: prop.set_delay(delay)
		return tw

	push_warning("EffectSlide: nieobsługiwany typ: " + node.get_class())
	return null
