@tool
class_name EzEquipment
extends Node

## Generyczny system slotów na ekwipunek — NIE fps-specific (żyje w toolboxie,
## ma być reużywalny w innych projektach). Slot to nazwa (String), przedmiot
## to dowolny Resource — ten node nie narzuca jego kształtu, to gra decyduje
## co Resource ma w sobie (nazwa, ikona, staty, itp).
##
## Domyślne sloty left_hand/right_hand pasują wprost pod
## player.gd::attacked(side: Side) w web/game/player/player.gd (dual-wield —
## LEFT/RIGHT już się rozróżnia w inpucie, ten node daje gdzie trzymać co jest
## w której ręce).

signal equipped(slot_name: String, item: Resource)
signal unequipped(slot_name: String, item: Resource)

@export var slot_names: Array[String] = ["left_hand", "right_hand"]

var _slots: Dictionary = {}  # String -> Resource albo null

func _ready() -> void:
	for s in slot_names:
		_slots[s] = null

## Zwraca false (i nic nie robi) jeśli slot_name nie jest w slot_names —
## slot trzeba zadeklarować z góry, żeby literówka w nazwie nie tworzyła
## cichego, nigdy niesprawdzanego slotu.
func equip(slot_name: String, item: Resource) -> bool:
	if not _slots.has(slot_name):
		push_warning("EzEquipment: nieznany slot '%s' — dodaj go do slot_names" % slot_name)
		return false
	if _slots[slot_name] != null:
		unequip(slot_name)
	_slots[slot_name] = item
	equipped.emit(slot_name, item)
	return true

func unequip(slot_name: String) -> Resource:
	if not _slots.has(slot_name):
		return null
	var item: Resource = _slots[slot_name]
	if item == null:
		return null
	_slots[slot_name] = null
	unequipped.emit(slot_name, item)
	return item

func get_equipped(slot_name: String) -> Resource:
	return _slots.get(slot_name)

func is_slot_filled(slot_name: String) -> bool:
	return _slots.get(slot_name) != null

func get_all_equipped() -> Dictionary:
	var out: Dictionary = {}
	for s in _slots:
		if _slots[s] != null:
			out[s] = _slots[s]
	return out
