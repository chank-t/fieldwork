shader_type spatial;
// Soft, painterly ground: low-frequency colour patches, faint mown bands and a
// hazy fade to the horizon so the world no longer ends at a hard slab edge.
uniform vec4 grass_color : source_color = vec4(0.57, 0.68, 0.44, 1.0);
uniform vec4 haze_color : source_color = vec4(0.80, 0.86, 0.82, 1.0);
uniform vec2 center = vec2(32.0, 27.0);
uniform float haze_start = 85.0;
uniform float haze_end = 170.0;
uniform float variation = 1.0;
uniform float winter_amount = 0.0;
uniform float wetness = 0.0;
uniform float heat_amount = 0.0;
varying vec3 world_position;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec2 p = world_position.xz;
	float broad = noise(p * 0.045) * 0.6 + noise(p * 0.13) * 0.3 + noise(p * 0.9) * 0.1;
	float bands = smoothstep(0.35, 0.65, fract(p.x * 0.11 + noise(p * 0.05) * 0.6)) * 0.035;
	vec3 color = grass_color.rgb * (0.90 + broad * 0.20 * variation + bands * variation);
	// slightly warmer, drier patches
	color = mix(color, color * vec3(1.08, 1.04, 0.86), smoothstep(0.62, 0.85, noise(p * 0.07 + 13.0)) * 0.45 * variation);
	float snow = smoothstep(0.34, 0.70, noise(p * 0.12 + 37.0));
	color = mix(color, color * vec3(0.78, 0.85, 0.96), winter_amount * 0.38);
	color = mix(color, vec3(0.82, 0.88, 0.91), snow * winter_amount * 0.82);
	color = mix(color, color * vec3(0.68, 0.76, 0.84), wetness * 0.40);
	color = mix(color, color * vec3(1.10, 0.94, 0.76), heat_amount * 0.24);
	float d = length(p - center);
	float haze = smoothstep(haze_start, haze_end, d);
	ALBEDO = mix(color, haze_color.rgb, haze);
	ROUGHNESS = mix(0.95, 0.62, wetness);
	SPECULAR = mix(0.2, 0.42, wetness);
}
