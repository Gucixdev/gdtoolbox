@tool
class_name EzAnim
extends Node

signal started
signal finished

@export var targets: Array[NodePath] = []
@export var effect: AnimEffect
@export var auto_play: bool = false
@export_tool_button("▶ Play") var _btn = func(): play()

var _tween: Tween

func _ready() -> void:
	if auto_play: play()

func play() -> void:
	var nodes := _get_targets()
	if nodes.is_empty():
		push_warning(name + ": brak celu (dodaj NodePath do 'targets' lub zostaw puste żeby animować rodzica)")
		return
	if not effect:
		push_warning(name + ": brak efektu (przypisz AnimEffect do 'effect')")
		return
	if _tween and _tween.is_valid(): _tween.kill()
	started.emit()
	_run_all(nodes)

func stop() -> void:
	if _tween and _tween.is_valid(): _tween.kill()

func _get_targets() -> Array[Node]:
	var result: Array[Node] = []
	for tp: NodePath in targets:
		if tp.is_empty(): continue
		var n := get_node_or_null(tp)
		if n and not result.has(n): result.append(n)
	if result.is_empty():
		var p := get_parent()
		if p: result.append(p)
	return result

func _run_all(nodes: Array[Node]) -> void:
	if nodes.size() == 1:
		if effect is EffectMix: _run_mix(nodes[0], effect as EffectMix)
		else: _run(nodes[0], effect)
		return
	# Wiele targetów — równolegle, finished gdy wszystkie skończą
	var pending := nodes.size()
	var on_one_done := func():
		pending -= 1
		if pending <= 0: finished.emit()
	if effect is EffectMix:
		for n: Node in nodes:
			_do_mix(n, effect as EffectMix, on_one_done)  # detached coroutine
	else:
		for n: Node in nodes:
			var tw := effect.apply(n)
			if tw: tw.finished.connect(on_one_done)
			else:  on_one_done.call()

func _run(n: Node, eff: AnimEffect) -> void:
	var tw := eff.apply(n)
	if tw:
		_tween = tw
		await tw.finished
	finished.emit()

func _run_mix(n: Node, mix: EffectMix) -> void:
	_do_mix(n, mix, func(): finished.emit())

# Wspólny async helper — uruchamiaj bez await dla "fire and forget" na wielu targetach
func _do_mix(n: Node, mix: EffectMix, done: Callable) -> void:
	if mix.effects.is_empty():
		done.call()
		return
	if mix.mode == 0:  # Parallel
		var pending_inner := mix.effects.size()
		var on_inner := func():
			pending_inner -= 1
			if pending_inner <= 0: done.call()
		for eff: AnimEffect in mix.effects:
			var tw := eff.apply(n)
			if tw: tw.finished.connect(on_inner)
			else:  on_inner.call()
	else:  # Sequential
		for eff: AnimEffect in mix.effects:
			var tw := eff.apply(n)
			if tw:
				_tween = tw
				await tw.finished
		done.call()
