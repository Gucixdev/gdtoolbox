@tool
class_name AnimPlayer
extends Node

signal started(label: String)
signal finished(label: String)

## Jeden node do wszystkich animacji (zastępuje EzAnim, EzAnimPlayer i UIAnim).
##
## Najprościej: wybierz `preset`, ustaw `duration` i zawołaj `play()`
## (albo zaznacz `play_on_ready`). Gra na `targets`, a gdy puste — na rodzicu.
## Zaawansowane: własny `effect` albo sekwencja `events` z labelami/opóźnieniami.
enum Preset {
	NONE,
	FADE_IN, FADE_OUT, POP_IN, POP_OUT, SLIDE_IN, SLIDE_OUT,
	FADE_SLIDE_IN, FADE_SLIDE_OUT, BOUNCE_IN, BOUNCE_OUT,
	WIGGLE, PULSE, PING, SHAKE, FLASH, WARN, GLITCH,
}

@export var preset: Preset = Preset.FADE_IN
@export var duration: float = 0.3
@export_group("Slide / Bounce")
@export var distance: float = 100.0
## Skąd wjeżdża (IN) / dokąd odjeżdża (OUT).
@export var direction: Vector2 = Vector2.LEFT
@export_group("Advanced")
## Własny efekt — ma pierwszeństwo przed `preset`.
@export var effect: AnimEffect
@export var targets: Array[NodePath] = []
@export var play_on_ready: bool = false
## Tryb sekwencji: wiele efektów z labelami i opóźnieniami. Gdy niepusty,
## ma pierwszeństwo przed `effect`.
@export var events: Array[EzAnimEvent] = []
## Gra automatycznie w _ready(). Pusty string = bez autoplay (w szybkim trybie
## wpisz cokolwiek, np. "play"). Label odpala tylko eventy z tym labelem.
@export var auto_play: String = ""
## Tool button odpala auto_play (lub wszystkie eventy jeśli pusty) — podgląd w edytorze.
@export_tool_button("▶ Play") var _btn = func(): play(auto_play)

var _active_tweens: Array[Tween] = []

func _ready() -> void:
	if Engine.is_editor_hint(): return
	if play_on_ready or not auto_play.is_empty():
		play(auto_play if not events.is_empty() else "")

## label="" → odpala WSZYSTKIE eventy (podgląd / sekwencja globalna).
## label="open" → tylko eventy z tym labelem.
func play(label: String = "") -> void:
	var src: Array[EzAnimEvent] = events
	var eff := effect if effect != null else _from_preset()
	if events.is_empty() and eff != null:
		var quick := EzAnimEvent.new()
		quick.effect = eff
		quick.targets = targets
		src = [quick]
	var group: Array = src.filter(func(e: EzAnimEvent):
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
	if result.is_empty() and get_parent():
		result.append(get_parent())
	return result

func _from_preset() -> AnimEffect:
	var e: AnimEffect
	var out := false
	match preset:
		Preset.FADE_IN, Preset.FADE_OUT: e = EffectFade.new()
		Preset.POP_IN, Preset.POP_OUT: e = EffectPop.new()
		Preset.SLIDE_IN, Preset.SLIDE_OUT: e = EffectSlide.new()
		Preset.FADE_SLIDE_IN, Preset.FADE_SLIDE_OUT: e = EffectFadeSlide.new()
		Preset.BOUNCE_IN, Preset.BOUNCE_OUT: e = EffectBounce.new()
		Preset.WIGGLE: e = EffectWiggle.new()
		Preset.PULSE: e = EffectPulse.new()
		Preset.PING: e = EffectPing.new()
		Preset.SHAKE: e = EffectShake.new()
		Preset.FLASH: e = EffectFlash.new()
		Preset.WARN: e = EffectWarn.new()
		Preset.GLITCH: e = EffectGlitch.new()
		_: return null
	out = preset in [Preset.FADE_OUT, Preset.POP_OUT, Preset.SLIDE_OUT,
			Preset.FADE_SLIDE_OUT, Preset.BOUNCE_OUT]
	e.duration = duration
	if "direction" in e:
		e.set("direction", 1 if out else 0)  # enum Direction { IN, OUT }
	if "distance" in e:
		e.set("distance", distance)
	if "slide_dir" in e:
		e.set("slide_dir", Vector3(direction.x, direction.y, 0.0))
	return e
