@tool
class_name PBRLayer
extends BaseLayer

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

@export_subgroup("Parallax (advanced)")
## Minimum number of layers when looking straight at the surface (mode POM/SPOM raises it toward pom_steps at grazing angles).
@export_range(2, 64) var pom_min_steps: int = 6:
	set(v): pom_min_steps = v; emit_changed()
## Bisection steps that refine where the ray meets the relief. SPOM always uses at least 4.
@export_range(0, 8) var pom_refine: int = 0:
	set(v): pom_refine = v; emit_changed()
## Height that coincides with the real surface. 1 = relief only sinks in; lower lets it rise above the surface.
@export_range(0.0, 1.0) var pom_ref_plane: float = 1.0:
	set(v): pom_ref_plane = v; emit_changed()
@export var pom_invert: bool = false:
	set(v): pom_invert = v; emit_changed()
@export var pom_fade_start: float = 12.0:
	set(v): pom_fade_start = v; emit_changed()
@export var pom_fade_end: float = 30.0:
	set(v): pom_fade_end = v; emit_changed()
## Discard where the parallaxed UV leaves the tile (use on single quads, not on tiled meshes).
@export var pom_clip_edges: bool = false:
	set(v): pom_clip_edges = v; emit_changed()
@export_range(0.0, 1.0) var pom_shadow_strength: float = 0.0:
	set(v): pom_shadow_strength = v; emit_changed()
@export_range(4, 32) var pom_shadow_steps: int = 12:
	set(v): pom_shadow_steps = v; emit_changed()
## World-space direction TOWARD the light, for the self-shadow.
@export var pom_light_dir: Vector3 = Vector3(0.4, 0.8, 0.45):
	set(v): pom_light_dir = v; emit_changed()

@export_subgroup("Occlusion (advanced)")
enum AOMode { ALBEDO, AMBIENT, BOTH }
## ALBEDO paints occlusion into the colour (visible without lights); AMBIENT only dims ambient light; BOTH does both.
@export var ao_mode: AOMode = AOMode.ALBEDO:
	set(v): ao_mode = v; emit_changed()
## Cavity AO derived from the height map (pom_texture).
@export_range(0.0, 4.0) var ao_cavity_strength: float = 0.0:
	set(v): ao_cavity_strength = v; emit_changed()
@export_range(0.0005, 0.05) var ao_cavity_radius: float = 0.006:
	set(v): ao_cavity_radius = v; emit_changed()
## Curvature AO derived from the normal map: creases dark, bulges untouched.
@export_range(0.0, 4.0) var ao_curvature_strength: float = 0.0:
	set(v): ao_curvature_strength = v; emit_changed()
## Vertex-colour AO (COLOR.r), e.g. baked in Blender.
@export_range(0.0, 1.0) var ao_vertex_strength: float = 0.0:
	set(v): ao_vertex_strength = v; emit_changed()
## Share of direct light that AO also dims (AMBIENT/BOTH modes).
@export_range(0.0, 1.0) var ao_light_affect: float = 0.0:
	set(v): ao_light_affect = v; emit_changed()
@export var ao_multibounce_on: bool = false:
	set(v): ao_multibounce_on = v; emit_changed()

@export_subgroup("Mapping")
enum MappingMode { UV, TRIPLANAR_WORLD, TRIPLANAR_OBJECT }
@export var mapping_mode: MappingMode = MappingMode.UV:
	set(v): mapping_mode = v; emit_changed()
@export var uv_tiling: Vector2 = Vector2.ONE:
	set(v): uv_tiling = v; emit_changed()
@export var uv_offset: Vector2 = Vector2.ZERO:
	set(v): uv_offset = v; emit_changed()
@export_range(-180.0, 180.0) var uv_rotation: float = 0.0:
	set(v): uv_rotation = v; emit_changed()
## Tiles per second.
@export var uv_scroll: Vector2 = Vector2.ZERO:
	set(v): uv_scroll = v; emit_changed()
## Hides texture repetition by blending random offsets per tile.
@export var uv_stochastic: bool = false:
	set(v): uv_stochastic = v; emit_changed()
@export var tri_scale: float = 0.25:
	set(v): tri_scale = v; emit_changed()
@export_range(1.0, 16.0) var tri_sharpness: float = 4.0:
	set(v): tri_sharpness = v; emit_changed()

@export_subgroup("Bump & detail")
## > 0 derives a normal from the height map (pom_texture) when there is no normal map.
@export_range(0.0, 8.0) var bump_strength: float = 0.0:
	set(v): bump_strength = v; emit_changed()
@export var detail_normal: Texture2D:
	set(v): detail_normal = v; emit_changed()
@export var detail_albedo: Texture2D:
	set(v): detail_albedo = v; emit_changed()
@export var detail_tiling: float = 6.0:
	set(v): detail_tiling = v; emit_changed()
@export_range(0.0, 2.0) var detail_normal_strength: float = 0.0:
	set(v): detail_normal_strength = v; emit_changed()
@export_range(0.0, 1.0) var detail_albedo_strength: float = 0.0:
	set(v): detail_albedo_strength = v; emit_changed()
