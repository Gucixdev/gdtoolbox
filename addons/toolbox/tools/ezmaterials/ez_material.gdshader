shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_disabled;

// ─── Base ────────────────────────────────────────────────────────────────────
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;

// ─── Matcap ──────────────────────────────────────────────────────────────────
uniform bool matcap_enabled = false;
uniform sampler2DArray matcap_array : filter_linear_mipmap, repeat_enable;
uniform int matcap_count = 0;
uniform float matcap_strengths[8];
uniform int matcap_freeze_mask = 0;
uniform float matcap_pbr_blend : hint_range(0.0, 1.0) = 1.0;

// ─── Seamless ─────────────────────────────────────────────────────────────────
// 0=VORONOI  1=ALPHA_BLEND  2=BOTH
uniform bool seamless_enabled = false;
uniform int seamless_scale : hint_range(1, 16) = 4;
uniform int seamless_mode = 0;
uniform float seamless_strength : hint_range(0.0, 1.0) = 0.3;

// ─── Layer misc ──────────────────────────────────────────────────────────────
uniform bool mc_invert = false;

// ─── Material ────────────────────────────────────────────────────────────────
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength : hint_range(0.0, 16.0) = 0.0;
uniform bool normal_enabled = false;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(0.0, 4.0) = 1.0;

// ─── Occlusion ───────────────────────────────────────────────────────────────
uniform bool ao_enabled = false;
uniform sampler2D ao_texture : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float ao_strength : hint_range(0.0, 1.0) = 1.0;
uniform int pom_mode = 0;
uniform sampler2D pom_texture : filter_linear_mipmap, repeat_enable, hint_default_black;
uniform float pom_depth : hint_range(0.0, 0.5) = 0.05;
uniform int pom_steps : hint_range(4, 128) = 16;

// ─── Ramp ────────────────────────────────────────────────────────────────────
uniform bool ramp_enabled = false;
uniform int ramp_count : hint_range(2, 8) = 3;
uniform float ramp_smooth : hint_range(0.0, 1.0) = 0.0;

// ─── Specular ────────────────────────────────────────────────────────────────
// 0=none, 1=Blinn-Phong, 2=Phong, 3=Toon
uniform int specular_mode = 0;
uniform float phong_shininess : hint_range(1.0, 512.0) = 32.0;
uniform float phong_strength : hint_range(0.0, 2.0) = 0.5;

// ─── Opal ────────────────────────────────────────────────────────────────────
uniform bool opal_enabled = false;
uniform float opal_strength : hint_range(0.0, 1.0) = 0.5;
uniform float opal_fresnel_power : hint_range(0.5, 8.0) = 2.0;
uniform float opal_hue_shift : hint_range(0.0, 1.0) = 0.0;
uniform float opal_saturation : hint_range(0.0, 1.0) = 1.0;
uniform vec4 opal_tint : source_color = vec4(1.0);
uniform sampler2D opal_texture : filter_linear_mipmap, repeat_disable, hint_default_black;
uniform bool opal_use_texture = false;
uniform bool opal_additive = false;

// ─── Atlas ───────────────────────────────────────────────────────────────────
uniform bool atlas_enabled = false;
uniform int atlas_columns : hint_range(1, 64) = 4;
uniform int atlas_rows : hint_range(1, 64) = 4;
uniform int atlas_frame : hint_range(0, 4095) = 0;

varying vec3 v_world_normal;

// ─── Seamless voronoi (computed in shader, no texture needed) ─────────────────
vec2 _vor_h(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(abs(sin(p) * 43758.5453));
}
// Returns vec2(cell_distance 0-1, cell_hash 0-1), seamless with given period
vec2 _voronoi(vec2 p, float period) {
	vec2 ip = floor(p);
	vec2 fp = fract(p);
	float d = 8.0;
	float bh = 0.0;
	for (int ny = -1; ny <= 1; ny++) {
		for (int nx = -1; nx <= 1; nx++) {
			vec2 nb = vec2(float(nx), float(ny));
			vec2 cw = mod(ip + nb + period * 128.0, period);
			vec2 pt = 0.5 + 0.5 * sin(TAU * _vor_h(cw));
			vec2 dv = nb + pt - fp;
			float dist = dot(dv, dv);
			if (dist < d) { d = dist; bh = pt.x; }
		}
	}
	return vec2(clamp(sqrt(d) / 0.75, 0.0, 1.0), bh);
}

void vertex() {
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 hsv2rgb(float h, float s, float v) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(vec3(h) + K.xyz) * 6.0 - K.www);
	return v * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), s);
}

void fragment() {
	vec2 uv = UV;

	if (atlas_enabled) {
		float col = float(atlas_frame % atlas_columns);
		float row = float(atlas_frame / atlas_columns);
		uv = (uv + vec2(col, row)) / vec2(float(atlas_columns), float(atlas_rows));
	}

	if (pom_mode > 0) {
		vec3 vts = normalize(vec3(dot(VIEW, TANGENT), dot(VIEW, BINORMAL), dot(VIEW, NORMAL)));
		float step_size = pom_depth / float(pom_steps);
		vec2 delta = -vts.xy / max(vts.z, 0.001) * step_size;
		vec2 off = vec2(0.0);
		vec2 prev_off = vec2(0.0);
		float cur_d = 0.0;
		float prev_h = 1.0;
		for (int i = 0; i < pom_steps; i++) {
			float h = texture(pom_texture, uv + off).r;
			if (cur_d >= (1.0 - h) * pom_depth) {
				if (pom_mode == 2) {
					float e_prev = (cur_d - step_size) - (1.0 - prev_h) * pom_depth;
					float e_curr = cur_d - (1.0 - h) * pom_depth;
					float t = clamp(-e_prev / (e_curr - e_prev), 0.0, 1.0);
					off = mix(prev_off, off, t);
				}
				break;
			}
			prev_off = off;
			prev_h = h;
			off += delta;
			cur_d += step_size;
		}
		uv += off;
	}

	// View-space normal (needed for matcap UV and NPR specular)
	vec3 view_n = mat3(VIEW_MATRIX) * v_world_normal;

	// Base albedo
	vec4 base = albedo_color * texture(albedo_texture, uv);

	if (normal_enabled) {
		NORMAL_MAP = texture(normal_texture, uv).rgb;
		NORMAL_MAP_DEPTH = normal_strength;
	}

	if (ao_enabled) {
		float ao_val = mix(1.0, texture(ao_texture, uv).r, ao_strength);
		base.rgb *= ao_val;
	}

	// Matcap
	if (matcap_enabled && matcap_count > 0) {
		vec2 view_uv = view_n.xy * 0.5 + 0.5;
		vec2 world_uv = v_world_normal.xy * 0.5 + 0.5;
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
				// KEY: use the same normal space as mc_uv — world for freeze, view for live.
				// This prevents flickering when the camera moves.
				if (do_vor) {
					vec3 n = frozen ? v_world_normal : view_n;
					// smooth exponent range 2–8 — never flickers, no sudden transitions
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
		mc_accum *= base.rgb;

		base.rgb = mix(base.rgb, mc_accum, matcap_pbr_blend);
	}

	// NPR Specular in view-space — works without scene lights
	if (specular_mode > 0) {
		vec3 fake_light = normalize(vec3(0.35, 0.5, 0.8));
		float spec = 0.0;
		if (specular_mode == 1) {
			vec3 h = normalize(fake_light + vec3(0.0, 0.0, 1.0));
			spec = pow(max(dot(view_n, h), 0.0), phong_shininess);
		} else if (specular_mode == 2) {
			vec3 r = reflect(-fake_light, view_n);
			spec = pow(max(dot(r, vec3(0.0, 0.0, 1.0)), 0.0), phong_shininess);
		}
		base.rgb += vec3(spec * phong_strength);
	}

	// Opal iridescence
	if (opal_enabled) {
		float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), opal_fresnel_power);
		vec3 iri;
		if (opal_use_texture) {
			iri = texture(opal_texture, vec2(fract(f + opal_hue_shift), 0.5)).rgb;
		} else {
			iri = hsv2rgb(fract(f * 0.8 + opal_hue_shift), opal_saturation, 1.0);
		}
		iri *= opal_tint.rgb;
		float blend = opal_strength * f;
		if (opal_additive) {
			base.rgb += iri * blend;
		} else {
			base.rgb = mix(base.rgb, iri, blend);
		}
	}

	// Emission additive to ALBEDO — visible in compatibility renderer without bloom
	vec3 em = emission.rgb * emission_strength;
	ALBEDO = base.rgb + em;
	EMISSION = em;  // also set EMISSION for bloom when WorldEnvironment has glow
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	ALPHA = base.a;
}

void light() {
	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * NdotL;
}
