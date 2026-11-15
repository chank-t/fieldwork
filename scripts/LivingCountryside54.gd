extends RefCounted
## Fieldwork 5.4 - deterministic village schedules, regional activities, and
## scenic discoveries. Pure data/rules: never mutates the farm or consumes RNG.

const SITES = {
	"village_square":{"region":"village","name":{"en":"Willow Square","es":"Plaza del Sauce"},"description":{"en":"The village noticeboard and its old stone well.","es":"El tablon del pueblo y su antiguo pozo de piedra."},"cost":2.0,"energy":6.0},
	"river_ford":{"region":"river","name":{"en":"Silver Ford","es":"Vado Plateado"},"description":{"en":"A quiet crossing where herons watch the current.","es":"Un paso tranquilo donde las garzas vigilan la corriente."},"cost":4.0,"energy":8.0},
	"forest_clearing":{"region":"woods","name":{"en":"Mosswood Clearing","es":"Claro del Bosque"},"description":{"en":"An ancient stump surrounded by wild berries.","es":"Un tocon antiguo rodeado de bayas silvestres."},"cost":4.0,"energy":9.0},
	"hill_lookout":{"region":"hills","name":{"en":"Golden Lookout","es":"Mirador Dorado"},"description":{"en":"A high trail overlooking the farms and vineyards.","es":"Un sendero elevado con vistas a fincas y vinedos."},"cost":5.0,"energy":10.0},
	"marsh_hide":{"region":"marsh","name":{"en":"Reed Bird Hide","es":"Observatorio de Juncos"},"description":{"en":"A small hide overlooking a protected pool.","es":"Un observatorio junto a una charca protegida."},"cost":5.0,"energy":11.0},
	"orchard_lane":{"region":"orchard","name":{"en":"Heritage Orchard Lane","es":"Camino de Frutales"},"description":{"en":"An old lane lined with apple and olive trees.","es":"Un camino antiguo bordeado de manzanos y olivos."},"cost":3.0,"energy":7.0},
	"lake_jetty":{"region":"lake","name":{"en":"Bluewater Jetty","es":"Embarcadero del Lago Azul"},"description":{"en":"A lakeside boardwalk overlooking reeds and open water.","es":"Una pasarela entre juncos y aguas abiertas."},"cost":6.0,"energy":11.0},
	"quarry_gate":{"region":"quarry","name":{"en":"Old Quarry Gate","es":"Entrada de la Cantera Vieja"},"description":{"en":"The entrance to a forgotten stone-cutters trail.","es":"La entrada a un antiguo sendero de canteros."},"cost":7.0,"energy":12.0}
}

const ACTIVITIES = {
	"market_volunteer":{"region":"village","name":{"en":"Help at the village market","es":"Ayudar en el mercado"},"description":{"en":"Help a trader set up for the day; gain reputation.","es":"Ayuda a montar un puesto y gana reputacion."},"fee":8.0,"energy":9.0,"hours":2,"good":"","quantity":0.0,"reputation":2,"xp":24},
	"river_herbs":{"region":"river","name":{"en":"Riverside herb walk","es":"Paseo de hierbas junto al rio"},"description":{"en":"Collect herbs without overharvesting the banks.","es":"Recoge hierbas sin agotar las riberas."},"fee":6.0,"energy":11.0,"hours":2,"good":"herbs","quantity":3.0,"reputation":0,"xp":22},
	"woodland_berries":{"region":"woods","name":{"en":"Woodland berry walk","es":"Ruta de bayas del bosque"},"description":{"en":"Gather seasonal berries from the woodland path.","es":"Recoge bayas de temporada en el sendero."},"fee":7.0,"energy":13.0,"hours":2,"good":"berries","quantity":3.0,"reputation":0,"xp":24},
	"hill_survey":{"region":"hills","name":{"en":"Landscape survey","es":"Observacion del paisaje"},"description":{"en":"Observe the watershed and learn from the terrain.","es":"Observa la cuenca y aprende del terreno."},"fee":5.0,"energy":12.0,"hours":2,"good":"","quantity":0.0,"reputation":1,"xp":31},
	"birdwatch":{"region":"marsh","name":{"en":"Wetland birdwatching","es":"Observacion de aves"},"description":{"en":"Count birds from the hide without disturbing nests.","es":"Cuenta aves sin molestar a sus nidos."},"fee":5.0,"energy":10.0,"hours":2,"good":"","quantity":0.0,"reputation":1,"xp":34},
	"fruit_trail":{"region":"orchard","name":{"en":"Orchard harvest workshop","es":"Taller de cosecha del huerto"},"description":{"en":"Join a small seasonal fruit picking group.","es":"Participa en una pequena cosecha de fruta."},"fee":9.0,"energy":13.0,"hours":2,"good":"apple","quantity":2.0,"reputation":0,"xp":25},
	"lake_clean_up":{"region":"lake","name":{"en":"Lakeside habitat clean-up","es":"Limpieza de habitat del lago"},"description":{"en":"Join a supervised effort to keep the lake shore healthy.","es":"Participa en el cuidado de la orilla del lago."},"fee":6.0,"energy":12.0,"hours":2,"good":"reeds","quantity":2.0,"reputation":1,"xp":29},
	"quarry_walk":{"region":"quarry","name":{"en":"Quarry heritage survey","es":"Recorrido historico por la cantera"},"description":{"en":"Document old paths and collect loose stone for restoration.","es":"Documenta rutas antiguas y recoge piedra suelta para restaurar."},"fee":7.0,"energy":14.0,"hours":3,"good":"stone","quantity":3.0,"reputation":1,"xp":32}
}

const NPC_ORDER = ["ines","mateo","rosa","bruno","lila","clara","elena","paco","omar","sofia"]
const ROUTES = [
	["village","orchard","village"],
	["hills","village","river"],
	["orchard","village","woods"],
	["village","river","village"],
	["marsh","woods","village"],
	["village","orchard","village"],
	["lake","village","river"],
	["village","river","marsh"],
	["quarry","village","hills"],
	["orchard","village","village"]
]

static func npc_region(npc_id: String, day: int, hour: int) -> String:
	var npc_index: int = NPC_ORDER.find(npc_id)
	if npc_index < 0:
		return ""
	# All NPCs go home for the night. Every seventh day is market day.
	if hour < 7 or hour >= 21:
		return "village"
	if (day - 1) % 7 == 6 and hour >= 10 and hour < 17:
		return "village"
	var index: int = 0 if hour < 12 else (1 if hour < 17 else 2)
	return str(ROUTES[npc_index][index])

static func villagers_at(region_id: String, day: int, hour: int) -> Array:
	var result: Array = []
	for npc_id in NPC_ORDER:
		if npc_region(str(npc_id),day,hour) == region_id:
			result.append(npc_id)
	return result

static func locations_in(region_id: String) -> Array:
	var result: Array = []
	for site_id in SITES.keys():
		if str(SITES[site_id]["region"]) == region_id:
			result.append(site_id)
	return result

static func activities_in(region_id: String) -> Array:
	var result: Array = []
	for activity_id in ACTIVITIES.keys():
		if str(ACTIVITIES[activity_id]["region"]) == region_id:
			result.append(activity_id)
	return result

static func label(entry: Dictionary, language: String, key: String = "name") -> String:
	var names: Variant = entry.get(key,{})
	if typeof(names) == TYPE_DICTIONARY:
		return str(names.get(language,names.get("en","")))
	return ""

static func new_state() -> Dictionary:
	return {"discovered":[],"met_days":{},"activity_days":{},"activity_history":[],"meetings":0,"activities":0}

static func valid(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if typeof(data.get("discovered")) != TYPE_ARRAY or data["discovered"].size() > SITES.size():
		return false
	if typeof(data.get("met_days")) != TYPE_DICTIONARY or typeof(data.get("activity_days")) != TYPE_DICTIONARY:
		return false
	if typeof(data.get("activity_history")) != TYPE_ARRAY or data["activity_history"].size() > 80:
		return false
	if int(data.get("meetings",-1)) < 0 or int(data.get("activities",-1)) < 0:
		return false
	var unique: Dictionary = {}
	for site_id in data["discovered"]:
		if typeof(site_id) != TYPE_STRING or not SITES.has(str(site_id)) or unique.has(str(site_id)):
			return false
		unique[str(site_id)] = true
	for npc_id in data["met_days"].keys():
		if not NPC_ORDER.has(str(npc_id)) or int(data["met_days"][npc_id]) < 0:
			return false
	for activity_id in data["activity_days"].keys():
		if not ACTIVITIES.has(str(activity_id)) or int(data["activity_days"][activity_id]) < 0:
			return false
	for item in data["activity_history"]:
		if typeof(item) != TYPE_DICTIONARY or not ACTIVITIES.has(str(item.get("id",""))) or int(item.get("day",-1)) < 0:
			return false
	return true
