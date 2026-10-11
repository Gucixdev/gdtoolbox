// ssao_post.gdshader - screen-space ambient occlusion as a full-screen post-process, for renderers with no built-in SSAO
// (Compatibility, and Mobile). Put a QuadMesh (size 2x2, flip_faces off) on a MeshInstance3D under the camera with this material and
// `extra_cull_margin` large - or just add the SSAOPost node, which does exactly that.
//
// Hemisphere sampling around a normal reconstructed from depth (edge-aware), per-pixel rotated kernel, range check so distant
// geometry doesn't darken near objects, distance fade, and "luminance protect" so bright/emissive pixels aren't smeared dark.
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;

group_uniforms ssao;
uniform float radius : hint_range(0.05, 4.0, 0.01) = 0.7;            // metres
uniform float intensity : hint_range(0.0, 4.0, 0.01) = 1.2;
uniform float power : hint_range(0.5, 4.0, 0.01) = 1.4;
uniform float bias : hint_range(0.0, 0.2, 0.001) = 0.02;
uniform int samples : hint_range(4, 32) = 14;
uniform float fade_start = 25.0;
uniform float fade_end = 60.0;
uniform float luminance_protect : hint_range(0.0, 1.0, 0.01) = 0.6;
uniform float strength : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform bool temporal_noise = false;                                  // vary the kernel per frame: TAA / the eye average the grain away
uniform bool debug_ao_only = false;
group_uniforms;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float ign(vec2 p) {                                                    // interleaved gradient noise
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

vec3 view_pos(vec2 suv, mat4 inv_proj) {
	float d = textureLod(depth_tex, suv, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(suv, d) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(suv * 2.0 - 1.0, d);
#endif
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return v.xyz / v.w;
}

bool is_sky(vec2 suv) {
	float d = textureLod(depth_tex, suv, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	return d >= 0.99999;
#else
	return d <= 0.00001;
#endif
}

// Occlusion factor 0..1 for the pixel at `suv` (1 = open). Lives in a function because Godot forbids `return` in fragment().
float ssao(vec2 suv, vec2 frag, vec2 viewport, mat4 proj, mat4 inv_proj) {
	if (is_sky(suv)) {
		return 1.0;
	}
	vec2 px = 1.0 / viewport;
	vec3 p = view_pos(suv, inv_proj);

	// edge-aware normal: pick the smaller depth difference on each axis (no halos on silhouettes)
	vec3 pl = view_pos(suv - vec2(px.x, 0.0), inv_proj);
	vec3 pr = view_pos(suv + vec2(px.x, 0.0), inv_proj);
	vec3 pd = view_pos(suv - vec2(0.0, px.y), inv_proj);
	vec3 pu = view_pos(suv + vec2(0.0, px.y), inv_proj);
	vec3 dx = abs(pl.z - p.z) < abs(pr.z - p.z) ? p - pl : pr - p;
	vec3 dy = abs(pd.z - p.z) < abs(pu.z - p.z) ? p - pd : pu - p;
	vec3 n = normalize(cross(dx, dy));
	if (dot(n, -p) < 0.0) {
		n = -n;                                                         // always face the camera
	}

	// per-pixel rotated tangent frame
	float ang = ign(frag) * 6.2831853;
	if (temporal_noise) {
		ang += fract(floor(TIME * 60.0) * 0.61803399) * 6.2831853;
	}
	vec3 rnd = vec3(cos(ang), sin(ang), 0.0);
	vec3 t = normalize(rnd - n * dot(rnd, n));
	vec3 b = cross(n, t);

	float occ = 0.0;
	int cnt = 0;
	for (int i = 0; i < 32; i++) {
		if (i >= samples) {
			break;
		}
		float fi = (float(i) + 0.5) / float(samples);
		// golden-angle spiral over a cosine-weighted hemisphere
		float phi = float(i) * 2.39996323 + ang;
		float r = sqrt(fi);
		vec3 h = vec3(cos(phi) * r, sin(phi) * r, sqrt(max(1.0 - fi, 0.0)));
		float scale = mix(0.15, 1.0, fi * fi);                          // more taps close to the point
		vec3 sp = p + (t * h.x + b * h.y + n * h.z) * radius * scale;

		vec4 cs = proj * vec4(sp, 1.0);
		vec2 s_uv = cs.xy / cs.w * 0.5 + 0.5;
		if (s_uv.x < 0.0 || s_uv.y < 0.0 || s_uv.x > 1.0 || s_uv.y > 1.0) {
			continue;
		}
		vec3 scene = view_pos(s_uv, inv_proj);
		// view space looks down -Z: a scene point with larger z is closer to the camera than the sample = it occludes it
		float occluded = (scene.z >= sp.z + bias) ? 1.0 : 0.0;
		float range = smoothstep(0.0, 1.0, radius / max(abs(p.z - scene.z), 0.0001));
		occ += occluded * range;
		cnt++;
	}
	float ao = 1.0 - occ / float(max(cnt, 1)) * intensity;
	ao = pow(clamp(ao, 0.0, 1.0), power);
	return mix(ao, 1.0, smoothstep(fade_start, max(fade_end, fade_start + 0.01), length(p)));
}

void fragment() {
	vec3 base = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float ao = ssao(SCREEN_UV, FRAGCOORD.xy, VIEWPORT_SIZE, PROJECTION_MATRIX, INV_PROJECTION_MATRIX);
	float lum = dot(base, vec3(0.2126, 0.7152, 0.0722));
	ao = mix(ao, 1.0, smoothstep(0.55, 1.2, lum) * luminance_protect);   // bright / emissive pixels are not smeared dark
	ao = mix(1.0, ao, strength);
	ALBEDO = debug_ao_only ? vec3(ao) : base * ao;
}
