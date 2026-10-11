extends Node

## Autoload singleton: the one shared native EcsWorld for the whole game, plus
## component-id caching by script so EcsEntity/EcsSystem don't re-resolve a
## name -> id lookup every call. One world per game is the normal ECS setup;
## add more EcsWorld.new() instances yourself if a project genuinely needs
## several isolated simulations.

var world: EcsWorld = EcsWorld.new()
var _ids_by_script: Dictionary = {}

func register(component_script: Script) -> int:
	var cached = _ids_by_script.get(component_script)
	if cached != null:
		return cached
	var comp_name := component_script.get_global_name()
	if comp_name.is_empty():
		push_error("Ecs: component script must have a class_name")
		return -1
	var id := world.component_id(comp_name)
	if id < 0:
		id = world.register_component(comp_name, component_script.byte_size())
	_ids_by_script[component_script] = id
	return id
