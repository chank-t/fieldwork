extends RefCounted
const Data = preload("res://scripts/NativeData.gd")
## Fieldwork 5.8 — Beyond the Farm.
## Data and validation only. The farm model owns every financial or state change.
## Eight three-step regional projects; all amounts are fictional gameplay values.

const PROFESSIONS: Dictionary = {
	"pathfinder":{"name":{"en":"Pathfinder","es":"Explorador de rutas"},"detail":{"en":"Expeditions use 20% less energy and cost 15% less.","es":"Las expediciones consumen un 20% menos de energia y cuestan un 15% menos."}},
	"naturalist":{"name":{"en":"Naturalist","es":"Naturalista"},"detail":{"en":"Expeditions award 30% more exploration XP and extra stewardship reputation.","es":"Las expediciones dan un 30% mas de experiencia de exploracion y reputacion."}},
	"artisan":{"name":{"en":"Community artisan","es":"Artesano comunitario"},"detail":{"en":"Completed projects award 2 extra units of produce when storage allows.","es":"Los proyectos terminados dan 2 unidades extra de productos si hay espacio."}}
}

const PROJECTS: Dictionary = {
	"village":{"name":{"en":"Restore the village noticeboard","es":"Restaurar el tablon del pueblo"},"story":{"en":"A meeting place for growers has fallen into disrepair.","es":"El lugar donde se reunen los agricultores necesita reparaciones."},"partner":"ines","material":"timber","quantity":2.0,"reward":"feed","reward_quantity":4.0,"fee":8.0,"energy":9.0,"hours":2,"steps":[{"en":"Survey the old meeting place","es":"Inspeccionar la plaza"},{"en":"Repair the community board","es":"Reparar el tablon"},{"en":"Celebrate the reopening","es":"Celebrar la reapertura"}]},
	"river":{"name":{"en":"Bring life back to Silver River","es":"Recuperar el Rio Plateado"},"story":{"en":"Restore an old riverside walk while protecting wildlife.","es":"Recupera un paseo junto al rio y protege su fauna."},"partner":"mateo","material":"clay","quantity":3.0,"reward":"herbs","reward_quantity":3.0,"fee":9.0,"energy":11.0,"hours":2,"steps":[{"en":"Survey the river banks","es":"Inspeccionar la ribera"},{"en":"Rebuild the footpath","es":"Restaurar la senda"},{"en":"Open a nature trail","es":"Abrir la ruta natural"}]},
	"woods":{"name":{"en":"Mosswood field station","es":"Estacion de campo del Bosque del Musgo"},"story":{"en":"Help local guides create a safe place to study the forest.","es":"Ayuda a crear un punto para estudiar el bosque."},"partner":"rosa","material":"timber","quantity":4.0,"reward":"berries","reward_quantity":4.0,"fee":10.0,"energy":13.0,"hours":3,"steps":[{"en":"Mark a forest route","es":"Marcar una ruta"},{"en":"Build a field shelter","es":"Construir un refugio"},{"en":"Start the forest surveys","es":"Iniciar los censos forestales"}]},
	"hills":{"name":{"en":"Golden Hills lookout","es":"Mirador de las Colinas Doradas"},"story":{"en":"An abandoned viewpoint could serve the valley again.","es":"Un mirador abandonado puede servir de nuevo al valle."},"partner":"bruno","material":"stone","quantity":4.0,"reward":"herbs","reward_quantity":3.0,"fee":12.0,"energy":14.0,"hours":3,"steps":[{"en":"Map the ridge","es":"Cartografiar la cresta"},{"en":"Secure the lookout","es":"Asegurar el mirador"},{"en":"Welcome the first visitors","es":"Recibir a los primeros visitantes"}]},
	"marsh":{"name":{"en":"Reed Marsh bird sanctuary","es":"Refugio de aves del Humedal de Juncos"},"story":{"en":"Create a quiet place for observing wetland wildlife.","es":"Crea un lugar tranquilo para observar la fauna del humedal."},"partner":"lila","material":"reeds","quantity":3.0,"reward":"mushrooms","reward_quantity":2.0,"fee":11.0,"energy":13.0,"hours":2,"steps":[{"en":"Count wetland birds","es":"Contar aves del humedal"},{"en":"Prepare the bird hide","es":"Preparar el observatorio"},{"en":"Open the sanctuary","es":"Abrir el refugio"}]},
	"orchard":{"name":{"en":"Heritage orchard revival","es":"Recuperacion del huerto antiguo"},"story":{"en":"Help preserve a collection of traditional fruit trees.","es":"Ayuda a conservar las variedades tradicionales de frutales."},"partner":"clara","material":"wildflowers","quantity":3.0,"reward":"apple","reward_quantity":3.0,"fee":10.0,"energy":10.0,"hours":2,"steps":[{"en":"Inventory the old trees","es":"Inventariar los arboles"},{"en":"Restore the pollinator border","es":"Recuperar la franja de polinizadores"},{"en":"Host a local harvest day","es":"Celebrar una jornada de cosecha"}]},
	"lake":{"name":{"en":"Bluewater Lake conservation","es":"Conservacion del Lago Azul"},"story":{"en":"Revive the lakeside jetty and make space for aquatic wildlife.","es":"Recupera el embarcadero y protege la fauna acuatica."},"partner":"elena","material":"reeds","quantity":4.0,"reward":"herbs","reward_quantity":4.0,"fee":13.0,"energy":15.0,"hours":3,"steps":[{"en":"Survey the shore","es":"Inspeccionar la orilla"},{"en":"Restore the jetty","es":"Restaurar el embarcadero"},{"en":"Start lakeside workshops","es":"Iniciar talleres en el lago"}]},
	"quarry":{"name":{"en":"Old Stone Quarry heritage trail","es":"Ruta historica de la Cantera Vieja"},"story":{"en":"Turn a disused quarry into a safe outdoor learning trail.","es":"Convierte una antigua cantera en un sendero educativo."},"partner":"omar","material":"stone","quantity":5.0,"reward":"clay","reward_quantity":4.0,"fee":14.0,"energy":16.0,"hours":3,"steps":[{"en":"Inspect the old quarry","es":"Inspeccionar la cantera"},{"en":"Mark the safe paths","es":"Senalizar los caminos"},{"en":"Open the heritage route","es":"Abrir la ruta historica"}]}
}

const REGION_ORDER: Array = ["village","river","woods","hills","marsh","orchard","lake","quarry"]

static func label(item: Dictionary, language: String, key: String = "name") -> String:
	var values: Dictionary = item.get(key,{})
	return str(values.get(language,values.get("en","")))

static func step_label(item: Dictionary, stage: int, language: String) -> String:
	var steps: Array = item.get("steps",[])
	if stage < 0 or stage >= steps.size():
		return ""
	return label({"name":steps[stage]}, language)

static func new_state() -> Dictionary:
	return {"profession":"none","profession_change_day":-9999,"chapters":{},"chapter_days":{},"history":[],"completed":0}

static func ensure(data: Dictionary) -> Dictionary:
	var answer: Dictionary = new_state()
	for key in answer.keys():
		if data.has(key):
			answer[key] = data[key]
	return answer

static func valid(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("profession") or not (str(data["profession"]) == "none" or PROFESSIONS.has(str(data["profession"]))):
		return false
	if not Data.is_json_integer(data.get("profession_change_day")) or int(data["profession_change_day"]) < -9999:
		return false
	if typeof(data.get("chapters")) != TYPE_DICTIONARY or typeof(data.get("chapter_days")) != TYPE_DICTIONARY:
		return false
	if typeof(data.get("history")) != TYPE_ARRAY or data["history"].size() > 100:
		return false
	var completed_count: int = 0
	for region_id in data["chapters"].keys():
		if not PROJECTS.has(str(region_id)) or not Data.is_json_integer(data["chapters"][region_id]):
			return false
		var chapter: int = int(data["chapters"][region_id])
		if chapter < 1 or chapter > 3:
			return false
		if chapter == 3:
			completed_count += 1
	for region_id in data["chapter_days"].keys():
		if not PROJECTS.has(str(region_id)) or not Data.is_json_integer(data["chapter_days"][region_id]) or int(data["chapter_days"][region_id]) < 1:
			return false
	if not Data.is_json_integer(data.get("completed")) or int(data["completed"]) != completed_count:
		return false
	for entry in data["history"]:
		if typeof(entry) != TYPE_DICTIONARY:
			return false
		if not PROJECTS.has(str(entry.get("region",""))) or not Data.is_json_integer(entry.get("stage")) or not Data.is_json_integer(entry.get("day")):
			return false
		if int(entry["stage"]) < 1 or int(entry["stage"]) > 3 or int(entry["day"]) < 1:
			return false
		if not ["protect","trade"].has(str(entry.get("approach",""))):
			return false
	return true
