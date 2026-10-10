class_name UIDynamicsMath
extends RefCounted

## Różniczkowe równania ruchu dla UI, w postaci zamkniętej (rozwiązanie dokładne kroku, nie całkowanie Eulera).
##
## Oscylator tłumiony  x'' + 2·ζ·ω·x' + ω²·(x − cel) = 0,  ω = 2π·f  jest rozwiązany DOKŁADNIE dla kroku dt:
## macierz przejścia 2×2 (pp, pv, vp, vv) zależy tylko od (f, ζ, dt). Dzięki temu:
##   • jest bezwarunkowo stabilny — hitch 2 s czy zwolniony FPS nie "wybucha",
##   • wygląda tak samo przy 30 i 240 FPS (rozwiązanie się składa: 60 kroków po 1/60 == 1 krok po 1 s),
##   • pokrywa cały zakres tłumienia: ζ<1 odbija, ζ=1 krytyczne, ζ>1 ociężałe.
## Wszystko jest zwykłym GDScriptem na floatach — działa w edytorze, na webie, na każdej platformie.

const TWO_PI := TAU

## Zwraca [pp, pv, vp, vv]:  x' = pp·(x−t) + pv·v + t ;  v' = vp·(x−t) + vv·v
static func spring_coeffs(frequency: float, zeta: float, dt: float) -> PackedFloat32Array:
	var c := PackedFloat32Array([1.0, dt, 0.0, 1.0])          # bez siły sprężyny: swobodna cząstka
	if dt <= 0.0:
		c[1] = 0.0
		return c
	if frequency <= 0.0:
		return c
	zeta = maxf(zeta, 0.0)
	var w := TWO_PI * frequency
	var eps := 1e-4
	if zeta > 1.0 + eps:                                      # przetłumiony: dwa rzeczywiste tempa zaniku
		var a := w * sqrt(zeta * zeta - 1.0)
		var r1 := -w * zeta + a
		var r2 := -w * zeta - a
		var e1 := exp(r1 * dt)
		var e2 := exp(r2 * dt)
		var inv := 1.0 / (r1 - r2)
		c[0] = (r1 * e2 - r2 * e1) * inv
		c[1] = (e1 - e2) * inv
		c[2] = r1 * r2 * (e2 - e1) * inv
		c[3] = (r1 * e1 - r2 * e2) * inv
	elif zeta < 1.0 - eps:                                    # niedotłumiony: gasnące drgania
		var wd := w * sqrt(1.0 - zeta * zeta)
		var e := exp(-zeta * w * dt)
		var cs := cos(wd * dt)
		var sn := sin(wd * dt)
		var k := zeta * w / wd
		c[0] = e * (cs + k * sn)
		c[1] = e * sn / wd
		c[2] = -e * (w * w / wd) * sn
		c[3] = e * (cs - k * sn)
	else:                                                     # krytyczny
		var e := exp(-w * dt)
		c[0] = e * (1.0 + w * dt)
		c[1] = e * dt
		c[2] = -e * w * w * dt
		c[3] = e * (1.0 - w * dt)
	return c

## Sprężyna krytyczna w konwencji Unity SmoothDamp (ω = 2/smooth_time): ~59% drogi po smooth_time, ~95% po ≈2.4×.
static func smooth_coeffs(smooth_time: float, dt: float) -> PackedFloat32Array:
	return spring_coeffs((2.0 / maxf(smooth_time, 0.0001)) / TWO_PI, 1.0, dt)

## Jeden krok: zwraca Vector2(x', v').
static func spring_step(x: float, v: float, target: float, c: PackedFloat32Array) -> Vector2:
	var y := x - target
	return Vector2(c[0] * y + c[1] * v + target, c[2] * y + c[3] * v)

## Pierwszego rzędu ("slide"): x += (cel − x)·(1 − e^(−rate·dt)). Bez przestrzelenia i bez stanu prędkości.
static func slide_factor(rate: float, dt: float) -> float:
	return 1.0 - exp(-maxf(rate, 0.0) * maxf(dt, 0.0))

## Drugiego rzędu (f, ζ, r) → [k1, k2, k3]. r<0: antycypacja (najpierw w złą stronę), r>1: chętne przestrzelenie.
static func second_order_params(frequency: float, zeta: float, response: float) -> PackedFloat32Array:
	var f := maxf(frequency, 1e-4)
	return PackedFloat32Array([zeta / (PI * f), 1.0 / pow(TWO_PI * f, 2.0), response * zeta / (TWO_PI * f)])

## Jeden krok drugiego rzędu. state = Vector3(y, yd, xp). Zwraca nowy state. k2 ograniczone → stabilne dla dużego dt.
static func second_order_step(state: Vector3, input: float, p: PackedFloat32Array, dt: float) -> Vector3:
	if dt <= 0.0:
		return state
	var k2 := maxf(p[1], maxf(dt * dt * 0.5 + dt * p[0] * 0.5, dt * p[0]))
	var xd := (input - state.z) / dt
	var y := state.x + dt * state.y
	var yd := state.y + dt * (input + p[2] * xd - y - p[0] * state.y) / k2
	return Vector3(y, yd, input)
