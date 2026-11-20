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
	var nutrient_plots: int = 0
	var disease_plots: int = 0
	var first_nutrient: String = ""
	var first_disease: String = ""
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
		else:
			if float(crop.get("development",0.0)) >= 0.995:
				ready_plots += 1
				if first_ready == "":
					first_ready = field_id
			var nutrient_ratio: float = minf(1.0,minf(float(soil.get("n",0.0))/24.0,minf(float(soil.get("p",0.0))/10.0,float(soil.get("k",0.0))/45.0)))
			if nutrient_ratio < 0.80:
				nutrient_plots += 1
				if first_nutrient == "":
					first_nutrient = field_id
			if float(crop.get("disease_stress",0.0)) > 0.08:
				disease_plots += 1
				if first_disease == "":
					first_disease = field_id
		var worst: float = 0.0
		for count in f.get("pests",{}).values():
			worst = maxf(worst,float(count))
		if worst >= 15.0 or float(crop.get("pest_stress",0.0)) > 0.05:
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
		"fallow":fallow_plots,"pests":pest_plots,"nutrient":nutrient_plots,"disease":disease_plots,
		"first_dry":first_dry,"first_ready":first_ready,"first_pest":first_pest,
		"first_nutrient":first_nutrient,"first_disease":first_disease,"first_fallow":first_fallow,
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

static func _contract_priority(farm: Variant, language: String) -> Dictionary:
	var state: Dictionary = farm.state
	var current_hour: int = int(state["time"]["total"])
	var best: Dictionary = {}
	for contract in state.get("market",{}).get("contracts",[]):
		var status: String = str(contract.get("status",""))
		if not ["open","active"].has(status):
			continue
		var good: String = str(contract.get("good",""))
		var amount: float = maxf(0.1,float(contract.get("kg",0.0)))
		var available: float = float(farm.stock(good))
		var due_hours: int = maxi(0,int(contract.get("deadline",current_hour))-current_hour)
		var priority: int = -1
		var id: String = ""
		var title_en: String = ""
		var title_es: String = ""
		var detail_en: String = ""
		var detail_es: String = ""
		if status == "active" and available + 0.001 >= amount:
			priority = 1
			id = "contract_deliver"
			title_en = "Deliver a ready contract"
			title_es = "Entrega un contrato con existencias listas"
			detail_en = "Your stock covers this %.1f kg order, due in %d h for EUR %.0f. Deliver it or keep the produce for the market." % [amount,due_hours,float(contract.get("payout",0.0))]
			detail_es = "Tus existencias cubren este pedido de %.1f kg, que vence en %d h y paga %.0f EUR. Entrégalo o guarda el producto para el mercado." % [amount,due_hours,float(contract.get("payout",0.0))]
		elif status == "active" and due_hours <= 48:
			var missing: float = maxf(0.0,amount-available)
			var deposit: float = float(contract.get("deposit",0.0))
			priority = 4
			id = "contract_deadline"
			title_en = "Contract deadline is close"
			title_es = "El contrato vence pronto"
			detail_en = "%.1f kg are still needed with %d h left; missing the deadline loses the EUR %.0f deposit and 3 reputation." % [missing,due_hours,deposit]
			detail_es = "Faltan %.1f kg y quedan %d h; si vence, pierdes %.0f EUR del depósito y 3 puntos de reputación." % [missing,due_hours,deposit]
		elif status == "open" and available + 0.001 >= amount:
			var contract_rate: float = float(contract.get("payout",0.0))/amount
			var market_rate: float = float(farm.market_price(good))
			if contract_rate > market_rate * 1.05:
				var deposit: float = float(contract.get("deposit",0.0))
				priority = 12
				id = "contract_offer"
				title_en = "Compare a premium contract"
				title_es = "Compara un contrato prémium"
				detail_en = "Pays EUR %.2f/kg versus EUR %.2f/kg at market; accepting puts the EUR %.0f deposit at risk until delivery." % [contract_rate,market_rate,deposit]
				detail_es = "Paga %.2f EUR/kg frente a %.2f EUR/kg en el mercado; al aceptarlo arriesgas %.0f EUR de depósito hasta entregarlo." % [contract_rate,market_rate,deposit]
		if id != "" and (best.is_empty() or priority < int(best["priority"])):
			best = {"priority":priority,"id":id,"title":{"en":title_en,"es":title_es},"detail":{"en":detail_en,"es":detail_es},"tab":"Market","contract":str(contract.get("id","")),"count":1}
	return best

static func priorities(farm: Variant, language: String) -> Array:
	var s: Dictionary = summary(farm)
	if s.is_empty():
		return []
	var tasks: Array = []
	var contract_task: Dictionary = _contract_priority(farm,language)
	if farm.season_goal_selection_open():
		tasks.append({"priority":2,"id":"season_goal","title":{"en":"Choose a seasonal objective","es":"Elige un objetivo estacional"},"detail":{"en":"Pick one of three optional goals by day 3; it is locked for the season and targets scale with your farm.","es":"Elige una de las tres metas opcionales antes del día 4; queda fijada toda la estación y se ajusta al tamaño de la finca."},"tab":"Festivals50","count":0})
	if int(s["ready"]) > 0:
		tasks.append({"priority":0,"id":"harvest","title":{"en":"Harvest ready crops","es":"Recoge las cosechas maduras"},"detail":{"en":"Ripe fields are waiting for harvest.","es":"Hay parcelas maduras esperando la cosecha."},"tab":"Fields","field":s["first_ready"],"count":s["ready"]})
	if not contract_task.is_empty() and int(contract_task["priority"]) <= 1:
		tasks.append(contract_task)
	if int(s["weak_animals"]) > 0:
		tasks.append({"priority":2,"id":"animals","title":{"en":"Check livestock welfare","es":"Revisa el bienestar del ganado"},"detail":{"en":"Some animals need care or better feeding.","es":"Algunos animales necesitan cuidados o alimento."},"tab":"Animals","count":s["weak_animals"]})
	if int(s["dry"]) > 0:
		var forecast: Array = farm.farm_forecast()
		var rain_chance: int = int(forecast[0].get("rain_percent",0)) if not forecast.is_empty() else 0
		var water_detail_en: String
		var water_detail_es: String
		if rain_chance >= 65:
			water_detail_en = "Rain chance is %d%% tomorrow; weigh waiting against the crop's current stress." % rain_chance
			water_detail_es = "Hay un %d%% de probabilidad de lluvia mañana; sopesa esperar frente al estrés actual del cultivo." % rain_chance
		elif rain_chance <= 35:
			water_detail_en = "Rain chance is only %d%% tomorrow; check crop stress before using reservoir water." % rain_chance
			water_detail_es = "Solo hay un %d%% de probabilidad de lluvia mañana; comprueba el cultivo antes de gastar agua." % rain_chance
		else:
			water_detail_en = "Rain chance is %d%% tomorrow; inspect crop stress before deciding when to irrigate." % rain_chance
			water_detail_es = "Hay un %d%% de probabilidad de lluvia mañana; revisa el cultivo antes de decidir cuándo regar." % rain_chance
		tasks.append({"priority":3,"id":"water","title":{"en":"Inspect dry fields","es":"Inspecciona las parcelas secas"},"detail":{"en":water_detail_en,"es":water_detail_es},"tab":"Fields","field":s["first_dry"],"count":s["dry"]})
	if not contract_task.is_empty() and int(contract_task["priority"]) == 4:
		tasks.append(contract_task)
	if int(s["pests"]) > 0:
		tasks.append({"priority":5,"id":"pests","title":{"en":"Scout pest pressure","es":"Revisa la presion de plagas"},"detail":{"en":"Choose a treatment only after checking conditions.","es":"Elige tratamientos tras comprobar el cultivo."},"tab":"Ecology","field":s["first_pest"],"count":s["pests"]})
	if int(s["nutrient"]) > 0:
		tasks.append({"priority":6,"id":"soil","title":{"en":"Review crop nutrition","es":"Revisa los nutrientes del cultivo"},"detail":{"en":"Low N/P/K can reduce crop growth; compare fertilizer, compost and rotation.","es":"Un nivel bajo de N/P/K reduce el crecimiento; compara fertilizantes, compost y rotación."},"tab":"Fields","field":s["first_nutrient"],"count":s["nutrient"]})
	if int(s["disease"]) > 0:
		tasks.append({"priority":7,"id":"disease","title":{"en":"Inspect crop disease","es":"Inspecciona las enfermedades"},"detail":{"en":"Check affected fields and compare treatment with current humidity and soil moisture.","es":"Revisa las parcelas afectadas y compara el tratamiento con la humedad ambiental y del suelo."},"tab":"Ecology","field":s["first_disease"],"count":s["disease"]})
	if float(s["energy"]) < 24.0:
		tasks.append({"priority":8,"id":"rest","title":{"en":"Rest before working","es":"Descansa antes de trabajar"},"detail":{"en":"Low energy can limit farm actions.","es":"La energia baja limita las labores."},"tab":"Countryside54","count":0})
	if float(s["storage_ratio"]) > 0.88:
		tasks.append({"priority":9,"id":"storage","title":{"en":"Free up storage","es":"Libera espacio en el almacen"},"detail":{"en":"Sell or process produce before storage fills up.","es":"Vende o procesa productos antes de llenar el almacen."},"tab":"Market","count":0})
	if int(s["building_jobs"]) > 0:
		tasks.append({"priority":10,"id":"building","title":{"en":"Review construction","es":"Revisa las construcciones"},"detail":{"en":"Track buildings that are not yet finished.","es":"Consulta los edificios que aun no han terminado."},"tab":"Buildings","count":s["building_jobs"]})
	if int(s["fallow"]) > 0:
		tasks.append({"priority":11,"id":"plant","title":{"en":"Plan your next crop","es":"Planifica el siguiente cultivo"},"detail":{"en":"Choose a crop compatible with soil and plot type.","es":"Elige cultivos compatibles con el suelo y la parcela."},"tab":"Fields","field":s["first_fallow"],"count":s["fallow"]})
	if not contract_task.is_empty() and int(contract_task["priority"]) == 12:
		tasks.append(contract_task)
	if tasks.size() < 3:
		tasks.append({"priority":13,"id":"community","title":{"en":"Help your neighbours","es":"Ayuda a tus vecinos"},"detail":{"en":"Progress a regional project or neighbour story.","es":"Avanza en un proyecto regional o historia vecinal."},"tab":"Expeditions58","count":0})
	if tasks.size() < 3:
		tasks.append({"priority":14,"id":"planner","title":{"en":"Plan tomorrow","es":"Planifica manana"},"detail":{"en":"Compare the forecast, budget and expected workloads.","es":"Compara la prevision, los costes y el trabajo previsto."},"tab":"Planning","count":0})
	tasks.sort_custom(func(a: Dictionary, b: Dictionary): return int(a["priority"]) < int(b["priority"]))
	return tasks.slice(0,mini(8,tasks.size()))
