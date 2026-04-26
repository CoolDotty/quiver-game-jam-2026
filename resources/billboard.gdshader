shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, skip_vertex_transform;

uniform sampler2D billboard_texture : source_color, filter_linear_mipmap, repeat_disable;
uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;

// Time stepping for the hand-drawn feel.
// Set to 0.0 for smooth animation.
uniform float step_time : hint_range(0.0, 1.0) = 0.25;

// Vertex wobble (shape motion).
uniform float wobble_amount : hint_range(0.0, 0.12) = 0.03;
uniform float wobble_speed : hint_range(0.0, 10.0) = 2.0;

// UV wobble (texture boil).
uniform float uv_wobble_amount : hint_range(0.0, 0.03) = 0.01;
uniform float uv_wobble_speed : hint_range(0.0, 10.0) = 2.6;

// Squash / stretch (animated jello effect).
// Both default to 0, so disabled unless you turn them up.
uniform float squash_x : hint_range(0.0, 0.95) = 0.0;
uniform float squash_y : hint_range(0.0, 0.95) = 0.0;
uniform float squash_speed : hint_range(0.0, 10.0) = 2.2;

// How much the middle stays stable compared to the edges.
// Lower = whole card wiggles more. Higher = edges/corners do most of the wobbling.
uniform float center_rigidity : hint_range(0.0, 1.0) = 0.75;

varying vec2 v_uv;
varying vec4 v_color;

float stepped_time(float speed) {
	if (step_time <= 0.0) {
		return TIME * speed;
	}

	return floor(TIME / step_time) * step_time * speed;
}

void vertex() {
	mat4 modelview = VIEW_MATRIX * MODEL_MATRIX;
	vec3 view_origin = modelview[3].xyz;

	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);

	v_uv = UV;
	v_color = COLOR;

	// Original billboard-local quad offset, preserving object scale.
	vec2 local_offset = vec2(VERTEX.x * scale_x, VERTEX.y * scale_y);

	// Stable per-corner coordinates in -1..1 space.
	vec2 corner = UV * 2.0 - 1.0;

	// Stronger wobble at the outer edges / corners, less in the center.
	float corner_dist = clamp(length(corner) / 1.41421356, 0.0, 1.0);
	float wobble_mask = mix(center_rigidity, 1.0, smoothstep(0.1, 1.0, corner_dist));

	// -----------------------------
	// Squash / stretch jello motion
	// -----------------------------
	// Uses stepped time too, so it keeps the same sketchy/chunky feel.
	float sq_t = stepped_time(squash_speed);

	// Two slightly different wave patterns so it feels alive instead of robotic.
	float x_push = sin(sq_t * 1.0);
	float y_push = sin(sq_t * 1.27 + 1.57079632679);

	// Each axis pushes against the opposite axis so it behaves like squash/stretch.
	// If X widens, Y compresses. If Y rises, X compresses.
	float sx = (1.0 + squash_x * x_push) / max(0.001, 1.0 + squash_y * y_push);
	float sy = (1.0 + squash_y * y_push) / max(0.001, 1.0 + squash_x * x_push);

	local_offset *= vec2(sx, sy);

	// Quantized time: updates every step_time seconds.
	float t = stepped_time(wobble_speed);

	// Sketchy hand-drawn shape wobble.
	// Because this is applied in billboard-local space BEFORE screen rotation,
	// the billboard still respects its camera-facing rotation behavior.
	vec2 sketch_wobble = vec2(
		sin(t * 1.9 + corner.y * 3.2 + corner.x * 2.1) +
		0.6 * sin(t * 3.7 - corner.y * 6.1) +
		0.35 * cos(t * 5.1 + corner.x * 8.0),

		cos(t * 1.7 - corner.x * 2.8 + corner.y * 2.3) +
		0.6 * sin(t * 3.9 + corner.x * 5.4) +
		0.35 * sin(t * 5.6 - corner.y * 7.2)
	) * 0.5;

	// Scale-aware wobble so bigger sprites wobble proportionally.
	local_offset += sketch_wobble * vec2(scale_x, scale_y) * wobble_amount * wobble_mask;

	// Preserve your existing billboard rotation logic.
	vec2 screen_right = modelview[0].xy;
	float screen_angle = 0.0;

	if (length(screen_right) > 0.000001) {
		screen_angle = atan(screen_right.y, screen_right.x);
	}

	float sin_angle = sin(screen_angle);
	float cos_angle = cos(screen_angle);

	vec2 rotated_offset = vec2(
		local_offset.x * cos_angle - local_offset.y * sin_angle,
		local_offset.x * sin_angle + local_offset.y * cos_angle
	);

	VERTEX = view_origin + vec3(rotated_offset, 0.0);
}

void fragment() {
	vec2 uv = v_uv;

	// Same stepped timing in fragment for the "boiling drawing" effect.
	float t = stepped_time(uv_wobble_speed);

	vec2 centered_uv = uv * 2.0 - 1.0;
	float uv_edge_mask = mix(center_rigidity, 1.0, smoothstep(0.1, 1.0, clamp(length(centered_uv) / 1.41421356, 0.0, 1.0)));

	// Quantized texture boil.
	vec2 uv_offset = vec2(
		sin(t * 1.6 + uv.y * 18.0) +
		0.5 * sin(t * 3.1 + uv.x * 31.0),

		sin(t * 1.4 + uv.x * 22.0) +
		0.5 * cos(t * 2.9 + uv.y * 27.0)
	) * uv_wobble_amount * uv_edge_mask;

	vec2 final_uv = clamp(uv + uv_offset, vec2(0.0), vec2(1.0));
	vec4 tex = texture(billboard_texture, final_uv);

	if (blur_amount > 0.0) {
		vec2 texel_size = vec2(blur_amount) / vec2(textureSize(billboard_texture, 0));
		vec4 blurred =
			texture(billboard_texture, final_uv) * 0.20 +
			texture(billboard_texture, final_uv + vec2(texel_size.x, 0.0)) * 0.15 +
			texture(billboard_texture, final_uv + vec2(-texel_size.x, 0.0)) * 0.15 +
			texture(billboard_texture, final_uv + vec2(0.0, texel_size.y)) * 0.15 +
			texture(billboard_texture, final_uv + vec2(0.0, -texel_size.y)) * 0.15 +
			texture(billboard_texture, final_uv + vec2(texel_size.x, texel_size.y)) * 0.0875 +
			texture(billboard_texture, final_uv + vec2(-texel_size.x, texel_size.y)) * 0.0875 +
			texture(billboard_texture, final_uv + vec2(texel_size.x, -texel_size.y)) * 0.0875 +
			texture(billboard_texture, final_uv + vec2(-texel_size.x, -texel_size.y)) * 0.0875;
		tex = blurred;
	}

	// Preserve Sprite3D modulate / tint / alpha.
	vec4 final_color = tex * v_color;

	ALBEDO = final_color.rgb;
	ALPHA = final_color.a;
}
