// triplanar_pbr.gdshader - world/object-space triplanar PBR with a top layer (snow/moss/dust) blended over a side layer (rock) by
// surface slope and noise, whiteout-blended normals, no UVs needed. Works on any mesh, including terrain and procedural geometry.
// Projection maths lives in inc/mapping.gdshaderinc (tri_scale, tri_sharpness).
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"
#include "res://addons/toolbox/tools/mats/inc/mapping.gdshaderinc"

group_uniforms side_layer;
uniform sampler2D side_albedo : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform sampler2D side_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 side_tint : source_color = vec4(0.55, 0.52, 0.5, 1.0);
uniform float side_roughness : hint_range(0.0, 1.0) = 0.85;
group_uniforms top_layer;
uniform sampler2D top_albedo : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform sampler2D top_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform vec4 top_tint : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform float top_roughness : hint_range(0.0, 1.0) = 0.6;
group_uniforms top_blend;
uniform float normal_strength : hint_range(0.0, 3.0) = 1.0;
uniform float top_amount : hint_range(0.0, 1.0) = 0.5;       // how much of the surface the top layer covers
uniform float top_sharpness : hint_range(0.5, 12.0) = 5.0;
uniform float noise_scale = 0.35;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.35;
group_uniforms;

varying vec3 v_pos;
varying vec3 v_nrm;

void vertex() {
	if (mapping_mode == 2) {
		v_pos = VERTEX;
		v_nrm = NORMAL;
	} else {
		v_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
		v_nrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	}
}

void fragment() {
	vec3 n = normalize(v_nrm);
	vec3 w = ez_tri_weights(n);
	vec3 p = v_pos * tri_scale;

	float cover = n.y * 0.5 + 0.5;                                  // 1 = facing up (object space: up of the mesh)
	cover += (ez_vnoise(v_pos * noise_scale) - 0.5) * noise_strength * 2.0;
	float top = smoothstep(0.0, 1.0, clamp((cover - (1.0 - top_amount)) * top_sharpness + 0.5, 0.0, 1.0));

	ALBEDO = mix(ez_tri_sample(side_albedo, p, w).rgb * side_tint.rgb, ez_tri_sample(top_albedo, p, w).rgb * top_tint.rgb, top);
	ROUGHNESS = mix(side_roughness, top_roughness, top);

	vec3 nm = normalize(mix(ez_tri_normal(side_normal, p, n, w, normal_strength), ez_tri_normal(top_normal, p, n, w, normal_strength), top));
	if (mapping_mode == 2) {
		NORMAL = normalize((VIEW_MATRIX * (MODEL_MATRIX * vec4(nm, 0.0))).xyz);
	} else {
		NORMAL = normalize((VIEW_MATRIX * vec4(nm, 0.0)).xyz);
	}
}
