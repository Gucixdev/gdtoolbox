@tool
class_name EffectFlash
extends AnimEffect

@export var color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export_range(1, 5) var count: int = 1

func apply(node: Node) -> Tween:
	if node is Control or node is Node2D:
		var ci := node as CanvasItem
		var base := ci.modulate
		var step := duration / float(count)
		var half := step * 0.4
		var back := step * 0.6

		var tw := _tw(node, Tween.TRANS_LINEAR)
		if delay > 0.0: tw.tween_interval(delay)
		for i in count:
			# .from(base) na pierwszym kroku — gwarantuje start od oryginalnego koloru
			# nawet gdy inny efekt animuje modulate równolegle w EffectMix
			var p1 := _curve(tw.tween_property(ci, "modulate", color, half))
			if i == 0: p1.from(base)
			_curve(tw.tween_property(ci, "modulate", base, back))
		# tween_callback jako ostatni krok — odpala przed finished, pewniejszy niż connect
		tw.tween_callback(func(): if is_instance_valid(ci): ci.modulate = base)
		return tw

	push_warning("EffectFlash: działa tylko z Control/Node2D")
	return null
