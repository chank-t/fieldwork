shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.20, 0.54, 0.58, 1.0);
uniform bool animate = true;
varying vec3 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (animate) VERTEX.y += sin(world_position.x * 1.8 + TIME * 0.9) * 0.035;
}
void fragment() {
	float t = animate ? TIME : 0.0;
	float ripple = sin(world_position.x * 2.8 + world_position.z * 1.5 + t) * sin(world_position.z * 3.0 - t * 0.7);
	ALBEDO = water_color.rgb + smoothstep(0.60, 0.95, ripple) * 0.11;
	ROUGHNESS = 0.34;
	METALLIC = 0.12;
}
