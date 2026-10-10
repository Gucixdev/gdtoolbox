@tool
class_name UIDynamicsState
extends Resource

## Jeden "stan" elementu UI: gdy trigger jest aktywny, kanały dążą do tych wartości (względem stanu spoczynkowego).
## Stany aktywne składają się: skala i alfa mnożą się, przesunięcie i obrót dodają.

enum Trigger { HOVER, PRESSED, FOCUS, DISABLED, APPEAR, ALWAYS }

@export var trigger: Trigger = Trigger.HOVER
## Mnożnik skali względem spoczynku (1 = bez zmian).
@export var scale: Vector2 = Vector2.ONE
## Przesunięcie w pikselach względem spoczynku. Ignorowane gdy rodzic to Container (kontener i tak ustawia pozycję).
@export var offset: Vector2 = Vector2.ZERO
@export_range(-180.0, 180.0, 0.1, "suffix:°") var rotation_deg: float = 0.0
## Mnożnik przezroczystości (self_modulate.a) względem spoczynku.
@export_range(0.0, 1.0, 0.01) var alpha: float = 1.0
