extends RefCounted
## Fieldwork 5.9 presentation-only controls. No simulation or save-state edits.
const PRESETS = ["eco", "balanced", "quality"]

static func normalize_preset(value: String) -> String:
	return value if PRESETS.has(value) else "balanced"

static func redraw_seconds(value: String, reduced_motion: bool) -> float:
	if reduced_motion:
		return 0.75
	match normalize_preset(value):
		"eco":
			return 0.125
		"quality":
			return 0.04
		_:
			return 0.066

static func rain_particles(value: String, normal: int) -> int:
	if normalize_preset(value) == "eco":
		return maxi(12, int(round(float(normal) * 0.40)))
	return normal

static func terrain_stride(value: String) -> int:
	return 2 if normalize_preset(value) == "eco" else 1

static func touch_target(scale: float) -> float:
	return clampf(52.0 * scale, 52.0, 70.0)

static func map_label(value: String, spanish: bool) -> String:
	match normalize_preset(value):
		"eco":
			return "Ahorro" if spanish else "Eco"
		"quality":
			return "Calidad" if spanish else "Quality"
		_:
			return "Equilibrado" if spanish else "Balanced"
