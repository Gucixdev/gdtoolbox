// mat.gdshader - the Mat uber-shader. This file only orchestrates; every feature lives in inc/:
//
//   common     hashes, noise, voronoi
//   mapping    UV transform, atlas, anti-tiling (stochastic), triplanar
//   normal     bump-from-height, detail normal
//   parallax   parallax occlusion mapping (adaptive layers, bisection, ref plane, self-shadow, DEPTH)
//   occlusion  ambient occlusion: baked / cavity (height) / curvature (normal) / vertex, multi-bounce
//   matcap     matcap + seamless + cel ramp
//   npr        view-space specular, opal iridescence
//
// Standalone shaders that reuse the same modules are in shaders/.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled;

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/mapping.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/normal.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/parallax.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/occlusion.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/matcap.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/npr.gdshaderinc"

// ─── Base ────────────────────────────────────────────────────────────────────
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 16.0) = 0.0;
uniform bool normal_enabled = false;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(0.0, 4.0) = 1.0;

varying vec3 v_world_normal;
varying vec3 v_world_pos;
varying vec3 v_obj_pos;
varying vec3 v_obj_normal;
varying float v_pom_shadow;        // written in fragment(), read by light(): POM self-shadow must dim DIRECT light only

void vertex() {
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_obj_pos = VERTEX;
	v_obj_normal = NORMAL;
}

void fragment() {
	bool tri = mapping_mode != 0;
	vec2 uv = ez_map_uv(UV);

	// Triplanar projection (no UVs). Parallax needs a tangent frame, so it is skipped in this mode.
	vec3 tri_n = normalize(mapping_mode == 2 ? v_obj_normal : v_world_normal);
	vec3 tri_p = (mapping_mode == 2 ? v_obj_pos : v_world_pos) * tri_scale;
	vec3 tri_w = ez_tri_weights(tri_n);

	v_pom_shadow = 1.0;
	if (pom_mode > 0 && !tri) {
		vec3 v_ts = pom_view_tangent(VIEW, TANGENT, BINORMAL, NORMAL);
		PomResult pom = pom_apply(uv, v_ts, length(VERTEX), pom_mode == 2 ? max(pom_refine, 4) : pom_refine);
		uv = pom.uv;
		if (pom_shadow_strength > 0.0) {
			vec3 l_view = normalize((VIEW_MATRIX * vec4(normalize(pom_light_dir), 0.0)).xyz);
			v_pom_shadow = pom_self_shadow(pom, vec3(dot(l_view, TANGENT), dot(l_view, BINORMAL), dot(l_view, NORMAL)));
		}
		if (pom_clip_edges && !atlas_enabled && pom_outside(uv, uv_tiling)) {
			discard;
		}
	}

	// View-space normal (needed for matcap UV and NPR specular)
	vec3 view_n = mat3(VIEW_MATRIX) * v_world_normal;

	// Base albedo
	vec4 base = albedo_color * (tri ? ez_tri_sample(albedo_texture, tri_p, tri_w) : ez_tex(albedo_texture, uv));
	if (detail_albedo_strength > 0.0) {
		vec3 det = texture(detail_albedo, uv * detail_tiling).rgb;
		base.rgb = mix(base.rgb, base.rgb * det * 2.0, detail_albedo_strength);     // overlay-ish: 0.5 grey = no change
	}

	// Normal
	if (normal_enabled) {
		if (tri) {
			vec3 nm = ez_tri_normal(normal_texture, tri_p, tri_n, tri_w, normal_strength);
			NORMAL = mapping_mode == 2 ? normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(nm, 0.0))).xyz) : normalize((VIEW_MATRIX * vec4(nm, 0.0)).xyz);
		} else {
			vec3 nm = ez_tex(normal_texture, uv).rgb;
			if (detail_normal_strength > 0.0) {
				nm = ez_blend_normal(nm, texture(detail_normal, uv * detail_tiling).rgb, detail_normal_strength);
			}
			NORMAL_MAP = nm;
			NORMAL_MAP_DEPTH = normal_strength;
		}
	} else if (bump_strength > 0.0 && !tri) {
		vec3 nm = ez_bump_normal(pom_texture, uv, bump_strength, bump_texel);
		if (detail_normal_strength > 0.0) {
			nm = ez_blend_normal(nm, texture(detail_normal, uv * detail_tiling).rgb, detail_normal_strength);
		}
		NORMAL_MAP = nm;
		NORMAL_MAP_DEPTH = 1.0;
	}

	// Ambient occlusion: baked texture x cavity (height) x curvature (normal) x vertex colour
	float ao_val = 1.0;
	if (ao_enabled) {
		float baked = tri ? ez_tri_sample(ao_texture, tri_p, tri_w).r : ez_tex(ao_texture, uv).r;
		ao_val = mix(1.0, baked, ao_strength);
	}
	if (!tri) {
		if (ao_cavity_strength > 0.0) {
			ao_val *= ao_from_height(pom_texture, uv, ao_cavity_radius, ao_cavity_strength, 0.01, 1.0);
		}
		if (ao_curvature_strength > 0.0 && normal_enabled) {
			ao_val *= ao_from_normal(normal_texture, uv, ao_cavity_radius, ao_curvature_strength);
		}
	}
	if (ao_vertex_strength > 0.0) {
		ao_val *= mix(1.0, ao_vertex(COLOR.r, 1.0), ao_vertex_strength);
	}
	if (ao_mode != 1) {
		base.rgb *= ao_val;                                  // legacy: occlusion painted into albedo (visible without any light)
	}
	if (ao_mode != 0) {
		AO = ao_multibounce_on ? ao_multibounce(ao_val, base.rgb).g : ao_val;
		AO_LIGHT_AFFECT = ao_light_affect;
	}

	// Matcap
	if (matcap_enabled && matcap_count > 0) {
		base.rgb = ez_apply_matcap(base.rgb, view_n, v_world_normal);
	}

	// NPR specular in view space - works without scene lights
	if (specular_mode > 0) {
		base.rgb = ez_npr_specular(base.rgb, view_n);
	}

	// Opal iridescence
	if (opal_enabled) {
		base.rgb = ez_opal(base.rgb, NORMAL, VIEW);
	}

	// Emission additive to ALBEDO - visible without bloom (also in the Compatibility renderer)
	vec3 em = emission.rgb * emission_strength;
	ALBEDO = base.rgb + em;
	EMISSION = em;  // also set EMISSION for bloom when WorldEnvironment has glow
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	ALPHA = base.a;
}

void light() {
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * NdotL * v_pom_shadow;
}
