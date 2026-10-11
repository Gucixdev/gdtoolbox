@tool
class_name EcsEntity
extends Node

## Scene-tree handle for one native-ECS entity (see Ecs.gd / EcsComponent.gd). Replaces
## the old EzEntity: component DATA no longer lives on this node (it's a contiguous
## column inside the shared Ecs.world), this is just the id plus node-lifecycle glue so
## you can still drop it under a CharacterBody3D/Node3D etc. like before.

var id: int = -1

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	id = Ecs.world.create_entity()

func _exit_tree() -> void:
	if Engine.is_editor_hint() or id < 0:
		return
	Ecs.world.destroy_entity(id)
	id = -1

func add_component(component_script: Script, data = null) -> void:
	var comp_id := Ecs.register(component_script)
	Ecs.world.add_component(id, comp_id)
	if data != null and component_script.byte_size() > 0:
		Ecs.world.set_component_bytes(id, comp_id, component_script.to_bytes(data))

func remove_component(component_script: Script) -> void:
	Ecs.world.remove_component(id, Ecs.register(component_script))

func has_component(component_script: Script) -> bool:
	return Ecs.world.has_component(id, Ecs.register(component_script))

## Tag (byte_size() == 0) -> true/null. Data component -> whatever from_bytes() returns, or null if absent.
func get_component(component_script: Script):
	var comp_id := Ecs.register(component_script)
	if not Ecs.world.has_component(id, comp_id):
		return null
	if component_script.byte_size() == 0:
		return true
	return component_script.from_bytes(Ecs.world.get_component_bytes(id, comp_id))

func set_component(component_script: Script, data) -> void:
	Ecs.world.set_component_bytes(id, Ecs.register(component_script), component_script.to_bytes(data))
