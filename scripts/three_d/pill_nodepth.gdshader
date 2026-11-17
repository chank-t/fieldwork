shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, shadows_disabled, depth_draw_never, depth_test_disabled;
uniform vec4 color : source_color = vec4(0.09, 0.17, 0.13, 0.78);
uniform vec2 size = vec2(2.0, 0.6);
void vertex() {
	vec3 scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * scale.x, INV_VIEW_MATRIX[1] * scale.y, INV_VIEW_MATRIX[2] * scale.z, MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = (UV - 0.5) * size;
	float r = size.y * 0.5;
	vec2 q = abs(p) - (size * 0.5 - vec2(r));
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
	float edge = fwidth(d);
	ALBEDO = color.rgb;
	ALPHA = color.a * (1.0 - smoothstep(-edge, edge, d));
}
