@tool
class_name UIAnim
extends Node

signal started
signal finished

enum Type {
	FADE_IN, FADE_OUT,
	POP_IN, POP_OUT,
	SLIDE_IN, SLIDE_OUT,
	FADE_SLIDE_IN, FADE_SLIDE_OUT,
	WIGGLE, PULSE, PING,
}

## Węzeł do animowania. Pusty = rodzic.
@export var target: NodePath = ^""
@export var type: Type = Type.FADE_IN
@export var duration: float = 0.3
@export var auto_play: bool = false
@export_group("Advanced")
@export var distance: float = 100.0
## Kierunek slajdu — skąd przychodzi (SLIDE_IN) / dokąd odchodzi (SLIDE_OUT).
@export var direction: Vector2 = Vector2.LEFT
## Opcjonalna krzywa easingu — nadpisuje wbudowany trans/ease gdy ustawiona.
@export var ease_curve: Curve
@export_tool_button("▶ Play") var _btn := play

var _tween: Tween

func _ready() -> void:
	if auto_play:
		play()

func play() -> void:
	var node := _node()
	if not node:
		push_warning("UIAnim: brak celu — ustaw target lub dodaj jako dziecko CanvasItem")
		return
	_stop()
	started.emit()
	_animate(node)

func stop() -> void:
	_stop()

# ── internal ───────────────────────────────────────────────────────────────────

func _node() -> CanvasItem:
	if target.is_empty():
		return get_parent() as CanvasItem
	return get_node_or_null(target) as CanvasItem

func _stop() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

func _tw(node: Node, trans := Tween.TRANS_CUBIC, ease := Tween.EASE_OUT) -> Tween:
	_tween = node.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
	if ease_curve:
		_tween.set_custom_interpolator(func(t: float) -> float: return ease_curve.sample(t))
	else:
		_tween.set_trans(trans).set_ease(ease)
	_tween.finished.connect(finished.emit)
	return _tween

func _animate(n: CanvasItem) -> void:
	var dir := direction.normalized()
	match type:
		Type.FADE_IN:
			_tw(n).tween_property(n, "modulate:a", 1.0, duration).from(0.0)
		Type.FADE_OUT:
			_tw(n, Tween.TRANS_CUBIC, Tween.EASE_IN).tween_property(n, "modulate:a", 0.0, duration)
		Type.POP_IN:
			n.modulate.a = 1.0
			_set_pivot(n)
			_tw(n, Tween.TRANS_BACK).tween_property(n, "scale", Vector2.ONE, duration).from(Vector2.ZERO)
		Type.POP_OUT:
			_set_pivot(n)
			var tw := _tw(n, Tween.TRANS_BACK, Tween.EASE_IN)
			var s0: Vector2 = n.get("scale") as Vector2
			tw.tween_property(n, "scale", Vector2.ZERO, duration)
			tw.finished.connect(func(): if is_instance_valid(n): n.set("scale", s0))
		Type.SLIDE_IN:
			var origin: Vector2 = n.get("position") as Vector2
			n.set("position", origin + dir * distance)
			_tw(n, Tween.TRANS_BACK).tween_property(n, "position", origin, duration)
		Type.SLIDE_OUT:
			var origin: Vector2 = n.get("position") as Vector2
			_tw(n, Tween.TRANS_BACK, Tween.EASE_IN).tween_property(n, "position", origin + dir * distance, duration)
		Type.FADE_SLIDE_IN:
			var origin: Vector2 = n.get("position") as Vector2
			var tw := _tw(n, Tween.TRANS_BACK)
			tw.set_parallel(true)
			tw.tween_property(n, "modulate:a", 1.0, duration).from(0.0)
			tw.tween_property(n, "position", origin, duration).from(origin + dir * distance)
		Type.FADE_SLIDE_OUT:
			var origin: Vector2 = n.get("position") as Vector2
			var tw := _tw(n, Tween.TRANS_BACK, Tween.EASE_IN)
			tw.set_parallel(true)
			tw.tween_property(n, "modulate:a", 0.0, duration)
			tw.tween_property(n, "position", origin + dir * distance, duration)
		Type.WIGGLE:
			var base: float = n.get("rotation_degrees") as float
			_set_pivot(n)
			var tw := _tw(n, Tween.TRANS_SINE).set_loops(2)
			tw.tween_property(n, "rotation_degrees",  2.5, duration * 0.25)
			tw.tween_property(n, "rotation_degrees", -2.5, duration * 0.5)
			tw.tween_property(n, "rotation_degrees",  0.0, duration * 0.25)
			tw.finished.connect(func(): if is_instance_valid(n): n.set("rotation_degrees", base))
		Type.PULSE:
			var base := n.modulate.a
			var tw := _tw(n, Tween.TRANS_SINE).set_loops(2)
			tw.tween_property(n, "modulate:a", 0.4, duration * 0.5)
			tw.tween_property(n, "modulate:a", 1.0, duration * 0.5)
			tw.finished.connect(func(): if is_instance_valid(n): n.modulate.a = base)
		Type.PING:
			_set_pivot(n)
			var s0: Vector2 = n.get("scale") as Vector2
			var m0: Color = n.modulate
			var tw := _tw(n, Tween.TRANS_CIRC)
			tw.set_parallel(true)
			tw.tween_property(n, "modulate", Color(3.3, 0, 0, 1), duration * 0.1)
			tw.tween_property(n, "scale", s0 + Vector2(0.1, 0.1), duration * 0.3)
			tw.set_parallel(false)
			tw.tween_property(n, "scale", s0, duration * 0.7)
			tw.tween_property(n, "modulate", m0, duration * 0.7)
			tw.finished.connect(func(): if is_instance_valid(n): n.set("scale", s0); n.modulate = m0)

func _set_pivot(n: CanvasItem) -> void:
	if n is Control:
		n.pivot_offset = n.size / 2.0
