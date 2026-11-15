extends RefCounted
## Fieldwork 5.2: data and pure calculations for plot layouts and crop varieties.
## No UI, RNG, file writes, or independent inventory transactions here.

const PLOTS = {
	"open":{"name":{"en":"Open field","es":"Parcela abierta"},"description":{"en":"Versatile soil for ordinary crops. No ongoing layout bonus.","es":"Suelo versatil para cultivos comunes, sin ventaja especial."},"cost":65.0,"capacity":1.0,"rain":1.0,"evap":1.0,"growth":1.0},
	"raised":{"name":{"en":"Raised beds","es":"Bancales elevados"},"description":{"en":"Faster vegetable growth and less compaction; dries out sooner.","es":"Hortalizas mas rapidas y menos compactacion; se seca antes."},"cost":190.0,"capacity":0.84,"rain":0.96,"evap":1.14,"growth":1.075},
	"orchard":{"name":{"en":"Orchard / vineyard","es":"Frutal / vinedo"},"description":{"en":"For perennial fruit trees and vines. Higher upfront cost, repeated harvests.","es":"Frutales y vides perennes: inversion inicial y cosechas repetidas."},"cost":510.0,"capacity":1.12,"rain":1.05,"evap":0.90,"growth":1.0},
	"paddy":{"name":{"en":"Irrigated paddy","es":"Arrozal irrigado"},"description":{"en":"Retains more rain and water for rice; loses water through daily seepage.","es":"Retiene mas lluvia y agua para arroz, pero pierde agua por filtracion."},"cost":365.0,"capacity":1.38,"rain":1.24,"evap":0.94,"growth":1.0}
}
const VARIETIES = {
	"standard":{"name":{"en":"Standard seeds","es":"Semilla normal"},"seed":1.0,"growth":1.0,"yield":1.0,"water":1.0},
	"early":{"name":{"en":"Early maturity","es":"Maduracion temprana"},"seed":1.17,"growth":1.19,"yield":0.88,"water":1.0},
	"resilient":{"name":{"en":"Drought-tolerant","es":"Tolerante a sequia"},"seed":1.24,"growth":0.96,"yield":0.98,"water":0.78}
}
const ORCHARD_CROPS = ["apple","olive","almond","grape"]
const PADDY_CROPS = ["rice"]

static func localized(entry: Dictionary, lang: String) -> String:
	var name: Dictionary = entry.get("name",{})
	return str(name.get(lang,name.get("en","?")))

static func allowed_layout(layout: String, terrain: String) -> bool:
	if not PLOTS.has(layout):
		return false
	if layout == "paddy":
		return terrain in ["stream","marsh","clay","loam","terrace"]
	if layout in ["orchard","raised"]:
		return terrain != "marsh"
	return true

static func allows_crop(field: Dictionary, crop: Dictionary) -> bool:
	var layout: String = str(field.get("plot_type","open"))
	var group: String = str(crop.get("plotMode","field"))
	if group == "orchard":
		return layout == "orchard"
	if group == "paddy":
		return layout == "paddy"
	return layout in ["open","raised"]

static func crop_group(crop: Dictionary, spanish: bool = false) -> String:
	var group: String = str(crop.get("plotMode","field"))
	if group == "orchard":
		return "Frutal perenne" if spanish else "Perennial orchard"
	if group == "paddy":
		return "Solo arrozal" if spanish else "Paddy only"
	return "Huerto / bancales" if spanish else "Open / raised"

static func water_factor(field: Dictionary, crop: Dictionary) -> float:
	var soil: Dictionary = field.get("soil",{})
	var capacity: float = maxf(1.0,float(soil.get("capacity",160.0)))
	var ratio: float = clampf(float(soil.get("water",0.0)) / (capacity * 0.55),0.05,1.0)
	var variety: Dictionary = VARIETIES.get(str(crop.get("variety","standard")),VARIETIES["standard"])
	var drought_relief: float = 1.0 - float(variety.get("water",1.0))
	var result: float = ratio + (1.0 - ratio) * drought_relief
	if str(field.get("plot_type","open")) == "paddy":
		result *= 0.35 + 0.65 * clampf(float(soil.get("water",0.0)) / (capacity * 0.52),0.0,1.0)
	return clampf(result,0.02,1.0)

static func growth_factor(field: Dictionary, crop: Dictionary, season: int) -> float:
	var layout: String = str(field.get("plot_type","open"))
	var variety: Dictionary = VARIETIES.get(str(crop.get("variety","standard")),VARIETIES["standard"])
	var result: float = float(PLOTS.get(layout,PLOTS["open"])["growth"]) * float(variety["growth"])
	if layout == "orchard" and season == 3:
		result *= 0.38 # winter dormancy; trees survive and wait for spring
	return result

static func duration(crop_def: Dictionary, crop_state: Dictionary) -> float:
	if bool(crop_def.get("perennial",false)) and int(crop_state.get("harvest_cycles",0)) > 0:
		return maxf(24.0,float(crop_def.get("regrowHours",crop_def.get("growHours",240.0))))
	return maxf(24.0,float(crop_def.get("growHours",120.0)))
