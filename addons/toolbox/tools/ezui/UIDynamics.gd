@tool
@icon("res://addons/toolbox/tools/ezui/assets/collapsible_container.svg")
class_name UIDynamics
extends Node

## Fizyka sprężysta dla UI jednym nodem — zamiast ręcznego składania Tweenów dla każdego przycisku.
## Wrzuć jako dziecko Control/Node2D, wybierz `style` (np. BUTTON_POP) i `preset` (np. BOUNCY). Gotowe:
## hover, press, focus, disabled i pojawienie się reagują same, a wartości dążą do celu przez równanie
## różniczkowe (sprężyna tłumiona) — płynnie wchodzą i wychodzą z animacji w dowolnym momencie, bez "skoków"
## gdy przerwiesz hover w połowie. Liczone w zwykłym GDScripcie (UIDynamicsMath), stabilne dla każdego `delta`.
##
## Kanały (wszystkie względem stanu spoczynkowego, który node sam odczytuje z elementu):
##   skala (x,y), przesunięcie (x,y), obrót, przezroczystość (self_modulate.a — nie koliduje z AnimPlayer/fade).
## Rozwiązywacze: SPRING (odbija), SMOOTH (jak Unity SmoothDamp), SLIDE (pierwszego rzędu, bez przestrzelenia),
## SECOND_ORDER (z antycypacją/przestrzeleniem). Gdy wszystko się uspokoi, node wyłącza własne _process.

signal settled
signal state_changed(trigger: int, active: bool)

enum Solver { SPRING, SMOOTH, SLIDE, SECOND_ORDER }
enum Preset { CUSTOM, SNAPPY, BOUNCY, JELLY, SMOOTH_SOFT, HEAVY, SLIDE_QUICK, ANTICIPATE }
enum Style { CUSTOM, BUTTON_POP, BUTTON_SOFT, CARD_LIFT, APPEAR_POP, APPEAR_SLIDE, HOVER_WOBBLE }

const _SX := 0
const _SY := 1
const _OX := 2
const _OY := 3
const _ROT := 4
const _AL := 5
const _N := 6
const _REST := [1.0, 1.0, 0.0, 0.0, 0.0, 1.0]
const _EPS := 0.0005

## Element do animowania. Puste = rodzic.
@export var target: NodePath = ^""

@export var preset: Preset = Preset.SNAPPY:
	set(v):
		preset = v
		_apply_preset()
@export var style: Style = Style.BUTTON_POP:
	set(v):
		style = v
		_apply_style()

@export_group("Solver")
@export var solver: Solver = Solver.SPRING
## Hz — jak szybko reaguje (2 = uspokaja się w ok. pół sekundy).
@export_range(0.1, 20.0, 0.05, "suffix:Hz") var frequency: float = 4.5
## Współczynnik tłumienia ζ: 0 nigdy się nie uspokoi, <1 odbija, 1 krytyczny, >1 ociężały.
@export_range(0.0, 3.0, 0.01) var damping: float = 0.85
## Tylko SECOND_ORDER: 1 zwykły, >1 przestrzela, <0 antycypuje (najpierw w złą stronę).
@export_range(-2.0, 3.0, 0.01) var response: float = 1.0
## Tylko SMOOTH: czas w konwencji Unity SmoothDamp.
@export_range(0.01, 2.0, 0.01, "suffix:s") var smooth_time: float = 0.18
## Tylko SLIDE: 1/s (14 ≈ domyka w ~0.2 s).
@export_range(0.5, 60.0, 0.1) var slide_rate: float = 14.0
## Ograniczenie prędkości (SPRING/SMOOTH), jednostki kanału/s. 0 = wyłączone.
@export_range(0.0, 200.0, 0.5) var max_speed: float = 0.0

@export_group("Stany")
## Co się dzieje przy hover/press/focus/disabled/appear. Dla stylu CUSTOM edytuj tu; inne style wypełniają to same.
@export var states: Array[UIDynamicsState] = []

@export_group("Zachowanie")
@export var react_to_input: bool = true
## Ustaw pivot na środek elementu (skala/obrót od środka) i trzymaj go tam po zmianie rozmiaru.
@export var center_pivot: bool = true
## Animuj przy każdym pokazaniu elementu (stany z triggerem APPEAR).
@export var play_on_appear: bool = true
@export var ignore_pause: bool = false

var _node: CanvasItem
var _x := PackedFloat32Array([1.0, 1.0, 0.0, 0.0, 0.0, 1.0])
var _v := PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _t := PackedFloat32Array([1.0, 1.0, 0.0, 0.0, 0.0, 1.0])
var _xp := PackedFloat32Array([1.0, 1.0, 0.0, 0.0, 0.0, 1.0])     # poprzednie wejście (SECOND_ORDER)
var _active := {}
var _rest_scale := Vector2.ONE
var _rest_pos := Vector2.ZERO
var _rest_rot := 0.0
var _rest_alpha := 1.0
var _in_container := false
var _warned := false

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if ignore_pause:
		process_mode = Node.PROCESS_MODE_ALWAYS
	_node = (get_node_or_null(target) if not target.is_empty() else get_parent()) as CanvasItem
	if _node == null:
		push_warning("UIDynamics: brak celu CanvasItem (ustaw `target` albo dodaj jako dziecko Control/Node2D)")
		set_process(false)
		return
	_in_container = _node.get_parent() is Container
	_capture_rest()
	if _node is Control:
		var c := _node as Control
		if center_pivot:
			c.pivot_offset = c.size * 0.5
			c.resized.connect(func(): c.pivot_offset = c.size * 0.5)
		if react_to_input:
			c.mouse_entered.connect(func(): set_state(UIDynamicsState.Trigger.HOVER, true))
			c.mouse_exited.connect(func(): set_state(UIDynamicsState.Trigger.HOVER, false))
			c.focus_entered.connect(func(): set_state(UIDynamicsState.Trigger.FOCUS, true))
			c.focus_exited.connect(func(): set_state(UIDynamicsState.Trigger.FOCUS, false))
			if c is BaseButton:
				var b := c as BaseButton
				b.button_down.connect(func(): set_state(UIDynamicsState.Trigger.PRESSED, true))
				b.button_up.connect(func(): set_state(UIDynamicsState.Trigger.PRESSED, false))
			else:
				c.gui_input.connect(_on_gui_input)
	if play_on_appear:
		_node.visibility_changed.connect(_on_visibility_changed)
	set_state(UIDynamicsState.Trigger.ALWAYS, true)
	set_process(false)

func _on_gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		set_state(UIDynamicsState.Trigger.PRESSED, ev.pressed)

func _on_visibility_changed() -> void:
	if _node == null or not _node.is_visible_in_tree():
		return
	# wejście: zacznij od wartości stanu APPEAR i dąż do spoczynku
	_capture_rest_if_idle()
	_active[UIDynamicsState.Trigger.APPEAR] = true
	var from := _targets()
	_active.erase(UIDynamicsState.Trigger.APPEAR)
	for i in _N:
		_x[i] = from[i]
		_xp[i] = from[i]
		_v[i] = 0.0
	_apply()
	_wake()

# ── API ──────────────────────────────────────────────────────────────────────────

## Włącza/wyłącza stan wg triggera (np. DISABLED z własnej logiki).
func set_state(trigger: UIDynamicsState.Trigger, active: bool) -> void:
	if _active.get(trigger, false) == active:
		return
	_capture_rest_if_idle()
	_active[trigger] = active
	state_changed.emit(trigger, active)
	_wake()

## Szturchnięcie: impuls prędkości na skali (np. po kliknięciu, trafieniu, zdobyciu przedmiotu).
func kick(strength: float = 1.0) -> void:
	_v[_SX] += 3.0 * strength
	_v[_SY] += 3.0 * strength
	_wake()

func kick_offset(impulse: Vector2) -> void:
	_v[_OX] += impulse.x
	_v[_OY] += impulse.y
	_wake()

func kick_rotation(degrees_per_second: float) -> void:
	_v[_ROT] += degrees_per_second
	_wake()

## Natychmiast do stanu spoczynkowego, bez ruchu.
func snap_to_rest() -> void:
	_active.clear()
	for i in _N:
		_x[i] = _REST[i]
		_t[i] = _REST[i]
		_xp[i] = _REST[i]
		_v[i] = 0.0
	_apply()
	set_process(false)

func is_settled() -> bool:
	return not is_processing()

## Wartość kanału (do debugowania / własnych efektów): 0 sx, 1 sy, 2 ox, 3 oy, 4 rot, 5 alpha.
func channel(i: int) -> float:
	return _x[i]

# ── wnętrze ──────────────────────────────────────────────────────────────────────

func _wake() -> void:
	if _node != null and not is_processing():
		set_process(true)

## Odczytuje spoczynek z elementu TYLKO gdy kanały są dokładnie w spoczynku — inaczej węzeł niesie nasze
## przekształcenie (np. skalę z hovera) i zapisalibyśmy je jako "spoczynek", mnożąc efekt drugi raz.
## Dzięki temu zewnętrzne zmiany pozycji/skali w bezczynności są respektowane, a w trakcie animacji nic się nie psuje.
func _capture_rest_if_idle() -> void:
	for i in _N:
		if _x[i] != _REST[i]:
			return
	_capture_rest()

func _capture_rest() -> void:
	if _node is Control:
		var c := _node as Control
		_rest_scale = c.scale
		_rest_pos = c.position
		_rest_rot = c.rotation_degrees
	elif _node is Node2D:
		var n := _node as Node2D
		_rest_scale = n.scale
		_rest_pos = n.position
		_rest_rot = n.rotation_degrees
	_rest_alpha = _node.self_modulate.a

## Cele kanałów z aktywnych stanów: skala i alfa mnożą się, offset i obrót dodają.
func _targets() -> PackedFloat32Array:
	var t := PackedFloat32Array(_REST)
	var disabled := false
	if _node is BaseButton:
		disabled = (_node as BaseButton).disabled
	for s in states:
		if s == null:
			continue
		var on: bool = _active.get(s.trigger, false)
		if s.trigger == UIDynamicsState.Trigger.DISABLED:
			on = on or disabled
		if not on:
			continue
		t[_SX] *= s.scale.x
		t[_SY] *= s.scale.y
		t[_OX] += s.offset.x
		t[_OY] += s.offset.y
		t[_ROT] += s.rotation_deg
		t[_AL] *= s.alpha
	return t

func _process(delta: float) -> void:
	if _node == null or not is_instance_valid(_node):
		set_process(false)
		return
	_t = _targets()
	var dt := minf(delta, 0.25)
	match solver:
		Solver.SPRING:
			_step_spring(UIDynamicsMath.spring_coeffs(frequency, damping, dt))
		Solver.SMOOTH:
			_step_spring(UIDynamicsMath.smooth_coeffs(smooth_time, dt))
		Solver.SLIDE:
			var k := UIDynamicsMath.slide_factor(slide_rate, dt)
			for i in _N:
				var nx: float = _x[i] + (_t[i] - _x[i]) * k
				_v[i] = (nx - _x[i]) / maxf(dt, 1e-6)
				_x[i] = nx
		Solver.SECOND_ORDER:
			var p := UIDynamicsMath.second_order_params(frequency, damping, response)
			for i in _N:
				var s := UIDynamicsMath.second_order_step(Vector3(_x[i], _v[i], _xp[i]), _t[i], p, dt)
				_x[i] = s.x
				_v[i] = s.y
				_xp[i] = s.z
	_apply()
	if _is_at_rest():
		for i in _N:
			_x[i] = _t[i]
			_v[i] = 0.0
		_apply()
		set_process(false)
		settled.emit()

func _step_spring(c: PackedFloat32Array) -> void:
	for i in _N:
		var s := UIDynamicsMath.spring_step(_x[i], _v[i], _t[i], c)
		_x[i] = s.x
		_v[i] = clampf(s.y, -max_speed, max_speed) if max_speed > 0.0 else s.y

func _is_at_rest() -> bool:
	for i in _N:
		if absf(_x[i] - _t[i]) > _EPS or absf(_v[i]) > _EPS * 4.0:
			return false
	return true

func _apply() -> void:
	var sc := _rest_scale * Vector2(_x[_SX], _x[_SY])
	var pos := _rest_pos + Vector2(_x[_OX], _x[_OY])
	var rot := _rest_rot + _x[_ROT]
	var sm := _node.self_modulate
	sm.a = _rest_alpha * _x[_AL]
	_node.self_modulate = sm
	if _node is Control:
		var c := _node as Control
		c.scale = sc
		c.rotation_degrees = rot
		if _in_container:
			if not _warned and (absf(_x[_OX]) > 0.0 or absf(_x[_OY]) > 0.0):
				_warned = true
				push_warning("UIDynamics: przesunięcie ignorowane — rodzic to Container (użyj skali/obrotu/alfa)")
		else:
			c.position = pos
	elif _node is Node2D:
		var n := _node as Node2D
		n.scale = sc
		n.rotation_degrees = rot
		n.position = pos

func _apply_preset() -> void:
	match preset:
		Preset.SNAPPY:       _set_params(Solver.SPRING, 4.5, 0.85)
		Preset.BOUNCY:       _set_params(Solver.SPRING, 3.0, 0.35)
		Preset.JELLY:        _set_params(Solver.SPRING, 2.2, 0.18)
		Preset.SMOOTH_SOFT:  _set_params(Solver.SMOOTH, 0.0, 0.0, 1.0, 0.18)
		Preset.HEAVY:        _set_params(Solver.SPRING, 1.6, 1.1)
		Preset.SLIDE_QUICK:  _set_params(Solver.SLIDE, 0.0, 0.0, 1.0, 0.18, 14.0)
		Preset.ANTICIPATE:   _set_params(Solver.SECOND_ORDER, 2.5, 0.6, -0.6)
		_: pass

func _set_params(s: Solver, f: float, z: float, r: float = 1.0, st: float = -1.0, rate: float = -1.0) -> void:
	solver = s
	if f > 0.0:
		frequency = f
		damping = z
	response = r
	if st > 0.0:
		smooth_time = st
	if rate > 0.0:
		slide_rate = rate

func _apply_style() -> void:
	if style == Style.CUSTOM:
		return
	var out: Array[UIDynamicsState] = []
	match style:
		Style.BUTTON_POP:
			out.append(_state(UIDynamicsState.Trigger.HOVER, Vector2(1.06, 1.06)))
			out.append(_state(UIDynamicsState.Trigger.PRESSED, Vector2(0.94, 0.94)))
		Style.BUTTON_SOFT:
			out.append(_state(UIDynamicsState.Trigger.HOVER, Vector2(1.03, 1.03)))
			out.append(_state(UIDynamicsState.Trigger.PRESSED, Vector2(0.97, 0.97), Vector2.ZERO, 0.0, 0.9))
		Style.CARD_LIFT:
			out.append(_state(UIDynamicsState.Trigger.HOVER, Vector2(1.03, 1.03), Vector2(0, -6)))
			out.append(_state(UIDynamicsState.Trigger.PRESSED, Vector2(0.99, 0.99), Vector2(0, -2)))
		Style.APPEAR_POP:
			out.append(_state(UIDynamicsState.Trigger.APPEAR, Vector2(0.6, 0.6), Vector2.ZERO, 0.0, 0.0))
		Style.APPEAR_SLIDE:
			out.append(_state(UIDynamicsState.Trigger.APPEAR, Vector2.ONE, Vector2(0, 24), 0.0, 0.0))
		Style.HOVER_WOBBLE:
			out.append(_state(UIDynamicsState.Trigger.HOVER, Vector2(1.04, 1.04), Vector2.ZERO, 4.0))
	states = out

static func _state(trigger: UIDynamicsState.Trigger, scale: Vector2, offset := Vector2.ZERO, rot := 0.0, alpha := 1.0) -> UIDynamicsState:
	var s := UIDynamicsState.new()
	s.trigger = trigger
	s.scale = scale
	s.offset = offset
	s.rotation_deg = rot
	s.alpha = alpha
	return s
