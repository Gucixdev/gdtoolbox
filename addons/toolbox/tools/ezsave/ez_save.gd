@tool
class_name EzSave
extends Node

signal saved(ok: bool)

## Opcjonalny shared config (slot + entries w jednym .tres).
## Jeśli ustawiony, nadpisuje lokalne `slot` i `entries`.
@export var config: EzSaveConfig

@export var slot: int = 0
@export var auto_save_on_exit: bool = false

## Lista nodów i properties do automatycznego zapisu.
## Wstaw SaveEntry w Inspektorze — nie trzeba ręcznie budować Dictionary.
@export var entries: Array[SaveEntry] = []

func _slot() -> int:
	return config.slot if config else slot

func _entries() -> Array[SaveEntry]:
	return config.entries if config else entries

var _last_data: Dictionary = {}

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and auto_save_on_exit:
		save(collect() if not _entries().is_empty() else _last_data)

## Zbiera dane ze wszystkich entries (node + properties).
func collect() -> Dictionary:
	var data: Dictionary = {}
	for e in _entries():
		if not e or e.node.is_empty(): continue
		var node := get_node_or_null(e.node)
		if not is_instance_valid(node): continue
		var nd: Dictionary = {}
		for p in e.properties:
			nd[p] = node.get(p)
		data[str(e.node)] = nd
	return data

## Aplikuje wczytane dane z powrotem do nodów wg entries.
func apply(data: Dictionary) -> void:
	for e in _entries():
		if not e or e.node.is_empty(): continue
		var node := get_node_or_null(e.node)
		if not is_instance_valid(node): continue
		var nd: Variant = data.get(str(e.node))
		if not nd is Dictionary: continue
		for p in e.properties:
			if (nd as Dictionary).has(p):
				node.set(p, nd[p])

## Skrót: collect() + save(). Używa entries z Inspektora.
func save_nodes() -> bool:
	return save(collect())

## Zapisuje podane dane (lub pusty dict jeśli pominięty).
func save(data: Dictionary = {}) -> bool:
	if Engine.is_editor_hint(): return false
	if data.is_empty() and not entries.is_empty():
		data = collect()
	_last_data = data
	var ss := get_node_or_null("/root/SaveSystem")
	if not is_instance_valid(ss):
		push_error("EzSave: SaveSystem nie znaleziony")
		return false
	var ok: bool = ss.call(&"save", _slot(), data)
	saved.emit(ok)
	return ok

func save_async(data: Dictionary = {}) -> bool:
	if Engine.is_editor_hint(): return false
	if data.is_empty() and not entries.is_empty():
		data = collect()
	_last_data = data
	var ss := get_node_or_null("/root/SaveSystem")
	if not is_instance_valid(ss):
		push_error("EzSave: SaveSystem nie znaleziony")
		return false
	var sig = ss.call(&"save_async", _slot(), data)
	if sig is Signal: await sig
	var ok: bool = is_instance_valid(ss) and ss.call(&"slot_exists", _slot())
	saved.emit(ok)
	return ok
