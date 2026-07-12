@tool
class_name EzLoad
extends Node

signal loaded(data: Dictionary)
signal load_failed

## Opcjonalny shared config (slot w jednym .tres, ten sam co w EzSave).
@export var config: EzSaveConfig

@export var slot: int = 0
@export var auto_load: bool = true

func _slot() -> int:
	return config.slot if config else slot

## Jeśli true, szuka EzSave z tym samym slotem i wywołuje apply() po załadowaniu.
@export var auto_apply: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint() and auto_load:
		load_and_apply() if auto_apply else load_slot()

## Ładuje slot i zwraca dane.
func load_slot() -> Dictionary:
	if Engine.is_editor_hint(): return {}
	var ss := get_node_or_null("/root/SaveSystem")
	if not is_instance_valid(ss):
		push_error("EzLoad: SaveSystem nie znaleziony")
		load_failed.emit()
		return {}
	var data: Dictionary = ss.call(&"load", _slot())
	if data.is_empty(): load_failed.emit()
	else:               loaded.emit(data)
	return data

## Ładuje i od razu aplikuje do nodów (przez EzSave.apply()).
func load_and_apply() -> Dictionary:
	var data := load_slot()
	if data.is_empty(): return data
	var saver := _find_saver()
	if saver: saver.apply(data)
	return data

func load_slot_async() -> Dictionary:
	if Engine.is_editor_hint(): return {}
	var ss := get_node_or_null("/root/SaveSystem")
	if not is_instance_valid(ss):
		push_error("EzLoad: SaveSystem nie znaleziony")
		load_failed.emit()
		return {}
	var sig = ss.call(&"load_async", _slot())
	if sig is Signal: await sig
	return load_slot()

func slot_exists() -> bool:
	var ss := get_node_or_null("/root/SaveSystem")
	if not is_instance_valid(ss): return false
	return ss.call(&"slot_exists", _slot())

func _find_saver() -> EzSave:
	var parent := get_parent()
	if parent:
		for child in parent.get_children():
			if child is EzSave and child._slot() == _slot():
				return child
	return null
