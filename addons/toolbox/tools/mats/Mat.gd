@tool
class_name Mat
extends Node

const _SHADER_PATH := "res://addons/toolbox/tools/mats/mat.gdshader"

const _PBR_EXTRA: Array[StringName] = [
	&"pom_min_steps", &"pom_refine", &"pom_ref_plane", &"pom_invert", &"pom_fade_start", &"pom_fade_end", &"pom_clip_edges",
	&"pom_shadow_strength", &"pom_shadow_steps", &"pom_light_dir",
	&"ao_cavity_strength", &"ao_cavity_radius", &"ao_curvature_strength", &"ao_vertex_strength", &"ao_light_affect", &"ao_multibounce_on",
	&"uv_tiling", &"uv_offset", &"uv_rotation", &"uv_scroll", &"uv_stochastic", &"tri_scale", &"tri_sharpness",
	&"bump_strength", &"detail_normal", &"detail_albedo", &"detail_tiling", &"detail_normal_strength", &"detail_albedo_strength",
]

@export var targets: Array[NodePath]:
	set(v):
		targets = v
		_apply_to_meshes()

## -1 overrides the whole mesh (material_override, works with single-surface meshes).
## >= 0 overrides just that surface, so several Mat nodes can share one multi-material mesh.
@export var surface_idx: int = -1:
	set(v):
		surface_idx = v
		_apply_to_meshes()

var _mat: ShaderMaterial

func _get_target_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if not targets.is_empty():
		for tp in targets:
			var m := get_node_or_null(tp) as MeshInstance3D
			if m: out.append(m)
		return out
	var parent := get_parent()
	if parent is MeshInstance3D:
		out.append(parent as MeshInstance3D)
	else:
		for child in parent.get_children():
			if child is MeshInstance3D:
				out.append(child as MeshInstance3D)
	return out

func _ready() -> void:
	# Always create our own ShaderMaterial — never steal from another Mat node
	_mat = ShaderMaterial.new()
	_mat.shader = load(_SHADER_PATH)
	_connect_signals()
	_sync_all()  # assigns _mat to all targets via _apply_to_meshes()
	update_configuration_warnings()

func _notification(what: int) -> void:
	if not Engine.is_editor_hint(): return
	match what:
		NOTIFICATION_EDITOR_PRE_SAVE:
			if _mat: _mat.set_shader_parameter(&"matcap_array", null)
		NOTIFICATION_EDITOR_POST_SAVE:
			if _mat: _apply_matcap_array()

func _get_configuration_warnings() -> PackedStringArray:
	var meshes := _get_target_meshes()
	if meshes.is_empty():
		return ["Brak MeshInstance3D — dodaj jako dziecko meshu, lub ustaw 'targets'."]
	if surface_idx >= 0:
		for m in meshes:
			if m.mesh and surface_idx >= m.mesh.get_surface_count():
				return ["surface_idx %d poza zakresem dla '%s' (ma %d surface'ów)." % [surface_idx, m.name, m.mesh.get_surface_count()]]
	return []

func _apply_to_meshes() -> void:
	if not _mat: return
	for m in _get_target_meshes():
		if surface_idx >= 0:
			m.set_surface_override_material(surface_idx, _mat)
		else:
			m.material_override = _mat
	update_configuration_warnings()

func get_material() -> ShaderMaterial:
	return _mat

func _sp(v: Variant, param: StringName) -> void:
	if _mat: _mat.set_shader_parameter(param, v)

# ═══════════════════════════════════════════════════════════════════════════════
# LAYERS
# ═══════════════════════════════════════════════════════════════════════════════

@export_group("Layers")
@export var layers: Array[BaseLayer]:
	set(v):
		for l in layers:
			if l and l.changed.is_connected(_sync_all):
				l.changed.disconnect(_sync_all)
		layers = v
		for l in layers:
			if l and not l.changed.is_connected(_sync_all):
				l.changed.connect(_sync_all)
		_sync_all()

@export_group("Tools")
@export_tool_button("▶ Refresh") var _refresh_btn: Callable:
	get: return Callable(self, "_do_refresh")
	set(_v): pass
@export_tool_button("Smooth Normals (all targets)") var _smooth_btn: Callable:
	get: return Callable(self, "_smooth_normals")
	set(_v): pass
@export_tool_button("Save layers as .tres") var _save_btn: Callable:
	get: return Callable(self, "_save_to_res")
	set(_v): pass

# ─── Signals ──────────────────────────────────────────────────────────────────

func _connect_signals() -> void:
	for l in layers:
		if l == null: continue
		if l.changed.is_connected(_sync_all): l.changed.disconnect(_sync_all)
		l.changed.connect(_sync_all)

# ─── Sync ─────────────────────────────────────────────────────────────────────

func _sync_all() -> void:
	if not _mat:
		_mat = ShaderMaterial.new()
		_mat.shader = load(_SHADER_PATH)
	# First enabled MatcapLayer drives the non-array shader params
	var primary := _first_matcap()
	if primary:
		_apply_matcap_params(primary)
	# First enabled PBRLayer drives PBR shader params
	var pbr := _first_pbr()
	if pbr:
		_apply_pbr_params(pbr)
	_apply_matcap_array()
	_apply_to_meshes()

func _first_matcap() -> MatcapLayer:
	for l in layers:
		if l is MatcapLayer and l.enabled:
			return l as MatcapLayer
	return null

func _first_pbr() -> PBRLayer:
	for l in layers:
		if l is PBRLayer and l.enabled:
			return l as PBRLayer
	return null

func _apply_matcap_params(l: MatcapLayer) -> void:
	_sp(l.albedo_color,       &"albedo_color")
	_sp(l.albedo_texture,     &"albedo_texture")
	_sp(l.invert,             &"mc_invert")
	_sp(l.emission,           &"emission")
	_sp(l.emission_strength,  &"emission_strength")
	_sp(l.ramp_enabled,       &"ramp_enabled")
	_sp(l.ramp_count,         &"ramp_count")
	_sp(l.ramp_smooth,        &"ramp_smooth")
	_sp(l.seamless_enabled,   &"seamless_enabled")
	_sp(l.seamless_scale,     &"seamless_scale")
	_sp(int(l.seamless_mode), &"seamless_mode")
	_sp(l.seamless_strength,  &"seamless_strength")
	_sp(l.opal_enabled,       &"opal_enabled")
	_sp(l.opal_strength,      &"opal_strength")
	_sp(l.opal_fresnel_power, &"opal_fresnel_power")
	_sp(l.opal_hue_shift,     &"opal_hue_shift")
	_sp(l.opal_saturation,    &"opal_saturation")
	_sp(l.opal_tint,          &"opal_tint")
	_sp(l.opal_texture,       &"opal_texture")
	_sp(l.opal_use_texture,   &"opal_use_texture")
	_sp(l.opal_additive,      &"opal_additive")
	_sp(l.atlas_enabled,      &"atlas_enabled")
	_sp(l.atlas_columns,      &"atlas_columns")
	_sp(l.atlas_rows,         &"atlas_rows")
	_sp(l.atlas_frame,        &"atlas_frame")

func _apply_pbr_params(p: PBRLayer) -> void:
	_sp(p.normal_enabled,     &"normal_enabled")
	_sp(p.normal_texture,     &"normal_texture")
	_sp(p.normal_strength,    &"normal_strength")
	_sp(int(p.specular_mode), &"specular_mode")
	_sp(p.phong_shininess,    &"phong_shininess")
	_sp(p.phong_strength,     &"phong_strength")
	_sp(p.ao_enabled,         &"ao_enabled")
	_sp(p.ao_texture,         &"ao_texture")
	_sp(p.ao_strength,        &"ao_strength")
	_sp(int(p.parallax_mode), &"pom_mode")
	_sp(p.pom_texture,        &"pom_texture")
	_sp(p.pom_depth,          &"pom_depth")
	_sp(p.pom_steps,          &"pom_steps")
	# advanced modules (inc/parallax, inc/occlusion, inc/mapping, inc/normal): the layer property names ARE the shader uniform names
	for n in _PBR_EXTRA:
		_sp(p.get(n), n)
	_sp(int(p.ao_mode),       &"ao_mode")
	_sp(int(p.mapping_mode),  &"mapping_mode")

func _apply_matcap_array() -> void:
	var active: Array[MatcapLayer] = []
	for l in layers:
		if l is MatcapLayer and l.enabled and (l as MatcapLayer).texture != null:
			active.append(l as MatcapLayer)

	_sp(not active.is_empty(), &"matcap_enabled")
	if active.is_empty():
		_sp(0, &"matcap_count")
		return

	_sp(active.size(), &"matcap_count")
	_sp(active[0].pbr_blend, &"matcap_pbr_blend")

	var freeze_mask := 0
	var strengths := PackedFloat32Array()
	strengths.resize(8)
	for i in active.size():
		if active[i].freeze:
			freeze_mask |= (1 << i)
		strengths[i] = active[i].strength
	_sp(freeze_mask, &"matcap_freeze_mask")
	_sp(strengths,   &"matcap_strengths")
	_rebuild_matcap_array(active)

func _rebuild_matcap_array(active: Array[MatcapLayer]) -> void:
	if not _mat or active.is_empty(): return
	var imgs: Array[Image] = []
	var sz_x := 0
	var sz_y := 0
	for layer in active:
		var img := layer.texture.get_image()
		if img == null:
			push_warning("[Mat] texture.get_image() zwróciło null")
			return
		img = img.duplicate()
		if img.is_compressed():
			var derr := img.decompress()
			if derr != OK:
				push_warning("[Mat] img.decompress() failed (%d)" % derr)
				return
		img.convert(Image.FORMAT_RGBA8)
		if sz_x == 0:
			sz_x = img.get_width()
			sz_y = img.get_height()
		elif img.get_width() != sz_x or img.get_height() != sz_y:
			img.resize(sz_x, sz_y)
		imgs.append(img)
	var arr := Texture2DArray.new()
	var err := arr.create_from_images(imgs)
	if err != OK:
		push_error("[Mat] Texture2DArray błąd: %d" % err)
		return
	_sp(arr, &"matcap_array")

# ─── Tools ────────────────────────────────────────────────────────────────────

func _do_refresh() -> void:
	_sync_all()

func _smooth_normals() -> void:
	if not Engine.is_editor_hint(): return
	var meshes := _get_target_meshes()
	if meshes.is_empty():
		push_warning("[Mat] Brak target meshów")
		return
	for mi in meshes:
		if not mi.mesh: continue
		var orig := mi.mesh
		var out := ArrayMesh.new()
		var st := SurfaceTool.new()
		for s in orig.get_surface_count():
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.create_from(orig, s)
			st.generate_normals(false)
			var mat := orig.surface_get_material(s)
			var arr := st.commit_to_arrays()
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			if mat: out.surface_set_material(s, mat)
		mi.mesh = out
		print("[Mat] Smooth normals: %s" % mi.name)
	_sync_all()

func _save_to_res() -> void:
	if not Engine.is_editor_hint(): return
	DirAccess.open("res://").make_dir_recursive("materials")
	var ts := Time.get_ticks_msec()
	for i in layers.size():
		var l := layers[i]
		if l == null: continue
		var path := "res://materials/mat_layer_%d_%d.tres" % [i, ts]
		if ResourceSaver.save(l, path) == OK:
			print("[Mat] Saved layer[%d]: %s" % [i, path])
		else:
			push_error("[Mat] Zapis nieudany: " + path)
	EditorInterface.get_resource_filesystem().scan()
