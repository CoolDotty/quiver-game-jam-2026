shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, skip_vertex_transform;

uniform sampler2D billboard_texture : source_color, filter_linear_mipmap, repeat_disable;


void fragment() {
	vec4 tex = texture(billboard_texture, UV);
	ALBEDO = tex.rgb;
	ALPHA = tex.a;
}


void vertex() {
	vec3 view_origin = (VIEW_MATRIX * vec4(MODEL_MATRIX[3].xyz, 1.0)).xyz;
	float scale_x = length(MODEL_MATRIX[0].xyz);
	float scale_y = length(MODEL_MATRIX[1].xyz);
	vec2 local_offset = vec2(VERTEX.x * scale_x, VERTEX.y * scale_y);

	VERTEX = view_origin + vec3(local_offset, 0.0);
}
