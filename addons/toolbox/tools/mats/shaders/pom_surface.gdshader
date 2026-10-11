// pom_surface.gdshader - standalone PBR surface with parallax occlusion mapping, self-shadowing and layered ambient occlusion.
// Uses the same modules as ez_material.gdshader (inc/), but with the engine's real PBR lighting instead of the NPR/matcap path,
// and with DEPTH written so other geometry intersects the DISPLACED surface (not the flat quad).
// Textures: albedo, tangent-space normal, height (white = high; drives parallax + cavity AO), optional roughness / baked AO.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/mapping.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/normal.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/parallax.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/occlusion.gdshaderinc"

group_uniforms surface;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(0.0, 4.0, 0.01) = 1.0;
uniform sampler2D roughness_texture : hint_roughness_r, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;
group_uniforms;

void fragment() {
	vec2 uv = ez_map_uv(UV);
	vec3 v_ts = pom_view_tangent(VIEW, TANGENT, BINORMAL, NORMAL);
	PomResult pom = pom_apply(uv, v_ts, length(VERTEX), pom_refine);
	uv = pom.uv;
	if (pom_clip_edges && pom_outside(uv, uv_tiling)) {
		discard;
	}

	vec3 albedo = albedo_color.rgb * ez_tex(albedo_texture, uv).rgb;
	ALBEDO = albedo;
	ROUGHNESS = roughness * texture(roughness_texture, uv).r;
	METALLIC = metallic;
	NORMAL_MAP = ez_tex(normal_texture, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;

	// ambient occlusion: baked x cavity (height) x curvature (normal) x vertex colour
	float ao = ao_enabled ? mix(1.0, texture(ao_texture, uv).r, ao_strength) : 1.0;
	if (ao_cavity_strength > 0.0) {
		ao *= ao_from_height(pom_texture, uv, ao_cavity_radius, ao_cavity_strength, 0.01, 1.0);
	}
	if (ao_curvature_strength > 0.0) {
		ao *= ao_from_normal(normal_texture, uv, ao_cavity_radius, ao_curvature_strength);
	}
	if (ao_vertex_strength > 0.0) {
		ao *= mix(1.0, ao_vertex(COLOR.r, 1.0), ao_vertex_strength);
	}

	// self-shadow: light direction into tangent space
	vec3 l_view = normalize((VIEW_MATRIX * vec4(normalize(pom_light_dir), 0.0)).xyz);
	vec3 l_ts = vec3(dot(l_view, TANGENT), dot(l_view, BINORMAL), dot(l_view, NORMAL));
	float shadow = pom_self_shadow(pom, l_ts);

	float occlusion = ao * shadow;
	AO = ao_multibounce_on ? ao_multibounce(occlusion, albedo).g : occlusion;
	AO_LIGHT_AFFECT = max(ao_light_affect, 1.0 - shadow);       // a shadow must dim direct light fully, not just ambient

	DEPTH = pom_depth_value(VERTEX, VIEW, pom.view_dist, PROJECTION_MATRIX);
}
