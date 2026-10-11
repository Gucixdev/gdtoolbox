// common.gdshaderinc - small helpers shared by the other modules.
#ifndef EZ_COMMON_INC
#define EZ_COMMON_INC

vec3 ez_hsv2rgb(float h, float s, float v) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(vec3(h) + K.xyz) * 6.0 - K.www);
	return v * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), s);
}

float ez_hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec4 ez_hash42(vec2 p) {
	vec4 p4 = fract(vec4(p.xyxy) * vec4(0.1031, 0.1030, 0.0973, 0.1099));
	p4 += dot(p4, p4.wzxy + 33.33);
	return fract((p4.xxyz + p4.yzzw) * p4.zywx);
}

float ez_hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float ez_vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(ez_hash13(i), ez_hash13(i + vec3(1, 0, 0)), f.x), mix(ez_hash13(i + vec3(0, 1, 0)), ez_hash13(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(ez_hash13(i + vec3(0, 0, 1)), ez_hash13(i + vec3(1, 0, 1)), f.x), mix(ez_hash13(i + vec3(0, 1, 1)), ez_hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

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

#endif
