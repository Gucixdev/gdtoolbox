// npr.gdshaderinc - non-photoreal extras that work without scene lights: view-space specular and opal iridescence.
#ifndef EZ_NPR_INC
#define EZ_NPR_INC

#include "res://addons/toolbox/tools/mats/inc/common.gdshaderinc"

group_uniforms specular;
uniform int specular_mode = 0;                      // 0 off, 1 Blinn-Phong, 2 Phong
uniform float phong_shininess : hint_range(1.0, 512.0) = 32.0;
uniform float phong_strength : hint_range(0.0, 2.0) = 0.5;
group_uniforms opal;
uniform bool opal_enabled = false;
uniform float opal_strength : hint_range(0.0, 1.0) = 0.5;
uniform float opal_fresnel_power : hint_range(0.5, 8.0) = 2.0;
uniform float opal_hue_shift : hint_range(0.0, 1.0) = 0.0;
uniform float opal_saturation : hint_range(0.0, 1.0) = 1.0;
uniform vec4 opal_tint : source_color = vec4(1.0);
uniform sampler2D opal_texture : filter_linear_mipmap, repeat_disable, hint_default_black;
uniform bool opal_use_texture = false;
uniform bool opal_additive = false;
group_uniforms;

// NPR Specular in view-space - works without scene lights
vec3 ez_npr_specular(vec3 rgb, vec3 view_n) {
	vec3 fake_light = normalize(vec3(0.35, 0.5, 0.8));
	float spec = 0.0;
	if (specular_mode == 1) {
		vec3 h = normalize(fake_light + vec3(0.0, 0.0, 1.0));
		spec = pow(max(dot(view_n, h), 0.0), phong_shininess);
	} else if (specular_mode == 2) {
		vec3 r = reflect(-fake_light, view_n);
		spec = pow(max(dot(r, vec3(0.0, 0.0, 1.0)), 0.0), phong_shininess);
	}
	return rgb + vec3(spec * phong_strength);
}

// Opal iridescence
vec3 ez_opal(vec3 rgb, vec3 normal, vec3 view) {
	float f = pow(1.0 - clamp(dot(normal, view), 0.0, 1.0), opal_fresnel_power);
	vec3 iri;
	if (opal_use_texture) {
		iri = texture(opal_texture, vec2(fract(f + opal_hue_shift), 0.5)).rgb;
	} else {
		iri = ez_hsv2rgb(fract(f * 0.8 + opal_hue_shift), opal_saturation, 1.0);
	}
	iri *= opal_tint.rgb;
	float blend = opal_strength * f;
	if (opal_additive) {
		return rgb + iri * blend;
	}
	return mix(rgb, iri, blend);
}

#endif
