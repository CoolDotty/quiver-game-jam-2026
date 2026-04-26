shader_type spatial;

render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;

uniform float shoreline_y : hint_range(0.0, 1.0) = 0.205;
uniform float tide_amount : hint_range(0.0, 0.08) = 0.024;
uniform float band_size : hint_range(0.01, 0.2) = 0.07;
uniform float wave_speed : hint_range(0.0, 4.0) = 0.9;
uniform float distort_amount : hint_range(0.0, 0.03) = 0.009;
uniform float foam_boost : hint_range(0.0, 0.3) = 0.08;

void fragment() {
	vec2 uv = UV;

	float shoreline =
		shoreline_y +
		sin(uv.x * 10.0 + TIME * 0.35) * 0.014 +
		sin(uv.x * 23.0 - TIME * 0.22) * 0.008;

	float tide = sin(TIME * wave_speed) * tide_amount;
	float front = shoreline + tide;

	float dist = uv.y - front;

	float band = 1.0 - smoothstep(0.0, band_size, abs(dist));
	float water_mask = 1.0 - smoothstep(-0.005, 0.05, dist);

	float ripple =
		sin(uv.x * 36.0 - TIME * 2.0) * 0.6 +
		sin(uv.x * 71.0 + TIME * 1.3) * 0.4;

	uv.y += ripple * distort_amount * band;
	uv.x += sin(uv.y * 80.0 + TIME * 1.6) * distort_amount * 0.2 * water_mask;

	vec4 col = texture(albedo_texture, uv);

	float foam = 1.0 - smoothstep(0.0, 0.012, abs(dist));
	col.rgb += foam * foam_boost;

	ALBEDO = col.rgb;
}
