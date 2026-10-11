// matcap.gdshaderinc - material-capture shading with seamless blending, freezing to world space, and a cel ramp.
// ez_apply_matcap(base, view_n, world_n) returns the new base colour (ramp, invert, albedo tint and pbr blend included).
#ifndef EZ_MATCAP_INC
#define EZ_MATCAP_INC

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"

group_uniforms matcap;
uniform bool matcap_enabled = false;
uniform sampler2DArray matcap_array : filter_linear_mipmap, repeat_enable;
uniform int matcap_count = 0;
uniform float matcap_strengths[8];
uniform int matcap_freeze_mask = 0;
uniform float matcap_pbr_blend : hint_range(0.0, 1.0) = 1.0;
uniform bool mc_invert = false;
group_uniforms matcap_seamless;
uniform bool seamless_enabled = false;
uniform int seamless_scale : hint_range(1, 16) = 4;
uniform int seamless_mode = 0;
uniform float seamless_strength : hint_range(0.0, 1.0) = 0.3;
group_uniforms matcap_ramp;
uniform bool ramp_enabled = false;
uniform int ramp_count : hint_range(2, 8) = 3;
uniform float ramp_smooth : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

vec3 ez_apply_matcap(vec3 base_rgb, vec3 view_n, vec3 world_n) {
	vec2 view_uv = view_n.xy * 0.5 + 0.5;
	vec2 world_uv = world_n.xy * 0.5 + 0.5;
	vec3 mc_accum = vec3(0.0);
	float weight_sum = 0.0;
	for (int i = 0; i < matcap_count; i++) {
		bool frozen = (matcap_freeze_mask & (1 << i)) != 0;
		vec2 mc_uv = frozen ? world_uv : view_uv;
		vec3 mc;
		if (seamless_enabled) {
			bool do_vor   = (seamless_mode == 0 || seamless_mode == 2);
			bool do_alpha = (seamless_mode == 1 || seamless_mode == 2);

			// VORONOI = triplanar.
			// KEY: use the same normal space as mc_uv - world for freeze, view for live.
			// This prevents flickering when the camera moves.
			if (do_vor) {
				vec3 n = frozen ? world_n : view_n;
				// smooth exponent range 2-8 - never flickers, no sudden transitions
				float sharp = 2.0 + seamless_strength * 6.0;
				vec3 w = pow(abs(n), vec3(sharp));
				w /= (w.x + w.y + w.z + 0.001);
				vec2 uv_z = n.xy * 0.5 + 0.5;
				vec2 uv_y = n.xz * 0.5 + 0.5;
				vec2 uv_x = n.yz * 0.5 + 0.5;
				vec3 mc_z = texture(matcap_array, vec3(uv_z, float(i))).rgb;
				vec3 mc_y = texture(matcap_array, vec3(uv_y, float(i))).rgb;
				vec3 mc_x = texture(matcap_array, vec3(uv_x, float(i))).rgb;
				mc = mc_z * w.z + mc_y * w.y + mc_x * w.x;
			} else {
				mc = texture(matcap_array, vec3(mc_uv, float(i))).rgb;
			}

			// ALPHA_BLEND: near UV edges only, blend with a voronoi-rotated sample.
			// Center stays sharp; seam area gets softened.
			if (do_alpha) {
				vec2 edge_d = abs(mc_uv - 0.5) * 2.0;
				float near_seam = smoothstep(
					max(0.0, 0.7 - seamless_strength * 0.4), 1.0,
					max(edge_d.x, edge_d.y));
				if (near_seam > 0.001) {
					float period = float(seamless_scale);
					float h = _voronoi(world_uv * period, period).y;
					float angle = (h - 0.5) * PI * seamless_strength;
					float cs = cos(angle), sn = sin(angle);
					vec2 mc_alt = clamp(vec2(
						cs * (mc_uv.x - 0.5) - sn * (mc_uv.y - 0.5) + 0.5,
						sn * (mc_uv.x - 0.5) + cs * (mc_uv.y - 0.5) + 0.5
					), 0.0, 1.0);
					vec3 mc_alt_col = texture(matcap_array, vec3(mc_alt, float(i))).rgb;
					mc = mix(mc, mc_alt_col, near_seam * 0.5);
				}
			}
		} else {
			mc = texture(matcap_array, vec3(mc_uv, float(i))).rgb;
		}
		float w = matcap_strengths[i];
		mc_accum += mc * w;
		weight_sum += w;
	}
	if (weight_sum > 0.0) mc_accum /= weight_sum;

	// Ramp: quantize matcap luminance (cel-shading, no lights needed)
	if (ramp_enabled) {
		float lum = dot(mc_accum, vec3(0.299, 0.587, 0.114));
		float fc = float(ramp_count);
		float stepped = clamp(floor(lum * fc) / max(fc - 1.0, 1.0), 0.0, 1.0);
		mc_accum *= mix(stepped, lum, ramp_smooth) / max(lum, 0.001);
	}

	if (mc_invert) mc_accum = 1.0 - mc_accum;

	// Albedo tints the matcap
	mc_accum *= base_rgb;

	return mix(base_rgb, mc_accum, matcap_pbr_blend);
}

#endif
