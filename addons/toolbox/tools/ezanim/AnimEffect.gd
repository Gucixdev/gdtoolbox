@tool
class_name AnimEffect
extends Resource

@export var duration: float = 0.3
@export var delay: float = 0.0
@export var ease_curve: Curve

func apply(_node: Node) -> Tween:
	return null

func _tw(node: Node, trans: int = Tween.TRANS_CUBIC, ease_mode: int = Tween.EASE_OUT) -> Tween:
	var tw: Tween = node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	tw.set_trans(trans).set_ease(ease_mode)
	return tw

func _curve(pt: PropertyTweener) -> PropertyTweener:
	if ease_curve:
		pt.set_custom_interpolator(ease_curve.sample)
	return pt

func _dir2(v: Vector3) -> Vector2:
	return Vector2(v.x, v.y).normalized()
