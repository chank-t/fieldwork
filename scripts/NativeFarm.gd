extends RefCounted
## Fully native GDScript farming and economy model. All state changes occur
## via act(). A rejected action restores cash, RNG, crops and inventory.
## The equations are a new game-model adaptation, not bitwise parity with JS.

const Data = preload("res://scripts/NativeData.gd")
const Decisions = preload("res://scripts/DecisionContent.gd")
const Chains = preload("res://scripts/ChoiceChains.gd")
const Life = preload("res://scripts/FarmingLife.gd")
const World50 = preload("res://scripts/WorldWorth.gd")
const Fields52 = preload("res://scripts/FieldsOpportunity.gd")
const Style53 = preload("res://scripts/FarmerStyle.gd")
const Country54 = preload("res://scripts/LivingCountryside.gd")
const Living57 = preload("res://scripts/LivingFarm.gd")
const Beyond58 = preload("res://scripts/BeyondFarm.gd")
const SAVE_FILE = "user://fieldwork_native_6_0.json"
const V59_SAVE_FILE = "user://fieldwork_native_5_9.json"
const V58_SAVE_FILE = "user://fieldwork_native_5_8.json"
const V57_SAVE_FILE = "user://fieldwork_native_5_7.json"
const PREVIOUS_SAVE_FILE = "user://fieldwork_native_5_6.json"
const V55_SAVE_FILE = "user://fieldwork_native_5_5.json"
const V54_SAVE_FILE = "user://fieldwork_native_5_4.json"
const OLDER_SAVE_FILE = "user://fieldwork_native_5_3.json"
const V52_SAVE_FILE = "user://fieldwork_native_5_2.json"
const V51_SAVE_FILE = "user://fieldwork_native_5_1.json"
const V50_SAVE_FILE = "user://fieldwork_native_5_0.json"
const PRIOR_SAVE_FILE = "user://fieldwork_native_4_9.json"
const V48_SAVE_FILE = "user://fieldwork_native_4_8.json"
const LEGACY_SAVE_FILE = "user://fieldwork_native_4_5.json"
const ANCIENT_SAVE_FILE = "user://fieldwork_native_4_1.json"
const VERSION = 10
const SAVE_SLOT_COUNT = 3
const SLOT_DIRECTORY = "user://fieldwork_slots_60"
const V59_SLOT_DIRECTORY = "user://fieldwork_slots_59"
const V58_SLOT_DIRECTORY = "user://fieldwork_slots_58"
const V57_SLOT_DIRECTORY = "user://fieldwork_slots_57"
const PREVIOUS_SLOT_DIRECTORY = "user://fieldwork_slots_56"
const V55_SLOT_DIRECTORY = "user://fieldwork_slots_55"
const V54_SLOT_DIRECTORY = "user://fieldwork_slots_54"
const OLDER_SLOT_DIRECTORY = "user://fieldwork_slots_53"
const V52_SLOT_DIRECTORY = "user://fieldwork_slots_52"
const V51_SLOT_DIRECTORY = "user://fieldwork_slots_51"
const V50_SLOT_DIRECTORY = "user://fieldwork_slots_50"
const V49_SLOT_DIRECTORY = "user://fieldwork_slots_49"
const LEGACY_SLOT_DIRECTORY = "user://fieldwork_slots"
const MAX_FIELDS = 24
const SEASON_DAYS = 12
const AREA_HA = 0.25
const TERRAIN_ORDER = [
	"loam", "stream", "hill", "clay", "wild", "sand",
	"forest", "terrace", "marsh", "rocky", "loam", "wild",
	"terrace", "stream", "forest", "sand", "clay", "hill",
	"marsh", "loam", "rocky", "wild", "forest", "terrace"
]
const REGIONS = {
	"village":{"name":{"en":"Willow Village","es":"Villa Sauce"},"description":{"en":"A warm village with a market and friendly farmers.","es":"Un pueblo amable con mercado y agricultores."},"hours":1,"fee":0.0,"risk":0.00,"find":"feed"},
	"river":{"name":{"en":"Silver River","es":"Rio Plateado"},"description":{"en":"Riverbank foraging, water and watchful wildlife.","es":"Recoleccion en la ribera y fauna salvaje."},"hours":3,"fee":8.0,"risk":0.12,"find":"herbs"},
	"woods":{"name":{"en":"Mosswood Forest","es":"Bosque del Musgo"},"description":{"en":"A quiet woodland with edible berries in the game.","es":"Bosque tranquilo con bayas del juego."},"hours":4,"fee":12.0,"risk":0.15,"find":"berries"},
	"hills":{"name":{"en":"Golden Hills","es":"Colinas Doradas"},"description":{"en":"Hill paths with wild herbs and animal tracks.","es":"Senderos con hierbas y rastros de fauna."},"hours":5,"fee":15.0,"risk":0.16,"find":"herbs"},
	"marsh":{"name":{"en":"Reed Wetlands","es":"Humedal de Juncos"},"description":{"en":"A biodiverse but difficult wetland habitat.","es":"Un humedal con mucha biodiversidad y riesgos."},"hours":4,"fee":10.0,"risk":0.24,"find":"mushrooms"},
	"orchard":{"name":{"en":"Old Orchard","es":"Huerto Antiguo"},"description":{"en":"Meet other farmers and gather seasonal fruit.","es":"Conoce agricultores y recoge fruta de temporada."},"hours":3,"fee":6.0,"risk":0.05,"find":"berries"},
	"lake":{"name":{"en":"Bluewater Lake","es":"Lago Azul"},"description":{"en":"A calm lake with birds, reeds and a weathered jetty.","es":"Un lago con aves, juncos y un viejo embarcadero."},"hours":4,"fee":11.0,"risk":0.10,"find":"herbs"},
	"quarry":{"name":{"en":"Old Stone Quarry","es":"Cantera Vieja"},"description":{"en":"Old stone-cutters paths and a wide view of the valley.","es":"Antiguos caminos de canteros y vistas del valle."},"hours":5,"fee":13.0,"risk":0.15,"find":"stone"}
}
# Local gathering is limited to one trip per region and simulated day. These
# resource rates and costs are fictional game-balancing values, not field data.
const MATERIAL_SITES = {
	"woods":{"good":"timber","kg":9.0,"fee":6.0,"hours":3,"energy":13.0},
	"hills":{"good":"stone","kg":11.0,"fee":7.0,"hours":4,"energy":16.0},
	"river":{"good":"clay","kg":8.0,"fee":5.0,"hours":3,"energy":12.0},
	"orchard":{"good":"wildflowers","kg":5.0,"fee":4.0,"hours":2,"energy":9.0},
	"marsh":{"good":"reeds","kg":8.0,"fee":5.0,"hours":3,"energy":15.0},
	"lake":{"good":"reeds","kg":7.0,"fee":6.0,"hours":3,"energy":13.0},
	"quarry":{"good":"stone","kg":10.0,"fee":7.0,"hours":4,"energy":17.0}
}
const DECORATIONS = {
	"bench":{"name":{"en":"Woodland bench","es":"Banco del bosque"},"materials":{"timber":5.0,"stone":2.0},"fee":15.0,"hours":8,"level":1,"icon":"bench"},
	"flowerArch":{"name":{"en":"Flower arch","es":"Arco de flores"},"materials":{"timber":3.0,"wildflowers":4.0},"fee":12.0,"hours":10,"level":2,"icon":"flower_arch"},
	"birdhouse":{"name":{"en":"Birdhouse","es":"Casita de aves"},"materials":{"timber":3.0,"reeds":2.0},"fee":9.0,"hours":6,"level":2,"icon":"birdhouse"},
	"lantern":{"name":{"en":"Lantern stand","es":"Farol de jardin"},"materials":{"timber":2.0,"stone":2.0,"clay":1.0},"fee":20.0,"hours":12,"level":3,"icon":"lantern"},
	"stonePath":{"name":{"en":"Garden stepping stones","es":"Piedras de jardin"},"materials":{"stone":6.0,"clay":2.0},"fee":8.0,"hours":7,"level":1,"icon":"stone_path"}
}
const MASTERY_TRACKS = ["farming", "ecology", "livestock", "crafting", "trading", "exploration", "community"]
const PEST_IDS = ["aphids", "caterpillars", "slugs", "mites", "whiteflies", "cutworms", "locusts", "nematodes"]
const DISEASE_IDS = ["mildew", "blight", "rootRot"]
const RECIPES = {
	"flour":{"input":"wheat","output":"flour","ratio":0.78,"hours":8,"building":"mill","cost":0.12},
	"oil":{"input":"sunflower","output":"oil","ratio":0.35,"hours":12,"building":"press","cost":0.20},
	"cheese":{"input":"milk","output":"cheese","ratio":0.20,"hours":12,"building":"dairy","cost":0.15},
	"jam":{"input":"strawberry","output":"jam","ratio":0.65,"hours":10,"building":"kitchen","cost":0.30},
	"cornmeal":{"input":"maize","output":"cornmeal","ratio":0.72,"hours":8,"building":"mill","cost":0.13},
	"tomato_sauce":{"input":"tomato","output":"tomato_sauce","ratio":0.65,"hours":9,"building":"kitchen","cost":0.24},
	"lavender_oil":{"input":"lavender","output":"lavender_oil","ratio":0.12,"hours":12,"building":"press","cost":0.45}
}
const QUESTS = {
	"firstHarvest":{"en":"First harvest","es":"Primera cosecha","stat":"harvest_kg","target":150.0,"reward":190.0},
	"expansion":{"en":"Growing roots","es":"Echar raices","stat":"fields_bought","target":1.0,"reward":160.0},
	"artisan":{"en":"Artisan's first batch","es":"Primera produccion artesanal","stat":"processed_kg","target":100.0,"reward":210.0},
	"herd":{"en":"Animals are thriving","es":"Animales sanos","stat":"animal_kg","target":20.0,"reward":180.0},
	"trusted":{"en":"A reliable supplier","es":"Proveedor fiable","stat":"contracts_delivered","target":3.0,"reward":250.0},
	"builder":{"en":"Build a home","es":"Levanta tu hogar","stat":"buildings_completed","target":4.0,"reward":230.0},
	"gatherer":{"en":"Valley steward","es":"Guarda del valle","stat":"resources_gathered","target":35.0,"reward":125.0},
	"gardenArtist":{"en":"Garden artist","es":"Artista del jardin","stat":"decorations_built","target":2.0,"reward":140.0}
}
const TUTORIAL = [
	{"en":"Walk on your farm with WASD or tap the map.","es":"Pasea con WASD o toca el mapa.","action":"move"},
	{"en":"Inspect the first field to read its soil and pests.","es":"Inspecciona tu primera parcela y su suelo.","action":"inspect"},
	{"en":"Plant a crop in your field.","es":"Siembra un cultivo en tu parcela.","action":"plant"},
	{"en":"Irrigate thoughtfully; the reservoir is finite.","es":"Riega con cuidado; el deposito es limitado.","action":"irrigate"},
	{"en":"Read pest pressure and use a compatible control.","es":"Revisa las plagas y aplica un control adecuado.","action":"treat"},
	{"en":"Let the simulation advance a day.","es":"Deja transcurrir un dia.","action":"tick"},
	{"en":"Harvest a ripe crop.","es":"Recoge un cultivo maduro.","action":"harvest"},
	{"en":"Sell stored produce at the market.","es":"Vende tu cosecha en el mercado.","action":"sell"},
	{"en":"Build a structure for your growing farm.","es":"Construye un edificio en tu finca.","action":"build"},
	{"en":"Enroll in a farming course.","es":"Apuntate a un curso agricola.","action":"enrollCourse"},
	{"en":"Learn a talent when you have points.","es":"Aprende una habilidad cuando tengas puntos.","action":"learnTalent"},
	{"en":"Buy another field and compare its terrain.","es":"Compra otra parcela y compara los terrenos.","action":"buyField"},
	{"en":"Inspect a neighbour's advice or a completed building.","es":"Consulta a tus vecinos o visita un edificio.","action":"visit"},
	{"en":"Travel to another valley region; bring enough energy and supplies.","es":"Viaja a otra zona del valle con energia suficiente.","action":"explore"},
	{"en":"Help one of your neighbours and build trust in the village.","es":"Ayuda a un vecino y gana confianza en el pueblo.","action":"helpNeighbour"},
	{"en":"Gather renewable materials at a valley site. Each site can be visited once a day.","es":"Recoge materiales de una zona del valle una vez al dia.","action":"gatherMaterials"},
	{"en":"Build your own garden decoration from gathered materials.","es":"Construye una decoracion con los materiales recogidos.","action":"craftDecoration"}
]

const STARTER_GUIDE = [
	{"en":"Prepare a plot: inspect its soil and moisture before planting.","es":"Prepara la parcela: revisa el suelo y la humedad antes de sembrar.","action":"inspect"},
	{"en":"Plant one crop in your field.","es":"Siembra un cultivo en tu parcela.","action":"plant"},
	{"en":"Water the crop thoughtfully; the reservoir is limited.","es":"Riega el cultivo con cuidado; la reserva es limitada.","action":"irrigate"},
	{"en":"Advance time until the crop ripens, then harvest it.","es":"Avanza el tiempo hasta que madure y recoge la cosecha.","action":"harvest"}
]
const GUIDED_ONBOARDING_STEP_COUNT: int = 10

# New lessons are appended so active 4.2 tutorials keep their step index.
# Progression bonuses do not consume simulation RNG.

var content: Dictionary = {}
var state: Dictionary = {}
var language: String = "en"
var last_error: String = ""
var messages_es: Dictionary = {}
var world_catalog: Dictionary = {}

func _init() -> void:
	content = Data.catalog()
	world_catalog = World50.catalog()
	var lang_file: FileAccess = FileAccess.open("res://data/messages_es.json",FileAccess.READ)
	if lang_file != null:
		var parsed: Variant = JSON.parse_string(lang_file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			messages_es = parsed

func _message(text_value: String) -> String:
	return str(messages_es.get(text_value,text_value)) if language == "es" else text_value

func message(text_value: String) -> String:
	return _message(text_value)

func n(entry: Variant, key: String = "name") -> String:
	return Data.name_of(entry, language, key)

func _make_field(i: int, is_owned: bool = false) -> Dictionary:
	var pests: Dictionary = {}
	for pest_id in PEST_IDS:
		pests[pest_id] = float(content.get("pests", {}).get(pest_id, {}).get("initial", 0.0))
	var diseases: Dictionary = {}
	for disease_id in DISEASE_IDS:
		diseases[disease_id] = 0.0
	var terrain: String = TERRAIN_ORDER[i]
	var capacity: float = 160.0
	if terrain == "rocky":
		capacity = 100.0
	elif terrain == "marsh":
		capacity = 205.0
	elif terrain == "sand":
		capacity = 118.0
	return {"id":"plot" + str(i + 1),"index":i,"owned":is_owned,
		"terrain":terrain,"crop":{},"last_family":"","history":[],
		"soil":{"water":minf(90.0, capacity),"capacity":capacity,"n":90.0,"p":55.0,"k":220.0,
		"organic_n":1400.0,"organic_p":220.0,"organic_k":500.0,"mulch":0.0,
		"organic_matter":2.8,"compaction":0.12,"erosion":0.02},
		"pests":pests,"diseases":diseases,"beneficial":{"ladybirds":0.6,"parasitoids":0.15,"bees":0.8},
		"protection":{},"spray_residue":0.0,"solarize_until":0,"harvests":0,"inspections":0,"last_inspection_day":-1,
		"cover_until":0,"hedgerow":false,"scouted_day":-1,"scout_report":{},
		"plot_type":"open","last_conversion_day":-9999}

func _new_overworld() -> Dictionary:
	return {"known":["village"],"visits":{},"last_region":"village","foraged":0.0,"journal":[]}

func _new_wildlife() -> Dictionary:
	return {"venom_hours":0,"gear":false,"encounters":0,"observed":{},"energy":100.0}

func _new_progression() -> Dictionary:
	var tracks: Dictionary = {}
	for id in MASTERY_TRACKS:
		tracks[id] = 0
	return {"tracks":tracks,"levels_earned":0,"recent_level":0}

func mastery_level(id: String) -> int:
	var prog: Dictionary = state.get("progression", {})
	var xp: int = int(prog.get("tracks", {}).get(id, 0))
	return 1 + int(xp / 140)

func mastery_bonus(id: String) -> float:
	return minf(0.12, 0.02 * maxi(0, mastery_level(id) - 1))

func xp_to_next_level() -> int:
	return 220 - int(state.get("player", {}).get("xp", 0)) % 220

func _migrate_v42(candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schema", -1)) != 2:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 3
	upgraded["decorations"] = []
	upgraded["resources"] = {"gathered_today":{}, "total_gathered":0.0, "crafted":0}
	upgraded["progression"] = _new_progression()
	for field in upgraded["fields"]:
		if not field.has("last_inspection_day"):
			field["last_inspection_day"] = -1
	for key in ["resources_gathered", "decorations_built", "compost_used"]:
		if not upgraded["stats"].has(key):
			upgraded["stats"][key] = 0.0
	return upgraded

func _migrate_legacy(candidate: Dictionary) -> Dictionary:
	# Keep every old field and its complete farming history. Never delete fields.
	if int(candidate.get("schema", -1)) != 1 or candidate.get("fields", []).size() != 12:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	for i in range(12, MAX_FIELDS):
		upgraded["fields"].append(_make_field(i))
	# Migrate first to the 4.2 shape; load_text then upgrades it to schema 3.
	upgraded["schema"] = 2
	upgraded["overworld"] = _new_overworld()
	upgraded["wildlife"] = _new_wildlife()
	upgraded["neighbours"] = {"favours":{},"helped":0}
	upgraded["player"]["energy"] = 100.0
	return upgraded

func _migrate_v43(candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schema",-1)) != 3:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 4
	upgraded["decisions"] = {"effects":{}, "history":[]}
	return upgraded

func _migrate_v47(candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schema",-1)) != 4:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 5
	var decisions: Dictionary = upgraded["decisions"]
	decisions["branches"] = {}
	decisions["followups"] = []
	decisions["relationships"] = {}
	decisions["relationship_history"] = []
	decisions["clues"] = {}
	decisions["last_invitation_hour"] = -72
	return upgraded

func _migrate_v48(candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schema",-1)) != 5:
		return {}
	if typeof(candidate.get("fields")) != TYPE_ARRAY or candidate["fields"].size() != MAX_FIELDS or typeof(candidate.get("animals")) != TYPE_ARRAY or typeof(candidate.get("buildings")) != TYPE_ARRAY:
		return {}
	for original_field in candidate["fields"]:
		if typeof(original_field) != TYPE_DICTIONARY or typeof(original_field.get("soil")) != TYPE_DICTIONARY:
			return {}
	for original_animal in candidate["animals"]:
		if typeof(original_animal) != TYPE_DICTIONARY:
			return {}
	for original_building in candidate["buildings"]:
		if typeof(original_building) != TYPE_DICTIONARY:
			return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 6
	if not upgraded.has("life"):
		upgraded["life"] = {"path":"balanced","last_change":-9999,"machines":{},"quality_stock":{},"vet_visits":0,"machine_breakdowns":0}
	for f in upgraded["fields"]:
		var soil: Dictionary = f["soil"]
		for key in ["organic_matter","compaction","erosion"]:
			if not soil.has(key):
				soil[key] = {"organic_matter":2.8,"compaction":0.12,"erosion":0.02}[key]
		for key in ["cover_until","hedgerow","scouted_day","scout_report"]:
			if not f.has(key):
				f[key] = {"cover_until":0,"hedgerow":false,"scouted_day":-1,"scout_report":{}}[key]
	for a in upgraded["animals"]:
		for key in ["age_days","health","nutrition","feeding","vet_until","pregnancy_due"]:
			if not a.has(key):
				a[key] = {"age_days":40,"health":clampf(float(a.get("condition",1.0)),0.2,1.0),"nutrition":0.75,"feeding":"standard","vet_until":0,"pregnancy_due":0}[key]
	# Keep existing 4.8 building positions when slot placement is introduced.
	var next_slot: int = 0
	for i in range(upgraded["buildings"].size()):
		if str(upgraded["buildings"][i].get("field","")) == "":
			upgraded["buildings"][i]["slot"] = next_slot
			next_slot += 1
		else:
			upgraded["buildings"][i]["slot"] = -1
	return upgraded

func _migrate_v49(candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schema",-1)) != 6 or typeof(candidate.get("stats")) != TYPE_DICTIONARY:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 7
	upgraded["world50"] = World50.new_state(int(upgraded["time"].get("day",1)),upgraded["stats"])
	return upgraded

func _migrate_v51(candidate: Dictionary) -> Dictionary:
	# 5.2 appends only plot metadata. Existing crops, inventory and decisions remain intact.
	if int(candidate.get("schema",-1)) != 7 or typeof(candidate.get("fields")) != TYPE_ARRAY or candidate["fields"].size() != MAX_FIELDS:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 8
	for f in upgraded["fields"]:
		if typeof(f) != TYPE_DICTIONARY or typeof(f.get("crop")) != TYPE_DICTIONARY:
			return {}
		f["plot_type"] = "open"
		f["last_conversion_day"] = -9999
		if not f["crop"].is_empty():
			f["crop"]["variety"] = "standard"
			f["crop"]["harvest_cycles"] = 0
	return upgraded

func _migrate_v52(candidate: Dictionary) -> Dictionary:
	# Keep the exact 5.2 farm. Only append cosmetic fields and three empty presets.
	if int(candidate.get("schema",-1)) != 8 or typeof(candidate.get("player")) != TYPE_DICTIONARY:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = 9
	var old_player: Dictionary = upgraded["player"]
	var normalized: Dictionary = Style53.normalize(old_player)
	for field in Style53.FIELDS:
		old_player[field] = normalized[field]
	upgraded["wardrobe53"] = Style53.new_wardrobe()
	return upgraded

func _migrate_v53(candidate: Dictionary) -> Dictionary:
	if int(candidate.get("schema",-1)) != 9 or typeof(candidate.get("wardrobe53")) != TYPE_DICTIONARY:
		return {}
	var upgraded: Dictionary = candidate.duplicate(true)
	upgraded["schema"] = VERSION
	upgraded["countryside54"] = Country54.new_state()
	return upgraded

func _upgrade_state(candidate: Dictionary) -> Dictionary:
	var loaded: Dictionary = candidate.duplicate(true)
	if int(loaded.get("schema",-1)) == 1:
		loaded = _migrate_legacy(loaded)
	if int(loaded.get("schema",-1)) == 2:
		loaded = _migrate_v42(loaded)
	if int(loaded.get("schema",-1)) == 3:
		loaded = _migrate_v43(loaded)
	if int(loaded.get("schema",-1)) == 4:
		loaded = _migrate_v47(loaded)
	if int(loaded.get("schema",-1)) == 5:
		loaded = _migrate_v48(loaded)
	if int(loaded.get("schema",-1)) == 6:
		loaded = _migrate_v49(loaded)
	if int(loaded.get("schema",-1)) == 7:
		loaded = _migrate_v51(loaded)
	if int(loaded.get("schema",-1)) == 8:
		loaded = _migrate_v52(loaded)
	if int(loaded.get("schema",-1)) == 9:
		loaded = _migrate_v53(loaded)
	if int(loaded.get("schema",-1)) == VERSION and typeof(loaded.get("countryside54")) == TYPE_DICTIONARY:
		var rural: Dictionary = loaded["countryside54"]
		if not rural.has("beyond58"):
			rural["beyond58"] = Beyond58.new_state()
		elif typeof(rural["beyond58"]) == TYPE_DICTIONARY:
			var inherited58: Dictionary = rural["beyond58"]
			rural["beyond58"] = Beyond58.ensure(inherited58)
	if typeof(loaded.get("story")) == TYPE_DICTIONARY:
		var story: Dictionary = loaded["story"]
		if not story.has("starter_guide"):
			story["starter_guide"] = STARTER_GUIDE.size()
		elif Data.is_json_integer(story["starter_guide"]) and int(story["starter_guide"]) > STARTER_GUIDE.size():
			var old_onboarding_step: int = int(story["starter_guide"])
			var saved_onboarding_step: Variant = story.get("guided_onboarding", 0)
			if Data.is_json_integer(saved_onboarding_step):
				story["guided_onboarding"] = maxi(int(saved_onboarding_step), old_onboarding_step)
			else:
				story["guided_onboarding"] = old_onboarding_step
			story["starter_guide"] = STARTER_GUIDE.size()
	return loaded

func npc_trust(npc_id: String) -> int:
	return int(state.get("decisions",{}).get("relationships",{}).get(npc_id,0))

func _change_trust(npc_id: String, amount: int, cause: String) -> void:
	if amount == 0 or not content.get("npcs",{}).has(npc_id):
		return
	var relationships: Dictionary = state["decisions"]["relationships"]
	var previous: int = int(relationships.get(npc_id,0))
	var updated: int = clampi(previous + amount,-10,10)
	if updated == previous:
		return
	relationships[npc_id] = updated
	var history: Array = state["decisions"]["relationship_history"]
	history.append({"npc":npc_id,"amount":updated-previous,"total":updated,"hour":int(state["time"]["total"]),"cause":cause})
	while history.size() > 100:
		history.pop_front()

func _effect(effect_id: String) -> float:
	var item: Dictionary = state.get("decisions",{}).get("effects",{}).get(effect_id,{})
	var timed: float = 0.0
	if not item.is_empty() and int(item.get("until",0)) > int(state.get("time",{}).get("total",0)):
		timed = float(item.get("amount",0.0))
	var relationship: float = 0.0
	match effect_id:
		"water_saver":
			if npc_trust("mateo") >= 4:
				relationship = 0.025
		"market_trust":
			if npc_trust("clara") >= 4:
				relationship = 0.025
		"pest_suppression":
			if npc_trust("lila") >= 4:
				relationship = 0.025
		"animal_welfare":
			if npc_trust("rosa") >= 4:
				relationship = 0.003
	return minf(0.9,timed + relationship)

func _grant_effect(effect_id: String, amount: float, hours: int) -> void:
	var current: int = int(state["time"]["total"])
	var previous: Dictionary = state["decisions"]["effects"].get(effect_id,{})
	var expiry: int = maxi(current + hours,int(previous.get("until",0)))
	state["decisions"]["effects"][effect_id] = {"amount":maxf(amount,float(previous.get("amount",0.0))),"until":expiry}

func active_effects() -> Array:
	var result: Array = []
	for effect_id in state.get("decisions",{}).get("effects",{}).keys():
		var item: Dictionary = state["decisions"]["effects"][effect_id]
		if int(item.get("until",0)) > int(state["time"]["total"]):
			result.append({"id":str(effect_id),"amount":float(item["amount"]),"hours":int(item["until"])-int(state["time"]["total"])})
	result.sort_custom(func(a,b):return str(a["id"]) < str(b["id"]))
	return result

func new_game(options: Dictionary = {}) -> void:
	language = str(options.get("language", "en"))
	var starting_look: Dictionary = Style53.normalize(options)
	var seed: int = absi(int(options.get("seed", 47291))) & 0xffffffff
	if seed == 0:
		seed = 1
	var mode: String = str(options.get("mode", "story"))
	var difficulty: String = str(options.get("difficulty", "standard"))
	var background: String = str(options.get("background", "balanced"))
	var fields: Array = []
	for i in range(MAX_FIELDS):
		fields.append(_make_field(i, i == 0))
	if background == "steward":
		for field in fields:
			field["soil"]["organic_n"] += 100.0
	elif background == "naturalist":
		for field in fields:
			field["beneficial"]["ladybirds"] += 0.6
	var initial_cash: float = 5200.0
	if difficulty == "relaxed":
		initial_cash = 7200.0
	elif difficulty == "hard" or mode == "challenge":
		initial_cash = 3400.0
	state = {
		"schema":VERSION,"seed":seed,"rng":seed,"mode":mode,"difficulty":difficulty,
		"time":{"total":0,"hour":8,"day":1,"season":0},
		"player":{"name":str(options.get("name", "Alex")),"farm":str(options.get("farm", "Little Valley")),
			"background":background,"hair":str(options.get("hair", "crop")),"skin":str(options.get("skin", "#deb58e")),
			"outfit":str(options.get("outfit", "#42684b")),"x":10.0,"y":10.0,"energy":100.0,"xp":0,"level":1,"talents":[],"courses":[],"training":[]},
		"fields":fields,"economy":{"cash":initial_cash,"revenue":0.0,"costs":0.0,"ledger":[],"reputation":0},
		"water":{"stored":3500.0 if background == "engineer" else 3000.0,"capacity":5000.0},
		"weather":{"kind":"clear","temperature":18.0,"rain":0.0,"humidity":0.5,"forecast":"mixed"},
		"market":{"index":1.0,"offers":[],"contracts":[],"price_index":{}},
		"inventory":{"feed":40.0,"timber":3.0,"stone":2.0},"flows":{},"buildings":[],"animals":[],"processing":[],
		"deliveries":[],"automation":false,"events":{"active":{},"history":[],"next":30},
		"story":{"chapter":1,"completed":false,"tutorial":0,"tutorial_skipped":false,"starter_guide":0,"guided_onboarding":0,"quests":[],"achievements":[]},
		"stats":{"harvest_kg":0.0,"sold_kg":0.0,"fields_bought":0,"processed_kg":0.0,"animal_kg":0.0,"contracts_delivered":0,"buildings_completed":0,"inspections":0,"visits":0,"resources_gathered":0.0,"decorations_built":0.0,"compost_used":0.0},
		"logs":[],"next_id":1,"decisions":{"effects":{},"history":[],"branches":{},"followups":[],"relationships":{},"relationship_history":[],"clues":{},"last_invitation_hour":-72},"decorations":[],"resources":{"gathered_today":{},"total_gathered":0.0,"crafted":0},"progression":_new_progression(),"overworld":_new_overworld(),"wildlife":_new_wildlife(),"neighbours":{"favours":{},"helped":0},"life":{"path":"balanced","last_change":-9999,"machines":{},"quality_stock":{},"vet_visits":0,"machine_breakdowns":0},
		"hourly_baselines":{"water_in":0.0,"water_out":0.0,"nutrient_input":0.0,"nutrient_export":0.0}
	}
	for field in Style53.FIELDS:
		state["player"][field] = starting_look[field]
	state["wardrobe53"] = Style53.new_wardrobe()
	state["countryside54"] = Country54.new_state()
	state["countryside54"]["beyond58"] = Beyond58.new_state()
	state["world50"] = World50.new_state(1,state["stats"])
	if mode == "challenge":
		for field in fields:
			field["pests"]["aphids"] *= 1.9
	_log("You inherited one field. Listen to the valley, learn the land, and grow your farm.")

func _rand() -> float:
	# Exact uint32 LCG, deterministic on Godot's 64-bit integers.
	var value: int = int(state["rng"])
	value = (1664525 * value + 1013904223) & 0xffffffff
	state["rng"] = value
	return float(value) / 4294967296.0

func _id() -> String:
	var i: int = int(state["next_id"])
	state["next_id"] = i + 1
	return str(i)

func _log(message: String, kind: String = "info") -> void:
	var logs: Array = state.get("logs", [])
	logs.append({"id":_id(),"hour":int(state.get("time", {}).get("total", 0)),"kind":kind,"message":message})
	while logs.size() > 140:
		logs.pop_front()

func _fail(message: String) -> Dictionary:
	last_error = message
	return {"ok":false,"error":_message(message)}

func _ok(message: String = "Done") -> Dictionary:
	return {"ok":true,"message":_message(message)}

func _cash() -> float:
	return float(state.get("economy", {}).get("cash", 0.0))

func _pay(amount: float, category: String, description: String) -> bool:
	var cost: float = Data.money(amount)
	if cost < 0.0 or _cash() + 0.0001 < cost:
		return false
	var ec: Dictionary = state["economy"]
	ec["cash"] = Data.money(_cash() - cost)
	ec["costs"] = Data.money(float(ec["costs"]) + cost)
	ec["ledger"].append({"id":_id(),"hour":state["time"]["total"],"kind":category,"amount":-cost,"description":description})
	return true

func _earn(amount: float, category: String, description: String) -> void:
	var income: float = Data.money(maxf(0.0, amount))
	var ec: Dictionary = state["economy"]
	ec["cash"] = Data.money(_cash() + income)
	ec["revenue"] = Data.money(float(ec["revenue"]) + income)
	ec["ledger"].append({"id":_id(),"hour":state["time"]["total"],"kind":category,"amount":income,"description":description})

func _xp(amount: int, track: String = "farming") -> void:
	var gained: int = maxi(0, amount)
	if gained == 0:
		return
	var p: Dictionary = state["player"]
	var old_level: int = int(p["level"])
	p["xp"] = int(p["xp"]) + gained
	p["level"] = maxi(old_level, 1 + int(int(p["xp"]) / 220))
	if MASTERY_TRACKS.has(track):
		var tracks: Dictionary = state["progression"]["tracks"]
		tracks[track] = int(tracks.get(track,0)) + gained
	if int(p["level"]) > old_level:
		state["progression"]["levels_earned"] = int(state["progression"]["levels_earned"]) + int(p["level"]) - old_level
		state["progression"]["recent_level"] = int(p["level"])
		_log("Level up! Farmer level " + str(p["level"]) + "; talent points available: " + str(available_points()), "progression")

func available_points() -> int:
	return maxi(0, int(state["player"]["level"]) - state["player"]["talents"].size())

func has_talent(id: String) -> bool:
	return state["player"]["talents"].has(id)

func has_course(id: String) -> bool:
	return state["player"]["courses"].has(id)

func has_certificate(id: String) -> bool:
	return state.get("world50",{}).get("certifications",[]).has(id)

func current_festival() -> Dictionary:
	if state.is_empty():
		return {}
	return world_catalog.get("festivals",{}).get(World50.season_id(int(state["time"]["season"])),{})

func festival_available() -> bool:
	if state.is_empty():
		return false
	var day_in_season: int = 1 + (int(state["time"]["day"])-1) % SEASON_DAYS
	if day_in_season < 9:
		return false
	for record in state["world50"]["festival_history"]:
		if int(record["season_key"]) == World50.season_key(int(state["time"]["day"])):
			return false
	return true

func npc_chapter_info(npc_id: String) -> Dictionary:
	if state.is_empty():
		return {}
	var stage: int = int(state["world50"]["npc_chapters"].get(npc_id,0))
	return World50.chapter(world_catalog,npc_id,stage)

func season_goal_info() -> Dictionary:
	if state.is_empty():
		return {}
	return world_catalog.get("season_goals",{}).get(World50.season_id(int(state["world50"]["season_key"])),{})

func season_goal_progress() -> float:
	return World50.goal_progress(world_catalog,state["world50"],state["stats"])

func owned_count() -> int:
	var count: int = 0
	for f in state.get("fields", []):
		if f.get("owned", false):
			count += 1
	return count

func field_of(id: String) -> Dictionary:
	for f in state.get("fields", []):
		if str(f.get("id", "")) == id:
			return f
	return {}

func _owned(id: String) -> bool:
	var f: Dictionary = field_of(id)
	return not f.is_empty() and bool(f.get("owned", false))

func land_price(field_id: String = "") -> float:
	var amount: float = 460.0 + pow(float(owned_count()), 1.6) * 190.0
	var plot: Dictionary = field_of(field_id)
	if not plot.is_empty():
		var multiplier: Dictionary = {"stream":1.16,"forest":1.13,"wild":1.10,"terrace":1.12,
			"marsh":0.78,"rocky":0.68,"sand":0.85,"clay":0.94,"hill":1.06}
		amount *= float(multiplier.get(str(plot["terrain"]), 1.0))
	if has_talent("builder"):
		amount *= 0.95
	if has_talent("plotSurveyor"):
		amount *= 0.92
	return Data.money(amount)

func level_of(kind: String, field_id: String = "") -> int:
	for b in state.get("buildings", []):
		if b["kind"] == kind and str(b.get("field", "")) == field_id:
			return int(b["level"])
	return 0

func building_of(kind: String, field_id: String = "") -> Dictionary:
	for b in state.get("buildings", []):
		if b["kind"] == kind and str(b.get("field", "")) == field_id:
			return b
	return {}

func ready(kind: String, field_id: String = "") -> bool:
	return level_of(kind, field_id) > 0

func storage_capacity() -> float:
	return 650.0 + 1150.0 * level_of("warehouse") + 650.0 * level_of("rootCellar")

func stored() -> float:
	var total: float = 0.0
	for amount in state["inventory"].values():
		total += float(amount)
	return total

func stock(id: String) -> float:
	return float(state["inventory"].get(id, 0.0))

func _stock_add(id: String, quantity: float) -> float:
	var accepted: float = minf(maxf(0.0, quantity), maxf(0.0, storage_capacity() - stored()))
	state["inventory"][id] = stock(id) + accepted
	return accepted

func _stock_take(id: String, quantity: float) -> bool:
	if quantity < 0.0 or stock(id) + 0.0001 < quantity:
		return false
	var premium: float = premium_stock(id)
	var standard: float = maxf(0.0,stock(id)-premium)
	var consumed_premium: float = maxf(0.0,quantity-standard)
	state["life"]["quality_stock"][id] = maxf(0.0,premium-consumed_premium)
	state["inventory"][id] = maxf(0.0, stock(id) - quantity)
	return true

func machine_efficiency(machine_id: String) -> float:
	var item: Dictionary = state.get("life",{}).get("machines",{}).get(machine_id,{})
	if item.is_empty() or int(item.get("broken_until",0)) > int(state["time"]["total"]):
		return 0.0
	return clampf((float(item.get("condition",0.0)) - 0.18) / 0.62,0.0,1.0)

func _wear_machine(machine_id: String, wear: float) -> void:
	var machine: Dictionary = state["life"]["machines"].get(machine_id,{})
	if machine.is_empty() or machine_efficiency(machine_id) <= 0.0:
		return
	machine["condition"] = maxf(0.0,float(machine["condition"]) - wear)
	machine["hours_used"] = int(machine["hours_used"]) + 1

func premium_stock(good: String) -> float:
	return minf(stock(good),float(state["life"]["quality_stock"].get(good,0.0)))

func rotation_advice(field_id: String, limit: int = 4) -> Array:
	var field: Dictionary = field_of(field_id)
	if field.is_empty():
		return []
	# Rotation suggestions must be plantable on the field's actual 5.2 layout.
	var compatible: Dictionary = {}
	for crop_id in content["crops"]:
		var crop: Dictionary = content["crops"][crop_id]
		if Fields52.allows_crop(field,crop):
			compatible[crop_id] = crop
	return Life.rotation_suggestions(field,compatible,language=="es",limit)

func soil_health(field_id: String) -> float:
	var field: Dictionary = field_of(field_id)
	return Life.organic_score(field) if not field.is_empty() else 0.0

func farm_forecast() -> Array:
	return Life.forecast(state,language=="es")

func operating_budget() -> Dictionary:
	return Life.budget(state,content["buildings"],content["animals"])

func market_price(good: String) -> float:
	var base: float = float(content.get("goods", {}).get(good, {}).get("basePrice", 0.0))
	var factor: float = float(state["market"]["price_index"].get(good, 1.0))
	return Data.money(base * factor * (1.08 if has_talent("fairTrader") else 1.0) * (1.0 + mastery_bonus("trading")) * (1.0 + _effect("market_trust")) * (1.06 if has_certificate("market_mentor") else 1.0))

func weather_text() -> String:
	var w: Dictionary = state["weather"]
	var name: String = str(w["kind"])
	if language == "es":
		name = {"clear":"Despejado","rain":"Lluvia","heat":"Calor"}.get(name,name)
		return name + "  " + str(snappedf(float(w["temperature"]),0.1)) + " °C  |  Lluvia " + str(snappedf(float(w["rain"]),0.1)) + " mm"
	return name.capitalize() + "  " + str(snappedf(float(w["temperature"]),0.1)) + " °C  |  Rain " + str(snappedf(float(w["rain"]),0.1)) + " mm"

func status() -> Dictionary:
	return {"cash":_cash(),"fields":owned_count(),"water":float(state["water"]["stored"]),"season":season_name(),"day":int(state["time"]["day"]),"hour":int(state["time"]["hour"]),"inventory":stored(),"capacity":storage_capacity(),"level":int(state["player"]["level"]),"xp":int(state["player"]["xp"]),"xp_to_next":xp_to_next_level(),"talent_points":available_points()}

func animal_daily_requirements(animal: Dictionary) -> Dictionary:
	var species: Dictionary = content.get("animals",{}).get(str(animal.get("kind","")),{})
	if species.is_empty():
		return {}
	var count: int = maxi(0,int(animal.get("count",0)))
	var balanced: bool = str(animal.get("feeding","standard")) == "balanced"
	var feed: float = count * float(species["feedKgDaily"]) * (0.90 if has_talent("feedPlanner") else 1.0)
	feed *= 1.10 if balanced else 1.0
	feed *= 0.88 if str(state["life"]["path"]) == "livestock" else 1.0
	feed *= 1.0 - 0.09 * machine_efficiency("mixer")
	var nutrition_gain: float = (0.08 if balanced else 0.034) + 0.009 * machine_efficiency("mixer")
	return {"feed_kg":feed,"water_m3":count*float(species["waterM3Daily"]),
		"nutrition_gain":nutrition_gain,"base_production_kg":count*float(species["produceKgDaily"])}

func season_name() -> String:
	var names: Array = ["Spring", "Summer", "Autumn", "Winter"]
	var i: int = int(state["time"]["season"]) % names.size()
	if language == "es":
		return ["Primavera","Verano","Otoño","Invierno"][i]
	return names[i]

func _canonical_json(value: Variant) -> String:
	# Stable field ordering independent of dictionary insertion order.
	if typeof(value) == TYPE_DICTIONARY:
		var keys: Array = value.keys()
		keys.sort()
		var parts: Array = []
		for k in keys:
			parts.append(JSON.stringify(str(k)) + ":" + _canonical_json(value[k]))
		return "{" + ",".join(PackedStringArray(parts)) + "}"
	if typeof(value) == TYPE_ARRAY:
		var elements: Array = []
		for item in value:
			elements.append(_canonical_json(item))
		return "[" + ",".join(PackedStringArray(elements)) + "]"
	return JSON.stringify(value)

func export_text() -> String:
	# Hash precisely the values which JSON will persist, not pre-serialization floats.
	# This avoids checksum disagreements after a normal JSON numeric round trip.
	var wire: Variant = JSON.parse_string(JSON.stringify(state))
	if typeof(wire) != TYPE_DICTIONARY:
		return ""
	var encoded: String = _canonical_json(wire)
	return JSON.stringify({"format":"FW_NATIVE_5_4","payload":wire,"sha256":encoded.sha256_text()}, "  ")

func load_text(data: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(data)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _fail("The file is not valid JSON")
	var format_id: String = str(parsed.get("format", ""))
	if not ["FW_NATIVE_4_1", "FW_NATIVE_4_2", "FW_NATIVE_4_3", "FW_NATIVE_4_5", "FW_NATIVE_4_8", "FW_NATIVE_4_9", "FW_NATIVE_5_0", "FW_NATIVE_5_1", "FW_NATIVE_5_2", "FW_NATIVE_5_3", "FW_NATIVE_5_4"].has(format_id):
		return _fail("Unsupported native save format")
	var payload: Variant = parsed.get("payload")
	if typeof(payload) != TYPE_DICTIONARY or str(parsed.get("sha256", "")) != _canonical_json(payload).sha256_text():
		return _fail("Save checksum does not match")
	var loaded: Dictionary = _upgrade_state(payload)
	if not _valid_state(loaded):
		return _fail("Save state failed validation")
	state = loaded
	return _ok("Farm restored")

func _valid_state(candidate: Dictionary) -> bool:
	if int(candidate.get("schema", -1)) != VERSION:
		return false
	if typeof(candidate.get("fields")) != TYPE_ARRAY or candidate["fields"].size() != MAX_FIELDS:
		return false
	for key in ["player", "economy", "time", "water", "weather", "inventory", "market", "events", "story", "stats", "overworld", "wildlife", "neighbours", "progression", "resources", "decisions", "life", "world50", "wardrobe53", "countryside54"]:
		if typeof(candidate.get(key)) != TYPE_DICTIONARY:
			return false
	var story: Dictionary = candidate["story"]
	if not Data.is_json_integer(story.get("starter_guide",-1)) or int(story["starter_guide"]) < 0 or int(story["starter_guide"]) > STARTER_GUIDE.size():
		return false
	var guided_onboarding_step: Variant = story.get("guided_onboarding", 0)
	if not Data.is_json_integer(guided_onboarding_step) or int(guided_onboarding_step) < 0 or int(guided_onboarding_step) > GUIDED_ONBOARDING_STEP_COUNT:
		return false
	for key in ["buildings", "animals", "processing", "deliveries", "logs", "decorations"]:
		if typeof(candidate.get(key)) != TYPE_ARRAY:
			return false
	if not (candidate.get("rng") is int or candidate.get("rng") is float):
		return false
	var consequences: Dictionary = candidate["decisions"]
	if typeof(consequences.get("effects")) != TYPE_DICTIONARY or typeof(consequences.get("history")) != TYPE_ARRAY:
		return false
	if typeof(consequences.get("branches")) != TYPE_DICTIONARY or typeof(consequences.get("followups")) != TYPE_ARRAY:
		return false
	if typeof(consequences.get("relationships")) != TYPE_DICTIONARY or typeof(consequences.get("relationship_history")) != TYPE_ARRAY or typeof(consequences.get("clues")) != TYPE_DICTIONARY:
		return false
	if not Data.is_json_integer(consequences.get("last_invitation_hour")) or int(consequences["last_invitation_hour"]) < -72:
		return false
	if consequences["followups"].size() > 24 or consequences["branches"].size() > 6:
		return false
	for npc in consequences["relationships"].keys():
		if not content["npcs"].has(str(npc)) or not Data.is_json_integer(consequences["relationships"][npc]) or abs(int(consequences["relationships"][npc])) > 10:
			return false
	for arc_id in consequences["branches"].keys():
		if Chains.arc(str(arc_id)).is_empty():
			return false
		var branch: Variant = consequences["branches"][arc_id]
		if typeof(branch) != TYPE_DICTIONARY or not ["pending","active","completed"].has(str(branch.get("status",""))):
			return false
	for followup in consequences["followups"]:
		if typeof(followup) != TYPE_DICTIONARY or Chains.stage(str(followup.get("stage",""))).is_empty() or int(followup.get("due",-1)) < 0:
			return false
	for effect_id in consequences["effects"].keys():
		var value: Variant = consequences["effects"][effect_id]
		if typeof(value) != TYPE_DICTIONARY:
			return false
		if not is_finite(float(value.get("amount",0.0))) or absf(float(value.get("amount",0.0))) > 1.0 or int(value.get("until",-1)) < 0:
			return false
	var world_state: Dictionary = candidate["world50"]
	if typeof(world_state.get("npc_chapters")) != TYPE_DICTIONARY or typeof(world_state.get("npc_next_hours")) != TYPE_DICTIONARY or typeof(world_state.get("npc_history")) != TYPE_ARRAY:
		return false
	if typeof(world_state.get("certifications")) != TYPE_ARRAY or typeof(world_state.get("festival_history")) != TYPE_ARRAY or typeof(world_state.get("season_results")) != TYPE_ARRAY or typeof(world_state.get("season_snapshot")) != TYPE_DICTIONARY:
		return false
	if int(world_state.get("season_key",-1)) < 0 or world_state["npc_history"].size() > 120 or world_state["festival_history"].size() > 100 or world_state["season_results"].size() > 100:
		return false
	for npc_id in world_state["npc_chapters"].keys():
		if not world_catalog.get("npc_chapters",{}).has(str(npc_id)) or not Data.is_json_integer(world_state["npc_chapters"][npc_id]):
			return false
		if int(world_state["npc_chapters"][npc_id]) < 0 or int(world_state["npc_chapters"][npc_id]) > 3:
			return false
	for npc_id in world_state["npc_next_hours"].keys():
		if not world_catalog.get("npc_chapters",{}).has(str(npc_id)) or int(world_state["npc_next_hours"][npc_id]) < 0:
			return false
	var unique_certificates: Dictionary = {}
	for certificate_id in world_state["certifications"]:
		if not world_catalog.get("certifications",{}).has(str(certificate_id)) or unique_certificates.has(str(certificate_id)):
			return false
		unique_certificates[str(certificate_id)] = true
	var seen_festival_seasons: Dictionary = {}
	for festival in world_state["festival_history"]:
		if typeof(festival) != TYPE_DICTIONARY or int(festival.get("season_key",-1)) < 0:
			return false
		if seen_festival_seasons.has(int(festival["season_key"])) or not ["gold","silver","participant"].has(str(festival.get("rank",""))):
			return false
		seen_festival_seasons[int(festival["season_key"])] = true
	var life: Dictionary = candidate["life"]
	if not Life.PATHS.has(str(life.get("path",""))) or typeof(life.get("machines")) != TYPE_DICTIONARY or typeof(life.get("quality_stock")) != TYPE_DICTIONARY:
		return false
	if int(life.get("last_change",0)) < -9999 or int(life.get("machine_breakdowns",-1)) < 0 or int(life.get("vet_visits",-1)) < 0:
		return false
	for machine_id in life["machines"].keys():
		if not Life.MACHINES.has(str(machine_id)):
			return false
		var machine: Variant = life["machines"][machine_id]
		if typeof(machine) != TYPE_DICTIONARY or not _valid_quantity(machine.get("condition",-1.0)) or float(machine["condition"]) > 1.0:
			return false
		if int(machine.get("broken_until",-1)) < 0 or int(machine.get("hours_used",-1)) < 0:
			return false
	for quality_id in life["quality_stock"].keys():
		if not content["goods"].has(str(quality_id)) or not _valid_quantity(life["quality_stock"][quality_id]):
			return false
		if float(life["quality_stock"][quality_id]) > float(candidate["inventory"].get(quality_id,0.0)) + 0.001:
			return false
	var occupied_building_slots: Dictionary = {}
	for building in candidate["buildings"]:
		if not content["buildings"].has(str(building.get("kind",""))):
			return false
		var scope: String = str(content["buildings"][str(building["kind"])].get("scope","farm"))
		if scope == "farm":
			var slot: int = int(building.get("slot",-1))
			if slot < 0 or slot >= Life.CONSTRUCTION_SLOT_COUNT or occupied_building_slots.has(slot):
				return false
			occupied_building_slots[slot] = true
		elif int(building.get("slot",-1)) != -1:
			return false
	for animal in candidate["animals"]:
		if not content["animals"].has(str(animal.get("kind",""))) or int(animal.get("count",0)) < 1:
			return false
		if not _valid_quantity(animal.get("age_days",-1.0)) or not _valid_quantity(animal.get("health",-1.0)) or not _valid_quantity(animal.get("nutrition",-1.0)):
			return false
		if float(animal["health"]) > 1.001 or float(animal["nutrition"]) > 1.001 or not ["standard","balanced"].has(str(animal.get("feeding",""))):
			return false
		if int(animal.get("vet_until",-1)) < 0 or int(animal.get("pregnancy_due",-1)) < 0:
			return false
	var cash: float = float(candidate["economy"].get("cash", -1.0))
	if not is_finite(cash) or cash < -0.01:
		return false
	var reservoir: Dictionary = candidate["water"]
	if not _valid_quantity(reservoir.get("stored", -1.0)) or not _valid_quantity(reservoir.get("capacity", -1.0)):
		return false
	if float(reservoir["stored"]) > float(reservoir["capacity"]) + 0.001 or float(reservoir["capacity"]) < 1.0:
		return false
	var wildlife_data: Dictionary = candidate["wildlife"]
	if not _valid_quantity(wildlife_data.get("energy", -1.0)) or float(wildlife_data["energy"]) > 100.001:
		return false
	if int(wildlife_data.get("venom_hours", -1)) < 0:
		return false
	var player: Dictionary = candidate["player"]
	if int(player.get("level",0)) < 1 or int(player.get("xp",-1)) < 0 or int(player.get("level",1)) < 1 + int(int(player.get("xp",0))/220):
		return false
	# No arbitrary color strings or unbounded preset data may enter a save.
	if not Style53.valid(candidate["player"]):
		return false
	if not Country54.valid(candidate["countryside54"]):
		return false
	if not Beyond58.valid(candidate["countryside54"].get("beyond58",{})):
		return false
	var wardrobe: Dictionary = candidate["wardrobe53"]
	if typeof(wardrobe.get("presets")) != TYPE_ARRAY or wardrobe["presets"].size() != 3:
		return false
	for outfit_preset in wardrobe["presets"]:
		if typeof(outfit_preset) != TYPE_DICTIONARY or not Style53.valid_preset(outfit_preset):
			return false
	var prog: Dictionary = candidate["progression"]
	if typeof(prog.get("tracks")) != TYPE_DICTIONARY:
		return false
	for track in MASTERY_TRACKS:
		if int(prog["tracks"].get(track,-1)) < 0:
			return false
	var resource_data: Dictionary = candidate["resources"]
	if typeof(resource_data.get("gathered_today")) != TYPE_DICTIONARY or not _valid_quantity(resource_data.get("total_gathered",-1.0)):
		return false
	for region in resource_data["gathered_today"].keys():
		if not MATERIAL_SITES.has(str(region)) or int(resource_data["gathered_today"][region]) < 1:
			return false
	var used_slots: Dictionary = {}
	for obj in candidate["decorations"]:
		if typeof(obj) != TYPE_DICTIONARY or not DECORATIONS.has(str(obj.get("kind",""))):
			return false
		var slot: int = int(obj.get("slot", -1))
		if slot < 0 or slot >= 24 or used_slots.has(slot) or int(obj.get("ready_at", -1)) < 0:
			return false
		if typeof(obj.get("completed")) != TYPE_BOOL:
			return false
		used_slots[slot] = true
	var fields_seen: Dictionary = {}
	for i in range(MAX_FIELDS):
		var f: Variant = candidate["fields"][i]
		if typeof(f) != TYPE_DICTIONARY or str(f.get("id", "")) != "plot" + str(i+1):
			return false
		if not TERRAIN_ORDER.has(str(f.get("terrain", ""))) or fields_seen.has(str(f["id"])):
			return false
		if not Fields52.allowed_layout(str(f.get("plot_type","")),str(f["terrain"])):
			return false
		if not Data.is_json_integer(f.get("last_conversion_day")) or int(f["last_conversion_day"]) < -9999 or int(f["last_conversion_day"]) > int(candidate["time"].get("day",0)):
			return false
		fields_seen[str(f["id"])] = true
		if int(f.get("last_inspection_day", -2)) < -1 or int(f.get("scouted_day",-2)) < -1 or int(f.get("cover_until",-1)) < 0:
			return false
		if typeof(f.get("hedgerow")) != TYPE_BOOL or typeof(f.get("scout_report")) != TYPE_DICTIONARY:
			return false
		if typeof(f.get("soil")) != TYPE_DICTIONARY or typeof(f.get("crop")) != TYPE_DICTIONARY:
			return false
		if typeof(f.get("pests")) != TYPE_DICTIONARY or typeof(f.get("diseases")) != TYPE_DICTIONARY or typeof(f.get("beneficial")) != TYPE_DICTIONARY:
			return false
		var soil: Dictionary = f["soil"]
		for key in ["water", "capacity", "n", "p", "k", "organic_n", "organic_p", "organic_k", "mulch", "organic_matter", "compaction", "erosion"]:
			if not _valid_quantity(soil.get(key, -1.0)):
				return false
		if float(soil["capacity"]) < 1.0 or float(soil["water"]) > float(soil["capacity"]) + 0.001:
			return false
		if float(soil["mulch"]) > 1.001 or float(soil["organic_matter"]) > 12.001 or float(soil["compaction"]) > 1.001 or float(soil["erosion"]) > 1.001:
			return false
		for id in PEST_IDS:
			if not _valid_quantity(f["pests"].get(id,-1.0)):
				return false
		for id in DISEASE_IDS:
			if not _valid_quantity(f["diseases"].get(id,-1.0)):
				return false
		for id in ["ladybirds","parasitoids","bees"]:
			if not _valid_quantity(f["beneficial"].get(id,-1.0)):
				return false
		if not f["crop"].is_empty():
			if not content["crops"].has(str(f["crop"].get("id", ""))):
				return false
			if not Fields52.allows_crop(f,content["crops"][str(f["crop"]["id"])]):
				return false
			if not Fields52.VARIETIES.has(str(f["crop"].get("variety",""))) or int(f["crop"].get("harvest_cycles",-1)) < 0 or int(f["crop"].get("harvest_cycles",0)) > 2000:
				return false
			for key in ["age","development","biomass","health"]:
				if not _valid_quantity(f["crop"].get(key,-1.0)):
					return false
	for key in candidate["inventory"].keys():
		if not content["goods"].has(str(key)) or not _valid_quantity(candidate["inventory"][key]):
			return false
	return true

func _valid_quantity(value: Variant) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and float(value) >= -0.000001

# Save and recovery policy: 6.0 retains the proven schema 10 / 5.4 wire format.
# Version 6.0 saves are separate; 5.9 and older are read-only migration sources.
# Writes are staged, checked, and protected by two rolling backup files.
func _verified_envelope(text: String) -> bool:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var envelope: Dictionary = parsed
	if not ["FW_NATIVE_4_1", "FW_NATIVE_4_2", "FW_NATIVE_4_3", "FW_NATIVE_4_5", "FW_NATIVE_4_8", "FW_NATIVE_4_9", "FW_NATIVE_5_0", "FW_NATIVE_5_1", "FW_NATIVE_5_2", "FW_NATIVE_5_3", "FW_NATIVE_5_4"].has(str(envelope.get("format", ""))):
		return false
	var payload: Variant = envelope.get("payload")
	if typeof(payload) != TYPE_DICTIONARY:
		return false
	return str(envelope.get("sha256", "")) == _canonical_json(payload).sha256_text()

func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path)

func _copy_file(source: String, target: String) -> bool:
	return DirAccess.copy_absolute(_absolute(source), _absolute(target)) == OK

func _protected_write(target: String, contents: String) -> Dictionary:
	if not _verified_envelope(contents):
		return _fail("Save content failed checksum validation")
	var folder: String = target.get_base_dir()
	var mkdir_error: int = DirAccess.make_dir_recursive_absolute(_absolute(folder))
	if mkdir_error != OK:
		return _fail("Save directory unavailable: " + str(mkdir_error))
	var temporary: String = target + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot create temporary save file")
	file.store_string(contents)
	file.flush()
	file.close()
	if not _verified_envelope(FileAccess.get_file_as_string(temporary)):
		DirAccess.remove_absolute(_absolute(temporary))
		return _fail("Temporary save verification failed")
	# Never turn a corrupt primary into a recovery backup.
	if FileAccess.file_exists(target):
		var previous: String = FileAccess.get_file_as_string(target)
		if _verified_envelope(previous):
			var staged_backup: String = target + ".bak.tmp"
			if not _copy_file(target, staged_backup):
				DirAccess.remove_absolute(_absolute(temporary))
				return _fail("Cannot protect previous save; current farm preserved")
			if FileAccess.file_exists(target + ".bak") and _verified_envelope(FileAccess.get_file_as_string(target + ".bak")):
				if not _copy_file(target + ".bak", target + ".bak2"):
					DirAccess.remove_absolute(_absolute(temporary))
					DirAccess.remove_absolute(_absolute(staged_backup))
					return _fail("Could not preserve second recovery copy")
			if not _copy_file(staged_backup, target + ".bak"):
				DirAccess.remove_absolute(_absolute(temporary))
				DirAccess.remove_absolute(_absolute(staged_backup))
				return _fail("Could not write recovery backup")
			DirAccess.remove_absolute(_absolute(staged_backup))
		else:
			# Do not silently discard a damaged primary. Keep it for inspection.
			if not _copy_file(target, target + ".corrupt"):
				DirAccess.remove_absolute(_absolute(temporary))
				return _fail("Cannot preserve corrupt primary")
	var replace_error: int = DirAccess.rename_absolute(_absolute(temporary), _absolute(target))
	if replace_error != OK:
		# On Windows rename cannot replace an existing target. The verified
		# backup has already been made, so a staged copy is safe to attempt.
		if not _copy_file(temporary, target):
			return _fail("Save replacement failed: " + str(replace_error))
		DirAccess.remove_absolute(_absolute(temporary))
	if not _verified_envelope(FileAccess.get_file_as_string(target)):
		return _fail("Saved file failed post-write verification; recover from .bak")
	return _ok("Saved locally with recovery copies")

func save_file() -> Dictionary:
	if state.is_empty():
		return _fail("No farm to save")
	return _protected_write(SAVE_FILE, export_text())

func _slot_path(index: int) -> String:
	if index < 1 or index > SAVE_SLOT_COUNT:
		return ""
	return SLOT_DIRECTORY + "/slot_" + str(index) + ".json"

func save_slot(index: int) -> Dictionary:
	if state.is_empty() or _slot_path(index) == "":
		return _fail("Choose a valid save slot")
	return _protected_write(_slot_path(index), export_text())

func _valid_slot_candidate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var contents: String = FileAccess.get_file_as_string(path)
	if not _verified_envelope(contents):
		return {}
	var envelope: Dictionary = JSON.parse_string(contents)
	var candidate: Dictionary = _upgrade_state(envelope["payload"])
	if not _valid_state(candidate):
		return {}
	return {"path":path,"name":str(candidate["player"]["farm"]),"day":int(candidate["time"]["day"]),"level":int(candidate["player"]["level"])}

func slot_info(index: int) -> Dictionary:
	var path: String = _slot_path(index)
	if path == "":
		return {"exists":false,"valid":false}
	var any_existing: bool = false
	var v59: String = V59_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v58: String = V58_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v57: String = V57_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var prior: String = PREVIOUS_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v55: String = V55_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v54: String = V54_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var older: String = OLDER_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v52: String = V52_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v51: String = V51_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v50: String = V50_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v49: String = V49_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var legacy: String = LEGACY_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	for candidate_path in [path,path + ".bak",path + ".bak2",v59,v59 + ".bak",v59 + ".bak2",v58,v58 + ".bak",v58 + ".bak2",v57,v57 + ".bak",v57 + ".bak2",prior,prior + ".bak",prior + ".bak2",v55,v55 + ".bak",v55 + ".bak2",v54,v54 + ".bak",v54 + ".bak2",older,older + ".bak",older + ".bak2",v52,v52 + ".bak",v52 + ".bak2",v51,v51 + ".bak",v51 + ".bak2",v50,v50 + ".bak",v50 + ".bak2",v49,v49 + ".bak",v49 + ".bak2",legacy,legacy + ".bak",legacy + ".bak2"]:
		if not FileAccess.file_exists(str(candidate_path)):
			continue
		any_existing = true
		var details: Dictionary = _valid_slot_candidate(str(candidate_path))
		if not details.is_empty():
			return {"exists":true,"valid":true,"name":details["name"],"day":details["day"],"level":details["level"],"recovery":str(candidate_path) != path}
	return {"exists":any_existing,"valid":false}

func load_slot(index: int) -> Dictionary:
	var path: String = _slot_path(index)
	if path == "":
		return _fail("Choose a valid save slot")
	var v59: String = V59_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v58: String = V58_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v57: String = V57_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var prior: String = PREVIOUS_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v55: String = V55_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v54: String = V54_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var older: String = OLDER_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v52: String = V52_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v51: String = V51_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v50: String = V50_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var v49: String = V49_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	var legacy: String = LEGACY_SLOT_DIRECTORY + "/slot_" + str(index) + ".json"
	for candidate_path in [path,path + ".bak",path + ".bak2",v59,v59 + ".bak",v59 + ".bak2",v58,v58 + ".bak",v58 + ".bak2",v57,v57 + ".bak",v57 + ".bak2",prior,prior + ".bak",prior + ".bak2",v55,v55 + ".bak",v55 + ".bak2",v54,v54 + ".bak",v54 + ".bak2",older,older + ".bak",older + ".bak2",v52,v52 + ".bak",v52 + ".bak2",v51,v51 + ".bak",v51 + ".bak2",v50,v50 + ".bak",v50 + ".bak2",v49,v49 + ".bak",v49 + ".bak2",legacy,legacy + ".bak",legacy + ".bak2"]:
		if not FileAccess.file_exists(str(candidate_path)):
			continue
		var result: Dictionary = load_text(FileAccess.get_file_as_string(str(candidate_path)))
		if bool(result.get("ok",false)):
			# The active farm is installed; do not overwrite the slot while loading.
			if str(candidate_path) != path:
				return _ok("Manual slot recovered from backup")
			return result
	return _fail("This slot and its backups could not be validated")

func load_file() -> Dictionary:
	var candidates: Array = [SAVE_FILE, SAVE_FILE + ".bak", SAVE_FILE + ".bak2", V59_SAVE_FILE, V59_SAVE_FILE + ".bak", V59_SAVE_FILE + ".bak2", V58_SAVE_FILE, V58_SAVE_FILE + ".bak", V58_SAVE_FILE + ".bak2", V57_SAVE_FILE, V57_SAVE_FILE + ".bak", V57_SAVE_FILE + ".bak2", PREVIOUS_SAVE_FILE, PREVIOUS_SAVE_FILE + ".bak", PREVIOUS_SAVE_FILE + ".bak2", V55_SAVE_FILE, V55_SAVE_FILE + ".bak", V55_SAVE_FILE + ".bak2", V54_SAVE_FILE, V54_SAVE_FILE + ".bak", V54_SAVE_FILE + ".bak2", OLDER_SAVE_FILE, OLDER_SAVE_FILE + ".bak", OLDER_SAVE_FILE + ".bak2", V52_SAVE_FILE, V52_SAVE_FILE + ".bak", V52_SAVE_FILE + ".bak2", V51_SAVE_FILE, V51_SAVE_FILE + ".bak", V51_SAVE_FILE + ".bak2", V50_SAVE_FILE, V50_SAVE_FILE + ".bak", V50_SAVE_FILE + ".bak2", PRIOR_SAVE_FILE, PRIOR_SAVE_FILE + ".bak", PRIOR_SAVE_FILE + ".bak2", V48_SAVE_FILE, V48_SAVE_FILE + ".bak", V48_SAVE_FILE + ".bak2", LEGACY_SAVE_FILE, LEGACY_SAVE_FILE + ".bak", LEGACY_SAVE_FILE + ".bak2", ANCIENT_SAVE_FILE]
	var attempted: bool = false
	for path in candidates:
		if not FileAccess.file_exists(str(path)):
			continue
		attempted = true
		var result: Dictionary = load_text(FileAccess.get_file_as_string(str(path)))
		if not bool(result.get("ok", false)):
			continue
		if str(path) != SAVE_FILE:
			# A recovery is installed in memory; rebuild the primary safely.
			var written: Dictionary = save_file()
			if not bool(written.get("ok", false)):
				return {"ok":true,"message":"Recovered in memory; primary save could not be repaired","warning":str(written.get("error", ""))}
			return _ok("Farm recovered from a protected backup")
		return result
	return _fail("No valid save found; backups were not deleted" if attempted else "No saved farm found")

func quote(kind: String, args: Dictionary = {}) -> Dictionary:
	var original: Dictionary = state.duplicate(true)
	var result: Dictionary = act(kind, args)
	var delta: float = _cash() - float(original.get("economy", {}).get("cash", 0.0))
	state = original
	result["cost"] = Data.money(maxf(0.0, -delta))
	result["revenue"] = Data.money(maxf(0.0, delta))
	return result

func act(kind: String, args: Dictionary = {}) -> Dictionary:
	if state.is_empty():
		return _fail("Start a farm first")
	var original: Dictionary = state.duplicate(true)
	var result: Dictionary = _apply(kind, args)
	if not bool(result.get("ok", false)):
		state = original
		return result
	if not _valid_state(state):
		state = original
		return _fail("Action violated the farm state invariant")
	if kind != "tutorial":
		_checkpoint_tutorial(kind)
		_checkpoint_starter_guide(kind)
	if kind != "move" and kind != "inspect" and kind != "tutorial":
		_check_milestones(original["stats"])
	return result

func _checkpoint_starter_guide(kind: String) -> void:
	var story: Dictionary = state["story"]
	var index: int = int(story.get("starter_guide",STARTER_GUIDE.size()))
	if index >= STARTER_GUIDE.size() or str(STARTER_GUIDE[index]["action"]) != kind:
		return
	story["starter_guide"] = index + 1
	if int(story["starter_guide"]) == STARTER_GUIDE.size():
		story["tutorial"] = maxi(7,int(story.get("tutorial",0)))

func _checkpoint_tutorial(kind: String) -> void:
	var s: Dictionary = state["story"]
	var index: int = int(s.get("tutorial", 0))
	if index < TUTORIAL.size() and str(TUTORIAL[index]["action"]) == kind:
		s["tutorial"] = index + 1
		_xp(15)
		_log("Tutorial lesson " + str(index + 1) + " completed", "story")

func _check_milestones(previous_stats: Dictionary) -> void:
	var stats: Dictionary = state["stats"]
	for id in QUESTS:
		var quest: Dictionary = QUESTS[id]
		var stat: String = str(quest["stat"])
		var target: float = float(quest["target"])
		if not state["story"]["quests"].has(id) and float(previous_stats.get(stat, 0.0)) < target and float(stats.get(stat, 0.0)) >= target:
			# Rewards require a separate claim action.
			_log("Quest ready: " + n(quest), "quest")
	for trophy in ["first_crop", "thousand_kg", "first_building", "first_animal", "first_contract", "first_course", "all_land", "artisan"]:
		if state["story"]["achievements"].has(trophy):
			continue
		var unlocked: bool = false
		match trophy:
			"first_crop": unlocked = float(stats["harvest_kg"]) > 0.0
			"thousand_kg": unlocked = float(stats["harvest_kg"]) >= 1000.0
			"first_building": unlocked = int(stats["buildings_completed"]) > 0
			"first_animal": unlocked = state["animals"].size() > 0
			"first_contract": unlocked = int(stats["contracts_delivered"]) > 0
			"first_course": unlocked = state["player"]["courses"].size() > 0
			"all_land": unlocked = owned_count() >= MAX_FIELDS
			"artisan": unlocked = float(stats["processed_kg"]) >= 250.0
		if unlocked:
			state["story"]["achievements"].append(trophy)
			_xp(35)

func _field_index(id: String) -> int:
	for i in range(state["fields"].size()):
		if str(state["fields"][i]["id"]) == id:
			return i
	return -1

func _apply(kind: String, args: Dictionary) -> Dictionary:
	var field_id: String = str(args.get("fieldId", "plot1"))
	var field: Dictionary = field_of(field_id)
	var current: int = int(state["time"]["total"])
	var ecological_care_cost: float = 1.08 if str(state["life"]["path"]) == "ecology" else 1.0
	match kind:
		"configurePlot":
			if not _owned(field_id) or not field["crop"].is_empty():
				return _fail("Plot conversion needs empty land you own")
			var target_layout: String = str(args.get("plotType",""))
			if not Fields52.allowed_layout(target_layout,str(field["terrain"])):
				return _fail("This layout is unsuitable for the selected terrain")
			if target_layout == str(field["plot_type"]):
				return _fail("This plot already has that layout")
			if int(field["last_conversion_day"]) == int(state["time"]["day"]):
				return _fail("Only one plot conversion per simulated day is allowed")
			if int(field["cover_until"]) > current or int(field["solarize_until"]) > current:
				return _fail("Wait until the protective cover or solarization finishes")
			if target_layout in ["orchard","paddy"] and not building_of("greenhouse",field_id).is_empty():
				return _fail("Remove or use a different field: greenhouse blocks this layout")
			var layout_info: Dictionary = Fields52.PLOTS[target_layout]
			if not _pay(float(layout_info["cost"]),"land","Convert plot to " + target_layout):
				return _fail("Not enough cash to convert this field")
			var soil: Dictionary = field["soil"]
			var original_layout: Dictionary = Fields52.PLOTS[str(field["plot_type"])]
			var base_capacity: float = float(soil["capacity"]) / float(original_layout["capacity"])
			soil["capacity"] = maxf(50.0,base_capacity * float(layout_info["capacity"]))
			soil["water"] = minf(float(soil["water"]),float(soil["capacity"]))
			field["plot_type"] = target_layout
			field["last_conversion_day"] = int(state["time"]["day"])
			_xp(20,"crafting")
			_log("Converted " + field_id + " to " + target_layout,"construction")
			return _ok("Plot layout updated: " + Fields52.localized(layout_info,language))
		"choosePath":
			var selected_path: String = str(args.get("path",""))
			if not Life.PATHS.has(selected_path) or selected_path == str(state["life"]["path"]):
				return _fail("Choose a different valid farming specialization")
			var previous_change: int = int(state["life"]["last_change"])
			if previous_change >= 0 and current - previous_change < 288:
				return _fail("Specialization can be changed once every 12 game days")
			if previous_change >= 0 and not _pay(240.0,"specialization","Retrain farm business"):
				return _fail("Insufficient money to change specialization")
			state["life"]["path"] = selected_path
			state["life"]["last_change"] = current
			_log("Farm direction chosen: " + selected_path,"strategy")
			return _ok("Farm strategy updated")
		"buyMachine":
			var machine_id: String = str(args.get("machineId",""))
			if not Life.MACHINES.has(machine_id):
				return _fail("Unknown machine")
			if state["life"]["machines"].has(machine_id):
				return _fail("You already have this machine")
			if not _pay(float(Life.MACHINES[machine_id]["cost"]),"equipment","Buy " + machine_id):
				return _fail("Not enough cash for the machine")
			state["life"]["machines"][machine_id] = {"condition":1.0,"broken_until":0,"hours_used":0,"services":0}
			_xp(24,"crafting")
			return _ok("Machine purchased and available")
		"serviceMachine":
			var machine_id: String = str(args.get("machineId",""))
			var item: Dictionary = state["life"]["machines"].get(machine_id,{})
			if item.is_empty() or not Life.MACHINES.has(machine_id):
				return _fail("This machine is not owned")
			if float(item["condition"]) >= 0.995 and int(item["broken_until"]) <= current:
				return _fail("Machine already in full working order")
			var service_cost: float = 35.0 + 0.17 * float(Life.MACHINES[machine_id]["cost"]) * (1.0-float(item["condition"]))
			if int(item["broken_until"]) > current:
				service_cost += 34.0
			service_cost *= 0.88 if has_certificate("master_mechanic") else 1.0
			if not _pay(service_cost,"equipment","Service " + machine_id):
				return _fail("Not enough cash for servicing")
			item["condition"] = 1.0
			item["broken_until"] = 0
			item["services"] = int(item.get("services",0)) + 1
			return _ok("Machine serviced and operational")
		"coverCrop":
			if not _owned(field_id) or not field["crop"].is_empty():
				return _fail("Cover crops need an empty owned field")
			if int(field["cover_until"]) > current:
				return _fail("A cover crop is already growing here")
			var cover_cost: float = 28.0 * ecological_care_cost
			if not _pay(cover_cost,"soil","Cover crop " + field_id):
				return _fail("Not enough cash for cover seeds")
			field["cover_until"] = current + 96
			field["soil"]["erosion"] = maxf(0.0,float(field["soil"]["erosion"])-0.025)
			_xp(15,"ecology")
			return _ok("Four-day cover planted; wait before sowing a cash crop")
		"aerateSoil":
			if not _owned(field_id):
				return _fail("Own the field before aeration")
			if float(state["wildlife"]["energy"]) < 6.0:
				return _fail("Farmer needs 6 energy to aerate the field")
			var aeration_cost: float = 54.0 * (1.0-0.28*machine_efficiency("cultivator"))
			aeration_cost *= ecological_care_cost
			if not _pay(aeration_cost,"soil","Aerate " + field_id):
				return _fail("Not enough cash for soil aeration")
			state["wildlife"]["energy"] = maxf(0.0,float(state["wildlife"]["energy"])-6.0)
			field["soil"]["compaction"] = maxf(0.0,float(field["soil"]["compaction"])-0.20-0.045*machine_efficiency("cultivator"))
			_wear_machine("cultivator",0.015)
			_xp(11,"ecology")
			return _ok("Compaction reduced; roots can breathe again")
		"plantHedgerow":
			if not _owned(field_id):
				return _fail("Choose a field you own")
			if bool(field.get("hedgerow",false)):
				return _fail("This field already has a hedgerow")
			if not _pay(95.0,"habitat","Plant field hedgerow"):
				return _fail("Not enough cash for native hedgerow plants")
			field["hedgerow"] = true
			_xp(28,"ecology")
			return _ok("A field hedgerow will support wildlife and reduce erosion")
		"scoutField":
			if not _owned(field_id):
				return _fail("Own the field before hiring a scout")
			if int(field.get("scouted_day",-1)) == int(state["time"]["day"]):
				return _fail("This field has already been scouted today")
			if not _pay(9.0 if has_certificate("soil_specialist") else 14.0,"scouting","Pest scouting " + field_id):
				return _fail("Not enough cash for a field scout")
			field["scouted_day"] = int(state["time"]["day"])
			field["scout_report"] = {"pests":field["pests"].duplicate(true),"diseases":field["diseases"].duplicate(true),"hour":current}
			_xp(8,"ecology")
			return _ok("Fresh pest and disease measurements are now available")
		"relocateBuilding":
			var building_id: String = str(args.get("buildingId",""))
			var position: int = int(args.get("slot",-1))
			if position < 0 or position >= Life.CONSTRUCTION_SLOT_COUNT:
				return _fail("Choose a valid construction position")
			var to_move: Dictionary = {}
			for b in state["buildings"]:
				if str(b["id"]) == building_id:
					to_move = b
				elif str(b.get("field","")) == "" and int(b.get("slot",-1)) == position:
					return _fail("A building already occupies that position")
			if to_move.is_empty() or str(to_move.get("field","")) != "":
				return _fail("Only farm-wide structures can be relocated")
			if int(to_move["level"]) < 1 or int(to_move["target"]) > int(to_move["level"]):
				return _fail("Finish construction before relocating this structure")
			if int(to_move["slot"]) == position:
				return _fail("The structure is already at this location")
			if not _pay(45.0,"construction","Relocate " + str(to_move["kind"])):
				return _fail("Not enough cash to relocate the building")
			to_move["slot"] = position
			return _ok("Building moved to selected construction position")
		"feedingPlan":
			var herd_id: String = str(args.get("animalId",""))
			var plan: String = str(args.get("mode",""))
			if not ["standard","balanced"].has(plan):
				return _fail("Unknown livestock feeding plan")
			for herd in state["animals"]:
				if str(herd["id"]) == herd_id:
					herd["feeding"] = plan
					return _ok("Feed plan updated for this animal group")
			return _fail("Unknown animal group")
		"vetVisit":
			var herd_id: String = str(args.get("animalId",""))
			for herd in state["animals"]:
				if str(herd["id"]) != herd_id:
					continue
				if int(herd["vet_until"]) > current:
					return _fail("A veterinary protection plan is already active")
				var cost: float = (27.0 + float(herd["count"])*8.0) * (1.10 if str(state["life"]["path"]) == "livestock" else 1.0)
				cost *= 0.88 if has_certificate("animal_carer") else 1.0
				if not _pay(cost,"animals","Veterinary visit"):
					return _fail("Not enough cash for veterinary care")
				herd["health"] = minf(1.0,float(herd["health"])+0.25)
				herd["condition"] = minf(1.0,float(herd["condition"])+0.10)
				herd["vet_until"] = current + 168
				state["life"]["vet_visits"] = int(state["life"]["vet_visits"]) + 1
				_xp(12,"livestock")
				return _ok("Veterinary care completed; protection lasts seven days")
			return _fail("Unknown animal group")
		"breedAnimal":
			var herd_id: String = str(args.get("animalId",""))
			for herd in state["animals"]:
				if str(herd["id"]) != herd_id:
					continue
				if int(herd["count"]) < 2 or float(herd["condition"]) < 0.75 or float(herd["health"]) < 0.70:
					return _fail("Breeding needs two healthy animals in good condition")
				if int(herd["pregnancy_due"]) > current:
					return _fail("This group already has an expected newborn")
				var capacity_used: float = 0.0
				for other in state["animals"]:
					if str(other["home"]) != str(herd["home"]):
						continue
					var definition: Dictionary = content["animals"][str(other["kind"])]
					capacity_used += (float(other["count"])+(1.0 if int(other.get("pregnancy_due",0)) > current else 0.0))/maxf(1.0,float(definition["capacityPerLevel"]))
				var animal_definition: Dictionary = content["animals"][str(herd["kind"])]
				if capacity_used + 1.0/maxf(1.0,float(animal_definition["capacityPerLevel"])) > float(level_of(str(herd["home"]))) + 0.00001:
					return _fail("Reserve more housing before breeding")
				if not _pay(44.0,"animals","Plan breeding"):
					return _fail("Not enough cash for the breeding programme")
				herd["pregnancy_due"] = current + 96
				return _ok("One offspring is expected in four game days")
			return _fail("Unknown animal group")
		"move":
			var x: float = float(args.get("x", -1.0))
			var y: float = float(args.get("y", -1.0))
			if x < 1.0 or x > 63.0 or y < 1.0 or y > 53.0:
				return _fail("Movement out of bounds")
			state["player"]["x"] = x
			state["player"]["y"] = y
			return _ok("Walking")
		"inspect":
			if not _owned(field_id):
				return _fail("This field is not owned")
			field["inspections"] = int(field["inspections"]) + 1
			state["stats"]["inspections"] = int(state["stats"]["inspections"]) + 1
			# Reading is unlimited; XP is awarded once per plot and day.
			if int(field.get("last_inspection_day",-1)) != int(state["time"]["day"]):
				field["last_inspection_day"] = int(state["time"]["day"])
				_xp(3, "ecology")
			return _ok("Soil and pest readings inspected")
		"plant":
			if not _owned(field_id):
				return _fail("You must own this field before planting")
			if not field["crop"].is_empty():
				return _fail("Harvest the existing crop first")
			if int(field.get("cover_until",0)) > current:
				return _fail("Cover crop still protects this plot; wait for it to finish")
			if int(field["solarize_until"]) > current:
				return _fail("The field is still being solarized")
			var crop_id: String = str(args.get("cropId", ""))
			if not content["crops"].has(crop_id):
				return _fail("Unknown crop")
			var crop_def: Dictionary = content["crops"][crop_id]
			if not Fields52.allows_crop(field,crop_def):
				return _fail("Choose the correct plot layout for this crop")
			var variety_id: String = str(args.get("variety","standard"))
			if not Fields52.VARIETIES.has(variety_id):
				return _fail("Unknown seed variety")
			var variety_info: Dictionary = Fields52.VARIETIES[variety_id]
			var seed_cost: float = float(crop_def["seedCost"]) * AREA_HA
			if has_talent("seedSteward"):
				seed_cost *= 0.85
			seed_cost *= float(variety_info["seed"])
			var labor_cost: float = float(crop_def["plantLabor"]) * AREA_HA * 15.0 * _labor_multiplier()
			labor_cost *= 1.0 - 0.19 * machine_efficiency("cultivator")
			seed_cost *= 1.05 if str(state["life"]["path"]) == "crops" else 1.0
			if not _pay(seed_cost + labor_cost, "seeds", "Plant " + crop_id):
				return _fail("Not enough money for seeds and labor")
			var wet_machine_pressure: float = 0.020 if machine_efficiency("cultivator") > 0.0 and float(field["soil"]["water"]) > float(field["soil"]["capacity"]) * 0.70 else 0.0
			_wear_machine("cultivator",0.009)
			field["soil"]["compaction"] = clampf(float(field["soil"]["compaction"]) + 0.015 + wet_machine_pressure,0.0,1.0)
			field["crop"] = {"id":crop_id,"age":0.0,"development":0.0,"biomass":0.0,"health":1.0,"planted_at":current,"water_stress":0.0,"pest_stress":0.0,"disease_stress":0.0,"variety":variety_id,"harvest_cycles":0}
			var soil: Dictionary = field["soil"]
			soil["n"] += float(crop_def.get("seedN", 0.0)) * AREA_HA
			soil["p"] += float(crop_def.get("seedP", 0.0)) * AREA_HA
			soil["k"] += float(crop_def.get("seedK", 0.0)) * AREA_HA
			_log("Planted " + crop_id + " in " + field_id)
			return _ok("New crop planted")
		"harvest":
			if not _owned(field_id) or field["crop"].is_empty():
				return _fail("No growing crop in this field")
			var crop: Dictionary = field["crop"]
			if float(crop["development"]) < 0.995:
				return _fail("The crop is not ripe yet")
			var crop_def: Dictionary = content["crops"][str(crop["id"])]
			var kg: float = maxf(0.0, float(crop["biomass"]) * float(crop_def["harvestIndex"]) * AREA_HA * (1.0 + mastery_bonus("farming")))
			kg *= float(Fields52.VARIETIES.get(str(crop.get("variety","standard")),Fields52.VARIETIES["standard"])["yield"])
			if str(state["life"]["path"]) == "crops":
				kg *= 1.08
			# With functioning harvest equipment, less production is lost in the field.
			kg *= 1.0 + 0.035 * machine_efficiency("harvester")
			var labor: float = float(crop_def["harvestLabor"]) * AREA_HA * 15.0 * _labor_multiplier()
			labor *= 1.0 - 0.26 * machine_efficiency("harvester")
			if not _pay(labor, "labor", "Harvest " + str(crop["id"])):
				return _fail("Cannot pay the harvest crew")
			var accepted: float = _stock_add(str(crop["id"]), kg)
			var grade: float = clampf((float(crop["health"]) * 0.65 + Life.organic_score(field) * 0.35 - 0.23) / 0.75,0.0,1.0)
			var premium_amount: float = accepted * clampf((grade - 0.60) * 1.6,0.0,0.65)
			state["life"]["quality_stock"][str(crop["id"])] = premium_stock(str(crop["id"])) + premium_amount
			_wear_machine("harvester",0.012)
			var loss: float = kg - accepted
			field["last_family"] = str(crop_def["family"])
			field["history"].append({"crop":str(crop["id"]),"hour":current,"yield":accepted})
			if bool(crop_def.get("perennial",false)):
				crop["harvest_cycles"] = int(crop.get("harvest_cycles",0)) + 1
				crop["development"] = 0.07
				crop["biomass"] = float(crop_def["biomassMax"]) * 0.16
				crop["health"] = clampf(float(crop["health"]) + 0.10,0.0,1.0)
			else:
				field["crop"] = {}
			field["harvests"] = int(field["harvests"]) + 1
			state["stats"]["harvest_kg"] = float(state["stats"]["harvest_kg"]) + accepted
			state["economy"]["reputation"] = int(state["economy"]["reputation"]) + 1
			_xp(80, "farming")
			_log("Harvest " + str(snappedf(accepted, 0.1)) + " kg from " + field_id + "; overflow " + str(snappedf(loss, 0.1)) + " kg", "harvest")
			return _ok("Harvest stored: " + str(snappedf(accepted, 0.1)) + " kg")
		"irrigate":
			if not _owned(field_id):
				return _fail("You must own this field")
			var mm: float = float(args.get("mm", 0.0))
			if not is_finite(mm) or mm <= 0.0 or mm > 60.0:
				return _fail("Irrigation must be between 0 and 60 mm")
			var water: float = mm * AREA_HA * 10.0
			water *= 1.0 - 0.12 * machine_efficiency("pump")
			water *= 0.93 if has_certificate("water_engineer") else 1.0
			if has_talent("rainPlanner"):
				water *= 0.90
			if float(state["water"]["stored"]) + 0.0001 < water:
				return _fail("Reservoir does not contain enough water")
			var cost: float = 2.5 + water * 0.12
			cost *= 1.0 - 0.10 * machine_efficiency("pump")
			if has_course("water"):
				cost *= 0.88
			if not _pay(cost, "water", "Irrigation " + field_id):
				return _fail("Insufficient cash for pumping")
			state["water"]["stored"] -= water
			var soil: Dictionary = field["soil"]
			soil["water"] = minf(float(soil["capacity"]), float(soil["water"]) + mm)
			_wear_machine("pump",0.008)
			state["hourly_baselines"]["water_out"] += water
			return _ok("Applied " + str(mm) + " mm of water")
		"fertilize":
			if not _owned(field_id):
				return _fail("You must own this field")
			var element: String = str(args.get("element", "n")).to_lower()
			var kg: float = float(args.get("kg", 0.0))
			if not ["n", "p", "k"].has(element) or not is_finite(kg) or kg <= 0.0 or kg > 80.0:
				return _fail("Select N, P or K and an amount between 0 and 80 kg")
			var material: float = kg * {"n":1.0,"p":1.5,"k":1.2}[element]
			if has_course("soil"):
				material *= 0.9
			if not _pay((material + 4.0) * ecological_care_cost, "treatments", "Fertilizer " + element):
				return _fail("Insufficient cash for fertilizer")
			field["soil"][element] += kg
			state["hourly_baselines"]["nutrient_input"] += kg
			return _ok(element.to_upper() + " added to soil")
		"useManure":
			if not _owned(field_id):
				return _fail("Choose a field you own")
			if stock("manure") < 10.0:
				return _fail("Collect 10 kg of manure from livestock first")
			if not _pay(5.0 * ecological_care_cost, "labor", "Spread farm manure"):
				return _fail("Cannot pay for spreading manure")
			_stock_take("manure", 10.0)
			field["soil"]["organic_matter"] = minf(12.0,float(field["soil"]["organic_matter"])+0.14)
			field["soil"]["organic_n"] += 13.0
			field["soil"]["organic_p"] += 2.5
			field["soil"]["organic_k"] += 5.0
			return _ok("Recycled manure into soil fertility")
		"compost":
			if not _owned(field_id):
				return _fail("You must own this field")
			if not _pay(35.0 * ecological_care_cost, "treatments", "Compost"):
				return _fail("Insufficient cash for compost")
			var soil: Dictionary = field["soil"]
			soil["organic_matter"] = minf(12.0,float(soil["organic_matter"])+0.20)
			soil["organic_n"] += 45.0
			soil["organic_p"] += 8.0
			soil["organic_k"] += 13.0
			return _ok("Organic fertility added")
		"mulch":
			if not _owned(field_id):
				return _fail("You must own this field")
			if not _pay(26.0 * ecological_care_cost, "treatments", "Mulch"):
				return _fail("Insufficient cash for mulch")
			field["soil"]["mulch"] = minf(1.0, float(field["soil"]["mulch"]) + 0.65)
			return _ok("Mulch slows evaporation but may shelter slugs")
		"treat":
			if not _owned(field_id):
				return _fail("You must own this field")
			var method: String = str(args.get("method", ""))
			var costs: Dictionary = {"soap":32.0,"bt":39.0,"trap":22.0,"nets":55.0,"spray":60.0,"fungicide":47.0,"solarize":70.0}
			if not costs.has(method):
				return _fail("Unknown treatment")
			if method == "solarize" and not field["crop"].is_empty():
				return _fail("Solarization requires an empty field")
			if method == "spray" and float(field["spray_residue"]) > 0.65:
				return _fail("Spray residue ceiling reached")
			if not _pay(float(costs[method]) * ecological_care_cost, "treatments", "Treatment " + method):
				return _fail("Not enough cash for treatment")
			if method == "solarize":
				field["solarize_until"] = current + 48
				field["pests"]["nematodes"] *= 0.35
				field["diseases"]["rootRot"] *= 0.5
			elif method == "nets" or method == "trap":
				field["protection"][method] = current + 72
			else:
				for pest_id in PEST_IDS:
					var applies: bool = false
					match method:
						"soap": applies = ["aphids", "mites", "whiteflies"].has(pest_id)
						"bt": applies = ["caterpillars", "cutworms"].has(pest_id)
						"spray": applies = pest_id != "nematodes"
					if applies:
						field["pests"][pest_id] *= 0.45 if method != "spray" else 0.25
				if method == "fungicide":
					for disease_id in DISEASE_IDS:
						field["diseases"][disease_id] *= 0.50
				if method == "spray":
					field["spray_residue"] = minf(1.0, float(field["spray_residue"]) + 0.5)
					var harm: float = 0.65 if not has_talent("gentleControl") else 0.83
					for ally in field["beneficial"].keys():
						field["beneficial"][ally] *= harm
			_log("Treatment applied: " + method + " to " + field_id)
			return _ok("Pest/disease action completed")
		"release":
			if not _owned(field_id):
				return _fail("You must own this field")
			var species: String = str(args.get("species", "ladybirds"))
			if not ["ladybirds", "parasitoids"].has(species):
				return _fail("Unknown beneficial insect")
			if not _pay((45.0 if species == "ladybirds" else 53.0) * ecological_care_cost, "treatments", "Beneficial insects"):
				return _fail("Not enough cash for the beneficial insects")
			state["deliveries"].append({"id":_id(),"field":field_id,"species":species,"arrive":current + 24})
			return _ok("Beneficial insects arrive in 24 game hours")
		"gatherMaterials":
			var site_id: String = str(args.get("regionId", ""))
			if not MATERIAL_SITES.has(site_id):
				return _fail("Choose a valley resource site")
			if not state["events"]["active"].is_empty():
				return _fail("Resolve the pending event first")
			var site: Dictionary = MATERIAL_SITES[site_id]
			var day: int = int(state["time"]["day"])
			if int(state["resources"]["gathered_today"].get(site_id,-1)) == day:
				return _fail("This site has been gathered today; return tomorrow")
			var amount: float = float(site["kg"]) * (1.0 + mastery_bonus("exploration"))
			if stored() + amount > storage_capacity() + 0.0001:
				return _fail("Not enough storage for gathered resources")
			if float(state["wildlife"]["energy"]) < float(site["energy"]):
				return _fail("Your farmer needs rest before gathering")
			if not _pay(float(site["fee"]), "gathering", "Sustainable gathering at " + site_id):
				return _fail("Not enough cash for travel and tools")
			state["wildlife"]["energy"] = maxf(0.0, float(state["wildlife"]["energy"]) - float(site["energy"]))
			state["resources"]["gathered_today"][site_id] = day
			for gather_hour in range(int(site["hours"])):
				_advance_hour()
				if not state["events"]["active"].is_empty():
					break
			var obtained: float = _stock_add(str(site["good"]), amount)
			state["resources"]["total_gathered"] = float(state["resources"]["total_gathered"]) + obtained
			state["stats"]["resources_gathered"] = float(state["stats"]["resources_gathered"]) + obtained
			_xp(18, "exploration")
			_log("Gathered " + str(snappedf(obtained,0.1)) + " kg " + str(site["good"]) + " at " + site_id, "resources")
			return _ok("Gathered " + str(snappedf(obtained,0.1)) + " kg " + str(site["good"]))
		"makeCompost":
			if stock("manure") < 8.0 or stock("wildflowers") < 2.0:
				return _fail("Compost needs 8 kg manure and 2 kg wildflowers")
			if stored() - 10.0 + 7.0 > storage_capacity() + 0.0001:
				return _fail("Storage is full")
			if not _pay(7.0, "crafting", "Make compost"):
				return _fail("Not enough money for compost labor")
			_stock_take("manure",8.0)
			_stock_take("wildflowers",2.0)
			_stock_add("compost",7.0)
			_xp(16,"ecology")
			return _ok("Made 7 kg compost from recycled organic material")
		"spreadCompost":
			if not _owned(field_id):
				return _fail("Select an owned field")
			if stock("compost") < 5.0:
				return _fail("This field needs 5 kg of finished compost")
			if not _pay(3.0 * ecological_care_cost,"labor","Spread saved compost"):
				return _fail("Insufficient cash for spreading")
			_stock_take("compost",5.0)
			field["soil"]["organic_matter"] = minf(12.0,float(field["soil"]["organic_matter"])+0.12)
			field["soil"]["organic_n"] = float(field["soil"]["organic_n"]) + 18.0
			field["soil"]["organic_p"] = float(field["soil"]["organic_p"]) + 3.2
			field["soil"]["organic_k"] = float(field["soil"]["organic_k"]) + 6.0
			state["stats"]["compost_used"] = float(state["stats"]["compost_used"]) + 5.0
			_xp(12,"ecology")
			return _ok("Recycled compost into soil organic reserves")
		"relocateDecoration":
			var decoration_id_57: String = str(args.get("decorationId", ""))
			var destination_57: int = int(args.get("slot", -1))
			if destination_57 < 0 or destination_57 >= Living57.GARDEN_SLOTS:
				return _fail("Select a valid garden position")
			var found_deco_57: Dictionary = {}
			for existing_deco_57 in state["decorations"]:
				if str(existing_deco_57.get("id", "")) == decoration_id_57:
					found_deco_57 = existing_deco_57
				elif int(existing_deco_57.get("slot", -1)) == destination_57:
					return _fail("Another decoration already occupies this spot")
			if found_deco_57.is_empty():
				return _fail("Choose an existing decoration")
			if not bool(found_deco_57.get("completed", false)):
				return _fail("Finish building this decoration before moving it")
			if int(found_deco_57["slot"]) == destination_57:
				return _fail("Choose a different garden position")
			if float(state["wildlife"]["energy"]) < Living57.MOVE_ENERGY:
				return _fail("Need 4 energy to relocate a decoration")
			if not _pay(Living57.MOVE_CASH, "crafting", "Move garden decoration"):
				return _fail("Not enough cash to relocate this decoration")
			state["wildlife"]["energy"] = maxf(0.0, float(state["wildlife"]["energy"]) - Living57.MOVE_ENERGY)
			found_deco_57["slot"] = destination_57
			_xp(5, "crafting")
			_log("Relocated a garden decoration to slot " + str(destination_57 + 1), "crafting")
			return _ok("Garden decoration moved successfully")
		"craftDecoration":
			var deco_id: String = str(args.get("decorationId", ""))
			var slot: int = int(args.get("slot",-1))
			if not DECORATIONS.has(deco_id):
				return _fail("Unknown farm decoration")
			if slot < 0 or slot >= 24:
				return _fail("Choose a valid decoration position")
			if state["decorations"].size() >= 24:
				return _fail("The farm has reached its decoration limit")
			for obj in state["decorations"]:
				if int(obj["slot"]) == slot:
					return _fail("That decoration position is occupied")
			var design: Dictionary = DECORATIONS[deco_id]
			if int(state["player"]["level"]) < int(design["level"]):
				return _fail("Gain farmer levels before crafting this decoration")
			for good in design["materials"].keys():
				if stock(str(good)) + 0.0001 < float(design["materials"][good]):
					return _fail("Not enough " + str(good) + " for this decoration")
			if not _pay(float(design["fee"]),"crafting","Craft " + deco_id):
				return _fail("Not enough cash for crafting")
			for good in design["materials"].keys():
				_stock_take(str(good),float(design["materials"][good]))
			state["decorations"].append({"id":_id(),"kind":deco_id,"slot":slot,"ready_at":current+int(design["hours"]),"completed":false})
			state["resources"]["crafted"] = int(state["resources"]["crafted"]) + 1
			_xp(22,"crafting")
			return _ok("Decoration will be ready in " + str(design["hours"]) + " h")
		"buyField":
			if field.is_empty() or bool(field["owned"]):
				return _fail("Select a field that is still for sale")
			if int(state["economy"]["reputation"]) < maxi(0, owned_count() - 3) * 2:
				return _fail("You need more reputation before expanding")
			if not _pay(land_price(field_id), "land", "Land purchase " + field_id):
				return _fail("Not enough cash to purchase this plot")
			field["owned"] = true
			state["stats"]["fields_bought"] = int(state["stats"]["fields_bought"]) + 1
			_xp(60, "crafting")
			return _ok("Purchased " + field_id)
		"build":
			var building_id: String = str(args.get("buildingId", ""))
			if not content["buildings"].has(building_id):
				return _fail("Unknown building")
			var info: Dictionary = content["buildings"][building_id]
			var target: String = field_id if str(info.get("scope", "farm")) == "field" else ""
			if target != "" and not _owned(target):
				return _fail("A field building needs owned land")
			if building_id == "greenhouse" and str(field.get("plot_type","open")) in ["orchard","paddy"]:
				return _fail("Greenhouse requires an open field or raised beds")
			if not building_of(building_id, target).is_empty():
				return _fail("Building already exists here; choose upgrade")
			if int(state["economy"]["reputation"]) < int(info.get("unlockReputation", 0)):
				return _fail("You need more reputation to unlock this building")
			if not _pay(float(info["cost"]), "construction", "Build " + building_id):
				return _fail("Not enough cash to start construction")
			var slot: int = -1
			if target == "":
				slot = int(args.get("slot",Life.suggested_slot(state["buildings"])))
				if slot < 0 or slot >= Life.CONSTRUCTION_SLOT_COUNT:
					return _fail("No construction slot available")
				for structure in state["buildings"]:
					if str(structure.get("field","")) == "" and int(structure.get("slot",-1)) == slot:
						return _fail("This construction position is occupied")
			var hours: int = maxi(1, int(ceil(float(info["buildHours"]) * (0.8 if has_talent("builder") else 1.0) * (1.0 - mastery_bonus("crafting")))))
			state["buildings"].append({"id":_id(),"kind":building_id,"field":target,"level":0,"target":1,"ready_at":current + hours,"built_at":current,"slot":slot})
			return _ok("Construction will finish in " + str(hours) + " h")
		"upgrade":
			var building_id: String = str(args.get("buildingId", ""))
			if not content["buildings"].has(building_id):
				return _fail("Unknown building")
			var info: Dictionary = content["buildings"][building_id]
			var target: String = field_id if str(info.get("scope", "farm")) == "field" else ""
			var b: Dictionary = building_of(building_id, target)
			if b.is_empty() or int(b["level"]) <= 0:
				return _fail("Build the first level before upgrading")
			if int(b["target"]) > int(b["level"]):
				return _fail("Upgrade already under construction")
			if int(b["level"]) >= int(info["maxLevel"]):
				return _fail("Already at maximum level")
			if not _pay(float(info["cost"]) * (0.7 + 0.55 * float(b["level"])), "construction", "Upgrade " + building_id):
				return _fail("Not enough money to upgrade")
			b["target"] = int(b["level"]) + 1
			b["ready_at"] = current + maxi(1, int(float(info["buildHours"]) * 0.8 * (1.0 - mastery_bonus("crafting"))))
			return _ok("Upgrade scheduled")
		"sell":
			var good: String = str(args.get("goodId", ""))
			var kg: float = float(args.get("kg", 0.0))
			if not content["goods"].has(good) or not is_finite(kg) or kg <= 0.0 or stock(good) + 0.0001 < kg:
				return _fail("Not enough of this good in storage")
			var premium: float = minf(kg,premium_stock(good))
			# Selling uses premium stock first. All other processing uses ordinary stock first.
			state["life"]["quality_stock"][good] = maxf(0.0,premium_stock(good)-premium)
			state["inventory"][good] = maxf(0.0,stock(good)-kg)
			var premium_factor: float = 1.12 if str(state["life"]["path"]) == "ecology" else 1.0
			_earn((kg-premium)*market_price(good) + premium*market_price(good)*1.28*premium_factor, "revenue", "Sell " + good)
			state["stats"]["sold_kg"] += kg
			_xp(2, "trading")
			return _ok("Sold " + str(snappedf(kg, 0.1)) + " kg " + good)
		"buySupply":
			var good: String = str(args.get("goodId", "feed"))
			var kg: float = float(args.get("kg", 0.0))
			if not ["feed", "wheat", "barley"].has(good) or not is_finite(kg) or kg <= 0.0 or kg > 1000.0:
				return _fail("Select a valid supply and positive quantity")
			if stored() + kg > storage_capacity() + 0.0001:
				return _fail("Storage is full")
			if not _pay(kg * market_price(good) * 1.12, "feed", "Buy " + good):
				return _fail("Insufficient money for supplies")
			_stock_add(good, kg)
			return _ok("Supplies purchased")
		"buyWater":
			var m3: float = float(args.get("m3", 0.0))
			if not is_finite(m3) or m3 <= 0.0 or m3 > 1500.0:
				return _fail("Water purchase must be between 0 and 1500 m3")
			if float(state["water"]["stored"]) + m3 > float(state["water"]["capacity"]) + 0.0001:
				return _fail("Reservoir cannot store that much water")
			if not _pay(m3 * 0.27, "water", "Water delivery"):
				return _fail("Insufficient cash for a water delivery")
			state["water"]["stored"] += m3
			return _ok("Reservoir replenished")
		"buyAnimal":
			var animal_id: String = str(args.get("animalId", ""))
			var count: int = int(args.get("count", 1))
			if not content["animals"].has(animal_id) or count < 1 or count > 20:
				return _fail("Unknown animal or invalid count")
			var animal_info: Dictionary = content["animals"][animal_id]
			var home: String = str(animal_info["building"])
			if not ready(home):
				return _fail("Build and finish the animal housing first")
			# Different species use different shares of the same housing capacity.
			var occupied_units: float = 0.0
			for a in state["animals"]:
				if str(a["home"]) == home:
					var old_def: Dictionary = content["animals"][str(a["kind"])]
					occupied_units += (float(a["count"]) + (1.0 if int(a.get("pregnancy_due",0)) > current else 0.0)) / maxf(1.0, float(old_def["capacityPerLevel"]))
			var required_units: float = float(count) / maxf(1.0, float(animal_info["capacityPerLevel"]))
			if occupied_units + required_units > float(level_of(home)) + 0.00001:
				return _fail("No space for more animals in this building")
			if not _pay(float(animal_info["price"]) * count, "animals", "Purchase " + animal_id):
				return _fail("Insufficient money for animals")
			state["animals"].append({"id":_id(),"kind":animal_id,"count":count,"home":home,"condition":1.0,
				"age_days":40,"health":1.0,"nutrition":0.80,"feeding":"standard","vet_until":0,"pregnancy_due":0})
			_xp(20, "livestock")
			return _ok("Animals arrived at the farm")
		"process":
			var recipe_id: String = str(args.get("recipeId", ""))
			var kg: float = float(args.get("kg", 0.0))
			if not RECIPES.has(recipe_id) or not is_finite(kg) or kg <= 0.0 or kg > 500.0:
				return _fail("Unknown recipe or invalid batch size")
			var rec: Dictionary = RECIPES[recipe_id]
			if not ready(str(rec["building"])):
				return _fail("A completed processing building is required")
			if stock(str(rec["input"])) + 0.0001 < kg:
				return _fail("Not enough ingredients for this batch")
			if not _pay(kg * float(rec["cost"]) * (1.08 if str(state["life"]["path"]) == "artisan" else 1.0), "processing", "Process " + recipe_id):
				return _fail("Insufficient money for processing")
			_stock_take(str(rec["input"]), kg)
			var duration: float = float(rec["hours"]) * (0.85 if has_talent("artisanHands") else 1.0)
			state["processing"].append({"id":_id(),"recipe":recipe_id,"input_kg":kg,"output_kg":kg * float(rec["ratio"]) * (1.12 if str(state["life"]["path"]) == "artisan" else 1.0) * (1.07 if has_certificate("artisan_master") else 1.0),"finish":current + maxi(1, int(ceil(duration)))})
			return _ok("Production job started")
		"automation":
			var enabled: bool = bool(args.get("enabled", not state["automation"]))
			if enabled and not ready("farmhouse"):
				return _fail("Build the farmhands lodge first")
			state["automation"] = enabled
			return _ok("Farmhands automation " + ("enabled" if enabled else "disabled"))
		"enrollCourse":
			var course_id: String = str(args.get("courseId", ""))
			if not content["courses"].has(course_id):
				return _fail("Unknown course")
			if has_course(course_id):
				return _fail("Course already completed")
			for job in state["player"]["training"]:
				if str(job["id"]) == course_id:
					return _fail("Course already in progress")
			var info: Dictionary = content["courses"][course_id]
			if info.get("building") != null and str(info["building"]) != "" and not ready(str(info["building"])):
				return _fail("Build a learning cottage to unlock this course")
			var tuition: float = float(info["cost"]) * (1.0 - 0.12 * level_of("academy"))
			if not _pay(tuition, "training", "Study " + course_id):
				return _fail("Insufficient money for course tuition")
			state["player"]["training"].append({"id":course_id,"finish":current + int(info["hours"])})
			return _ok("Course underway")
		"learnTalent":
			var talent_id: String = str(args.get("talentId", ""))
			if not content["talents"].has(talent_id):
				return _fail("Unknown talent")
			if has_talent(talent_id):
				return _fail("Talent already learned")
			if available_points() < 1:
				return _fail("Earn another level to receive a talent point")
			var talent: Dictionary = content["talents"][talent_id]
			if talent.get("requires") != null and str(talent["requires"]) != "" and not has_talent(str(talent["requires"])):
				return _fail("Learn the prerequisite talent first")
			if talent.get("course") != null and str(talent["course"]) != "" and not has_course(str(talent["course"])):
				return _fail("Complete the required course first")
			state["player"]["talents"].append(talent_id)
			return _ok("New talent learned")
		"tutorial":
			var step: int = int(state["story"]["tutorial"])
			if step >= TUTORIAL.size():
				return _fail("Tutorial already completed")
			if bool(args.get("skip", false)):
				state["story"]["tutorial"] = step + 1
				state["story"]["tutorial_skipped"] = true
				return _ok("Tutorial step skipped")
			return _fail("Complete the lesson action or skip it explicitly")
		"starterGuide":
			if not bool(args.get("skip", false)):
				return _fail("Skip the starter guide explicitly")
			state["story"]["starter_guide"] = STARTER_GUIDE.size()
			state["story"]["tutorial"] = maxi(7,int(state["story"].get("tutorial",0)))
			state["story"]["tutorial_skipped"] = true
			return _ok("Starter guide skipped")
		"visit":
			state["stats"]["visits"] = int(state["stats"]["visits"]) + 1
			return _ok("Visited a neighbour or structure")
		"buyGear":
			if bool(state["wildlife"]["gear"]):
				return _fail("You already own the outdoor field kit")
			if not _pay(120.0, "equipment", "Outdoor field kit"):
				return _fail("Insufficient money for the field kit")
			state["wildlife"]["gear"] = true
			return _ok("Outdoor field kit purchased. Wildlife encounter risk is lower")
		"explore":
			var region_id: String = str(args.get("regionId", ""))
			if not REGIONS.has(region_id):
				return _fail("Unknown overworld destination")
			if not state["events"]["active"].is_empty():
				return _fail("Resolve the pending event before travelling")
			var place: Dictionary = REGIONS[region_id]
			var hours: int = int(place["hours"])
			if float(state["wildlife"]["energy"]) < float(hours * 6):
				return _fail("Your farmer needs a rest before this trip")
			if not _pay(float(place["fee"]) * (0.9 if has_talent("forager") else 1.0), "travel", "Visit " + region_id):
				return _fail("Not enough cash for the journey")
			state["wildlife"]["energy"] = maxf(0.0, float(state["wildlife"]["energy"]) - hours * 6.0)
			for travel_hour in range(hours):
				_advance_hour()
				if not state["events"]["active"].is_empty():
					break
			var chance: float = float(place["risk"])
			if bool(state["wildlife"]["gear"]):
				chance *= 0.38
			if ready("lookout"):
				chance *= 0.80
			if has_talent("wildlifeWatcher"):
				chance *= 0.75
			var encounter: bool = _rand() < chance
			var find: String = str(place["find"])
			var found: float = 0.0
			if region_id != "village":
				found = _stock_add(find, (2.0 + _rand() * 3.5) * (1.2 if has_talent("forager") else 1.0))
				state["overworld"]["foraged"] = float(state["overworld"]["foraged"]) + found
			if encounter:
				state["wildlife"]["venom_hours"] = maxi(int(state["wildlife"]["venom_hours"]), 12)
				state["wildlife"]["encounters"] = int(state["wildlife"]["encounters"]) + 1
				_log("Wildlife encounter: your farmer needs rest (game-only hazard)", "wildlife")
			var visits: Dictionary = state["overworld"]["visits"]
			visits[region_id] = int(visits.get(region_id,0)) + 1
			state["overworld"]["last_region"] = region_id
			if not state["overworld"]["known"].has(region_id):
				state["overworld"]["known"].append(region_id)
			state["wildlife"]["observed"][region_id] = int(visits[region_id])
			_xp(12 + hours * 4, "exploration")
			_log("Explored " + region_id + " and collected " + str(snappedf(found,0.1)) + " kg " + find, "travel")
			return _ok("Visited " + region_id + "; foraged " + str(snappedf(found,0.1)) + " kg" + (". Wildlife hazard: rest needed" if encounter else ""))
		"rest":
			var recovery: int = 8 if ready("clinic") else 4
			if not state["events"]["active"].is_empty():
				return _fail("Resolve the current event before resting")
			for rest_hour in range(4):
				_advance_hour()
				if not state["events"]["active"].is_empty():
					break
			state["wildlife"]["energy"] = minf(100.0, float(state["wildlife"]["energy"]) + 35.0)
			state["wildlife"]["venom_hours"] = maxi(0, int(state["wildlife"]["venom_hours"]) - recovery)
			return _ok("Rested in the valley; energy recovered")
		"helpNeighbour":
			var farmer_id: String = str(args.get("npcId", ""))
			if not content["npcs"].has(farmer_id):
				return _fail("Unknown neighbour")
			var previous_hours: Dictionary = state["neighbours"].get("last_help_hour", {})
			if previous_hours.has(farmer_id) and current < int(previous_hours[farmer_id]) + 24:
				return _fail("You already helped this neighbour recently. Come back another day")
			if not _pay(24.0, "community", "Help neighbour " + farmer_id):
				return _fail("Not enough money for the supplies")
			var favours: Dictionary = state["neighbours"]["favours"]
			favours[farmer_id] = int(favours.get(farmer_id, 0)) + 1
			if not state["neighbours"].has("last_help_hour"):
				state["neighbours"]["last_help_hour"] = {}
			state["neighbours"]["last_help_hour"][farmer_id] = current
			state["neighbours"]["helped"] = int(state["neighbours"]["helped"]) + 1
			state["economy"]["reputation"] = int(state["economy"]["reputation"]) + 1
			_change_trust(farmer_id,1,"Helped with supplies")
			_xp(16, "community")
			return _ok("Helped " + farmer_id + "; village reputation improved")
		"animalCare":
			var animal_id: String = str(args.get("animalId", ""))
			for herd in state["animals"]:
				if str(herd["id"]) == animal_id:
					if not _pay(9.0, "animals", "Animal welfare visit"):
						return _fail("Not enough cash for animal care")
					herd["condition"] = minf(1.0, float(herd["condition"]) + (0.195 if has_talent("animalWhisperer") else 0.15))
					_xp(5, "livestock")
					return _ok("Animal care improved the group's welfare")
			return _fail("Unknown animal group")
		"tick":
			var hours: int = int(args.get("hours", 0))
			if hours < 1 or hours > 24:
				return _fail("You may advance between 1 and 24 hours")
			if not state["events"]["active"].is_empty():
				return _fail("Resolve the pending valley event before advancing time")
			for hour in range(hours):
				_advance_hour()
				if not state["events"]["active"].is_empty():
					break
			return _ok("Time advanced")
		"eventChoice":
			return _resolve_event(str(args.get("choice", "")))
		"eventResearch":
			return _research_event()
		"inviteStory":
			return _invite_story(str(args.get("arcId","")))
		"offer":
			return _resolve_offer(str(args.get("offerId", "")), bool(args.get("accept", true)))
		"contractAccept":
			return _contract_accept(str(args.get("contractId", "")))
		"contractDeliver":
			return _contract_deliver(str(args.get("contractId", "")))
		"festivalEnter":
			return _enter_festival(str(args.get("category","produce")))
		"completeNpcChapter":
			return _complete_npc_chapter(str(args.get("npcId","")),str(args.get("approach","share")))
		"earnCertificate":
			return _earn_certificate(str(args.get("certificateId","")))
		"setFarmerLook":
			return _set_farmer_appearance_53(args)
		"saveOutfitPreset":
			return _save_outfit_53(args)
		"applyOutfitPreset":
			return _apply_outfit_53(args)
		"clearOutfitPreset":
			return _clear_outfit_53(args)
		"discoverSite54":
			return _discover_site_54(str(args.get("siteId","")))
		"countrysideActivity54":
			return _do_activity_54(str(args.get("activityId","")))
		"chooseProfession58":
			return _choose_profession_58(str(args.get("profession","")))
		"advanceProject58":
			return _advance_project_58(str(args.get("regionId","")),str(args.get("approach","protect")))
		"meetNeighbour54":
			return _meet_neighbour_54(str(args.get("npcId","")))
		"claimQuest":
			var quest_id: String = str(args.get("questId", ""))
			if not QUESTS.has(quest_id):
				return _fail("Unknown quest")
			if state["story"]["quests"].has(quest_id):
				return _fail("Quest reward already claimed")
			var q: Dictionary = QUESTS[quest_id]
			if float(state["stats"].get(q["stat"], 0.0)) < float(q["target"]):
				return _fail("Quest requirement not yet met")
			state["story"]["quests"].append(quest_id)
			_earn(float(q["reward"]), "grant", "Quest reward")
			_xp(40)
			return _ok("Quest reward claimed")
	return _fail("Unknown action: " + kind)

# Wardrobe actions have their own scopes. In 5.3 these lived inside
# _apply(), whose existing `field` local collided with a `for field` iterator.
func _set_farmer_appearance_53(args: Dictionary) -> Dictionary:
	var next_look: Dictionary = Style53.normalize(state["player"])
	for style_key in Style53.FIELDS:
		if args.has(style_key):
			if typeof(args[style_key]) != TYPE_STRING or not Style53.OPTIONS[style_key].has(args[style_key]):
				return _fail("Invalid appearance option")
			next_look[style_key] = args[style_key]
	if not Style53.allowed_in_state(next_look,state):
		return _fail("That cosmetic is still locked")
	for style_key in Style53.FIELDS:
		state["player"][style_key] = next_look[style_key]
	return _ok("Farmer appearance updated")

func _save_outfit_53(args: Dictionary) -> Dictionary:
	var wardrobe_slot: int = int(args.get("slot",-1))
	if wardrobe_slot < 0 or wardrobe_slot >= 3:
		return _fail("Choose wardrobe slot 1, 2 or 3")
	var chosen: Dictionary = Style53.normalize(state["player"])
	var proposed: Variant = args.get("look",{})
	if typeof(proposed) != TYPE_DICTIONARY:
		return _fail("Invalid wardrobe preset")
	for style_key in Style53.PRESET_FIELDS:
		if proposed.has(style_key):
			if typeof(proposed[style_key]) != TYPE_STRING or not Style53.OPTIONS[style_key].has(proposed[style_key]):
				return _fail("Invalid wardrobe preset")
			chosen[style_key] = proposed[style_key]
	if not Style53.allowed_in_state(chosen,state):
		return _fail("That cosmetic is still locked")
	state["wardrobe53"]["presets"][wardrobe_slot] = Style53.preset(chosen)
	return _ok("Outfit saved to wardrobe")

func _apply_outfit_53(args: Dictionary) -> Dictionary:
	var wardrobe_slot: int = int(args.get("slot",-1))
	if wardrobe_slot < 0 or wardrobe_slot >= 3:
		return _fail("Choose wardrobe slot 1, 2 or 3")
	var saved: Dictionary = state["wardrobe53"]["presets"][wardrobe_slot]
	if saved.is_empty() or not Style53.valid_preset(saved):
		return _fail("This wardrobe slot is empty")
	var wearable: Dictionary = Style53.normalize(state["player"])
	for style_key in Style53.PRESET_FIELDS:
		wearable[style_key] = saved[style_key]
	if not Style53.allowed_in_state(wearable,state):
		return _fail("One of these cosmetics is still locked")
	for style_key in Style53.PRESET_FIELDS:
		state["player"][style_key] = saved[style_key]
	return _ok("Wardrobe outfit equipped")

func _clear_outfit_53(args: Dictionary) -> Dictionary:
	var wardrobe_slot: int = int(args.get("slot",-1))
	if wardrobe_slot < 0 or wardrobe_slot >= 3:
		return _fail("Choose wardrobe slot 1, 2 or 3")
	state["wardrobe53"]["presets"][wardrobe_slot] = {}
	return _ok("Wardrobe slot cleared")

func _choose_profession_58(profession_id: String) -> Dictionary:
	if not Beyond58.PROFESSIONS.has(profession_id):
		return _fail("Choose a valid expedition profession")
	var profile: Dictionary = state["countryside54"]["beyond58"]
	if str(profile["profession"]) == profession_id:
		return _fail("This profession is already selected")
	var day: int = int(state["time"]["day"])
	if int(profile["profession_change_day"]) >= 1 and day - int(profile["profession_change_day"]) < 12:
		return _fail("You can retrain this profession once every 12 days")
	if str(profile["profession"]) != "none" and not _pay(90.0,"training","Change expedition profession"):
		return _fail("Not enough money for professional retraining")
	profile["profession"] = profession_id
	profile["profession_change_day"] = day
	_log("Exploration profession: " + profession_id,"progression")
	return _ok("Expedition profession selected")

func _advance_project_58(region_id: String, approach: String) -> Dictionary:
	if not Beyond58.PROJECTS.has(region_id) or not ["protect","trade"].has(approach):
		return _fail("Choose a valid regional project and approach")
	if not state["events"]["active"].is_empty():
		return _fail("Resolve the pending event before joining a regional project")
	if not _at_region_54(region_id):
		return _fail("Travel to the project region first")
	var project: Dictionary = Beyond58.PROJECTS[region_id]
	var profile: Dictionary = state["countryside54"]["beyond58"]
	var stage: int = int(profile["chapters"].get(region_id,0))
	if stage >= 3:
		return _fail("This regional project is already complete")
	var day: int = int(state["time"]["day"])
	if int(profile["chapter_days"].get(region_id,-1)) == day:
		return _fail("Return on a different game day for the next chapter")
	var profession: String = str(profile["profession"])
	var cost: float = float(project["fee"]) * (0.85 if profession == "pathfinder" else 1.0) * (1.0 + 0.30 * float(stage))
	var energy_cost: float = float(project["energy"]) * (0.80 if profession == "pathfinder" else 1.0)
	var hours: int = int(project["hours"])
	if float(state["wildlife"]["energy"]) + 0.0001 < energy_cost:
		return _fail("Rest before joining this expedition")
	if _cash() + 0.0001 < cost:
		return _fail("Not enough money for expedition supplies")
	if stage == 1 and stock(str(project["material"])) + 0.0001 < float(project["quantity"]):
		return _fail("Gather the required construction materials first")
	if stage == 2:
		var reward_amount: float = float(project["reward_quantity"]) + (2.0 if profession == "artisan" else 0.0)
		if stored() + reward_amount > storage_capacity() + 0.0001:
			return _fail("Clear enough warehouse space for the completion reward")
	# All checks precede all mutations. act() also rolls back on any invalid state.
	if not _pay(cost,"exploration","Regional project " + region_id + " chapter " + str(stage + 1)):
		return _fail("Not enough money for expedition supplies")
	if stage == 1 and not _stock_take(str(project["material"]),float(project["quantity"])):
		return _fail("Required materials are missing")
	state["wildlife"]["energy"] = maxf(0.0,float(state["wildlife"]["energy"]) - energy_cost)
	var gained_xp: int = int(round(float(22 + stage * 15) * (1.30 if profession == "naturalist" else 1.0)))
	_xp(gained_xp,"exploration")
	if stage == 2:
		var earned_good: float = _stock_add(str(project["reward"]),float(project["reward_quantity"]) + (2.0 if profession == "artisan" else 0.0))
		state["economy"]["reputation"] = int(state["economy"]["reputation"]) + (3 if approach == "protect" else 1) + (1 if profession == "naturalist" else 0)
		_change_trust(str(project["partner"]),2 if approach == "protect" else 1,"Completed project in " + region_id)
		if approach == "trade":
			_earn(65.0,"community","Regional trading partnership: " + region_id)
		profile["completed"] = int(profile["completed"]) + 1
		_log("Completed regional project in " + region_id + "; awarded " + str(earned_good) + " supplies","community")
	else:
		_change_trust(str(project["partner"]),1,"Worked together in " + region_id)
	profile["chapters"][region_id] = stage + 1
	profile["chapter_days"][region_id] = day
	var history: Array = profile["history"]
	history.append({"region":region_id,"stage":stage + 1,"day":day,"approach":approach})
	while history.size() > 100:
		history.pop_front()
	for work_hour in range(hours):
		_advance_hour()
		if not state["events"]["active"].is_empty():
			break
	return _ok("Regional project chapter completed: " + region_id + " " + str(stage + 1) + "/3")

func _at_region_54(region_id: String) -> bool:
	var location: Dictionary = state.get("overworld",{})
	return str(location.get("last_region","")) == region_id and (region_id == "village" or int(location.get("visits",{}).get(region_id,0)) > 0)

func _discover_site_54(site_id: String) -> Dictionary:
	if not Country54.SITES.has(site_id):
		return _fail("Unknown scenic location")
	if not state["events"]["active"].is_empty():
		return _fail("Resolve the pending valley event first")
	if state["countryside54"]["discovered"].has(site_id):
		return _fail("This scenic place is already in your journal")
	var info: Dictionary = Country54.SITES[site_id]
	if not _at_region_54(str(info["region"])):
		return _fail("Travel to this region before discovering its sights")
	if float(state["wildlife"]["energy"]) < float(info["energy"]):
		return _fail("Rest before exploring this trail")
	if not _pay(float(info["cost"]),"exploration","Explore " + site_id):
		return _fail("Not enough funds for the trail")
	state["wildlife"]["energy"] = maxf(0.0,float(state["wildlife"]["energy"]) - float(info["energy"]))
	state["countryside54"]["discovered"].append(site_id)
	_xp(30,"exploration")
	_log("Discovered scenic location: " + site_id,"travel")
	_advance_hour()
	return _ok("Scenic location added to your countryside journal")

func _do_activity_54(activity_id: String) -> Dictionary:
	if not Country54.ACTIVITIES.has(activity_id):
		return _fail("Unknown countryside activity")
	if not state["events"]["active"].is_empty():
		return _fail("Resolve the pending valley event first")
	var activity: Dictionary = Country54.ACTIVITIES[activity_id]
	if not _at_region_54(str(activity["region"])):
		return _fail("Travel to this region before joining the activity")
	var current_day: int = int(state["time"]["day"])
	if int(state["countryside54"]["activity_days"].get(activity_id,-1)) == current_day:
		return _fail("This activity is only available once per day")
	if float(state["wildlife"]["energy"]) < float(activity["energy"]):
		return _fail("Your farmer needs more energy")
	if str(activity["good"]) != "" and stored() + float(activity["quantity"]) > storage_capacity() + 0.0001:
		return _fail("Clear space in storage before gathering")
	if not _pay(float(activity["fee"]),"community","Countryside activity " + activity_id):
		return _fail("Not enough cash for this countryside activity")
	state["wildlife"]["energy"] = maxf(0.0,float(state["wildlife"]["energy"]) - float(activity["energy"]))
	state["countryside54"]["activity_days"][activity_id] = current_day
	state["countryside54"]["activities"] = int(state["countryside54"]["activities"]) + 1
	var reward: float = 0.0
	if str(activity["good"]) != "":
		reward = _stock_add(str(activity["good"]),float(activity["quantity"]))
	state["economy"]["reputation"] = int(state["economy"]["reputation"]) + int(activity["reputation"])
	_xp(int(activity["xp"]),"exploration")
	var history: Array = state["countryside54"]["activity_history"]
	history.append({"id":activity_id,"day":current_day,"reward_kg":reward})
	if history.size() > 80:
		history.pop_front()
	_log("Joined countryside activity: " + activity_id,"community")
	for activity_hour in range(int(activity["hours"])):
		_advance_hour()
		if not state["events"]["active"].is_empty():
			break
	return _ok("Countryside activity completed" + ("; gathered " + str(snappedf(reward,0.1)) + " kg" if reward > 0.0 else ""))

func _meet_neighbour_54(npc_id: String) -> Dictionary:
	if not content["npcs"].has(npc_id):
		return _fail("Unknown neighbour")
	if not state["events"]["active"].is_empty():
		return _fail("Resolve the pending valley event first")
	var day: int = int(state["time"]["day"])
	var hour: int = int(state["time"]["hour"])
	if hour < 7 or hour >= 21:
		return _fail("Neighbours are at home for the night")
	var region_id: String = Country54.npc_region(npc_id,day,hour)
	if not _at_region_54(region_id):
		return _fail("Find your neighbour in the scheduled region")
	if int(state["countryside54"]["met_days"].get(npc_id,-1)) == day:
		return _fail("You already spent time together today")
	if float(state["wildlife"]["energy"]) < 7.0:
		return _fail("Your farmer needs rest before meeting anyone")
	if not _pay(3.0,"community","Tea with " + npc_id):
		return _fail("You need EUR 3 for a shared meal")
	state["wildlife"]["energy"] = maxf(0.0,float(state["wildlife"]["energy"]) - 7.0)
	state["countryside54"]["met_days"][npc_id] = day
	state["countryside54"]["meetings"] = int(state["countryside54"]["meetings"]) + 1
	_change_trust(npc_id,1,"Spent time together in the countryside")
	_xp(12,"community")
	_log("Met " + npc_id + " near " + region_id,"community")
	_advance_hour()
	return _ok("A neighbour remembers your visit; trust improved")

func _complete_npc_chapter(npc_id: String, approach: String) -> Dictionary:
	var story: Dictionary = state["world50"]
	if not world_catalog.get("npc_chapters",{}).has(npc_id) or not ["share","trade"].has(approach):
		return _fail("Choose a valid neighbour and contribution")
	var chapter_number: int = int(story["npc_chapters"].get(npc_id,0))
	var chapter: Dictionary = World50.chapter(world_catalog,npc_id,chapter_number)
	if chapter.is_empty():
		return _fail("This neighbour's story is already complete")
	var current_hour: int = int(state["time"]["total"])
	if current_hour < int(story["npc_next_hours"].get(npc_id,0)):
		return _fail("Allow one day before the next chapter")
	var good: String = str(chapter["good"])
	var kg: float = float(chapter["kg"])
	if stock(good)+0.00001 < kg or not _stock_take(good,kg):
		return _fail("The requested supplies are not yet available")
	var income: float = float(chapter["cash"]) * (0.65 if approach == "share" else 1.0)
	_earn(income,"community","Neighbour contribution: " + npc_id)
	_change_trust(npc_id,int(chapter["trust"]) + (1 if approach == "share" else 0),"Neighbour chapter " + str(chapter_number+1))
	_xp(int(chapter["xp"]),"community")
	story["npc_chapters"][npc_id] = chapter_number + 1
	story["npc_next_hours"][npc_id] = current_hour + int(chapter["cooldown_hours"])
	story["npc_history"].append({"npc":npc_id,"chapter":chapter_number+1,"hour":current_hour,"good":good,"kg":kg,"approach":approach,"cash":income})
	while story["npc_history"].size() > 110:
		story["npc_history"].pop_front()
	if chapter_number == 2:
		state["economy"]["reputation"] = int(state["economy"]["reputation"]) + 2
		_log("Completed all three chapters with " + npc_id,"community")
	else:
		_log("Neighbour chapter completed with " + npc_id,"community")
	return _ok("Supplies delivered; neighbour story advanced")

func _earn_certificate(id: String) -> Dictionary:
	var certificate: Dictionary = world_catalog.get("certifications",{}).get(id,{})
	if certificate.is_empty() or has_certificate(id):
		return _fail("Choose an available unearned certificate")
	if not World50.certificate_ready(world_catalog,state["world50"],state["stats"],state["player"],state["progression"],id):
		return _fail("Complete its course, experience and practical requirement first")
	if not _pay(float(certificate["fee"]),"training","Professional certification: " + id):
		return _fail("Not enough cash for certification")
	state["world50"]["certifications"].append(id)
	_xp(int(certificate["xp_reward"]),str(certificate["track"]))
	_log("Certified in " + id,"learning")
	return _ok("Certification earned and its benefit is now active")

func _enter_festival(category: String) -> Dictionary:
	if not festival_available():
		return _fail("Festival entries are open only on days 9-12, once per season")
	var info: Dictionary = current_festival()
	var requirements: Dictionary = info.get("entries",{}).get(category,{})
	if requirements.is_empty():
		return _fail("Choose a valid festival exhibition")
	var good: String = str(requirements["good"])
	var kg: float = float(requirements["kg"])
	if stock(good) + 0.00001 < kg:
		return _fail("Not enough supplies for the festival exhibit")
	if not _pay(25.0,"festival","Seasonal village festival entry"):
		return _fail("Not enough cash for the festival entry")
	var premium_ratio: float = clampf(premium_stock(good)/maxf(kg,stock(good)),0.0,1.0)
	if not _stock_take(good,kg):
		return _fail("Exhibit supplies were no longer available")
	var relationship_score: int = 0
	for npc_id in state["decisions"]["relationships"].keys():
		relationship_score += maxi(0,npc_trust(str(npc_id)))
	var score: float = clampf(47.0 + mini(19,relationship_score)*0.62 + premium_ratio*24.0 + minf(9.0,float(state["economy"]["reputation"])*0.30) + (_rand()-0.5)*28.0,0.0,100.0)
	var rank: String = World50.festival_rank(score)
	var prize: float = 260.0 if rank == "gold" else (140.0 if rank == "silver" else 45.0)
	_earn(prize,"festival","Festival exhibition prize")
	_xp(105 if rank == "gold" else (75 if rank == "silver" else 50),"community")
	state["economy"]["reputation"] = int(state["economy"]["reputation"]) + (3 if rank == "gold" else (2 if rank == "silver" else 1))
	var trust_npc: String = "clara" if category == "artisan" else ("lila" if category == "community" else "ines")
	_change_trust(trust_npc,1,"Seasonal festival")
	state["world50"]["festival_history"].append({"season_key":World50.season_key(int(state["time"]["day"])),"category":category,"good":good,"kg":kg,"score":snappedf(score,0.1),"rank":rank,"prize":prize,"hour":int(state["time"]["total"])})
	while state["world50"]["festival_history"].size() > 95:
		state["world50"]["festival_history"].pop_front()
	_log("Festival: " + rank + " with " + good,"festival")
	if language == "es":
		var rank_es: String = str({"gold":"oro","silver":"plata","participant":"participación"}.get(rank,rank))
		return _ok("Resultado de la fiesta: " + rank_es + "; premio: " + str(int(prize)) + " EUR")
	return _ok("Festival result: " + rank + "; prize EUR " + str(int(prize)))

func _seasonal_recap() -> void:
	var reports: Dictionary = state["world50"]
	var new_key: int = World50.season_key(int(state["time"]["day"]))
	if new_key == int(reports["season_key"]):
		return
	var objective: Dictionary = season_goal_info()
	var achieved: float = season_goal_progress()
	var completed: bool = not objective.is_empty() and achieved >= float(objective["target"])
	if completed:
		_earn(float(objective["cash"]),"season","Seasonal goal reward")
		_xp(int(objective["xp"]),"farming")
	var previous_key: int = int(reports["season_key"])
	reports["season_results"].append({"season_key":previous_key,"progress":snappedf(achieved,0.1),"target":float(objective.get("target",0.0)),"completed":completed,"cash":float(objective.get("cash",0.0)) if completed else 0.0})
	while reports["season_results"].size() > 95:
		reports["season_results"].pop_front()
	reports["season_key"] = new_key
	reports["season_snapshot"] = state["stats"].duplicate(true)
	_log("Season " + str(previous_key+1) + " completed; goal " + ("earned" if completed else "not met"),"season")

func _labor_multiplier() -> float:
	var efficiency: float = 0.9 if has_talent("efficientWork") else 1.0
	if int(state["wildlife"]["venom_hours"]) > 0:
		efficiency *= 1.2
	efficiency *= 1.0 + _effect("labor_slowdown") - _effect("work_efficiency")
	return maxf(0.65,efficiency)

func story_branches() -> Array:
	var result: Array = []
	for arc_id in state.get("decisions",{}).get("branches",{}).keys():
		var branch: Dictionary = state["decisions"]["branches"][arc_id]
		result.append({"id":str(arc_id),"name":Chains.arc_name(str(arc_id),language),
			"status":str(branch.get("status","pending")),"npc":str(branch.get("npc","")),
			"last_choice":str(branch.get("last_choice",""))})
	result.sort_custom(func(a,b):return str(a["id"]) < str(b["id"]))
	return result

func pending_story_events() -> Array:
	var result: Array = []
	for task in state.get("decisions",{}).get("followups",[]):
		result.append({"stage":str(task["stage"]),"arc":str(task["arc"]),
			"hours":maxi(0,int(task["due"])-int(state["time"]["total"]))})
	result.sort_custom(func(a,b):return int(a["hours"]) < int(b["hours"]))
	return result

func _queue_story_followup(arc_id: String, stage_id: String, hours: int) -> void:
	if stage_id == "" or Chains.stage(stage_id).is_empty():
		return
	for job in state["decisions"]["followups"]:
		if str(job["stage"]) == stage_id:
			return
	state["decisions"]["followups"].append({"arc":arc_id,"stage":stage_id,"due":int(state["time"]["total"])+maxi(1,hours)})

func _start_story_root(event_id: String, choice_id: String) -> void:
	var arc_id: String = Chains.root_arc(event_id)
	if arc_id == "" or state["decisions"]["branches"].has(arc_id):
		return
	var arc: Dictionary = Chains.arc(arc_id)
	var npc_id: String = str(arc["npc"])
	_change_trust(npc_id,int(arc.get("trust",{}).get(choice_id,0)),"original decision: " + event_id)
	state["decisions"]["branches"][arc_id] = {"status":"pending","npc":npc_id,
		"root_choice":choice_id,"last_choice":choice_id,"started_at":int(state["time"]["total"])}
	_queue_story_followup(arc_id,str(arc["first"]),int(arc["delay_hours"]))
	_log("A village storyline has begun: " + Chains.arc_name(arc_id,"en"),"event")

func _invite_story(arc_id: String) -> Dictionary:
	var info: Dictionary = Chains.arc(arc_id)
	if info.is_empty():
		return _fail("Unknown village storyline")
	if state["decisions"]["branches"].has(arc_id):
		return _fail("This village storyline has already started")
	if not state["events"]["active"].is_empty():
		return _fail("Finish the current event before inviting a neighbour")
	var now: int = int(state["time"]["total"])
	if now < int(state["decisions"]["last_invitation_hour"]) + 72:
		return _fail("The village notice board needs three days between invitations")
	if arc_id == "livestock" and state["animals"].is_empty():
		return _fail("Raise animals before requesting the livestock storyline")
	if not _pay(20.0,"community","Post a village invitation for " + arc_id):
		return _fail("You need EUR 20 to host a village meeting")
	state["decisions"]["last_invitation_hour"] = now
	var root_event: String = str(info["root"])
	state["events"]["active"] = {"id":root_event,"title":Decisions.title(root_event,"en"),"hour":now}
	_log("The village accepted an invitation: " + Decisions.title(root_event,"en"),"event")
	return _ok("A neighbour has come to discuss the project")

func _show_due_story_event() -> bool:
	if not state["events"]["active"].is_empty():
		return false
	var now: int = int(state["time"]["total"])
	var jobs: Array = state["decisions"]["followups"]
	var chosen_index: int = -1
	var earliest: int = 9223372036854775807
	for i in range(jobs.size()):
		var due: int = int(jobs[i]["due"])
		if due <= now and due < earliest:
			chosen_index = i
			earliest = due
	if chosen_index < 0:
		return false
	var job: Dictionary = jobs[chosen_index]
	jobs.remove_at(chosen_index)
	var stage_id: String = str(job["stage"])
	var arc_id: String = str(job["arc"])
	state["events"]["active"] = {"id":stage_id,"arc":arc_id,
		"title":Chains.title(stage_id,"en"),"hour":now}
	state["decisions"]["branches"][arc_id]["status"] = "active"
	_log("A follow-up decision is ready: " + Chains.title(stage_id,"en"),"event")
	return true

func option_probability(stage_id: String, option_id: String) -> float:
	var option: Dictionary = Chains.option(stage_id,option_id)
	if option.is_empty():
		return 0.0
	var basic: float = clampf(float(option.get("chance",1.0)),0.0,1.0)
	if basic >= 1.0:
		return 1.0
	return minf(0.95,basic + (0.10 if bool(state["decisions"]["clues"].get(stage_id,false)) else 0.0))

func has_event_research(stage_id: String) -> bool:
	return bool(state.get("decisions",{}).get("clues",{}).get(stage_id,false))

func _research_event() -> Dictionary:
	var event: Dictionary = state["events"]["active"]
	if event.is_empty() or str(event.get("arc","")) == "":
		return _fail("Only active village stories can be researched")
	var stage_id: String = str(event["id"])
	if has_event_research(stage_id):
		return _fail("This event has already been investigated")
	if not _pay(18.0,"information","Consult a neighbour about " + stage_id):
		return _fail("You need EUR 18 to research the options")
	state["decisions"]["clues"][stage_id] = true
	return _ok("The neighbour assessed the risk; chances are now clearer")

func _apply_story_values(values: Dictionary, npc_id: String, cause: String) -> Dictionary:
	var fee: float = float(values.get("cost",0.0))
	if fee < 0.0 or not is_finite(fee):
		return _fail("Invalid event payment")
	if fee > 0.0 and not _pay(fee,"event","Village decision: " + cause):
		return _fail("Not enough cash for this choice")
	var goods: Dictionary = values.get("goods",{})
	for good_id in goods.keys():
		var delta: float = float(goods[good_id])
		if not content["goods"].has(str(good_id)) or not is_finite(delta):
			return _fail("Invalid event goods")
		if delta < 0.0 and stock(str(good_id))+0.0001 < -delta:
			return _fail("Not enough stored goods for this choice")
		if delta > 0.0 and stored()+delta > storage_capacity()+0.0001:
			return _fail("Not enough storage for this choice")
		if delta < 0.0:
			_stock_take(str(good_id),-delta)
		elif delta > 0.0:
			_stock_add(str(good_id),delta)
	if values.has("water"):
		state["water"]["stored"] = clampf(float(state["water"]["stored"])+float(values["water"]),0.0,float(state["water"]["capacity"]))
	if values.has("reputation"):
		state["economy"]["reputation"] = maxi(0,int(state["economy"]["reputation"])+int(values["reputation"]))
	if values.has("trust"):
		_change_trust(npc_id,int(values["trust"]),cause)
	var first: Dictionary = field_of("plot1")
	if values.has("soil_n"):
		first["soil"]["n"] = maxf(0.0,float(first["soil"]["n"])+float(values["soil_n"]))
	if values.has("organic_n"):
		first["soil"]["organic_n"] = maxf(0.0,float(first["soil"]["organic_n"])+float(values["organic_n"]))
	if values.has("aphid_delta"):
		first["pests"]["aphids"] = maxf(0.0,float(first["pests"]["aphids"])+float(values["aphid_delta"]))
	if values.has("bees_delta"):
		first["beneficial"]["bees"] = clampf(float(first["beneficial"]["bees"])+float(values["bees_delta"]),0.0,5.0)
	if values.has("animal_condition"):
		for animal in state["animals"]:
			animal["condition"] = clampf(float(animal["condition"])+float(values["animal_condition"]),0.2,1.0)
	if values.has("modifier"):
		var bonus: Dictionary = values["modifier"]
		_grant_effect(str(bonus["id"]),float(bonus["amount"]),int(bonus["hours"]))
	if values.has("xp"):
		_xp(int(values["xp"]),"community")
	return _ok("Village effects applied")

func _resolve_story_stage(choice_id: String) -> Dictionary:
	var event: Dictionary = state["events"]["active"]
	var stage_id: String = str(event["id"])
	var arc_id: String = str(event["arc"])
	var stage_info: Dictionary = Chains.stage(stage_id)
	var option: Dictionary = Chains.option(stage_id,choice_id)
	if option.is_empty() or stage_info.is_empty():
		return _fail("Choose a valid village response")
	var npc_id: String = str(Chains.arc(arc_id)["npc"])
	var initial_cash: float = _cash()
	var initial_water: float = float(state["water"]["stored"])
	var initial_reputation: int = int(state["economy"]["reputation"])
	var initial_trust: int = npc_trust(npc_id)
	var before_rng: int = int(state["rng"])
	var step: Dictionary = _apply_story_values(option,npc_id,stage_id+":"+choice_id)
	if not bool(step.get("ok",false)):
		return step
	var probability: float = option_probability(stage_id,choice_id)
	var outcome: String = "certain"
	if probability < 1.0:
		var success: bool = _rand() < probability
		outcome = "success" if success else "setback"
		var extra: Dictionary = {}
		if success:
			extra = option.get("win",{})
		else:
			extra = option.get("lose",{})
		var bonus_result: Dictionary = _apply_story_values(extra,npc_id,stage_id+":"+choice_id+":"+outcome)
		if not bool(bonus_result.get("ok",false)):
			return bonus_result
	var now: int = int(state["time"]["total"])
	state["events"]["history"].append({"id":stage_id,"choice":choice_id,"hour":now})
	var record: Dictionary = {"id":stage_id,"choice":choice_id,"arc":arc_id,"hour":now,"result":outcome,
		"cash_change":Data.money(_cash()-initial_cash),"water_change":float(state["water"]["stored"])-initial_water,
		"reputation_change":int(state["economy"]["reputation"])-initial_reputation,"trust_change":npc_trust(npc_id)-initial_trust,
		"risk_checked":has_event_research(stage_id),"chance":probability,"rng_used":int(state["rng"]) != before_rng}
	state["decisions"]["history"].append(record)
	while state["decisions"]["history"].size() > 140:
		state["decisions"]["history"].pop_front()
	var next_stage: String = str(stage_info.get("next",""))
	state["decisions"]["branches"][arc_id]["last_choice"] = choice_id
	if next_stage == "":
		state["decisions"]["branches"][arc_id]["status"] = "completed"
	else:
		state["decisions"]["branches"][arc_id]["status"] = "pending"
		_queue_story_followup(arc_id,next_stage,int(stage_info["delay_hours"]))
	state["events"]["active"] = {}
	_log("Village story: " + Chains.title(stage_id,"en") + " (" + outcome + ")","event")
	_xp(28,"community")
	return _ok("Village decision applied: " + outcome)

func _advance_hour() -> void:
	var clock: Dictionary = state["time"]
	clock["total"] = int(clock["total"]) + 1
	clock["hour"] = (8 + int(clock["total"])) % 24
	clock["day"] = 1 + int(int(clock["total"]) / 24)
	clock["season"] = int((int(clock["day"]) - 1) / SEASON_DAYS) % 4
	_finish_timed_jobs()
	if int(state["wildlife"]["venom_hours"]) > 0:
		state["wildlife"]["venom_hours"] = int(state["wildlife"]["venom_hours"]) - 1
	_grow_one_hour()
	if int(clock["total"]) % 24 == 0:
		_roll_day()
	# Remove expired event modifiers without consuming simulation RNG.
	for effect_id in state["decisions"]["effects"].keys():
		if int(state["decisions"]["effects"][effect_id]["until"]) <= int(clock["total"]):
			state["decisions"]["effects"].erase(effect_id)
	var events: Dictionary = state["events"]
	if events["active"].is_empty() and _show_due_story_event():
		return
	if events["active"].is_empty() and int(clock["total"]) >= int(events["next"]):
		var chance: float = 0.40 if state["difficulty"] == "relaxed" else (0.68 if state["difficulty"] == "hard" else 0.56)
		events["next"] = int(clock["total"]) + 20 + int(_rand() * 26)
		if _rand() < chance:
			_spawn_event()

func _finish_timed_jobs() -> void:
	var now: int = int(state["time"]["total"])
	for herd in state["animals"]:
		if int(herd.get("pregnancy_due",0)) > 0 and int(herd["pregnancy_due"]) <= now:
			herd["pregnancy_due"] = 0
			herd["count"] = int(herd["count"]) + 1
			_log("Newborn added to the " + str(herd["kind"]) + " group","animals")
			_xp(24,"livestock")
	for decoration in state["decorations"]:
		if not bool(decoration["completed"]) and int(decoration["ready_at"]) <= now:
			decoration["completed"] = true
			state["stats"]["decorations_built"] = float(state["stats"]["decorations_built"]) + 1.0
			_xp(24,"crafting")
			_log("Decoration complete: " + str(decoration["kind"]),"crafting")
	for building in state["buildings"]:
		if int(building["target"]) > int(building["level"]) and int(building["ready_at"]) <= now:
			building["level"] = int(building["target"])
			state["stats"]["buildings_completed"] = int(state["stats"]["buildings_completed"]) + 1
			if building["kind"] == "pond":
				state["water"]["capacity"] += 350.0
			_log("Construction completed: " + str(building["kind"]), "building")
			_xp(35, "crafting")
	for job in state["player"]["training"].duplicate():
		if int(job["finish"]) <= now:
			state["player"]["training"].erase(job)
			state["player"]["courses"].append(str(job["id"]))
			_log("Course completed: " + str(job["id"]), "learning")
			_xp(75, "crafting")
	for delivery in state["deliveries"].duplicate():
		if int(delivery["arrive"]) <= now:
			var f: Dictionary = field_of(str(delivery["field"]))
			if not f.is_empty() and bool(f["owned"]):
				var ally: String = str(delivery["species"])
				f["beneficial"][ally] = minf(20.0, float(f["beneficial"].get(ally, 0.0)) + (1.5 if ally == "ladybirds" else 0.5))
			state["deliveries"].erase(delivery)
			_log("Beneficial insects arrived", "ecology")
	for batch in state["processing"].duplicate():
		if int(batch["finish"]) <= now:
			var accepted: float = _stock_add(str(batch["recipe"]), float(batch["output_kg"]))
			state["stats"]["processed_kg"] += accepted
			state["processing"].erase(batch)
			_log("Processing finished: " + str(snappedf(accepted, 0.1)) + " kg " + str(batch["recipe"]), "processing")
			_xp(20, "crafting")

func _grow_one_hour() -> void:
	var temperature: float = float(state["weather"]["temperature"])
	for f in state["fields"]:
		if not f["owned"] or f["crop"].is_empty():
			continue
		var crop: Dictionary = f["crop"]
		var def: Dictionary = content["crops"].get(str(crop["id"]), {})
		if def.is_empty():
			continue
		var soil: Dictionary = f["soil"]
		var terrain: Dictionary = content["terrains"].get(str(f["terrain"]), {})
		var local_temp: float = temperature + float(terrain.get("temp", 0.0)) + 2.0 * level_of("greenhouse", str(f["id"]))
		var base_temp: float = float(def.get("baseTempC", 3.0))
		var optimum: float = float(def.get("optimumTempC", 20.0))
		var thermal: float = clampf((local_temp - base_temp) / maxf(1.0, optimum - base_temp), 0.0, 1.25)
		var water_ratio: float = Fields52.water_factor(f,crop)
		var nutrient_ratio: float = minf(1.0, minf(float(soil["n"]) / 24.0, minf(float(soil["p"]) / 10.0, float(soil["k"]) / 45.0)))
		var pest_pressure: float = 0.0
		for pest_id in PEST_IDS:
			var pest_info: Dictionary = content["pests"][pest_id]
			pest_pressure += minf(0.13, float(f["pests"][pest_id]) / maxf(1.0, float(pest_info["capacity"])) * float(pest_info["damageMax"]))
		pest_pressure = minf(0.8, pest_pressure * (0.9 if has_talent("pestScout") or has_course("ecology") else 1.0))
		var disease_pressure: float = 0.0
		for disease_id in DISEASE_IDS:
			disease_pressure += float(f["diseases"][disease_id]) * float(content["diseases"][disease_id]["damageMax"])
		disease_pressure = minf(0.8, disease_pressure * (0.86 if has_talent("diseaseReader") else 1.0))
		var crop_family: String = str(def.get("family", ""))
		var rotation: float = 0.90 if crop_family == str(f["last_family"]) and str(f["plot_type"]) != "orchard" else 1.0
		var bee_dependency: float = float(def.get("pollinationDependence", 0.0))
		var bee_sufficiency: float = clampf(float(f["beneficial"]["bees"]) * float(terrain.get("bees", 1.0)), 0.25, 1.0)
		var pollination: float = 1.0 - bee_dependency * (1.0 - bee_sufficiency)
		var growth_rate: float = thermal * (1.15 if has_talent("greenThumb") else 1.0)
		if has_talent("hillGrower") and str(f["terrain"]) == "hill":
			growth_rate *= 1.1
		growth_rate *= 1.0 + 0.07 * level_of("greenhouse", str(f["id"]))
		growth_rate *= Fields52.growth_factor(f,crop,int(state["time"]["season"]))
		crop["age"] = float(crop["age"]) + 1.0
		var delta_development: float = minf(1.0 - float(crop["development"]), growth_rate / Fields52.duration(def,crop))
		crop["development"] = minf(1.0, float(crop["development"]) + delta_development)
		var gain_ratio: float = maxf(0.0, nutrient_ratio * water_ratio * rotation * pollination * (1.0 - pest_pressure) * (1.0 - disease_pressure))
		gain_ratio *= Life.organic_score(f)
		var biomass_gain: float = float(def["biomassMax"]) / Fields52.duration(def,crop) * thermal * gain_ratio
		# All nutrient uptake is limited by the actually available mineral pool.
		var needed_n: float = biomass_gain * float(def["nPerBiomass"]) * AREA_HA
		var needed_p: float = biomass_gain * float(def["pPerBiomass"]) * AREA_HA
		var needed_k: float = biomass_gain * float(def["kPerBiomass"]) * AREA_HA
		var available: float = 1.0
		if needed_n > 0.0:
			available = minf(available, float(soil["n"]) / needed_n)
		if needed_p > 0.0:
			available = minf(available, float(soil["p"]) / needed_p)
		if needed_k > 0.0:
			available = minf(available, float(soil["k"]) / needed_k)
		available = clampf(available, 0.0, 1.0)
		biomass_gain *= available
		soil["n"] = maxf(0.0, float(soil["n"]) - needed_n * available)
		soil["p"] = maxf(0.0, float(soil["p"]) - needed_p * available)
		soil["k"] = maxf(0.0, float(soil["k"]) - needed_k * available)
		crop["biomass"] = minf(float(def["biomassMax"]), float(crop["biomass"]) + biomass_gain)
		crop["water_stress"] = 1.0 - water_ratio
		crop["pest_stress"] = pest_pressure
		crop["disease_stress"] = disease_pressure
		crop["health"] = clampf((water_ratio + nutrient_ratio + (1.0-pest_pressure) + (1.0-disease_pressure)) / 4.0, 0.0, 1.0)
		if float(crop["development"]) >= 1.0:
			# Delay causes slow standing losses rather than a guaranteed perfect harvest.
			crop["biomass"] *= 0.9996

func _roll_day() -> void:
	_seasonal_recap()
	_generate_weather()
	var weather: Dictionary = state["weather"]
	var rain: float = float(weather["rain"])
	var temp: float = float(weather["temperature"])
	# Rain capture produces finite reservoir input; no implied infinite water.
	state["water"]["stored"] = minf(float(state["water"]["capacity"]), float(state["water"]["stored"]) + rain * (0.65 + 0.10 * level_of("pond")) * 1.0)
	for f in state["fields"]:
		if not f["owned"]:
			continue
		var soil: Dictionary = f["soil"]
		var terrain: Dictionary = content["terrains"][str(f["terrain"])]
		var layout: Dictionary = Fields52.PLOTS[str(f["plot_type"])]
		var add_rain: float = rain * float(terrain["rain"]) * float(layout["rain"]) * (1.0 - 0.26 * float(soil["compaction"]))
		var base_evap: float = 4.5 * clampf(temp / 20.0, 0.30, 1.65) * float(terrain["evap"])
		base_evap *= float(layout["evap"])
		base_evap *= 1.0 - 0.40 * float(soil["mulch"])
		base_evap *= 1.0 - _effect("water_saver")
		base_evap *= 1.0 - 0.08 * level_of("irrigation", str(f["id"]))
		if has_talent("moistureSense"):
			base_evap *= 0.92
		if has_talent("mulchMastery"):
			base_evap *= 1.0 - 0.15 * float(soil["mulch"])
		var seepage: float = 3.2 if str(f["plot_type"]) == "paddy" else 0.0
		soil["water"] = clampf(float(soil["water"]) + add_rain - base_evap - seepage, 0.0, float(soil["capacity"]))
		if str(f["plot_type"]) == "raised":
			soil["compaction"] = maxf(0.0,float(soil["compaction"])-0.002)
		soil["mulch"] = maxf(0.0, float(soil["mulch"]) - 0.012)
		var covered: bool = int(f.get("cover_until",0)) > int(state["time"]["total"])
		if covered:
			soil["organic_matter"] = minf(12.0,float(soil["organic_matter"])+0.014)
			soil["compaction"] = maxf(0.0,float(soil["compaction"])-0.004)
		else:
			soil["organic_matter"] = maxf(0.2,float(soil["organic_matter"])-0.002)
		var erosion_risk: float = maxf(0.0,(rain-7.0)/120.0) * (0.17 if covered else (0.50 if f["crop"].is_empty() else 0.23))
		if bool(f.get("hedgerow",false)):
			erosion_risk *= 0.55
		if str(state["life"]["path"]) == "ecology":
			erosion_risk *= 0.65
		soil["erosion"] = clampf(float(soil["erosion"])+erosion_risk-0.0006,0.0,1.0)
		soil["compaction"] = clampf(float(soil["compaction"])+(0.0025 if rain > 8.0 else 0.0)-0.0004,0.0,1.0)
		# Organic mineralization moves existing nutrients, not new free fertilizer.
		for element in ["n", "p", "k"]:
			var organic: String = "organic_" + element
			var rate: float = {"n":0.002,"p":0.001,"k":0.004}[element]
			var mineralized: float = float(soil[organic]) * rate * clampf(temp / 20.0, 0.2, 1.7)
			soil[organic] = maxf(0.0, float(soil[organic]) - mineralized)
			soil[element] += mineralized
		if rain > 8.0:
			var shelter: float = _effect("nutrient_shield")
			soil["n"] *= 0.995 + 0.005 * shelter
			soil["p"] *= 0.999 + 0.001 * shelter
			soil["k"] *= 0.997 + 0.003 * shelter
		f["spray_residue"] = maxf(0.0, float(f["spray_residue"]) * 0.72)
		for method in f["protection"].keys():
			if int(f["protection"][method]) <= int(state["time"]["total"]):
				f["protection"].erase(method)
		_update_field_ecology(f, temp, rain)
	_update_animals_daily()
	state["wildlife"]["energy"] = minf(100.0, float(state["wildlife"]["energy"]) + 11.0)
	_spoil_daily()
	_charge_upkeep()
	_update_market()
	_update_story()
	if bool(state["automation"]):
		_automate_care()

func _generate_weather() -> void:
	var season: int = int(state["time"]["season"])
	var base: float = [18.0, 27.0, 17.0, 8.0][season]
	var temperature: float = base + (_rand() - 0.5) * 10.0
	var rain_chance: float = [0.50, 0.28, 0.50, 0.62][season]
	if str(state["difficulty"]) == "hard" or str(state["mode"]) == "challenge":
		rain_chance *= 0.78
	var rain: float = (2.0 + _rand() * 13.0) if _rand() < rain_chance else 0.0
	var weather_kind: String = "rain" if rain > 0.0 else "clear"
	if _rand() < 0.09 and rain == 0.0:
		weather_kind = "heat"
		temperature += 7.0
	state["weather"] = {"kind":weather_kind,"temperature":temperature,"rain":rain,"humidity":0.80 if rain > 0.0 else 0.35 + _rand() * 0.3,"forecast":"variable"}

func _update_field_ecology(f: Dictionary, temp: float, rain: float) -> void:
	var terrain: Dictionary = content["terrains"][str(f["terrain"])]
	var pest_factor: float = 1.0 if not f["crop"].is_empty() else 0.4
	var pressure: float = maxf(0.3, 1.0 + (temp - 20.0) / 40.0)
	var prey_aphid: float = float(f["pests"]["aphids"])
	var lady: float = float(f["beneficial"]["ladybirds"])
	var parasitoid: float = float(f["beneficial"]["parasitoids"])
	for pest_id in PEST_IDS:
		var item: Dictionary = content["pests"][pest_id]
		var amount: float = float(f["pests"][pest_id])
		var habitat: float = 1.0
		if pest_id == "slugs":
			habitat = float(terrain["slugs"]) * (1.25 if rain > 0.0 else 0.85)
		elif pest_id == "mites":
			habitat = float(terrain["mites"]) * (1.3 if temp > 26.0 and rain <= 0.0 else 0.8)
		elif pest_id == "whiteflies" and level_of("greenhouse", str(f["id"])) > 0:
			habitat = 1.4
		elif pest_id == "nematodes" and f["crop"] != {}:
			habitat = 1.2 if str(f["last_family"]) == str(content["crops"][str(f["crop"]["id"])]["family"]) else 0.9
		var predation: float = 0.0
		if ["aphids", "whiteflies"].has(pest_id):
			predation = lady * (0.13 if has_talent("observation") else 0.10)
		elif ["caterpillars", "cutworms"].has(pest_id):
			predation = parasitoid * 0.55
		var growth: float = maxf(0.0, float(item["growthDaily"]) * amount * (1.0 - amount / maxf(1.0, float(item["capacity"]))) * habitat * pressure * pest_factor)
		growth *= 1.0 - _effect("pest_suppression")
		if pest_id == "locusts" and f["protection"].has("nets"):
			growth *= 0.4
		if ["slugs", "cutworms"].has(pest_id) and f["protection"].has("trap"):
			growth *= 0.5
		f["pests"][pest_id] = clampf(amount + growth - predation, 0.0, float(item["capacity"]))
	f["beneficial"]["ladybirds"] = clampf(lady + prey_aphid * 0.0015 + 0.03 - 0.10, 0.0, 20.0)
	f["beneficial"]["parasitoids"] = clampf(parasitoid + float(f["pests"]["caterpillars"]) * 0.002 + 0.015 - 0.025, 0.0, 10.0)
	f["beneficial"]["bees"] = clampf(float(f["beneficial"]["bees"]) * 0.93 + 0.07 * float(terrain["bees"]) + 0.06 * level_of("flowers") + _effect("pollinator_bonus") * 0.04 + (0.10 if bool(f.get("hedgerow",false)) else 0.0) + (0.04 if str(state["life"]["path"]) == "ecology" else 0.0), 0.0, 5.0)
	var wet: bool = rain > 3.0 or float(f["soil"]["water"]) > float(f["soil"]["capacity"]) * 0.75
	for disease_id in DISEASE_IDS:
		var disease: Dictionary = content["diseases"][disease_id]
		var severity: float = float(f["diseases"][disease_id])
		var favorable: bool = wet if disease_id != "mildew" else float(state["weather"]["humidity"]) > 0.60
		if disease_id == "rootRot":
			favorable = float(f["soil"]["water"]) > 125.0
		var delta: float = float(disease["growthDaily"]) * (1.0 - severity) * float(terrain["rootRot"] if disease_id == "rootRot" else 1.0) if favorable else -float(disease["recoveryDaily"])
		f["diseases"][disease_id] = clampf(severity + delta * pest_factor, 0.0, 1.0)

func _update_animals_daily() -> void:
	for a in state["animals"]:
		var species: Dictionary = content["animals"][str(a["kind"])]
		var count: int = int(a["count"])
		var needs: Dictionary = animal_daily_requirements(a)
		var feed_needed: float = float(needs["feed_kg"])
		var water_needed: float = float(needs["water_m3"])
		var enough_feed: bool = stock("feed") + 0.001 >= feed_needed
		var enough_water: bool = float(state["water"]["stored"]) + 0.001 >= water_needed
		if enough_feed and enough_water:
			_stock_take("feed",feed_needed)
			state["water"]["stored"] = maxf(0.0,float(state["water"]["stored"])-water_needed)
			a["condition"] = minf(1.0,float(a["condition"]) + 0.018 + _effect("animal_welfare"))
			a["nutrition"] = minf(1.0,float(a["nutrition"]) + float(needs["nutrition_gain"]))
			_wear_machine("mixer",0.003)
		else:
			a["condition"] = maxf(0.10,float(a["condition"])-0.12)
			a["nutrition"] = maxf(0.0,float(a["nutrition"])-0.14)
		var weather_temp: float = float(state["weather"]["temperature"])
		var exposed: bool = weather_temp < 1.0 or weather_temp > 35.0
		var has_veterinary_cover: bool = int(a["vet_until"]) > int(state["time"]["total"])
		var illness: float = 0.012 if exposed else 0.003
		if float(a["nutrition"]) < 0.35:
			illness += 0.030
		if has_veterinary_cover:
			illness *= 0.35
		a["health"] = clampf(float(a["health"]) - illness + (0.007 if enough_feed and enough_water else 0.0),0.12,1.0)
		a["age_days"] = int(a["age_days"]) + 1
		var elderly: float = 0.82 if int(a["age_days"]) > 180 else 1.0
		var multiplier: float = 1.0 + (0.1 if has_course("livestock") else 0.0) + (0.15 if has_talent("rancher") else 0.0) + (0.12 if has_talent("happyHerd") else 0.0)
		multiplier *= 1.09 if str(state["life"]["path"]) == "livestock" else 1.0
		var yield_factor: float = (0.0 if not enough_feed or not enough_water else 1.0)
		var produced: float = count * float(species["produceKgDaily"]) * float(a["condition"]) * float(a["health"]) * (0.55 + 0.45*float(a["nutrition"])) * multiplier * elderly * yield_factor * (1.0 + mastery_bonus("livestock"))
		var accepted: float = _stock_add(str(species["produceGood"]),produced)
		state["stats"]["animal_kg"] += accepted
	if ready("apiary"):
		var honey: float = _stock_add("honey",0.8*level_of("apiary"))
		state["stats"]["animal_kg"] += honey

func _spoil_daily() -> void:
	for good in state["inventory"].keys():
		var entry: Dictionary = content["goods"].get(str(good), {})
		var rate: float = float(entry.get("spoilageDaily", 0.0))
		var multiplier: float = 0.80 if level_of("warehouse") > 0 else 1.0
		if level_of("rootCellar") > 0:
			multiplier *= 0.80
		if has_talent("storageCare"):
			multiplier *= 0.82
		multiplier *= 1.0 - _effect("spoilage_guard")
		var existing_premium: float = premium_stock(str(good))
		state["inventory"][good] = maxf(0.0, float(state["inventory"][good]) * (1.0 - rate * multiplier))
		state["life"]["quality_stock"][good] = minf(float(state["inventory"][good]),existing_premium * (1.0 - rate * multiplier))

func _charge_upkeep() -> void:
	var upkeep: float = 0.0
	for b in state["buildings"]:
		if int(b["level"]) > 0:
			upkeep += float(content["buildings"][str(b["kind"])]["upkeepDaily"]) * int(b["level"])
	if upkeep > 0.0 and not _pay(upkeep, "upkeep", "Daily maintenance"):
		state["economy"]["reputation"] = maxi(0, int(state["economy"]["reputation"]) - 1)
		_log("Insufficient cash for building maintenance", "warning")
	for machine_id in state["life"]["machines"].keys():
		var machine: Dictionary = state["life"]["machines"][machine_id]
		var fee: float = float(Life.MACHINES[machine_id]["upkeep"])
		if not _pay(fee,"equipment","Daily machinery maintenance"):
			machine["condition"] = maxf(0.0,float(machine["condition"])-0.045)
			_log("Machinery maintenance unpaid: " + str(machine_id),"warning")
		if float(machine["condition"]) < 0.35 and int(machine["broken_until"]) <= int(state["time"]["total"]):
			if _rand() < 0.12 + 0.18 * (0.35-float(machine["condition"])):
				machine["broken_until"] = int(state["time"]["total"]) + 48
				state["life"]["machine_breakdowns"] = int(state["life"]["machine_breakdowns"]) + 1
				_log("Equipment breakdown: " + str(machine_id) + "; service is required", "warning")

func _update_market() -> void:
	var trend: float = clampf(float(state["market"]["index"]) + (_rand() - 0.5) * 0.12, 0.78, 1.30)
	state["market"]["index"] = trend
	for good in content["goods"].keys():
		state["market"]["price_index"][good] = clampf(trend + (_rand() - 0.5) * 0.25, 0.60, 1.50)
	for offer in state["market"]["offers"]:
		if offer["status"] == "open" and int(offer["expires"]) <= int(state["time"]["total"]):
			offer["status"] = "expired"
	for contract in state["market"]["contracts"]:
		if contract["status"] == "open" and int(contract["deadline"]) <= int(state["time"]["total"]):
			contract["status"] = "expired"
		if contract["status"] == "active" and int(contract["deadline"]) <= int(state["time"]["total"]):
			contract["status"] = "failed"
			state["economy"]["reputation"] = maxi(0, int(state["economy"]["reputation"]) - 3)
			_log("A contract was missed; deposit is forfeited", "warning")
	if int(state["time"]["day"]) % 3 == 0:
		_spawn_offer()
	if int(state["time"]["day"]) % 4 == 0:
		_spawn_contract()

func _spawn_offer() -> void:
	var offers: Array = state["market"]["offers"]
	var active: int = 0
	for o in offers:
		if o["status"] == "open":
			active += 1
	if active >= 3:
		return
	var possible: Array = []
	for good in state["inventory"].keys():
		if str(good) != "feed" and stock(str(good)) >= 10.0:
			possible.append(good)
	if possible.is_empty():
		return
	var good: String = str(possible[int(_rand() * possible.size())])
	var amount: float = minf(stock(good), 20.0 + float(int(_rand() * 40.0)))
	var ratio: float = 0.78 + _rand() * 0.65
	offers.append({"id":_id(),"kind":"buy","npc":"bruno","good":good,"kg":amount,"price":Data.money(market_price(good) * ratio),"expires":int(state["time"]["total"]) + 36,"status":"open"})
	_log("A travelling buyer has made a time-limited offer", "market")

func _spawn_contract() -> void:
	var contracts: Array = state["market"]["contracts"]
	var active: int = 0
	for c in contracts:
		if c["status"] == "open" or c["status"] == "active":
			active += 1
	if active >= 3:
		return
	var goods: Array = ["wheat", "bean", "sunflower", "barley", "potato", "carrot", "lettuce", "strawberry", "maize", "tomato", "pumpkin", "lavender", "eggs", "milk", "wool"]
	var good: String = str(goods[int(_rand() * goods.size())])
	var kg: float = 30.0 + float(int(_rand() * 70.0))
	var price: float = market_price(good) * (1.18 + _rand() * 0.25)
	contracts.append({"id":_id(),"good":good,"kg":kg,"payout":Data.money(kg * price),"deposit":Data.money(kg * price * 0.10),"deadline":int(state["time"]["total"]) + 120,"status":"open"})
	_log("A buyer posted a fresh harvest contract", "market")

func _resolve_offer(id: String, accept: bool) -> Dictionary:
	for o in state["market"]["offers"]:
		if str(o["id"]) != id:
			continue
		if str(o["status"]) != "open" or int(o["expires"]) <= int(state["time"]["total"]):
			return _fail("The offer has expired")
		if not accept:
			o["status"] = "declined"
			return _ok("Offer declined")
		if not _stock_take(str(o["good"]), float(o["kg"])):
			return _fail("You no longer have the requested harvest")
		_earn(float(o["kg"]) * float(o["price"]), "revenue", "Visitor sale")
		o["status"] = "accepted"
		state["economy"]["reputation"] += 1
		return _ok("Visitor offer accepted")
	return _fail("Offer not found")

func _contract_accept(id: String) -> Dictionary:
	for c in state["market"]["contracts"]:
		if str(c["id"]) != id:
			continue
		if str(c["status"]) != "open" or int(c["deadline"]) <= int(state["time"]["total"]):
			return _fail("The contract is no longer available")
		if not _pay(float(c["deposit"]), "penalty", "Contract deposit"):
			return _fail("Insufficient cash for contract deposit")
		c["status"] = "active"
		return _ok("Contract accepted; deposit held until delivery")
	return _fail("Contract not found")

func _contract_deliver(id: String) -> Dictionary:
	for c in state["market"]["contracts"]:
		if str(c["id"]) != id:
			continue
		if c["status"] != "active" or int(c["deadline"]) <= int(state["time"]["total"]):
			return _fail("Contract is not active")
		if not _stock_take(str(c["good"]), float(c["kg"])):
			return _fail("You must deliver the full contracted quantity")
		_earn(float(c["payout"]) + float(c["deposit"]), "revenue", "Completed contract and returned deposit")
		c["status"] = "delivered"
		state["stats"]["contracts_delivered"] += 1
		state["economy"]["reputation"] += 3
		_xp(55)
		return _ok("Contract successfully delivered")
	return _fail("Contract not found")

func _automate_care() -> void:
	if not ready("farmhouse"):
		return
	for f in state["fields"]:
		if not f["owned"] or f["crop"].is_empty():
			continue
		if float(f["crop"]["development"]) >= 0.995:
			_apply("harvest", {"fieldId":f["id"]})
		elif float(f["soil"]["water"]) < 38.0 and _cash() > 20.0:
			_apply("irrigate", {"fieldId":f["id"],"mm":12.0})

func _update_story() -> void:
	if state["mode"] != "story" or bool(state["story"]["completed"]):
		return
	var s: Dictionary = state["story"]
	var chapter: int = int(s["chapter"])
	var stats: Dictionary = state["stats"]
	var advanced: bool = false
	if chapter == 1 and float(stats["harvest_kg"]) >= 150.0:
		s["chapter"] = 2
		advanced = true
	elif chapter == 2 and int(stats["fields_bought"]) >= 1 and int(stats["buildings_completed"]) >= 1:
		s["chapter"] = 3
		advanced = true
	elif chapter == 3 and int(stats["contracts_delivered"]) >= 1 and state["player"]["courses"].size() >= 1:
		s["chapter"] = 4
		advanced = true
	elif chapter == 4 and int(stats["buildings_completed"]) >= 3 and int(state["economy"]["reputation"]) >= 10:
		s["completed"] = true
		advanced = true
	if advanced:
		_xp(100)
		_log("The farm story has moved forward", "story")

func _spawn_event() -> void:
	var catalog: Dictionary = Decisions.catalog()
	var scenarios: Array = catalog.keys()
	scenarios.sort()
	var eligible: Array = []
	for id in scenarios:
		if ["animal_health","livestock_inspection"].has(str(id)) and state["animals"].is_empty():
			continue
		if ["buyer","cold_storage_offer"].has(str(id)) and stored() < 5.0:
			continue
		eligible.append(id)
	if eligible.is_empty():
		return
	var picked: String = str(eligible[int(_rand() * eligible.size())])
	state["events"]["active"] = {"id":picked,"title":Decisions.title(picked,"en"),"hour":state["time"]["total"]}
	_log("A new decision needs your attention: " + Decisions.title(picked,"en"), "event")

func event_options() -> Array:
	var active: Dictionary = state.get("events",{}).get("active",{})
	if active.is_empty():
		return []
	if str(active.get("arc","")) != "":
		return Chains.options(str(active["id"]),language)
	return Decisions.options(str(active["id"]),language)

func _resolve_event(choice: String) -> Dictionary:
	var event: Dictionary = state["events"]["active"]
	if event.is_empty():
		return _fail("There is no pending event")
	if str(event.get("arc","")) != "":
		return _resolve_story_stage(choice)
	var valid: bool = false
	for option in event_options():
		if str(option["id"]) == choice:
			valid = true
			break
	if not valid:
		return _fail("Choose a listed event response")
	var kind: String = str(event["id"])
	var first: Dictionary = field_of("plot1")
	var before_cash: float = _cash()
	var before_water: float = float(state["water"]["stored"])
	var before_reputation: int = int(state["economy"]["reputation"])
	var outcome: String = "You chose to " + choice.replace("_", " ")
	match kind:
		"dry_spell":
			if choice == "water":
				if not _pay(27.0, "water", "Emergency water purchase"):
					return _fail("Cannot afford emergency water")
				state["water"]["stored"] = minf(float(state["water"]["capacity"]), float(state["water"]["stored"]) + 100.0)
			elif choice == "mulch":
				var result: Dictionary = _apply("mulch", {"fieldId":"plot1"})
				if not result["ok"]:
					return result
		"insect_flight":
			if choice == "allies":
				var result: Dictionary = _apply("release", {"fieldId":"plot1","species":"ladybirds"})
				if not result["ok"]:
					return result
			elif choice == "soap":
				var result: Dictionary = _apply("treat", {"fieldId":"plot1","method":"soap"})
				if not result["ok"]:
					return result
			else:
				first["pests"]["aphids"] += 2.0
		"buyer":
			if choice == "sell":
				var good: String = ""
				for id in state["inventory"].keys():
					if str(id) != "feed" and stock(str(id)) >= 15.0:
						good = str(id)
						break
				if good == "":
					return _fail("You need 15 kg of produce for the buyer")
				_stock_take(good, 15.0)
				_earn(15.0 * market_price(good) * 1.35, "revenue", "Premium visitor sale")
			elif choice == "invest":
				if not _pay(60.0, "training", "Trade network meeting"):
					return _fail("Cannot pay for the introduction")
				state["economy"]["reputation"] += 2
		"flood":
			if choice == "drain":
				if not _pay(75.0, "treatments", "Emergency drainage"):
					return _fail("Not enough cash for drainage")
				first["soil"]["water"] = maxf(0.0, float(first["soil"]["water"]) - 18.0)
			elif choice == "save":
				state["economy"]["reputation"] += 1
			else:
				first["diseases"]["rootRot"] = minf(1.0, float(first["diseases"]["rootRot"]) + 0.2)
		"animal_health":
			if choice == "vet":
				if not _pay(85.0, "animals", "Veterinarian"):
					return _fail("Cannot afford veterinary visit")
				for a in state["animals"]:
					a["condition"] = minf(1.0, float(a["condition"]) + 0.3)
			elif choice == "rest":
				for a in state["animals"]:
					a["condition"] = minf(1.0, float(a["condition"]) + 0.08)
			else:
				for a in state["animals"]:
					a["condition"] = maxf(0.2, float(a["condition"]) - 0.10)
		"water_rights":
			if choice == "share":
				if not _pay(50.0, "water", "Community water fund"):
					return _fail("Cannot afford this contribution")
				state["economy"]["reputation"] += 3
			elif choice == "buy":
				if not _pay(24.0, "water", "Cooperative water purchase"):
					return _fail("Cannot afford cooperative water")
				state["water"]["stored"] = minf(float(state["water"]["capacity"]), float(state["water"]["stored"]) + 80.0)
		"festival":
			if choice == "enter":
				var result: Dictionary = _apply("festivalEnter", {})
				if not result["ok"]:
					return result
			elif choice == "sponsor":
				if not _pay(80.0, "upkeep", "Festival sponsor"):
					return _fail("Not enough cash to sponsor")
				state["economy"]["reputation"] += 5
		"storm":
			if choice == "repair":
				if not _pay(60.0, "treatments", "Storm preparation"):
					return _fail("Not enough cash")
			elif choice == "cover":
				var result: Dictionary = _apply("treat", {"fieldId":"plot1","method":"nets"})
				if not result["ok"]:
					return result
			else:
				for f in state["fields"]:
					if f["owned"] and not f["crop"].is_empty():
						f["crop"]["biomass"] *= 0.94
		"soil_clinic":
			if choice == "study":
				if not _pay(45.0, "training", "Soil consultant"):
					return _fail("Cannot afford soil advice")
				first["soil"]["n"] += 12.0
			elif choice == "compost":
				var result: Dictionary = _apply("compost", {"fieldId":"plot1"})
				if not result["ok"]:
					return result
		"seed_exchange":
			if choice == "trade":
				if stored() + 30.0 > storage_capacity() or not _pay(23.0, "seeds", "Seed exchange"):
					return _fail("Not enough cash or storage")
				_stock_add("barley", 30.0)
			elif choice == "donate":
				if not _pay(25.0, "upkeep", "Seed-sharing donation"):
					return _fail("Not enough cash for donation")
				state["economy"]["reputation"] += 2
		"frost":
			if choice == "cover":
				if not _pay(65.0, "treatments", "Frost cover"):
					return _fail("Not enough cash for frost cover")
				first["protection"]["frost"] = int(state["time"]["total"]) + 72
			elif choice != "cover" and not first["crop"].is_empty():
				first["crop"]["biomass"] *= 0.95
		"neighbour_request":
			if choice == "help":
				if not _pay(40.0, "upkeep", "Neighbour assistance"):
					return _fail("Not enough cash to help")
				state["economy"]["reputation"] += 3
			elif choice == "gift":
				var good: String = ""
				for id in state["inventory"].keys():
					if str(id) != "feed" and stock(str(id)) >= 10.0:
						good = str(id)
						break
				if good == "":
					return _fail("Need 10 kg available to donate")
				_stock_take(good, 10.0)
				state["economy"]["reputation"] += 4
		"wildlife_alert":
			if choice == "scout":
				if not _pay(25.0,"community","Ranger scouting"):
					return _fail("Not enough cash for ranger scouting")
				state["wildlife"]["observed"]["river"] = int(state["wildlife"]["observed"].get("river",0)) + 1
				state["economy"]["reputation"] += 1
			elif choice == "gear":
				if not bool(state["wildlife"]["gear"]):
					var result: Dictionary = _apply("buyGear", {})
					if not bool(result["ok"]):
						return result
				else:
					return _fail("You already own an outdoor field kit")
		"lost_lamb":
			if choice == "search":
				if not _pay(30.0,"community","Help locate animal"):
					return _fail("Not enough cash for the search")
				state["economy"]["reputation"] += 3
			elif choice == "supplies":
				if not _stock_take("feed",10.0):
					return _fail("Not enough feed to donate")
				state["economy"]["reputation"] += 2
		"river_cleanup":
			if choice == "volunteer":
				if not _pay(35.0,"community","Restore riverside"):
					return _fail("Cannot afford to join the river care group")
				state["economy"]["reputation"] += 4
			elif choice == "donate":
				if not _stock_take("feed",15.0):
					return _fail("15 kg of feed supplies are required")
				state["economy"]["reputation"] += 3
		"soil_erosion":
			if choice == "cover":
				if not _pay(45.0,"ecology","Protect erosion-prone ground"):
					return _fail("Insufficient funds for ground cover")
				first["soil"]["mulch"] = minf(1.0,float(first["soil"]["mulch"]) + 0.22)
			elif choice == "buffer":
				if not _pay(70.0,"ecology","Plant a valley buffer"):
					return _fail("Insufficient funds to plant a buffer")
				first["beneficial"]["bees"] = minf(20.0,float(first["beneficial"]["bees"]) + 0.30)
				state["economy"]["reputation"] += 1
			else:
				first["soil"]["organic_n"] = maxf(0.0,float(first["soil"]["organic_n"]) - 6.0)
		"apiary_surge":
			if choice == "flowers":
				if not _pay(55.0,"ecology","Seasonal pollinator strips"):
					return _fail("Insufficient funds for flower strips")
				for f in state["fields"]:
					if f["owned"]:
						f["beneficial"]["bees"] = minf(20.0,float(f["beneficial"]["bees"]) + 0.35)
			elif choice == "observe":
				state["wildlife"]["observed"]["pollinators"] = int(state["wildlife"]["observed"].get("pollinators",0)) + 1
				_xp(12)
		"market_shortage":
			if choice == "sell":
				var selected_good: String = ""
				for good_id in state["inventory"].keys():
					if str(good_id) != "feed" and stock(str(good_id)) >= 20.0:
						selected_good = str(good_id)
						break
				if selected_good == "":
					return _fail("Not enough saleable farm produce (20 kg)")
				_stock_take(selected_good,20.0)
				_earn(20.0 * market_price(selected_good) * 1.2,"revenue","Village shortage premium")
			elif choice == "feed":
				if stored() + 50.0 > storage_capacity():
					return _fail("Not enough storage for feed")
				if not _pay(42.0,"supplies","Market shortage feed offer"):
					return _fail("Insufficient money for feed")
				_stock_add("feed",50.0)
		"wetland_rescue":
			if choice == "help":
				if not _pay(40.0,"community","Wetland habitat restoration"):
					return _fail("Insufficient funds for rescue team")
				state["economy"]["reputation"] += 3
				state["wildlife"]["observed"]["marsh"] = int(state["wildlife"]["observed"].get("marsh",0)) + 1
			elif choice == "watch":
				state["wildlife"]["observed"]["marsh"] = int(state["wildlife"]["observed"].get("marsh",0)) + 1
		"soil_research":
			if choice == "lab":
				if not _pay(70.0,"ecology","Soil research visit"):
					return _fail("Not enough cash for laboratory soil work")
				first["soil"]["n"] += 15.0
				first["soil"]["p"] += 5.0
				_grant_effect("nutrient_shield",0.45,216)
			elif choice == "compost":
				if not _pay(44.0,"ecology","Compost delivery"):
					return _fail("Cannot afford the compost delivery")
				first["soil"]["organic_n"] += 42.0
				first["soil"]["organic_p"] += 7.0
		"irrigation_cooperative":
			if choice == "join":
				if not _pay(95.0,"water","Irrigation cooperative pilot"):
					return _fail("You need EUR 95 for the irrigation pilot")
				_grant_effect("water_saver",0.16,336)
				state["economy"]["reputation"] += 2
			elif choice == "water":
				if not _pay(40.0,"water","Cooperative water supply"):
					return _fail("You need EUR 40 for extra water")
				state["water"]["stored"] = minf(float(state["water"]["capacity"]),float(state["water"]["stored"])+180.0)
			else:
				state["economy"]["reputation"] = maxi(0,int(state["economy"]["reputation"])-1)
		"cold_storage_offer":
			if choice == "insulate":
				if not _pay(110.0,"storage","Cold storage rental"):
					return _fail("Insufficient cash for cold storage")
				_grant_effect("spoilage_guard",0.55,288)
			elif choice == "sell":
				var good: String = ""
				for id in state["inventory"].keys():
					if float(content["goods"].get(str(id),{}).get("spoilageDaily",0.0)) > 0.0 and stock(str(id)) >= 15.0:
						good = str(id)
						break
				if good == "":
					return _fail("At least 15 kg of perishable stock is required")
				_stock_take(good,15.0)
				_earn(15.0*market_price(good)*1.17,"revenue","Cold-storage trader sale")
		"livestock_inspection":
			if choice == "vet":
				if not _pay(60.0,"animals","Preventive livestock care"):
					return _fail("Not enough cash for welfare care")
				for animal in state["animals"]:
					animal["condition"] = minf(1.0,float(animal["condition"])+0.12)
				_grant_effect("animal_welfare",0.012,192)
			elif choice == "feed":
				if stored()+40.0 > storage_capacity()+0.001:
					return _fail("Not enough storage for 40 kg feed")
				if not _pay(38.0,"animals","Welfare feed purchase"):
					return _fail("Not enough cash for feed")
				_stock_add("feed",40.0)
			else:
				for animal in state["animals"]:
					animal["condition"] = maxf(0.2,float(animal["condition"])-0.06)
		"machinery_breakdown":
			if choice == "repair":
				if not _pay(90.0,"labor","Machinery service"):
					return _fail("Not enough cash for a full repair")
				_grant_effect("work_efficiency",0.10,216)
			elif choice == "borrow":
				if not _pay(25.0,"labor","Borrowed farm tools"):
					return _fail("You need EUR 25 to borrow tools")
				state["economy"]["reputation"] = maxi(0,int(state["economy"]["reputation"])-1)
			else:
				_grant_effect("labor_slowdown",0.17,120)
		"pest_hotspot":
			if choice == "scout":
				if not _pay(34.0,"treatments","Preventive pest scouting"):
					return _fail("Not enough cash for pest scouting")
				for f in state["fields"]:
					if f["owned"]:
						for pest_id in ["aphids","caterpillars","whiteflies"]:
							f["pests"][pest_id] = float(f["pests"][pest_id]) * 0.82
				_grant_effect("pest_suppression",0.30,168)
			elif choice == "spray":
				var result: Dictionary = _apply("treat",{"fieldId":"plot1","method":"spray"})
				if not result.get("ok",false):
					return result
			else:
				for f in state["fields"]:
					if f["owned"]:
						f["pests"]["aphids"] = minf(150.0,float(f["pests"]["aphids"])+3.0)
		"flower_council":
			if choice == "plant":
				if not _pay(45.0,"ecology","Pollinator flower corridors"):
					return _fail("Not enough cash to plant flowers")
				for f in state["fields"]:
					if f["owned"]:
						f["beneficial"]["bees"] = minf(5.0,float(f["beneficial"]["bees"])+0.45)
				_grant_effect("pollinator_bonus",0.35,240)
			elif choice == "donate":
				if not _stock_take("wildflowers",3.0):
					return _fail("Need 3 kg of wildflowers")
				state["economy"]["reputation"] += 2
		"soil_hardpan":
			if choice == "aerate":
				if not _pay(68.0,"ecology","Soil aeration"):
					return _fail("Not enough cash for aeration")
				first["soil"]["organic_n"] += 9.0
				_grant_effect("water_saver",0.06,144)
			elif choice == "compost":
				var result: Dictionary = _apply("spreadCompost",{"fieldId":"plot1"})
				if not result.get("ok",false):
					return result
			else:
				first["soil"]["water"] = maxf(0.0,float(first["soil"]["water"])-10.0)
		"tourism_invite":
			if choice == "open":
				if not _pay(40.0,"community","Farm open day"):
					return _fail("Not enough cash for a farm visit")
				state["economy"]["reputation"] += 3
				_grant_effect("market_trust",0.10,240)
			elif choice == "workshop":
				if not _pay(75.0,"community","Farming workshop"):
					return _fail("Not enough cash to host a workshop")
				state["economy"]["reputation"] += 4
				_xp(35,"community")
		"wildfire_smoke":
			if choice == "prepare":
				if not _pay(65.0,"water","Fire season water cover"):
					return _fail("Not enough cash for water preparation")
				_grant_effect("water_saver",0.10,192)
			elif choice == "help":
				if not _pay(35.0,"community","Village emergency assistance"):
					return _fail("Not enough cash to help")
				if float(state["wildlife"]["energy"]) < 10.0:
					return _fail("Not enough farmer energy to help")
				state["wildlife"]["energy"] = float(state["wildlife"]["energy"])-10.0
				state["economy"]["reputation"] += 3
			else:
				for f in state["fields"]:
					if f["owned"] and not f["crop"].is_empty():
						f["crop"]["biomass"] = float(f["crop"]["biomass"])*0.96
	_start_story_root(kind,choice)
	state["events"]["history"].append({"id":kind,"choice":choice,"hour":state["time"]["total"]})
	var record: Dictionary = {"id":kind,"choice":choice,"hour":int(state["time"]["total"]),
		"cash_change":Data.money(_cash()-before_cash),"water_change":float(state["water"]["stored"])-before_water,
		"reputation_change":int(state["economy"]["reputation"])-before_reputation}
	state["decisions"]["history"].append(record)
	if state["decisions"]["history"].size() > 100:
		state["decisions"]["history"].pop_front()
	state["events"]["active"] = {}
	_log(outcome + " in the event: " + kind, "event")
	_xp(22)
	return _ok(outcome)

func talk(npc_id: String, topic: String) -> String:
	var info: Dictionary = content.get("npcs", {}).get(npc_id, {})
	if info.is_empty():
		return "No encuentro a ese vecino." if language == "es" else "I cannot find that neighbour."
	var npc_name: String = n(info)
	if topic == "relationship":
		var trust: int = npc_trust(npc_id)
		if language == "es":
			return npc_name + ": nivel de confianza " + str(trust) + "/10. Mis consejos son gratuitos; nuestras decisiones compartidas quedan en la memoria del valle."
		return npc_name + ": trust " + str(trust) + "/10. Advice is free; the choices we make together shape the valley."
	match topic:
		"weather":
			if language == "es":
				return npc_name + ": " + weather_text() + ". Mira la humedad de la tierra antes de regar; quizá la última lluvia haya sido suficiente."
			return npc_name + ": " + weather_text() + ". Check soil before you water; yesterday's rain may be enough."
		"soil":
			var f: Dictionary = field_of("plot1")
			var water: String = str(snappedf(float(f["soil"]["water"]),0.1))
			var nitrogen: String = str(snappedf(float(f["soil"]["n"]),0.1))
			if language == "es":
				return npc_name + ": La primera parcela tiene " + water + " mm de agua y " + nitrogen + " kg de nitrógeno. Cuida la estructura del suelo antes de ampliar."
			return npc_name + ": Your first field has " + water + " mm water and " + nitrogen + " kg nitrogen. Good soil keeps a farm alive."
		"pests":
			var biggest: String = "aphids"
			var amount: float = -1.0
			for f in state["fields"]:
				if not f["owned"]:
					continue
				for pest_id in PEST_IDS:
					if float(f["pests"][pest_id]) > amount:
						amount = float(f["pests"][pest_id])
						biggest = pest_id
			var localized: String = n(content["pests"][biggest])
			if language == "es":
				return npc_name + ": He observado mayor actividad de " + localized + " (" + str(snappedf(amount,0.1)) + "). Revisa la parcela antes de tratar; los insectos auxiliares pueden ayudar."
			return npc_name + ": The highest current pest activity is " + localized + " (" + str(snappedf(amount,0.1)) + "). Inspect before spraying; natural enemies may help."
		"market":
			if language == "es":
				return npc_name + ": El trigo se vende cerca de " + str(market_price("wheat")) + " €/kg. Los contratos pueden pagar más, pero exigen entregar toda la cantidad."
			return npc_name + ": Wheat sells near EUR " + str(market_price("wheat")) + " per kg. Contracts may pay more but require full delivery."
		"garden":
			return npc_name + (": El humedal retiene la lluvia, pero puede sufrir pudrición de raíz; las laderas rocosas se secan pronto. Explora antes de comprar." if language == "es" else ": Marsh soils retain rain but risk root rot, while rocky hills dry quickly. Explore before buying.")
		"wildlife":
			return npc_name + (": Algunas rutas tienen peligros ficticios de fauna. El equipo de campo reduce el riesgo en el juego. No es un consejo de seguridad real." if language == "es" else ": Some trails have fictional wildlife hazards. An outdoor kit lowers the game risk, not a real-world safety recommendation.")
		"favours":
			var friendship: String = str(state["neighbours"]["favours"].get(npc_id,0))
			return npc_name + (": Gracias por ayudar en el pueblo. Nuestra amistad tiene nivel " + friendship + "." if language == "es" else ": Thank you for helping our village. Our friendship level is " + friendship + ".")
	return npc_name + (": Bienvenido al valle. Siempre hay algo nuevo que aprender." if language == "es" else ": Welcome to the valley. There is something new to learn every season.")
