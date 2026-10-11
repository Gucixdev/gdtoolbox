// mapping.gdshaderinc - how a surface point finds its texel: UV transform, atlas, anti-tiling, triplanar.
//
//   ez_map_uv(UV)                      tiling / offset / rotation / scroll, then atlas frame (identity at the defaults)
//   ez_tex(tex, uv)                    texture() or, with uv_stochastic, a repetition-free 4-tap sample
//   ez_tri_weights / ez_tri_sample     triplanar projection: no UVs needed, works on any mesh
//   ez_tri_normal                      whiteout-blended triplanar normal map (returns the shading normal in the projection space)
#ifndef EZ_MAPPING_INC
#define EZ_MAPPING_INC

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"

group_uniforms mapping;
uniform int mapping_mode : hint_range(0, 2) = 0;               // 0 UV, 1 triplanar (world space), 2 triplanar (object space)
uniform vec2 uv_tiling = vec2(1.0);
uniform vec2 uv_offset = vec2(0.0);
uniform float uv_rotation : hint_range(-180.0, 180.0, 0.1) = 0.0;   // degrees around the centre of the tile
uniform vec2 uv_scroll = vec2(0.0);                             // tiles per second
uniform bool uv_stochastic = false;                             // hide texture repetition (breaks the tile grid with random offsets)
uniform float tri_scale = 0.25;                                 // triplanar texture repeats per metre
uniform float tri_sharpness : hint_range(1.0, 16.0) = 4.0;
group_uniforms atlas;
uniform bool atlas_enabled = false;
uniform int atlas_columns : hint_range(1, 64) = 4;
uniform int atlas_rows : hint_range(1, 64) = 4;
uniform int atlas_frame : hint_range(0, 4095) = 0;
group_uniforms;

vec2 ez_map_uv(vec2 uv) {
	if (uv_rotation != 0.0) {
		float a = radians(uv_rotation);
		float c = cos(a);
		float s = sin(a);
		vec2 d = uv - 0.5;
		uv = vec2(c * d.x - s * d.y, s * d.x + c * d.y) + 0.5;
	}
	uv = uv * uv_tiling + uv_offset + uv_scroll * TIME;
	if (atlas_enabled) {
		float col = float(atlas_frame % atlas_columns);
		float row = float(atlas_frame / atlas_columns);
		uv = (uv + vec2(col, row)) / vec2(float(atlas_columns), float(atlas_rows));
	}
	return uv;
}

// Offset-only stochastic sampling (no rotation/mirroring, so it is valid for normal maps too). Derivatives are taken from the
// continuous uv so mip selection never jumps at cell borders.
vec4 ez_tex_stochastic(sampler2D tex, vec2 uv) {
	vec2 iuv = floor(uv);
	vec2 fuv = fract(uv);
	vec2 dx = dFdx(uv);
	vec2 dy = dFdy(uv);
	vec4 a = textureGrad(tex, uv + ez_hash42(iuv).xy, dx, dy);
	vec4 b = textureGrad(tex, uv + ez_hash42(iuv + vec2(1.0, 0.0)).xy, dx, dy);
	vec4 c = textureGrad(tex, uv + ez_hash42(iuv + vec2(0.0, 1.0)).xy, dx, dy);
	vec4 d = textureGrad(tex, uv + ez_hash42(iuv + vec2(1.0, 1.0)).xy, dx, dy);
	vec2 w = smoothstep(0.25, 0.75, fuv);
	return mix(mix(a, b, w.x), mix(c, d, w.x), w.y);
}

vec4 ez_tex(sampler2D tex, vec2 uv) {
	if (uv_stochastic) {
		return ez_tex_stochastic(tex, uv);
	}
	return texture(tex, uv);
}

vec3 ez_tri_weights(vec3 n) {
	vec3 w = pow(abs(n), vec3(tri_sharpness));
	return w / (w.x + w.y + w.z + 0.0001);
}

vec4 ez_tri_sample(sampler2D tex, vec3 p, vec3 w) {
	return texture(tex, p.zy) * w.x + texture(tex, p.xz) * w.y + texture(tex, p.xy) * w.z;
}

vec3 ez_tri_normal(sampler2D tex, vec3 p, vec3 n, vec3 w, float strength) {
	vec3 tx = texture(tex, p.zy).xyz * 2.0 - 1.0;
	vec3 ty = texture(tex, p.xz).xyz * 2.0 - 1.0;
	vec3 tz = texture(tex, p.xy).xyz * 2.0 - 1.0;
	tx.xy *= strength;
	ty.xy *= strength;
	tz.xy *= strength;
	vec3 nx = vec3(tx.xy + n.zy, abs(tx.z) * n.x);
	vec3 ny = vec3(ty.xy + n.xz, abs(ty.z) * n.y);
	vec3 nz = vec3(tz.xy + n.xy, abs(tz.z) * n.z);
	return normalize(nx.zyx * w.x + ny.xzy * w.y + nz.xyz * w.z);
}

#endif
