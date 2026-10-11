// occlusion.gdshaderinc - ambient-occlusion building blocks for spatial shaders.
//
// These produce a 0..1 occlusion factor (1 = open, 0 = fully occluded) you feed into Godot's AO / AO_LIGHT_AFFECT outputs, so it
// only dims AMBIENT light (plus a controllable share of direct light) instead of painting darkness into the albedo.
//
//   ao_from_height     cavity AO from a height map: horizon-style sampling of nearby texels that rise above this one
//   ao_from_normal     curvature AO from a normal map: concave = dark, convex = bright
//   ao_vertex          vertex-colour AO with a contrast curve
//   ao_multibounce     Jimenez multi-bounce: AO on bright albedo is not as dark as AO on dark albedo (colour-aware)
//   ao_specular        Lagarde specular occlusion: spec reflections are occluded depending on roughness and view angle
//
// All sampling uses textureLod so it is legal inside branches/loops.
#ifndef EZ_OCCLUSION_INC
#define EZ_OCCLUSION_INC

group_uniforms occlusion;
uniform bool ao_enabled = false;
uniform sampler2D ao_texture : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float ao_strength : hint_range(0.0, 1.0) = 1.0;
uniform int ao_mode : hint_range(0, 2) = 0;                           // 0 multiply albedo (legacy, works with no lights), 1 ambient AO output, 2 both
uniform float ao_cavity_strength : hint_range(0.0, 4.0, 0.01) = 0.0;  // from the height map (pom_texture)
uniform float ao_cavity_radius : hint_range(0.0005, 0.05, 0.0005) = 0.006;
uniform float ao_curvature_strength : hint_range(0.0, 4.0, 0.01) = 0.0; // from the normal map
uniform float ao_vertex_strength : hint_range(0.0, 1.0, 0.01) = 0.0;  // vertex colour (COLOR.r) AO, e.g. baked in Blender
uniform float ao_light_affect : hint_range(0.0, 1.0, 0.01) = 0.0;     // share of direct light that AO also dims (ambient mode)
uniform bool ao_multibounce_on = false;
group_uniforms;

// samples: ring taps (8 is plenty); radius in UV units; strength scales the darkening; bias ignores tiny height differences.
float ao_from_height(sampler2D height_tex, vec2 uv, float radius, float strength, float bias, float height_range) {
	float h0 = textureLod(height_tex, uv, 0.0).r;
	float occ = 0.0;
	const int N = 8;
	for (int i = 0; i < N; i++) {
		float a = 6.2831853 * float(i) / float(N);
		vec2 dir = vec2(cos(a), sin(a));
		// two rings: near taps catch crevices, far taps catch wide pockets
		float h1 = textureLod(height_tex, uv + dir * radius * 0.5, 0.0).r;
		float h2 = textureLod(height_tex, uv + dir * radius, 0.0).r;
		float o1 = max(h1 - h0 - bias, 0.0);
		float o2 = max(h2 - h0 - bias, 0.0) * 0.7;
		occ += max(o1, o2);
	}
	occ = occ / float(N) * height_range * 1.5;
	return clamp(1.0 - occ * strength, 0.0, 1.0);
}

// normal_tex: tangent-space normal map. Curvature = divergence of the normal field; radius in UV units.
float ao_from_normal(sampler2D normal_tex, vec2 uv, float radius, float strength) {
	vec2 px = vec2(radius);
	vec3 nl = textureLod(normal_tex, uv - vec2(px.x, 0.0), 0.0).xyz * 2.0 - 1.0;
	vec3 nr = textureLod(normal_tex, uv + vec2(px.x, 0.0), 0.0).xyz * 2.0 - 1.0;
	vec3 nd = textureLod(normal_tex, uv - vec2(0.0, px.y), 0.0).xyz * 2.0 - 1.0;
	vec3 nu = textureLod(normal_tex, uv + vec2(0.0, px.y), 0.0).xyz * 2.0 - 1.0;
	float curvature = (nr.x - nl.x) + (nu.y - nd.y);        // > 0 convex (bulging), < 0 concave (a pit/crease)
	return clamp(1.0 + min(curvature, 0.0) * strength, 0.0, 1.0);
}

float ao_vertex(float vertex_ao, float contrast) {
	return clamp(pow(clamp(vertex_ao, 0.0, 1.0), contrast), 0.0, 1.0);
}

// "Practical Realtime Strategies for Accurate Indirect Occlusion" (GTAO), multi-bounce approximation.
vec3 ao_multibounce(float ao, vec3 albedo) {
	vec3 a = 2.0404 * albedo - vec3(0.3324);
	vec3 b = -4.7951 * albedo + vec3(0.6417);
	vec3 c = 2.7552 * albedo + vec3(0.6903);
	return max(vec3(ao), ((vec3(ao) * a + b) * ao + c) * ao);
}

// "Moving Frostbite to PBR": specular occlusion from diffuse AO.
float ao_specular(float n_dot_v, float ao, float roughness) {
	return clamp(pow(n_dot_v + ao, exp2(-16.0 * roughness - 1.0)) - 1.0 + ao, 0.0, 1.0);
}

#endif
