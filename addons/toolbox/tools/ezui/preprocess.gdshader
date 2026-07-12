shader_type canvas_item;

// Vignette
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_softness : hint_range(0.01, 1.0) = 0.45;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// Chromatic aberration
uniform float chromatic_amount : hint_range(0.0, 0.02) = 0.0;

// Film grain
uniform float grain_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float grain_time : hint_range(0.0, 100.0) = 0.0;

// Scanlines
uniform float scanlines_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float scanlines_count : hint_range(50.0, 800.0) = 300.0;

// Color grading (1.0 = neutral)
uniform float brightness : hint_range(0.0, 3.0) = 1.0;
uniform float contrast : hint_range(0.0, 3.0) = 1.0;
uniform float saturation : hint_range(0.0, 3.0) = 1.0;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Chromatic aberration
	vec3 col;
	if (chromatic_amount > 0.0) {
		vec2 offset = (uv - vec2(0.5)) * chromatic_amount;
		col.r = texture(SCREEN_TEXTURE, uv - offset).r;
		col.g = texture(SCREEN_TEXTURE, uv).g;
		col.b = texture(SCREEN_TEXTURE, uv + offset).b;
	} else {
		col = texture(SCREEN_TEXTURE, uv).rgb;
	}

	// Brightness / contrast / saturation
	col *= brightness;
	col = (col - 0.5) * contrast + 0.5;
	float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(lum), col, saturation);

	// Scanlines
	if (scanlines_intensity > 0.0) {
		float line = sin(uv.y * scanlines_count * PI) * 0.5 + 0.5;
		col = mix(col, col * line, scanlines_intensity);
	}

	// Film grain
	if (grain_intensity > 0.0) {
		float noise = rand(uv + vec2(grain_time * 0.01, grain_time * 0.007));
		col += (noise - 0.5) * grain_intensity * 0.3;
	}

	// Vignette (applied last so it darkens final result)
	float alpha = 1.0;
	if (vignette_intensity > 0.0) {
		vec2 center = uv - vec2(0.5);
		float dist = length(center);
		float v = smoothstep(0.5 - vignette_softness, 0.5, dist * (1.0 + vignette_intensity));
		v = clamp(v * vignette_intensity, 0.0, 1.0);
		col = mix(col, vignette_color.rgb, v);
	}

	col = clamp(col, 0.0, 1.0);
	COLOR = vec4(col, alpha);
}
