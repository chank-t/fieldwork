extends RefCounted
## Fieldwork 4.9 domain rules: deterministic reports, machinery and specializations.
## No gameplay RNG is drawn by the read-only UI/reporting helpers.

const MACHINES = {
	"cultivator":{"name":{"en":"Compact cultivator","es":"Cultivador compacto"},"description":{"en":"Cheaper soil aeration and planting labour. Using it can compact wet soil.","es":"Reduce el coste de airear y sembrar. Su uso puede compactar el suelo humedo."},"cost":620.0,"upkeep":1.25},
	"pump":{"name":{"en":"Efficient irrigation pump","es":"Bomba de riego eficiente"},"description":{"en":"Uses 12% less reservoir water and reduces pumping expense when working.","es":"Consume un 12% menos de agua y reduce el gasto de bombeo cuando funciona."},"cost":780.0,"upkeep":1.50},
	"harvester":{"name":{"en":"Light harvester","es":"Cosechadora ligera"},"description":{"en":"Reduces harvest labour and post-harvest losses. Needs maintenance.","es":"Reduce el coste de recoleccion y las perdidas. Necesita mantenimiento."},"cost":1150.0,"upkeep":2.30},
	"mixer":{"name":{"en":"Feed mixer","es":"Mezcladora de pienso"},"description":{"en":"Improves feed efficiency and daily livestock nutrition.","es":"Mejora el aprovechamiento del pienso y la nutricion del ganado."},"cost":560.0,"upkeep":1.10}
}

const PATHS = {
	"balanced":{"name":{"en":"Independent farm","es":"Finca independiente"},"description":{"en":"Flexible production, no specialist bonus or penalty.","es":"Produccion flexible, sin bonificaciones ni penalizaciones."}},
	"crops":{"name":{"en":"Crop producer","es":"Productor agricola"},"description":{"en":"Harvest +8%, seeds +5%, cereal contracts +12%.","es":"Cosecha +8 %, semillas +5 % y contratos de cereal +12 %."}},
	"horticulture":{"name":{"en":"Market gardener","es":"Horticultura de mercado"},"description":{"en":"Orders for vegetables, berries and similar produce pay 12% more.","es":"Los pedidos de hortalizas, frutos del bosque y cultivos afines pagan un 12 % más."}},
	"livestock":{"name":{"en":"Livestock keeper","es":"Ganaderia"},"description":{"en":"Feed -12%, animal production +9%, veterinary visits +10%, cheese processing cost −15%.","es":"Pienso -12%, produccion animal +9%, visitas veterinarias +10 % y coste de elaborar queso −15 %."}},
	"artisan":{"name":{"en":"Artisan processor","es":"Elaboracion artesana"},"description":{"en":"Processed output +12%, processing costs +8%.","es":"Elaboracion +12%, costes de procesado +8%."}},
	"ecology":{"name":{"en":"Ecological steward","es":"Gestion ecologica"},"description":{"en":"Healthier habitats, slower erosion, premium produce sells for more; field care costs +8%.","es":"Habitat saludable, menos erosion y mayor precio premium; cuidado del suelo +8%."}}
}

const CONSTRUCTION_SLOT_COUNT = 24

static func organic_score(field: Dictionary) -> float:
	var soil: Dictionary = field.get("soil", {})
	var matter: float = float(soil.get("organic_matter",2.8))
	var compaction: float = float(soil.get("compaction",0.12))
	var erosion: float = float(soil.get("erosion",0.02))
	return clampf(0.64 + matter * 0.105 - compaction * 0.29 - erosion * 0.32,0.32,1.12)

static func soil_label(field: Dictionary, spanish: bool) -> String:
	var score: float = organic_score(field)
	if score < 0.67:
		return "Degradado" if spanish else "Degraded"
	if score < 0.90:
		return "Fragil" if spanish else "Fragile"
	if score < 1.02:
		return "Estable" if spanish else "Stable"
	return "Vivo" if spanish else "Thriving"

static func rotation_streak(field: Dictionary, crops: Dictionary, family: String) -> int:
	if family.is_empty(): return 0
	var history: Array = field.get("history",[])
	if history.is_empty():
		return 1 if str(field.get("last_family","")) == family else 0
	var streak: int = 0
	for offset in range(1,4):
		var index: int = history.size()-offset
		if index < 0: break
		var entry: Variant = history[index]
		if typeof(entry) != TYPE_DICTIONARY: break
		var crop: Dictionary = crops.get(str(entry.get("crop","")),{})
		if crop.is_empty():
			if streak == 0 and str(field.get("last_family","")) == family: return 1
			break
		if str(crop.get("family","")) != family: break
		streak += 1
	return streak

static func rotation_growth_factor(streak: int) -> float:
	return [1.0,0.90,0.80,0.68][clampi(streak,0,3)]

static func rotation_nutrient_factor(streak: int) -> float:
	return 1.0+0.20*clampf(float(streak),0.0,3.0)

static func rotation_nematode_factor(streak: int) -> float:
	if streak <= 0: return 0.9
	return 1.2+0.1*minf(float(streak-1),2.0)

static func rotation_suggestions(field: Dictionary, crops: Dictionary, spanish: bool, limit: int = 4, history_crops: Dictionary = {}) -> Array:
	var results: Array = []
	var history_catalog: Dictionary = history_crops if not history_crops.is_empty() else crops
	var soil: Dictionary = field.get("soil", {})
	for crop_id in crops.keys():
		var entry: Dictionary = crops[crop_id]
		var family: String = str(entry.get("family", ""))
		var streak: int = rotation_streak(field,history_catalog,family)
		if str(field.get("plot_type","")) == "orchard": streak = 0
		var rotation: bool = streak > 0
		var nutrient: float = minf(float(soil.get("n",0.0))/35.0, minf(float(soil.get("p",0.0))/17.0,float(soil.get("k",0.0))/65.0))
		var score: float = 70.0 + 18.0 * clampf(nutrient,0.0,1.0) - 26.0*streak
		if family == "legume" or family == "legumes":
			score += 8.0
		var localized: Variant = entry.get("name",crop_id)
		var name: String = str(localized.get("es" if spanish else "en",crop_id)) if localized is Dictionary else str(localized)
		results.append({"id":str(crop_id),"name":name,"score":clampf(score,0.0,100.0),"repeat":rotation,"streak":streak,
			"growth_factor":rotation_growth_factor(streak),"nutrient_factor":rotation_nutrient_factor(streak),
			"nematode_factor":rotation_nematode_factor(streak),"nitrogen_fixation":family in ["legume","legumes"]})
	results.sort_custom(func(a,b): return float(a["score"]) > float(b["score"]) if float(a["score"]) != float(b["score"]) else str(a["id"]) < str(b["id"]))
	return results.slice(0,mini(limit,results.size()))

static func forecast(state: Dictionary, spanish: bool = false) -> Array:
	# Model climate probabilities, not privileged knowledge of the upcoming RNG.
	var season: int = int(state["time"]["season"]) % 4
	var chance: float = [0.50,0.28,0.50,0.62][season]
	if str(state.get("difficulty","")) == "hard" or str(state.get("mode","")) == "challenge":
		chance *= 0.78
	var day: int = int(state["time"]["day"])
	var today_temp: float = float(state["weather"]["temperature"])
	var output: Array = []
	for d in range(1,4):
		var wobble: float = sin(float(day * 11 + d * 19 + int(state.get("seed",0)) % 1009) * 0.43) * 0.11
		var pct: int = int(round(clampf(chance + wobble,0.10,0.88) * 100.0))
		var projected: int = int(round(today_temp * 0.38 + [18.0,27.0,17.0,8.0][season] * 0.62 + sin(float(day + d) * 1.2) * 3.0))
		output.append({"day":day+d,"rain_percent":pct,"temperature":projected,"summary":("Lluvia posible" if spanish else "Rain possible") if pct >= 50 else ("Mas bien seco" if spanish else "Mostly dry")})
	return output

static func budget(state: Dictionary, buildings_catalog: Dictionary, animals_catalog: Dictionary) -> Dictionary:
	var building_daily: float = 0.0
	for b in state.get("buildings", []):
		if int(b["level"]) > 0:
			building_daily += float(buildings_catalog.get(str(b["kind"]),{}).get("upkeepDaily",0.0)) * int(b["level"])
	var machinery_daily: float = 0.0
	for id in state.get("life",{}).get("machines",{}).keys():
		machinery_daily += float(MACHINES.get(str(id),{}).get("upkeep",0.0))
	var feed_daily: float = 0.0
	var water_daily: float = 0.0
	for a in state.get("animals",[]):
		var count: float = float(a.get("count",0))
		var definition: Dictionary = animals_catalog.get(str(a.get("kind","")),{})
		feed_daily += count * float(definition.get("feedKgDaily",0.0)) * (1.10 if str(a.get("feeding","standard")) == "balanced" else 1.0)
		water_daily += count * float(definition.get("waterM3Daily",0.0))
	var upkeep: float = building_daily + machinery_daily
	return {"building_upkeep":building_daily,"machine_upkeep":machinery_daily,"fixed_daily":upkeep,"week_fixed":upkeep*7.0,"cash":float(state["economy"]["cash"]),"days_runway":floorf(float(state["economy"]["cash"]) / upkeep) if upkeep > 0.0 else -1.0,"feed_estimate":feed_daily,"water_estimate":water_daily}

static func suggested_slot(buildings: Array) -> int:
	var occupied: Dictionary = {}
	for b in buildings:
		if str(b.get("field","")) == "":
			occupied[int(b.get("slot",-1))] = true
	for i in range(CONSTRUCTION_SLOT_COUNT):
		if not occupied.has(i):
			return i
	return -1
