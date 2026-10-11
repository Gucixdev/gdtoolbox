// normal.gdshaderinc - normal map helpers: bump-from-height (when you only have a height map) and detail normals.
#ifndef EZ_NORMAL_INC
#define EZ_NORMAL_INC

group_uniforms normal_extra;
uniform float bump_strength : hint_range(0.0, 8.0, 0.01) = 0.0;       // > 0: derive a normal from pom_texture when no normal map is set
uniform float bump_texel = 0.0039;                                   // sampling distance in UV units (~1/texture size)
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_albedo : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float detail_tiling = 6.0;
uniform float detail_normal_strength : hint_range(0.0, 2.0, 0.01) = 0.0;
uniform float detail_albedo_strength : hint_range(0.0, 1.0, 0.01) = 0.0;
group_uniforms;

// tangent-space normal (encoded 0..1) from a height map via central differences
vec3 ez_bump_normal(sampler2D h, vec2 uv, float strength, float texel) {
	float l = textureLod(h, uv - vec2(texel, 0.0), 0.0).r;
	float r = textureLod(h, uv + vec2(texel, 0.0), 0.0).r;
	float d = textureLod(h, uv - vec2(0.0, texel), 0.0).r;
	float u = textureLod(h, uv + vec2(0.0, texel), 0.0).r;
	vec3 n = normalize(vec3((l - r) * strength, (d - u) * strength, 2.0));   // strength 1 = one height unit per texel step
	return n * 0.5 + 0.5;
}

// blend a detail normal (encoded 0..1) onto a base normal (encoded 0..1): reoriented-normal-mapping-lite
vec3 ez_blend_normal(vec3 base_enc, vec3 detail_enc, float strength) {
	vec3 b = base_enc * 2.0 - 1.0;
	vec3 d = detail_enc * 2.0 - 1.0;
	vec3 n = normalize(vec3(b.xy + d.xy * strength, b.z));
	return n * 0.5 + 0.5;
}

#endif
