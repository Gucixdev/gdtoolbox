// parallax.gdshaderinc - Parallax Occlusion Mapping (POM) for Godot 4 spatial shaders.
//
//     vec3 v_ts = pom_view_tangent(VIEW, TANGENT, BINORMAL, NORMAL);   // BEFORE writing NORMAL / NORMAL_MAP
//     PomResult pom = pom_apply(uv, v_ts, length(VERTEX), refine_steps);
//     uv = pom.uv;                                                     // sample every texture with this
//
// Beyond a textbook POM:
//   * layer count adapts to viewing angle and distance (cheap head-on / far away, dense at grazing angles),
//   * linear search + bisection refinement - clean thin ridges without ladder artifacts,
//   * a reference plane (pom_ref_plane) so relief can rise above the surface as well as sink below it,
//   * mip-correct sampling inside the loop (textureGrad with derivatives taken outside it),
//   * optional silhouette clipping, soft self-shadowing, and a correct DEPTH value.
//
// The height map is "white = high". pom_depth is the full relief depth as a fraction of the UV extent; pom_uv_size is how many
// metres one UV unit spans (only used for DEPTH, so intersections with other geometry look right).
#ifndef EZ_PARALLAX_INC
#define EZ_PARALLAX_INC

group_uniforms parallax;
uniform int pom_mode : hint_range(0, 2) = 0;                        // 0 off, 1 POM, 2 smooth POM (bisection refined)
uniform sampler2D pom_texture : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float pom_depth : hint_range(0.0, 0.5, 0.001) = 0.05;
uniform int pom_steps : hint_range(4, 128) = 16;                    // maximum layers (reached at grazing angles)
uniform int pom_min_steps : hint_range(2, 64) = 6;                  // layers when looking straight at the surface
uniform int pom_refine : hint_range(0, 8) = 0;                      // bisection steps; mode 2 uses at least 4
uniform float pom_ref_plane : hint_range(0.0, 1.0, 0.01) = 1.0;     // height that coincides with the real surface (1 = relief sinks in)
uniform bool pom_invert = false;                                    // texture stores depth instead of height
uniform float pom_fade_start = 12.0;                                // metres: relief fades out between start and end
uniform float pom_fade_end = 30.0;
uniform bool pom_clip_edges = false;                                // discard where the parallaxed UV leaves the tile (single quads)
uniform float pom_uv_size = 1.0;
group_uniforms parallax_shadow;
uniform float pom_shadow_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform int pom_shadow_steps : hint_range(4, 32) = 12;
uniform vec3 pom_light_dir = vec3(0.4, 0.8, 0.45);                  // world space, pointing TOWARD the light
group_uniforms;

struct PomResult {
	vec2 uv;           // parallaxed UV
	float depth;       // 0..1 how far down the relief the ray travelled
	float height;      // relief height at the hit, 0..1
	float view_dist;   // extra metres travelled along the view ray (for DEPTH)
};

vec3 pom_view_tangent(vec3 view, vec3 tangent, vec3 binormal, vec3 normal) {
	return normalize(vec3(dot(view, tangent), dot(view, binormal), dot(view, normal)));
}

float _pom_h(vec2 uv, vec2 dx, vec2 dy) {
	float h = textureGrad(pom_texture, uv, dx, dy).r;
	return pom_invert ? 1.0 - h : h;
}

bool pom_outside(vec2 uv, vec2 tiling) {
	return uv.x < 0.0 || uv.y < 0.0 || uv.x > tiling.x || uv.y > tiling.y;
}

PomResult pom_apply(vec2 uv0, vec3 v_ts, float view_distance, int refine_steps) {
	PomResult r;
	r.uv = uv0;
	r.depth = 0.0;
	r.height = 1.0;
	r.view_dist = 0.0;

	float fade = 1.0 - smoothstep(pom_fade_start, max(pom_fade_end, pom_fade_start + 0.001), view_distance);
	float scale = pom_depth * fade;
	if (scale <= 0.00001) {
		return r;
	}

	vec2 dx = dFdx(uv0);                                  // derivatives taken once, outside the loop (uniform control flow)
	vec2 dy = dFdy(uv0);
	float vz = max(v_ts.z, 0.04);
	vec2 shift = v_ts.xy / vz * scale;                    // uv movement for the FULL relief depth, towards the eye

	float lod = clamp(v_ts.z, 0.0, 1.0);
	float layers = mix(float(pom_steps), float(pom_min_steps), lod);
	layers = mix(float(pom_min_steps), layers, fade);
	int n = int(max(layers, 2.0));
	float layer_step = 1.0 / float(n);

	// the ray enters the relief volume at the top (height 1), which sits above the surface by (1 - ref_plane)
	vec2 uv_top = uv0 + shift * (1.0 - pom_ref_plane);

	float d = 0.0;
	float prev_d = 0.0;
	float h_prev = _pom_h(uv_top, dx, dy);
	float h_cur = h_prev;
	bool hit = false;
	for (int i = 0; i < 128; i++) {
		if (i >= n) {
			break;
		}
		h_cur = _pom_h(uv_top - shift * d, dx, dy);
		if (d >= 1.0 - h_cur) {
			hit = true;
			break;
		}
		prev_d = d;
		h_prev = h_cur;
		d += layer_step;
	}
	if (!hit) {
		d = 1.0;
		prev_d = 1.0 - layer_step;
		h_cur = _pom_h(uv_top - shift, dx, dy);
	}

	if (refine_steps > 0) {                               // bisection between prev_d (above the surface) and d (below it)
		float lo = prev_d;
		float hi = d;
		for (int k = 0; k < 8; k++) {
			if (k >= refine_steps) {
				break;
			}
			float mid = 0.5 * (lo + hi);
			float hm = _pom_h(uv_top - shift * mid, dx, dy);
			if (mid >= 1.0 - hm) {
				hi = mid;
			} else {
				lo = mid;
			}
		}
		d = hi;
	} else {                                              // single linear interpolation across the last layer
		float before = (1.0 - h_prev) - prev_d;
		float after = d - (1.0 - h_cur);
		float t = after / max(after + before, 0.00001);
		d = mix(d, prev_d, clamp(t, 0.0, 1.0));
	}

	r.uv = uv_top - shift * d;
	r.depth = d;
	r.height = 1.0 - d;
	r.view_dist = ((d - (1.0 - pom_ref_plane)) * scale * pom_uv_size) / vz;
	return r;
}

// Soft self-shadow: march from the hit point toward the light through the height field. l_ts = light direction in tangent space.
float pom_self_shadow(PomResult hit, vec3 l_ts) {
	if (pom_shadow_strength <= 0.0) {
		return 1.0;
	}
	if (l_ts.z <= 0.02) {
		return 1.0 - pom_shadow_strength;
	}
	vec2 dx = dFdx(hit.uv);
	vec2 dy = dFdy(hit.uv);
	float h0 = hit.height;
	float rise_total = max(1.0 - h0, 0.0001);
	vec2 dir = l_ts.xy / l_ts.z * pom_depth;
	float occ = 0.0;
	for (int i = 1; i < 32; i++) {
		if (i > pom_shadow_steps) {
			break;
		}
		float t = float(i) / float(pom_shadow_steps);
		float ray_h = h0 + rise_total * t;
		float hs = _pom_h(hit.uv + dir * (rise_total * t), dx, dy);
		occ = max(occ, (hs - ray_h) * (1.0 - t));          // nearer occluders cast darker, softer far away
	}
	return 1.0 - clamp(occ * 8.0, 0.0, 1.0) * pom_shadow_strength;
}

// NDC depth for DEPTH of the displaced fragment (vertex_view / view_dir are VERTEX and VIEW).
float pom_depth_value(vec3 vertex_view, vec3 view_dir, float view_dist, mat4 projection) {
	vec3 p = vertex_view - view_dir * view_dist;
	vec4 clip = projection * vec4(p, 1.0);
	float ndc = clip.z / clip.w;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return ndc * 0.5 + 0.5;
#else
	return ndc;
#endif
}

#endif
