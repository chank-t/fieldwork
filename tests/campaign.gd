extends SceneTree

const Farm = preload("res://scripts/NativeFarm.gd")

var farm: Variant
var failures: Array[String] = []
var checks: int = 0
var resolved_events: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: " + description)

func act(kind: String, args: Dictionary = {}) -> bool:
	var result: Dictionary = farm.act(kind,args)
	if not bool(result.get("ok",false)):
		check(false,kind + " failed: " + str(result.get("error",result.get("message","unknown error"))))
		return false
	return true

func resolve_pending_events() -> bool:
	var attempts: int = 0
	while not farm.state["events"]["active"].is_empty() and attempts < 12:
		var resolved: bool = false
		for option in farm.event_options():
			var result: Dictionary = farm.act("eventChoice",{"choice":str(option["id"])})
			if bool(result.get("ok",false)):
				resolved_events += 1
				resolved = true
				break
		if not resolved:
			check(false,"Pending event has no affordable valid response: " + str(farm.state["events"]["active"].get("id","")))
			return false
		attempts += 1
	return farm.state["events"]["active"].is_empty()

func advance_hours(hours: int) -> bool:
	var target: int = int(farm.state["time"]["total"]) + hours
	var guard: int = 0
	while int(farm.state["time"]["total"]) < target and guard < hours + 100:
		if not resolve_pending_events():
			return false
		var before: int = int(farm.state["time"]["total"])
		var result: Dictionary = farm.act("tick",{"hours":mini(24,target-before)})
		if not bool(result.get("ok",false)):
			check(false,"Clock could not advance: " + str(result.get("error",result.get("message","unknown error"))))
			return false
		if int(farm.state["time"]["total"]) <= before:
			check(false,"Clock made no progress")
			return false
		if not resolve_pending_events():
			return false
		try_deliver_contracts()
		guard += 1
	return int(farm.state["time"]["total"]) >= target

func try_deliver_contracts() -> void:
	for contract in farm.state["market"]["contracts"].duplicate(true):
		var status: String = str(contract.get("status",""))
		if not ["open","active"].has(status) or farm.stock(str(contract["good"])) + 0.0001 < float(contract["kg"]):
			continue
		var contract_id: String = str(contract["id"])
		if status == "open" and not act("contractAccept",{"contractId":contract_id}):
			continue
		act("contractDeliver",{"contractId":contract_id})

func water_growing_fields() -> bool:
	for field in farm.state["fields"]:
		if not bool(field["owned"]) or field["crop"].is_empty() or float(field["soil"]["water"]) >= 35.0:
			continue
		if float(farm.state["water"]["stored"]) < 75.0:
			continue
		if not act("irrigate",{"fieldId":str(field["id"]),"mm":30.0}):
			return false
	return true

func grow_until_ready(field_ids: Array[String], max_hours: int = 240) -> bool:
	var elapsed: int = 0
	while elapsed <= max_hours:
		var all_ready: bool = true
		for field_id in field_ids:
			var crop: Dictionary = farm.field_of(field_id).get("crop",{})
			if crop.is_empty():
				check(false,"Expected a growing crop on " + field_id)
				return false
			if float(crop.get("development",0.0)) < 0.995:
				all_ready = false
		if all_ready:
			return true
		if not water_growing_fields() or not advance_hours(mini(24,max_hours-elapsed)):
			return false
		elapsed += 24
	return false

func harvest_and_sell_surplus(field_id: String, crop_id: String) -> bool:
	if not act("harvest",{"fieldId":field_id}):
		return false
	try_deliver_contracts()
	var surplus: float = farm.stock(crop_id) - 100.0
	if surplus > 5.0 and not act("sell",{"goodId":crop_id,"kg":surplus}):
		return false
	return true

func save_and_resume() -> bool:
	var saved: Dictionary = farm.save_file()
	if not bool(saved.get("ok",false)):
		check(false,"Campaign save failed: " + str(saved.get("error","unknown error")))
		return false
	var resumed: Variant = Farm.new()
	var loaded: Dictionary = resumed.load_file()
	if not bool(loaded.get("ok",false)):
		check(false,"Campaign resume failed: " + str(loaded.get("error","unknown error")))
		return false
	check(resumed.export_text() == farm.export_text(),"Resumed campaign preserves its complete state")
	farm = resumed
	return true

func run() -> void:
	farm = Farm.new()
	farm.new_game({"language":"en","mode":"story","difficulty":"relaxed","seed":6842017})
	check(farm._valid_state(farm.state),"New story campaign starts in a valid state")
	check(act("plant",{"fieldId":"plot1","cropId":"wheat"}),"First crop can be planted")
	if not grow_until_ready(["plot1"]):
		check(false,"First crop ripens within the expected season window")
		finish()
		return
	check(harvest_and_sell_surplus("plot1","wheat"),"First harvest can be stored and sold")
	check(float(farm.state["stats"]["harvest_kg"]) >= 150.0,"First harvest reaches the story goal")
	if not advance_hours(24):
		finish()
		return
	check(int(farm.state["story"]["chapter"]) >= 2,"First harvest advances the story")

	check(act("buyField",{"fieldId":"plot2"}),"Campaign can expand to a second field")
	for building in [{"id":"academy","slot":0},{"id":"coop","slot":1},{"id":"hutch","slot":2}]:
		check(act("build",{"buildingId":building["id"],"slot":building["slot"]}),"Construction starts: " + str(building["id"]))
	check(act("enrollCourse",{"courseId":"soil"}),"Campaign course can be enrolled")
	check(act("plant",{"fieldId":"plot1","cropId":"bean"}),"Crop rotation can be planted on the first field")
	check(act("plant",{"fieldId":"plot2","cropId":"wheat"}),"Second field can be planted")

	if not save_and_resume():
		finish()
		return
	check(grow_until_ready(["plot1","plot2"]),"Crops grow after resuming the saved campaign")
	check(harvest_and_sell_surplus("plot1","bean"),"Rotated bean harvest completes")
	check(harvest_and_sell_surplus("plot2","wheat"),"Second-field wheat harvest completes")
	if not advance_hours(24):
		finish()
		return
	check(int(farm.state["stats"]["buildings_completed"]) >= 3,"Construction finishes during the campaign")
	check(farm.state["player"]["courses"].has("soil"),"Course completes during the campaign")
	check(int(farm.state["story"]["chapter"]) >= 3,"Expansion and construction advance the story")

	var rotations: Array = [
		{"plot1":"potato","plot2":"barley"},
		{"plot1":"bean","plot2":"wheat"},
		{"plot1":"potato","plot2":"barley"},
		{"plot1":"bean","plot2":"wheat"},
		{"plot1":"potato","plot2":"barley"},
		{"plot1":"bean","plot2":"wheat"}
	]
	for rotation in rotations:
		if bool(farm.state["story"]["completed"]):
			break
		for field_id in ["plot1","plot2"]:
			check(act("plant",{"fieldId":field_id,"cropId":rotation[field_id]}),"Plant campaign rotation " + str(rotation[field_id]))
		if not grow_until_ready(["plot1","plot2"]):
			check(false,"Campaign rotation ripens before the seasonal limit")
			finish()
			return
		for field_id in ["plot1","plot2"]:
			check(harvest_and_sell_surplus(field_id,str(rotation[field_id])),"Harvest campaign rotation " + str(rotation[field_id]))
		if not advance_hours(24):
			finish()
			return

	check(farm.state["story"]["completed"],"Full story campaign reaches its ending")
	check(int(farm.state["story"]["chapter"]) == 4,"Campaign reaches its final progress stage")
	check(int(farm.state["stats"]["contracts_delivered"]) >= 1,"Campaign fulfills a market contract")
	check(int(farm.state["stats"]["buildings_completed"]) >= 3,"Campaign completes three buildings")
	check(int(farm.state["economy"]["reputation"]) >= 10,"Campaign reaches the ending reputation requirement")
	check(resolved_events > 0,"Campaign generates and resolves valley events")
	check(float(farm.state["economy"]["revenue"]) > 0.0 and float(farm.state["economy"]["costs"]) > 0.0,"Campaign exercises both sides of the farm economy")
	check(farm._valid_state(farm.state),"Completed campaign satisfies all save invariants")
	if save_and_resume():
		check(bool(farm.state["story"]["completed"]),"Completed campaign remains complete after resume")
		check(farm._valid_state(farm.state),"Resumed ending save remains valid")
	finish()

func finish() -> void:
	print("CAMPAIGN: day ",farm.state.get("time",{}).get("day",0),
		", chapter ",farm.state.get("story",{}).get("chapter",0),
		", harvest ",snappedf(float(farm.state.get("stats",{}).get("harvest_kg",0.0)),0.1)," kg",
		", contracts ",farm.state.get("stats",{}).get("contracts_delivered",0),
		", events ",resolved_events)
	print("RESULT: ",checks," checks, ",failures.size()," failures")
	for message in failures:
		print("FAILED: ",message)
	quit(0 if failures.is_empty() else 1)
