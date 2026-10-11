@tool
class_name MatcapLayer
extends BaseLayer

enum SeamlessMode { VORONOI, ALPHA_BLEND, BOTH }

@export_group("MatcapLayer")
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
