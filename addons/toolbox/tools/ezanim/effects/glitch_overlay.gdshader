// CP77-style glitch: duże bloki displaced + heavy RGB chromatic aberration + cyan/magenta corruption.
shader_type canvas_item;

uniform float time_val : hint_range(0.0, 1.0) = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.8;
uniform float chroma_strength : hint_range(0.0, 0.05) = 0.012;
uniform int strip_count : hint_range(4, 64) = 20;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float hash(float n) { return fract(sin(n) * 43758.5453); }

void fragment() {
	vec2 uv = SCREEN_UV;

	// Frame-locked feel — update ~15fps
	float t = floor(time_val * 15.0) / 15.0;

	// ── Warstwa 1: duże bloki (CP77 style) ───────────────────────────────────
	float blk_h   = 0.04 + hash(t * 7.31) * 0.12;
	float blk_y   = floor(uv.y / blk_h) * blk_h;
	float blk_rnd = hash(blk_y * 43.7 + t * 311.7);
	float do_blk  = step(1.0 - intensity * 0.65, blk_rnd);
	float blk_x   = (hash(blk_y * 2.71 + t) * 2.0 - 1.0) * intensity * 0.38 * do_blk;

	// ── Warstwa 2: cienkie scanlines (gęstość = strip_count * 4) ─────────────
	float sc      = float(strip_count) * 4.0;
	float fine_y   = floor(uv.y * sc) / sc;
	float fine_rnd = hash(fine_y * 127.1 + t * 523.1);
	float do_fine  = step(1.0 - intensity * 0.28, fine_rnd);
	float fine_x   = (hash(fine_y + t * 2.0) * 2.0 - 1.0) * intensity * 0.07 * do_fine;

	float total_x = blk_x + fine_x;

	// ── RGB chromatic aberration — siła kontrolowana przez chroma_strength ────
	float ca = (chroma_strength * 2.0 + do_blk * chroma_strength * 4.5) * intensity;

	vec2 uv_r = clamp(uv + vec2(total_x + ca * 2.8,  0.0), vec2(0.0), vec2(1.0));
	vec2 uv_g = clamp(uv + vec2(total_x,               0.0), vec2(0.0), vec2(1.0));
	vec2 uv_b = clamp(uv + vec2(total_x - ca * 2.8,  0.0), vec2(0.0), vec2(1.0));

	float r = texture(screen_texture, uv_r).r;
	float g = texture(screen_texture, uv_g).g;
	float b = texture(screen_texture, uv_b).b;
	float a = texture(screen_texture, uv_g).a;

	// ── CP77 color corruption: cyan lub magenta na glitchujących blokach ──────
	float corrupt     = do_blk * step(0.68, hash(blk_y * 17.3 + t * 89.1));
	float pick_cyan   = step(0.5, hash(blk_y * 3.1 + t * 13.7));   // 0=magenta, 1=cyan
	float corrupt_r   = mix(1.0, 0.0, pick_cyan);   // magenta=R+B, cyan=G+B
	float corrupt_g   = mix(0.0, 1.0, pick_cyan);
	r = mix(r, corrupt_r, corrupt * intensity * 0.55);
	g = mix(g, corrupt_g, corrupt * intensity * 0.35);
	b = mix(b, 1.0,       corrupt * intensity * 0.55);

	// ── Okazjonalny global flash (cyjan tint jak w CP77 damage) ───────────────
	float spike   = step(0.91, hash(t * 431.7)) * intensity * 0.45;
	float spike_r = spike * 0.1;
	float spike_b = spike * 0.9;

	COLOR = vec4(
		clamp(r + spike_r, 0.0, 2.0),
		clamp(g + spike * 0.05, 0.0, 2.0),
		clamp(b + spike_b, 0.0, 2.0),
		a
	);
}
