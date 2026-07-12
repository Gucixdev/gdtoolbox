@tool
class_name EzPBRLayer
extends EzBaseLayer

enum SpecularMode { NONE, BLINN_PHONG, PHONG }
enum ParallaxMode { NONE, POM, SPOM }

@export_group("PBRLayer")

@export_subgroup("Normal")
@export var normal_enabled: bool = false:
	set(v): normal_enabled = v; emit_changed()
@export var normal_texture: Texture2D:
	set(v): normal_texture = v; emit_changed()
@export_range(0.0, 4.0) var normal_strength: float = 1.0:
	set(v): normal_strength = v; emit_changed()

@export_subgroup("Specular")
@export var specular_mode: SpecularMode = SpecularMode.NONE:
	set(v): specular_mode = v; emit_changed()
@export_range(1.0, 512.0) var phong_shininess: float = 32.0:
	set(v): phong_shininess = v; emit_changed()
@export_range(0.0, 2.0) var phong_strength: float = 0.5:
	set(v): phong_strength = v; emit_changed()

@export_subgroup("Occlusion")
@export var ao_enabled: bool = false:
	set(v): ao_enabled = v; emit_changed()
@export var ao_texture: Texture2D:
	set(v): ao_texture = v; emit_changed()
@export_range(0.0, 1.0) var ao_strength: float = 1.0:
	set(v): ao_strength = v; emit_changed()

@export_subgroup("Parallax")
@export var parallax_mode: ParallaxMode = ParallaxMode.NONE:
	set(v): parallax_mode = v; emit_changed()
@export var pom_texture: Texture2D:
	set(v): pom_texture = v; emit_changed()
@export_range(0.0, 0.5) var pom_depth: float = 0.05:
	set(v): pom_depth = v; emit_changed()
@export_range(4, 128) var pom_steps: int = 16:
	set(v): pom_steps = v; emit_changed()
