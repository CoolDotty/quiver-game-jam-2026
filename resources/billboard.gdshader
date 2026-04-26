shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, skip_vertex_transform;

uniform sampler2D billboard_texture : source_color, filter_linear_mipmap, repeat_disable;


void fragment() {
	vec4 tex = texture(billboard_texture, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
	ALBEDO *= COLOR.rgb;
	ALPHA *= COLOR.a;
}


void vertex() {
	mat4 modelview = VIEW_MATRIX * MODEL_MATRIX;
	vec3 view_origin = modelview[3].xyz;
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	vec2 local_offset = vec2(VERTEX.x * scale_x, VERTEX.y * scale_y);
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
