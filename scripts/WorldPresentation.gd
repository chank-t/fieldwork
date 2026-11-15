extends RefCounted
## Presentation-only derived values. Never advance time or touch farm RNG.
## No persisted state; all presentation can be reconstructed from a 4.6 save.

const STAGES = ["sown", "sprout", "young", "flowering", "mature"]
const MOODS = ["sleeping", "resting", "grazing", "drinking", "walking", "unwell"]

static func crop_stage(development: float) -> int:
	var value: float = clampf(development, 0.0, 1.0)
	if value < 0.05:
		return 0
	if value < 0.23:
		return 1
	if value < 0.52:
		return 2
	if value < 0.82:
		return 3
	return 4

static func crop_stage_text(development: float, spanish: bool = false) -> String:
	var index: int = crop_stage(development)
	var en: Array = ["Sown", "Sprouting", "Growing", "Flowering", "Maturing"]
	var es: Array = ["Sembrado", "Germinando", "Creciendo", "Floracion", "Madurando"]
	return str(es[index] if spanish else en[index])

static func soil_visual(soil: Dictionary) -> String:
	var capacity: float = maxf(1.0, float(soil.get("capacity", 160.0)))
	var water: float = float(soil.get("water", 0.0))
	if water < capacity * 0.24:
		return "dry"
	if water > capacity * 0.82:
		return "wet"
	return "balanced"

static func plant_health(field: Dictionary) -> float:
	var soil: Dictionary = field.get("soil", {})
	var capacity: float = maxf(1.0, float(soil.get("capacity", 160.0)))
	var moisture: float = clampf(float(soil.get("water", 0.0)) / capacity, 0.0, 1.0)
	var pests: Dictionary = field.get("pests", {})
	var diseases: Dictionary = field.get("diseases", {})
	var max_pest: float = 0.0
	var max_disease: float = 0.0
	for amount in pests.values():
		max_pest = maxf(max_pest, float(amount))
	for amount in diseases.values():
		max_disease = maxf(max_disease, float(amount))
	var water_score: float = clampf(moisture / 0.38, 0.20, 1.0)
	return clampf(water_score * (1.0 - minf(0.50, max_pest / 140.0)) * (1.0 - minf(0.40, max_disease * 0.6)), 0.16, 1.0)

static func animal_behavior(animal: Dictionary, hour: int, index: int, elapsed: float) -> String:
	var condition: float = float(animal.get("condition", 1.0))
	if condition < 0.40:
		return "unwell"
	if hour >= 20 or hour < 6:
		return "sleeping"
	if hour >= 12 and hour < 14:
		return "resting"
	# Pattern is deterministic: no RNG, and the clock is the only simulation input.
	var phase: int = posmod(int(hour / 2) + index, 5)
	if phase == 0:
		return "drinking"
	if phase == 1:
		return "walking"
	return "grazing"

static func animal_offset(index: int, hour: int, elapsed: float, condition: float) -> Vector2:
	var pacing: float = 0.14 if condition < 0.40 else 0.46
	if hour >= 20 or hour < 6:
		pacing = 0.0
	return Vector2(sin(elapsed * 0.72 + float(index) * 1.91) * pacing,
		cos(elapsed * 0.58 + float(index) * 2.31) * pacing * 0.36)

static func ambient_phase(index: int, elapsed: float, speed: float = 1.0) -> float:
	return fposmod(float(index) * 0.6180339 + elapsed * speed, 1.0)

static func dawn_dusk(hour: int) -> String:
	if hour >= 20 or hour < 5:
		return "night"
	if hour >= 17:
		return "dusk"
	if hour < 8:
		return "dawn"
	return "day"

static func should_show_mist(hour: int, humidity: float) -> bool:
	return hour >= 5 and hour < 9 and humidity >= 0.62

static func weather_name(kind: String, spanish: bool = false) -> String:
	var en: Dictionary = {"clear":"Clear","rain":"Rain","cloudy":"Cloudy","heat":"Hot","dry":"Dry"}
	var es: Dictionary = {"clear":"Despejado","rain":"Lluvia","cloudy":"Nublado","heat":"Calor","dry":"Seco"}
	return str((es if spanish else en).get(kind,kind.capitalize()))
