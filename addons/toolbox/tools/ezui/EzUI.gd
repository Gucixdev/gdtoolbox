@tool
class_name EzUI
extends Node

## Jeden node-marker do oznaczania korzenia UI w drzewie sceny. Bez tego,
## przy mieszaniu Control/CanvasLayer/Node2D/Node3D (HUD, health bar 3D nad
## głową, panel 2D, radial menu...) trudno na oko odróżnić "moje UI" od
## reszty drzewa. Dzieci dodajesz swobodnie — Control, CanvasLayer, Node2D,
## Node3D, cokolwiek — EzUI nie narzuca typu ani layoutu, tylko oznacza
## poddrzewo (widać "EzUI" w kolumnie typu w Scene panel) i rejestruje je
## w grupie "ez_ui" żeby dało się je odnaleźć/schować z kodu bez trzymania
## referencji do każdego HUD-a z osobna.

@export var ui_id: String = ""

func _ready() -> void:
	add_to_group("ez_ui")

## Chowa/pokazuje całe poddrzewo niezależnie od tego czy dzieci to
## CanvasItem (2D/Control) czy Node3D — jedno wywołanie zamiast pilnowania
## typu każdego dziecka z osobna. Rekurencja schodzi tylko przez "gołe" Node
## (np. inny EzUI albo zwykły kontener organizacyjny) — jak trafi na
## CanvasItem/Node3D, ustawia visible i zatrzymuje się (Godot i tak propaguje
## widoczność w dół automatycznie).
func set_ui_visible(v: bool) -> void:
	_apply_visible(self, v)

static func _apply_visible(node: Node, v: bool) -> void:
	for child: Node in node.get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = v
		elif child is Node3D:
			(child as Node3D).visible = v
		else:
			_apply_visible(child, v)

## EzUI nie jest samo Controlem/Node3D więc nie ma własnej pozycji do
## wyrównania — subklasy budujące wizualne dziecko (NinePatchRect, quady...)
## centrują je tym helperem zamiast domyślnego top-left: dziecko wypada na
## (-size/2), sam rozmiar zostaje bez zmian. Jedno miejsce, żeby wszystkie
## EzUI-pochodne centrowały się tak samo.
static func center_child(child: Node, size: Vector2) -> void:
	if child is Control:
		(child as Control).position = -size / 2.0
	elif child is Node2D:
		(child as Node2D).position = -size / 2.0
	elif child is Node3D:
		(child as Node3D).position = Vector3(-size.x / 2.0, -size.y / 2.0, 0.0)
