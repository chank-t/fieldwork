extends RefCounted
## Fieldwork 5.1 presentation rules. No save-state edits, side effects or random values.
## All layer values come from real NativeFarm field state.

const OVERLAYS = ["none", "moisture", "growth", "soil", "pests"]
const OVERLAY_ORDER = ["none", "moisture", "growth", "soil", "pests"]

static func overlay_labels(spanish: bool) -> Array:
	return ["Normal", "Humedad", "Crecimiento", "Salud del suelo", "Plagas"] if spanish else ["Natural", "Moisture", "Growth", "Soil health", "Pests"]

static func overlay_name(mode: String, spanish: bool) -> String:
	var index: int = OVERLAY_ORDER.find(mode)
	if index < 0:
		return ""
	return str(overlay_labels(spanish)[index])

static func soil_texture(terrain_id: String, water: float, capacity: float) -> String:
	var relative: float = water / maxf(1.0,capacity)
	if relative < 0.19:
		return "terrain51_dry"
	if relative > 0.77:
		return "terrain51_wet"
	match terrain_id:
		"clay": return "terrain51_clay"
		"sand": return "terrain51_sand"
		"rocky", "hill": return "terrain51_rock"
		"forest", "wild": return "terrain51_forest"
		"stream", "marsh": return "terrain51_marsh"
		_: return "terrain51_loam"

static func overlay_value(mode: String, field: Dictionary) -> float:
	if not bool(field.get("owned",false)):
		return 0.0
	var soil: Dictionary = field.get("soil",{})
	match mode:
		"moisture":
			return clampf(float(soil.get("water",0.0)) / maxf(1.0,float(soil.get("capacity",1.0))),0.0,1.0)
		"growth":
			var crop: Dictionary = field.get("crop",{})
			return clampf(float(crop.get("development",0.0)),0.0,1.0)
		"soil":
			var organic: float = float(soil.get("organic_matter",2.8))
			var compaction: float = float(soil.get("compaction",0.12))
			var erosion: float = float(soil.get("erosion",0.02))
			return clampf((0.64+organic*0.105-compaction*0.29-erosion*0.32)/1.12,0.0,1.0)
		"pests":
			var high: float = 0.0
			for count in field.get("pests",{}).values():
				high = maxf(high,float(count))
			return clampf(high/40.0,0.0,1.0)
	return 0.0

static func overlay_tint(mode: String, value: float) -> Color:
	var v: float = clampf(value,0.0,1.0)
	var color: Color = Color("#d5a168").lerp(Color("#4d9b95"),v)
	if mode == "pests":
		color = Color("#72b57a").lerp(Color("#cb5d54"),v)
	elif mode == "growth":
		color = Color("#b6c9a3").lerp(Color("#e2bf63"),v)
	color.a = 0.36
	return color

static func navigation_groups(spanish: bool) -> Array:
	if spanish:
		return [
			{"heading":"EXPLORAR", "tabs":[["Farm","Resumen"],["Compass60","Brújula de la finca"],["Explorer","Guía del mundo"],["Fields","Parcelas"],["CropGuide52","Guía de cultivos"],["Valley","Mapa del valle"],["Countryside54","Vida rural"],["Expeditions58","Proyectos regionales"]]},
			{"heading":"PRODUCCIÓN Y GESTIÓN", "tabs":[["Ecology","Suelo y plagas"],["Planning","Plan diario"],["Machinery","Maquinaria"],["Resources","Recursos"],["GardenStudio57","Estudio del jardín"],["Buildings","Edificios"],["Animals","Animales"],["Processing","Elaboración"],["Market","Mercado"],["Economy","Estrategia"]]},
			{"heading":"COMUNIDAD Y PERSONAJE", "tabs":[["Neighbours","Vecinos"],["Stories","Historias del pueblo"],["Community50","Historias vecinales"],["Festivals50","Fiestas y estaciones"],["Certifications50","Acreditaciones"],["Character","Cursos y talentos"],["Story","Historia y objetivos"],["Journal","Diario"],["Options","Opciones"]]}
		]
	return [
		{"heading":"EXPLORE", "tabs":[["Farm","Farm overview"],["Compass60","Farm Compass"],["Explorer","World guide"],["Fields","Fields"],["CropGuide52","Crop guide"],["Valley","Valley map"],["Countryside54","Village life"],["Expeditions58","Regional projects"]]},
		{"heading":"FARM & BUSINESS", "tabs":[["Ecology","Soil & pests"],["Planning","Daily planner"],["Machinery","Machinery"],["Resources","Resources"],["GardenStudio57","Garden studio"],["Buildings","Buildings"],["Animals","Animals"],["Processing","Processing"],["Market","Market"],["Economy","Business strategy"]]},
		{"heading":"COMMUNITY & PROGRESS", "tabs":[["Neighbours","Neighbours"],["Stories","Village stories"],["Community50","Neighbour journeys"],["Festivals50","Festivals & seasons"],["Certifications50","Qualifications"],["Character","Courses & talents"],["Story","Story & goals"],["Journal","Journal"],["Options","Settings"]]}
	]
