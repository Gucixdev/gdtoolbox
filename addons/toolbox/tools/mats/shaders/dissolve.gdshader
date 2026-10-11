// dissolve.gdshader - noise dissolve with a glowing edge. Drive `amount` 0..1 from an AnimPlayer/tween/script.
// Direction mode makes it sweep along an axis (a scan/materialise effect) instead of random burn-through.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"

uniform vec4 albedo_color : source_color = vec4(0.8);
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float roughness : hint_range(0.0, 1.0) = 0.7;
uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale = 6.0;
uniform float edge_width : hint_range(0.0, 0.3) = 0.06;
uniform vec4 edge_color : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float edge_emission : hint_range(0.0, 16.0) = 6.0;
uniform bool directional = false;
uniform vec3 direction = vec3(0.0, 1.0, 0.0);               // object space sweep axis
uniform float direction_blend : hint_range(0.0, 1.0) = 0.35;  // 0 = pure sweep, 1 = pure noise
uniform vec2 height_range = vec2(-1.0, 1.0);                 // object-space extent along `direction` for the sweep

varying vec3 v_obj;

void vertex() {
	v_obj = VERTEX;
}

float fbm3(vec3 p) {
	return ez_vnoise(p) * 0.5 + ez_vnoise(p * 2.03) * 0.3 + ez_vnoise(p * 4.1) * 0.2;
}

void fragment() {
	float n = fbm3(v_obj * noise_scale);
	if (directional) {
		float t = (dot(v_obj, normalize(direction)) - height_range.x) / max(height_range.y - height_range.x, 0.0001);
		n = mix(clamp(t, 0.0, 1.0), n, direction_blend);
	}
	float threshold = mix(-edge_width, 1.0 + edge_width, amount);
	float d = n - threshold;
	if (d < 0.0) {
		discard;
	}
	vec3 albedo = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	float edge = 1.0 - smoothstep(0.0, edge_width, d);
	ALBEDO = mix(albedo, edge_color.rgb, edge);
	EMISSION = edge_color.rgb * edge * edge_emission;
	ROUGHNESS = roughness;
}
