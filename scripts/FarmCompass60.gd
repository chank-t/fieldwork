extends RefCounted
## Fieldwork 6.0 - deterministic Farm Compass.
## Everything here is read-only. No RNG, transactions, mutations or save schema changes.

const PILLARS: Array = [
	{"id":"land","title":{"en":"Healthy land","es":"Tierras sanas"},"detail":{"en":"Expand carefully and protect your soil.","es":"Amplia con cuidado y protege la tierra."},"tab":"Ecology"},
	{"id":"harvest","title":{"en":"Harvest & trade","es":"Cosechas y ventas"},"detail":{"en":"Grow produce and build a reliable market.","es":"Produce alimentos y consolida tus ventas."},"tab":"Market"},
	{"id":"animals","title":{"en":"Animal welfare","es":"Bienestar animal"},"detail":{"en":"Care for a healthy and diverse herd.","es":"Cuida de una ganaderia sana y variada."},"tab":"Animals"},
	{"id":"production","title":{"en":"Working farm","es":"Finca productiva"},"detail":{"en":"Develop buildings, equipment and processing.","es":"Desarrolla edificios, maquinaria y elaboracion."},"tab":"Buildings"},
	{"id":"community","title":{"en":"Valley community","es":"Comunidad del valle"},"detail":{"en":"Build trust and complete neighbour stories.","es":"Gana confianza y completa historias vecinales."},"tab":"Community50"},
	{"id":"exploration","title":{"en":"Valley explorer","es":"Explorador del valle"},"detail":{"en":"Visit regions and restore local landmarks.","es":"Visita regiones y recupera lugares del valle."},"tab":"Expeditions58"}
]

static func label(item: Dictionary, language: String, key: String = "title") -> String:
	var words: Dictionary = item.get(key,{})
	return str(words.get(language,words.get("en","")))

static func _ratio(actual: float, target: float) -> float:
	return clampf(actual / maxf(1.0,target),0.0,1.0)

static func summary(farm: Variant) -> Dictionary:
	if farm == null or farm.state.is_empty():
		return {}
	var st: Dictionary = farm.state
	var plots: int = 0
	var dry_plots: int = 0
	var ready_plots: int = 0
	var fallow_plots: int = 0
	var pest_plots: int = 0
	var healthy_plots: int = 0
	var first_dry: String = ""
	var first_ready: String = ""
	var first_fallow: String = ""
	var first_pest: String = ""
	for f in st.get("fields",[]):
		if not bool(f.get("owned",false)):
			continue
		plots += 1
		var field_id: String = str(f.get("id",""))
		var soil: Dictionary = f.get("soil",{})
		var ratio: float = float(soil.get("water",0.0)) / maxf(1.0,float(soil.get("capacity",1.0)))
		if ratio < 0.25:
			dry_plots += 1
			if first_dry == "":
				first_dry = field_id
		if farm.soil_health(field_id) >= 0.80:
			healthy_plots += 1
		var crop: Dictionary = f.get("crop",{})
		if crop.is_empty():
			fallow_plots += 1
			if first_fallow == "":
				first_fallow = field_id
		elif float(crop.get("development",0.0)) >= 0.995:
			ready_plots += 1
			if first_ready == "":
				first_ready = field_id
		var worst: float = 0.0
		for count in f.get("pests",{}).values():
			worst = maxf(worst,float(count))
		if worst >= 15.0:
			pest_plots += 1
			if first_pest == "":
				first_pest = field_id
	var animal_species: int = 0
	var weak_animals: int = 0
	for animal in st.get("animals",[]):
		if int(animal.get("count",0)) <= 0:
			continue
		animal_species += 1
		if float(animal.get("health",1.0)) < 0.65 or float(animal.get("nutrition",1.0)) < 0.48:
			weak_animals += 1
	var completed_buildings: int = 0
	var building_jobs: int = 0
	for building in st.get("buildings",[]):
		if int(building.get("level",0)) >= 1:
			completed_buildings += 1
		if int(building.get("target",0)) > int(building.get("level",0)):
			building_jobs += 1
	var trusted_neighbours: int = 0
	for value in st.get("decisions",{}).get("relationships",{}).values():
		if int(value) >= 2:
			trusted_neighbours += 1
	var story_chapters: int = 0
	for value in st.get("world50",{}).get("npc_chapters",{}).values():
		story_chapters += maxi(0,int(value))
	var rural: Dictionary = st.get("countryside54",{})
	var chapters: int = 0
	for value in rural.get("beyond58",{}).get("chapters",{}).values():
		chapters += maxi(0,int(value))
	var storage_ratio: float = farm.stored() / maxf(1.0,farm.storage_capacity())
	return {
		"owned":plots,"healthy":healthy_plots,"dry":dry_plots,"ready":ready_plots,
		"fallow":fallow_plots,"pests":pest_plots,"first_dry":first_dry,"first_ready":first_ready,
		"first_pest":first_pest,"first_fallow":first_fallow,
		"animal_species":animal_species,"weak_animals":weak_animals,
		"completed_buildings":completed_buildings,"building_jobs":building_jobs,
		"machine_count":st.get("life",{}).get("machines",{}).size(),
		"trusted_neighbours":trusted_neighbours,"story_chapters":story_chapters,
		"known_regions":st.get("overworld",{}).get("known",[]).size(),"regional_chapters":chapters,
		"storage_ratio":storage_ratio,"energy":float(st.get("player",{}).get("energy",100.0)),
		"cash":float(st.get("economy",{}).get("cash",0.0)),"day":int(st.get("time",{}).get("day",1))
	}

static func pillars(farm: Variant) -> Array:
	var s: Dictionary = summary(farm)
	if s.is_empty():
		return []
	var stats: Dictionary = farm.state.get("stats",{})
	var results: Array = []
	for definition in PILLARS:
		var id: String = str(definition["id"])
		var score: float = 0.0
		match id:
			"land":
				score = (_ratio(float(s["owned"]),4.0) + _ratio(float(s["healthy"]),3.0))*0.5
			"harvest":
				score = (_ratio(float(stats.get("harvest_kg",0.0)),500.0) + _ratio(float(stats.get("sold_kg",0.0)),300.0))*0.5
			"animals":
				score = (_ratio(float(s["animal_species"]),2.0) + _ratio(float(s["animal_species"]-s["weak_animals"]),2.0))*0.5
			"production":
				score = (_ratio(float(s["completed_buildings"]),3.0) + _ratio(float(s["machine_count"]),1.0) + _ratio(float(stats.get("processed_kg",0.0)),100.0))/3.0
			"community":
				score = (_ratio(float(s["trusted_neighbours"]),3.0) + _ratio(float(s["story_chapters"]),5.0))*0.5
			"exploration":
				score = (_ratio(float(s["known_regions"]),5.0) + _ratio(float(s["regional_chapters"]),4.0))*0.5
		var entry: Dictionary = definition.duplicate(true)
		entry["progress"] = clampf(score,0.0,1.0)
		results.append(entry)
	return results

static func overall_progress(farm: Variant) -> float:
	var tracks: Array = pillars(farm)
	if tracks.is_empty():
		return 0.0
	var total: float = 0.0
	for track in tracks:
		total += float(track["progress"])
	return total / float(tracks.size())

static func farm_stage(progress: float, language: String) -> String:
	if progress >= 0.999:
		return "A valley landmark" if language != "es" else "Un referente del valle"
	if progress >= 0.65:
		return "Thriving farm" if language != "es" else "Finca prospera"
	if progress >= 0.30:
		return "Growing roots" if language != "es" else "Echando raices"
	return "A new beginning" if language != "es" else "Un nuevo comienzo"

static func priorities(farm: Variant, language: String) -> Array:
	var s: Dictionary = summary(farm)
	if s.is_empty():
		return []
	var tasks: Array = []
	if int(s["ready"]) > 0:
		tasks.append({"priority":0,"id":"harvest","title":{"en":"Harvest ready crops","es":"Recoge las cosechas maduras"},"detail":{"en":"Ripe fields are waiting for harvest.","es":"Hay parcelas maduras esperando la cosecha."},"tab":"Fields","field":s["first_ready"],"count":s["ready"]})
	if int(s["weak_animals"]) > 0:
		tasks.append({"priority":1,"id":"animals","title":{"en":"Check livestock welfare","es":"Revisa el bienestar del ganado"},"detail":{"en":"Some animals need care or better feeding.","es":"Algunos animales necesitan cuidados o alimento."},"tab":"Animals","count":s["weak_animals"]})
	if int(s["dry"]) > 0:
		tasks.append({"priority":2,"id":"water","title":{"en":"Inspect dry fields","es":"Inspecciona las parcelas secas"},"detail":{"en":"Review water needs before irrigating.","es":"Comprueba el agua necesaria antes de regar."},"tab":"Fields","field":s["first_dry"],"count":s["dry"]})
	if int(s["pests"]) > 0:
		tasks.append({"priority":3,"id":"pests","title":{"en":"Scout pest pressure","es":"Revisa la presion de plagas"},"detail":{"en":"Choose a treatment only after checking conditions.","es":"Elige tratamientos tras comprobar el cultivo."},"tab":"Ecology","field":s["first_pest"],"count":s["pests"]})
	if float(s["energy"]) < 24.0:
		tasks.append({"priority":4,"id":"rest","title":{"en":"Rest before working","es":"Descansa antes de trabajar"},"detail":{"en":"Low energy can limit farm actions.","es":"La energia baja limita las labores."},"tab":"Countryside54","count":0})
	if float(s["storage_ratio"]) > 0.88:
		tasks.append({"priority":5,"id":"storage","title":{"en":"Free up storage","es":"Libera espacio en el almacen"},"detail":{"en":"Sell or process produce before storage fills up.","es":"Vende o procesa productos antes de llenar el almacen."},"tab":"Market","count":0})
	if int(s["building_jobs"]) > 0:
		tasks.append({"priority":6,"id":"building","title":{"en":"Review construction","es":"Revisa las construcciones"},"detail":{"en":"Track buildings that are not yet finished.","es":"Consulta los edificios que aun no han terminado."},"tab":"Buildings","count":s["building_jobs"]})
	if int(s["fallow"]) > 0:
		tasks.append({"priority":7,"id":"plant","title":{"en":"Plan your next crop","es":"Planifica el siguiente cultivo"},"detail":{"en":"Choose a crop compatible with soil and plot type.","es":"Elige cultivos compatibles con el suelo y la parcela."},"tab":"Fields","field":s["first_fallow"],"count":s["fallow"]})
	if tasks.size() < 3:
		tasks.append({"priority":8,"id":"community","title":{"en":"Help your neighbours","es":"Ayuda a tus vecinos"},"detail":{"en":"Progress a regional project or neighbour story.","es":"Avanza en un proyecto regional o historia vecinal."},"tab":"Expeditions58","count":0})
	if tasks.size() < 3:
		tasks.append({"priority":9,"id":"planner","title":{"en":"Plan tomorrow","es":"Planifica manana"},"detail":{"en":"Compare the forecast, budget and expected workloads.","es":"Compara la prevision, los costes y el trabajo previsto."},"tab":"Planning","count":0})
	tasks.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["priority"]) < int(b["priority"]))
	return tasks.slice(0,mini(7,tasks.size()))
