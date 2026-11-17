shader_type spatial;

void vertex() {
	float phase = TIME * 1.15 + float(INSTANCE_ID) * 0.73 + VERTEX.y * 0.8;
	float height_mask = smoothstep(0.12, 2.5, VERTEX.y);
	VERTEX.x += sin(phase) * 0.035 * height_mask;
	VERTEX.z += cos(phase * 0.83) * 0.018 * height_mask;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.95;
}
