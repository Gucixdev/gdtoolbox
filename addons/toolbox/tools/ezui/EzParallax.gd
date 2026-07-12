@tool
class_name EzParallax
extends MeshInstance3D

## Cienki wrapper na WBUDOWANY w Godota parallax/relief mapping
## (StandardMaterial3D.heightmap_enabled) — zamiast pisać własny shader od
## zera, korzysta z gotowego, przetestowanego mechanizmu silnika. Podepnij
## albedo_texture + height_texture (grayscale, biały = wypukłe) i gotowe.
##
## Pomyślane pod płaskie quady ścian/podłóg (np. dungeon_generator.gd) którym
## brakuje głębi bez dokładania geometrii — "belki"/corner posts w generatorze
## to uzupełniają (ukrywają krawędź quada), nie zastępują.

@export var albedo_texture: Texture2D:
	set(v): albedo_texture = v; _rebuild()
@export var height_texture: Texture2D:
	set(v): height_texture = v; _rebuild()
@export_range(0.0, 0.5, 0.001) var depth_scale: float = 0.05:
	set(v): depth_scale = v; _rebuild()
@export_range(1, 32) var min_layers: int = 8:
	set(v): min_layers = v; _rebuild()
@export_range(1, 32) var max_layers: int = 32:
	set(v): max_layers = v; _rebuild()
@export var deep_parallax: bool = true:
	set(v): deep_parallax = v; _rebuild()
@export var uv_scale: Vector2 = Vector2.ONE:
	set(v): uv_scale = v; _rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = albedo_texture
	mat.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	if height_texture:
		mat.heightmap_enabled = true
		mat.heightmap_texture = height_texture
		mat.heightmap_scale = depth_scale
		mat.heightmap_deep_parallax = deep_parallax
		mat.heightmap_min_layers = min_layers
		mat.heightmap_max_layers = max_layers
	material_override = mat
