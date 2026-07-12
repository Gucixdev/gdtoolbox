@tool
class_name EzAnimPlayer
extends Node

signal started(label: String)
signal finished(label: String)

@export var events: Array[EzAnimEvent] = []
## Pusty string = auto_play wszystkie eventy przy _ready(). Lub podaj label np. "open".
@export var auto_play: String = ""
## Tool button odpala auto_play (lub wszystkie eventy jeśli pusty) — podgląd w edytorze.
@export_tool_button("▶ Play") var _btn = func(): play(auto_play)

var _active_tweens: Array[Tween] = []

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if not auto_play.is_empty(): play(auto_play)

## label="" → odpala WSZYSTKIE eventy (podgląd / sekwencja globalna).
## label="open" → tylko eventy z tym labelem.
func play(label: String = "") -> void:
	var group: Array = events.filter(func(e: EzAnimEvent):
		return is_instance_valid(e) and e.effect != null and (label.is_empty() or e.label == label)
	)
	if group.is_empty():
		push_warning(name + ": brak eventów" + ("" if label.is_empty() else " z labelem '" + label + "'"))
		return

	stop()
	started.emit(label)

	var pending := group.size()
	var on_done := func():
		pending -= 1
		if pending <= 0:
			_active_tweens.clear()
			finished.emit(label)

	for ev: EzAnimEvent in group:
		_schedule(ev, on_done)

func stop() -> void:
	for tw in _active_tweens:
		if is_instance_valid(tw) and tw.is_valid():
			tw.kill()
	_active_tweens.clear()

func _schedule(ev: EzAnimEvent, on_done: Callable) -> void:
	if not ev.effect:
		on_done.call()
		return
	var nodes := _resolve(ev)
	if nodes.is_empty():
		push_warning(name + ": '" + ev.label + "' — brak targetów")
		on_done.call()
		return
	if ev.start_at > 0.0:
		var timer := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_BOUND)
		_active_tweens.append(timer)
		timer.tween_interval(ev.start_at)
		timer.tween_callback(func(): _fire(nodes, ev.effect, on_done))
	else:
		_fire(nodes, ev.effect, on_done)

func _fire(nodes: Array[Node], eff: AnimEffect, on_done: Callable) -> void:
	var pending := nodes.size()
	var on_target := func():
		pending -= 1
		if pending <= 0: on_done.call()
	for n: Node in nodes:
		_run(n, eff, on_target)

func _run(n: Node, eff: AnimEffect, done: Callable) -> void:
	if eff is EffectMix:
		_do_mix(n, eff as EffectMix, done)
		return
	var tw := eff.apply(n)
	if tw:
		_active_tweens.append(tw)
		tw.finished.connect(done)
	else:
		done.call()

func _do_mix(n: Node, mix: EffectMix, done: Callable) -> void:
	if mix.effects.is_empty():
		done.call()
		return
	if mix.mode == 0:
		var pending := mix.effects.size()
		var on_inner := func():
			pending -= 1
			if pending <= 0: done.call()
		for eff: AnimEffect in mix.effects:
			var tw := eff.apply(n)
			if tw:
				_active_tweens.append(tw)
				tw.finished.connect(on_inner)
			else:
				on_inner.call()
	else:
		_do_mix_seq(n, mix, done)

func _do_mix_seq(n: Node, mix: EffectMix, done: Callable) -> void:
	for eff: AnimEffect in mix.effects:
		var tw := eff.apply(n)
		if tw:
			_active_tweens.append(tw)
			await tw.finished
	done.call()

func _resolve(ev: EzAnimEvent) -> Array[Node]:
	var result: Array[Node] = []
	for tp: NodePath in ev.targets:
		if tp.is_empty(): continue
		var n := get_node_or_null(tp)
		if n and not result.has(n): result.append(n)
	return result
