shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, skip_vertex_transform;

uniform sampler2D arm_texture : source_color, filter_linear_mipmap, repeat_disable;


void fragment() {
	vec4 tex = texture(arm_texture, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
}


void vertex() {
	vec3 origin_view = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	vec3 axis_x_view = (VIEW_MATRIX * vec4(MODEL_MATRIX[0].xyz, 0.0)).xyz;
	float roll = atan(axis_x_view.y, axis_x_view.x);
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	vec2 right_2d = vec2(cos(roll), sin(roll));
	vec2 up_2d = vec2(-right_2d.y, right_2d.x);
	vec2 rotated_offset = right_2d * (VERTEX.x * scale_x) + up_2d * (VERTEX.y * scale_y);

	VERTEX = origin_view + vec3(rotated_offset, 0.0);
}
