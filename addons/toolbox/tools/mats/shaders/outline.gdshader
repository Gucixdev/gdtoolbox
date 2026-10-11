// outline.gdshader - constant-screen-width outline via an inflated back-face pass. Use as the `next_pass` of any material.
// Width is in pixels regardless of distance (the offset is applied in clip space), unlike a naive object-space inflate.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float width_px : hint_range(0.0, 12.0, 0.1) = 2.0;
uniform bool use_vertex_color_width = false;                  // COLOR.r scales the width (paint thin/thick areas)

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 n_view = normalize(MODELVIEW_NORMAL_MATRIX * NORMAL);
	vec2 n_clip = normalize((PROJECTION_MATRIX * vec4(n_view, 0.0)).xy + vec2(0.00001));
	float w = width_px * (use_vertex_color_width ? COLOR.r : 1.0);
	vec2 offset = n_clip * (w / VIEWPORT_SIZE) * 2.0 * clip.w;
	POSITION = vec4(clip.xy + offset, clip.z, clip.w);
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
