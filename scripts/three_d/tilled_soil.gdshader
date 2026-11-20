shader_type spatial;

// Each plot is a scaled unit box. Align six furrows with the planted rows.
uniform vec4 earth : source_color = vec4(0.48, 0.32, 0.21, 1.0);
uniform float moisture : hint_range(0, 1) = 0.5;
varying vec2 plot_position;
varying vec2 world_position;
varying float top;

void vertex() {
	plot_position = VERTEX.xz;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	top = max(NORMAL.y, 0.0);
}

void fragment() {
	vec2 p = world_position;
	float rows = (plot_position.y * 6.75 + 2.6) / 1.03;
	float phase = rows * TAU + 0.12 * sin(p.x * 1.7 + p.y);
	float edge = 1.0 - smoothstep(0.43, 0.49, abs(plot_position.x));
	float ridge = cos(phase) * edge * top;
	float clods = sin(p.x * 5.1 + sin(p.y * 4.3)) * sin(p.y * 7.0 + p.x);
	float detail = 1.0 - smoothstep(0.06, 0.24, max(fwidth(p.x), fwidth(p.y)));
	ALBEDO = earth.rgb * (1.0 + ridge * 0.17 + clods * 0.055 * detail);
	ROUGHNESS = mix(0.98, 0.58, moisture * (0.5 - 0.5 * ridge));
}
