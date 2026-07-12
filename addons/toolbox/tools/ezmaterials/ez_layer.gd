@tool
class_name EzLayer
extends Resource

enum SpecularMode { NONE, BLINN_PHONG, PHONG }
enum ParallaxMode { NONE, POM, SPOM }
enum SeamlessMode { VORONOI, ALPHA_BLEND, BOTH }

# ═══════════════════════════════════════════════════════════════════════════════
# MATCAP LAYER
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("MatcapLayer")
@export var enabled: bool = true:
	set(v): enabled = v; emit_changed()
@export var texture: Texture2D:
	set(v): texture = v; emit_changed()
@export var freeze: bool = false:
	set(v): freeze = v; emit_changed()
@export_range(0.0, 2.0) var strength: float = 1.0:
	set(v): strength = v; emit_changed()
@export var invert: bool = false:
	set(v): invert = v; emit_changed()
@export_range(0.0, 1.0) var pbr_blend: float = 1.0:
	set(v): pbr_blend = v; emit_changed()
@export var albedo_color: Color = Color.WHITE:
	set(v): albedo_color = v; emit_changed()
@export var albedo_texture: Texture2D:
	set(v): albedo_texture = v; emit_changed()
@export var emission: Color = Color.BLACK:
	set(v): emission = v; emit_changed()
@export_range(0.0, 16.0) var emission_strength: float = 0.0:
	set(v): emission_strength = v; emit_changed()

@export_subgroup("Ramp")
@export var ramp_enabled: bool = false:
	set(v): ramp_enabled = v; emit_changed()
@export_range(2, 8) var ramp_count: int = 3:
	set(v): ramp_count = v; emit_changed()
@export_range(0.0, 1.0) var ramp_smooth: float = 0.0:
	set(v): ramp_smooth = v; emit_changed()

@export_subgroup("Opal")
@export var opal_enabled: bool = false:
	set(v): opal_enabled = v; emit_changed()
@export_range(0.0, 1.0) var opal_strength: float = 0.5:
	set(v): opal_strength = v; emit_changed()
@export_range(0.5, 8.0) var opal_fresnel_power: float = 2.0:
	set(v): opal_fresnel_power = v; emit_changed()
@export_range(0.0, 1.0) var opal_hue_shift: float = 0.0:
	set(v): opal_hue_shift = v; emit_changed()
@export_range(0.0, 1.0) var opal_saturation: float = 1.0:
	set(v): opal_saturation = v; emit_changed()
@export var opal_tint: Color = Color.WHITE:
	set(v): opal_tint = v; emit_changed()
@export var opal_texture: Texture2D:
	set(v): opal_texture = v; emit_changed()
@export var opal_use_texture: bool = false:
	set(v): opal_use_texture = v; emit_changed()
@export var opal_additive: bool = false:
	set(v): opal_additive = v; emit_changed()

@export_subgroup("Seamless")
@export var seamless_enabled: bool = false:
	set(v): seamless_enabled = v; emit_changed()
@export_range(1, 16) var seamless_scale: int = 4:
	set(v): seamless_scale = v; emit_changed()
@export var seamless_mode: SeamlessMode = SeamlessMode.VORONOI:
	set(v): seamless_mode = v; emit_changed()
@export_range(0.0, 1.0) var seamless_strength: float = 0.3:
	set(v): seamless_strength = v; emit_changed()

@export_subgroup("Atlas")
@export var atlas_enabled: bool = false:
	set(v): atlas_enabled = v; emit_changed()
@export_range(1, 64) var atlas_columns: int = 4:
	set(v): atlas_columns = v; emit_changed()
@export_range(1, 64) var atlas_rows: int = 4:
	set(v): atlas_rows = v; emit_changed()
@export_range(0, 4095) var atlas_frame: int = 0:
	set(v): atlas_frame = v; emit_changed()

# ═══════════════════════════════════════════════════════════════════════════════
# PBR LAYER
# ═══════════════════════════════════════════════════════════════════════════════

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
