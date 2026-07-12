@tool
class_name EzInventory
extends Node

## Generyczny hotbar/inventory ze zmienną liczbą slotów zależną od
## backpack_level: slot_count = backpack_level * 3 (lvl1=3, lvl2=6, lvl3=9,
## itd — liniowe, więc działa dla dowolnego poziomu, nie tylko 1-3). Item to
## dowolny Resource, node nie narzuca jego kształtu.
##
## Wybór aktywnego slotu (selected_index) — jak hotbar w Minecraft:
## select_next()/select_prev() (np. pod scroll kółkiem myszy), zawija się na
## krańcach zamiast się zatrzymywać.

signal slots_changed
signal selection_changed(index: int)

@export var backpack_level: int = 1:
	set(v):
		backpack_level = maxi(v, 1)
		_resize_slots()

var slots: Array = []
var selected_index: int = 0

func _ready() -> void:
	_resize_slots()

func _resize_slots() -> void:
	var count := backpack_level * 3
	if count == slots.size():
		return
	if count < slots.size():
		slots.resize(count)
	else:
		while slots.size() < count:
			slots.append(null)
	selected_index = clampi(selected_index, 0, count - 1)
	slots_changed.emit()

func slot_count() -> int:
	return slots.size()

func get_selected_item():
	return slots[selected_index] if selected_index < slots.size() else null

func select_index(index: int) -> void:
	if slots.is_empty():
		return
	selected_index = ((index % slots.size()) + slots.size()) % slots.size()
	selection_changed.emit(selected_index)

func select_next() -> void:
	select_index(selected_index + 1)

func select_prev() -> void:
	select_index(selected_index - 1)

## Wrzuca item do pierwszego pustego slotu. Zwraca false jeśli brak miejsca
## (inventory pełne) — Twoja gra decyduje co wtedy (upuść przedmiot, komunikat itp).
func add_item(item) -> bool:
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = item
			slots_changed.emit()
			return true
	return false

func remove_at(index: int):
	if index < 0 or index >= slots.size():
		return null
	var item = slots[index]
	slots[index] = null
	slots_changed.emit()
	return item
