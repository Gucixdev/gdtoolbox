@tool
class_name EffectShake
extends AnimEffect

@export var strength: float = 20.0
@export_range(0.0, 1.0) var decay: float = 1.0

func apply(node: Node) -> Tween:
	var step := 0.04
	var steps := maxi(2, int(duration / step))

	if node is Control or node is Node2D:
		var o2 := (node as Control).position if node is Control else (node as Node2D).position

		var offsets: Array[Vector2] = []
		for i in steps:
			var t := float(i) / float(steps)
			var amp := strength * (1.0 - t * decay)
			offsets.append(Vector2(randf_range(-amp, amp), randf_range(-amp * 0.5, amp * 0.5)))

		var tw := _tw(node, Tween.TRANS_LINEAR)
		if delay > 0.0: tw.tween_interval(delay)
		for i in steps:
			var off := offsets[i]
			tw.tween_callback(func():
				if not is_instance_valid(node): return
				if node is Control: (node as Control).position = o2 + off
				else: (node as Node2D).position = o2 + off
			)
			tw.tween_interval(step)
		tw.tween_callback(func():
			if not is_instance_valid(node): return
			if node is Control: (node as Control).position = o2
			else: (node as Node2D).position = o2
		)
		return tw

	if node is Node3D:
		var s := node as Node3D
		var o3 := s.position
		var offsets3: Array[Vector3] = []
		for i in steps:
			var t := float(i) / float(steps)
			var amp := strength * 0.01 * (1.0 - t * decay)
			offsets3.append(Vector3(randf_range(-amp, amp), randf_range(-amp, amp), 0.0))

		var tw := _tw(s, Tween.TRANS_LINEAR)
		if delay > 0.0: tw.tween_interval(delay)
		for i in steps:
			var off := offsets3[i]
			tw.tween_callback(func(): if is_instance_valid(s): s.position = o3 + off)
			tw.tween_interval(step)
		tw.tween_callback(func(): if is_instance_valid(s): s.position = o3)
		return tw

	push_warning("EffectShake: nieobsługiwany typ: " + node.get_class())
	return null
