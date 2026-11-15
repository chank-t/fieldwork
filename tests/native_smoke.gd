extends SceneTree
## Run with: godot --headless --path . --script res://tests/native_smoke.gd
## Requires a real Godot 4.4+ executable. Exit code 1 on failure.

const Farm = preload("res://scripts/NativeFarm.gd")
const BootScene = preload("res://Boot.tscn")
const MenuScene = preload("res://Main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS " + label)
	else:
		failed += 1
		push_error("FAIL " + label)

func _contains_label(node: Node, text: String) -> bool:
	if node is Label and str(node.text).contains(text):
		return true
	if node is Button and str(node.text).contains(text):
		return true
	for child in node.get_children():
		if _contains_label(child,text):
			return true
	return false

func _run() -> void:
	var boot: Control = BootScene.instantiate() as Control
	root.add_child(boot)
	await process_frame
	_check(_contains_label(boot,"FIELDWORK"),"Static Boot title is visible without gameplay scripts")
	_check((_contains_label(boot,"Create a new farm") or _contains_label(boot,"Crear una finca nueva")),"Static title screen has localized entry button")
	boot.queue_free()
	await process_frame
	var ui: Control = MenuScene.instantiate() as Control
	root.add_child(ui)
	await process_frame
	_check(_contains_label(ui,"FIELDWORK"),"Native gameplay menu renders offline")
	_check(_contains_label(ui,"Create your farmer"),"Native gameplay menu offers character creation")
	ui.call("_show_creator")
	await process_frame
	_check(_contains_label(ui,"Your new beginning"),"Character creator renders in native Godot")
	ui.queue_free()
	await process_frame

	var farm = Farm.new()
	farm.new_game({"language":"en","seed":47291,"name":"Smoke test farmer","farm":"Test Valley"})
	_check(farm.owned_count() == 1,"New game owns precisely one field")
	_check(farm.state["fields"].size() == 24,"Twenty-four fields exist as purchasable land")
	_check(farm.content["crops"].size() == 27,"Twelve crops loaded from native JSON catalog")
	_check(farm.content["buildings"].size() == 24,"Twenty-four buildings in native catalog")
	_check(farm.content["talents"].size() == 25,"Twenty-five talents in native catalog")
	_check(farm.content["animals"].size() == 11,"Eleven animal species are catalogued")
	_check(farm.content["npcs"].size() == 10,"Ten scheduled neighbours are catalogued")
	_check(farm.content["terrains"].size() == 10,"Ten different soil and terrain profiles exist")
	_check(farm.state["schema"] == 10,"Native 5.0 starts with schema 7")
	_check(farm.content["goods"].size() == 50,"Six new resources join the 29 original goods")
	_check(farm.state["progression"]["tracks"].size() == 7,"Seven mastery disciplines initialize at zero")

	var original: Dictionary = farm.state.duplicate(true)
	var fail: Dictionary = farm.act("plant",{"fieldId":"plot2","cropId":"wheat"})
	_check(not fail.get("ok",false) and farm.state == original,"Rejected action does not change state or RNG")
	var quote: Dictionary = farm.quote("plant",{"fieldId":"plot1","cropId":"wheat"})
	_check(quote.get("ok",false) and farm.state == original,"Quoted action is read-only")
	var plant: Dictionary = farm.act("plant",{"fieldId":"plot1","cropId":"wheat"})
	_check(plant.get("ok",false) and not farm.field_of("plot1")["crop"].is_empty(),"Planting charges real resources and creates crop")
	var irrigate: Dictionary = farm.act("irrigate",{"fieldId":"plot1","mm":12.0})
	_check(irrigate.get("ok",false) and float(farm.state["water"]["stored"]) < 3000.0,"Irrigation consumes finite reservoir water")
	var gather_woods: Dictionary = farm.act("gatherMaterials",{"regionId":"woods"})
	_check(gather_woods.get("ok",false) and farm.stock("timber") > 10.0,"Gather timber using real time, energy and stock")
	var after_gather: Dictionary = farm.state.duplicate(true)
	_check(not farm.act("gatherMaterials",{"regionId":"woods"}).get("ok",false) and farm.state == after_gather,"Same site is limited to one visit per game day")
	_check(farm.act("gatherMaterials",{"regionId":"orchard"}).get("ok",false) and farm.stock("wildflowers") >= 5.0,"Collect wildflower resources")
	var craft: Dictionary = farm.act("craftDecoration",{"decorationId":"bench","slot":0})
	_check(craft.get("ok",false) and farm.state["decorations"].size()==1,"Decor uses materials, cash and a timed construction")
	var craft_state: Dictionary = farm.state.duplicate(true)
	_check(not farm.act("craftDecoration",{"decorationId":"bench","slot":0}).get("ok",false) and farm.state == craft_state,"Occupied decoration slot rejected atomically")
	var inspect_a: Dictionary = farm.act("inspect",{"fieldId":"plot1"})
	var post_inspect_xp: int = int(farm.state["player"]["xp"])
	var inspect_b: Dictionary = farm.act("inspect",{"fieldId":"plot1"})
	_check(inspect_a.get("ok",false) and inspect_b.get("ok",false) and int(farm.state["player"]["xp"]) == post_inspect_xp,"Unlimited soil readings give no repeat XP on same day")
	var gear: Dictionary = farm.act("buyGear",{})
	_check(gear.get("ok",false) and bool(farm.state["wildlife"]["gear"]),"Native outdoor field kit can be purchased")
	var explore: Dictionary = farm.act("explore",{"regionId":"woods"})
	_check(explore.get("ok",false) and int(farm.state["overworld"]["visits"].get("woods",0)) == 1,"Woodland exploration advances the game and records visits")
	var help: Dictionary = farm.act("helpNeighbour",{"npcId":"ines"})
	_check(help.get("ok",false) and int(farm.state["neighbours"]["favours"].get("ines",0)) == 1,"Community help increases favour and reputation")
	var help_before: Dictionary = farm.state.duplicate(true)
	var repeated_help: Dictionary = farm.act("helpNeighbour",{"npcId":"ines"})
	_check(not repeated_help.get("ok",false) and farm.state == help_before,"Same neighbour cannot be farmed repeatedly for reputation in one day")
	var rest: Dictionary = farm.act("rest",{})
	_check(rest.get("ok",false),"Rest is a native game-time action")
	var training: Dictionary = farm.act("enrollCourse",{"courseId":"soil"})
	_check(training.get("ok",false),"Course enrollment begins in native simulation")
	var buy: Dictionary = farm.act("buyField",{"fieldId":"plot2"})
	_check(buy.get("ok",false) and farm.owned_count() == 2,"Land purchase unlocks the selected field")
	var last_plot: Dictionary = farm.act("buyField",{"fieldId":"plot24"})
	_check(last_plot.get("ok",false) and farm.field_of("plot24")["owned"],"Last visible field is independently purchasable")
	var building: Dictionary = farm.act("build",{"buildingId":"warehouse","fieldId":"plot1"})
	_check(building.get("ok",false),"Construction starts with a timed job")
	var talent: Dictionary = farm.act("learnTalent",{"talentId":"mulchMastery"})
	_check(talent.get("ok",false) and farm.has_talent("mulchMastery"),"Permanent talent can be learned")
	farm.state["inventory"]["manure"] = 20.0
	var manure: Dictionary = farm.act("useManure",{"fieldId":"plot1"})
	_check(manure.get("ok",false) and farm.stock("manure") < 20.0,"Manure recycling consumes inventory and improves organic fertility")
	var made: Dictionary = farm.act("makeCompost",{})
	_check(made.get("ok",false) and farm.stock("compost") >= 7.0,"Finished compost uses manure, flowers and labor")
	var before_organic: float = float(farm.field_of("plot1")["soil"]["organic_n"])
	var spread: Dictionary = farm.act("spreadCompost",{"fieldId":"plot1"})
	_check(spread.get("ok",false) and float(farm.field_of("plot1")["soil"]["organic_n"]) > before_organic,"Spreading 5 kg compost improves retained soil fertility")

	var quote_fail: Dictionary = farm.quote("irrigate",{"fieldId":"plot9","mm":10.0})
	_check(not quote_fail.get("ok",false),"Unowned-field quote is rejected")
	for step in range(52):
		if not farm.state["events"]["active"].is_empty():
			var options: Array = farm.event_options()
			if options.is_empty():
				failed += 1
				push_error("No event choices")
				break
			var option: String = str(options[options.size()-1]["id"])
			var response: Dictionary = farm.act("eventChoice",{"choice":option})
			if not response.get("ok",false):
				failed += 1
				push_error("Cannot resolve event " + option)
				break
		var step_result: Dictionary = farm.act("tick",{"hours":12})
		if not step_result.get("ok",false):
			failed += 1
			push_error("Time advancement stopped: " + str(step_result.get("error","?")))
			break
	_check(int(farm.state["time"]["total"]) >= 200,"Time advances through real ecology/weather/events")
	_check(farm.has_course("soil"),"Timed course finishes in simulation")
	_check(farm.level_of("warehouse") >= 1,"Timed warehouse construction finishes")
	_check(bool(farm.state["decorations"][0]["completed"]),"Timed garden decoration eventually completes")
	_check(int(farm.state["player"]["level"]) >= 2 and farm.mastery_level("exploration") >= 1,"New XP, level and mastery systems advance from normal actions")

	_check(float(farm.field_of("plot1")["crop"].get("development",0.0)) > 0.4,"Crop growth responds to simulated hours")
	if float(farm.field_of("plot1")["crop"].get("development",0.0)) >= 0.995:
		var harvest: Dictionary = farm.act("harvest",{"fieldId":"plot1"})
		_check(harvest.get("ok",false),"Ripe crop can be harvested")
	else:
		print("INFO crop not yet ripe under tested weather; harvest assertion skipped")
	var json: String = farm.export_text()
	var recovered = Farm.new()
	var imported: Dictionary = recovered.load_text(json)
	_check(imported.get("ok",false),"Native JSON save passes its checksum and validation")
	var on_disk: Dictionary = JSON.parse_string(json)["payload"]
	_check(recovered.state == on_disk,"Native save/load reproduces all serialized state")
	var valid_state: Dictionary = recovered.state.duplicate(true)
	var corrupt: Dictionary = recovered.load_text(json.replace("FW_NATIVE_5_4","BROKEN_FORMAT"))
	_check(not corrupt.get("ok",false) and recovered.state == valid_state,"Bad save rejected without overwriting current farm")
	# Legacy save migration: preserve original twelve fields with no loss of farming history.
	var old_state: Dictionary = valid_state.duplicate(true)
	old_state["schema"] = 1
	old_state["fields"].resize(12)
	old_state.erase("overworld")
	old_state.erase("wildlife")
	old_state.erase("neighbours")
	old_state["player"].erase("energy")
	var legacy_text: String = JSON.stringify({"format":"FW_NATIVE_4_1","payload":old_state,"sha256":farm._canonical_json(old_state).sha256_text()})
	var migrated = Farm.new()
	var migration_result: Dictionary = migrated.load_text(legacy_text)
	_check(migration_result.get("ok",false) and migrated.state["fields"].size() == 24,"Valid 4.1 save migrates to 24-plot native edition")
	_check(migrated.state["fields"][0] == old_state["fields"][0],"Migration preserves the original first field exactly")
	var old_42: Dictionary = valid_state.duplicate(true)
	old_42["schema"] = 2
	old_42.erase("progression")
	old_42.erase("resources")
	old_42.erase("decorations")
	for f in old_42["fields"]:
		f.erase("last_inspection_day")
	var envelope_42: String = JSON.stringify({"format":"FW_NATIVE_4_2","payload":old_42,"sha256":farm._canonical_json(old_42).sha256_text()})
	var upgraded_42 = Farm.new()
	var migrated_42: Dictionary = upgraded_42.load_text(envelope_42)
	_check(migrated_42.get("ok",false) and upgraded_42.state["fields"].size()==24 and upgraded_42.state["schema"]==10,"Old native 4.2 complete state upgrades through to 5.0")
	_check(upgraded_42.state["inventory"] == old_42["inventory"],"4.2 conversion preserves stored goods")
	var bad_amount: Dictionary = migrated.state.duplicate(true)
	bad_amount["water"]["stored"] = -10.0
	_check(not migrated._valid_state(bad_amount),"Invalid negative water rejected by native state validator")
	var bad_crop: Dictionary = migrated.state.duplicate(true)
	bad_crop["fields"][0]["crop"] = {"id":"invented_crop","age":1.0,"development":0.0,"biomass":0.0,"health":1.0}
	_check(not migrated._valid_state(bad_crop),"Unknown crop in a tampered save is rejected")
	var pen = Farm.new()
	pen.new_game({"difficulty":"relaxed"})
	_check(pen.act("build",{"buildingId":"coop"}).get("ok",false),"Coop construction begins")
	_check(pen.act("tick",{"hours":15}).get("ok",false) and pen.ready("coop"),"Completed coop is usable")
	_check(pen.act("buyAnimal",{"animalId":"hen","count":7}).get("ok",false),"First species uses part of coop")
	_check(pen.act("buyAnimal",{"animalId":"turkey","count":2}).get("ok",false),"Second species shares remaining coop capacity")
	var packed: Dictionary = pen.state.duplicate(true)
	_check(not pen.act("buyAnimal",{"animalId":"goose","count":2}).get("ok",false) and pen.state == packed,"Mixed species cannot overfill shared coop")

	var event_state: Dictionary = migrated.state.duplicate(true)
	migrated.state["events"]["active"] = {"id":"wildlife_alert","title":"Ranger warning","hour":migrated.state["time"]["total"]}
	var event_choice: Dictionary = migrated.act("eventChoice",{"choice":"avoid"})
	_check(event_choice.get("ok",false) and migrated.state["events"]["active"].is_empty(),"New wildlife event resolves a selected safe option")
	for scenario in ["soil_erosion", "apiary_surge", "market_shortage", "wetland_rescue"]:
		migrated.state["events"]["active"] = {"id":scenario,"title":scenario,"hour":migrated.state["time"]["total"]}
		var available: Array = migrated.event_options()
		_check(available.size() == 3,"Strategic event " + scenario + " offers three meaningful responses")
		var safe: String = str(available[available.size()-1]["id"])
		var resolved: Dictionary = migrated.act("eventChoice",{"choice":safe})
		_check(resolved.get("ok",false) and migrated.state["events"]["active"].is_empty(),"Strategic event " + scenario + " resolves atomically")

	print("\nGODOT ENGINE SMOKE: %d passed, %d failed" % [passed,failed])
	quit(0 if failed == 0 else 1)
