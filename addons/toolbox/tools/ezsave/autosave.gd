class_name EzAutoSave
extends Node

## Automatyczny zapis co N sekund lub minut.
## Szuka EzSave w rodzeństwie lub przez `target` NodePath.

## Opcjonalny shared config — ten sam plik .tres co w EzSave/EzLoad.
@export var config: EzSaveConfig
@export var target: NodePath
@export_enum("Seconds", "Minutes") var interval_unit: int = 0
@export var interval: float = 30.0
@export var save_on_scene_change: bool = true
@export var enabled: bool = true

var _timer: float = 0.0

func _process(delta: float) -> void:
	if not enabled or Engine.is_editor_hint(): return
	_timer += delta
	if _timer >= _interval_sec():
		_timer = 0.0
		_do_save()

func force_save() -> void:
	_timer = 0.0
	_do_save()

func _interval_sec() -> float:
	return interval * (60.0 if interval_unit == 1 else 1.0)

func _do_save() -> void:
	var saver := _find_saver()
	if saver:
		saver.save_nodes()
	else:
		push_warning("EzAutoSave: brak EzSave w zasięgu")

func _find_saver() -> EzSave:
	if not target.is_empty():
		return get_node_or_null(target) as EzSave
	var parent := get_parent()
	if not parent: return null
	for child in parent.get_children():
		if not (child is EzSave): continue
		# Preferuj EzSave z tym samym configiem lub slotem
		if config and (child as EzSave).config == config: return child
		if (child as EzSave)._slot() == (config.slot if config else 0): return child
	return null
