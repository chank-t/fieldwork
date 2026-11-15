extends SceneTree
## Godot 4.4+ --headless --path . --script res://tests/beyond_farm_smoke.gd
## Real engine tests. A few controlled day jumps are clearly marked test fixtures.
const FarmScript = preload("res://scripts/NativeFarm.gd")
const Beyond58 = preload("res://scripts/BeyondFarm.gd")
const Country54 = preload("res://scripts/LivingCountryside.gd")
const ValleyScript = preload("res://scripts/Overworld.gd")
const MainScene = preload("res://Main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS 5.8 ",label)
	else:
		failed += 1
		push_error("FAIL 5.8 " + label)

func _next_day_fixture(farm: Variant) -> void:
	# Preserve a consistent clock, without spawning random events in the test.
	var clock: Dictionary = farm.state["time"]
	var next_day: int = int(clock["day"]) + 1
	clock["day"] = next_day
	clock["total"] = (next_day - 1) * 24
	clock["hour"] = 8
	clock["season"] = int((next_day - 1) / FarmScript.SEASON_DAYS) % 4
	farm.state["wildlife"]["energy"] = 100.0

func _run() -> void:
	var farm58: Variant = FarmScript.new()
	farm58.new_game({"name":"Beyond Test","seed":58058,"language":"en"})
	_check(FarmScript.V58_SAVE_FILE == "user://fieldwork_native_5_8.json" and FarmScript.V57_SAVE_FILE != FarmScript.SAVE_FILE,"5.8 has its own protected save path")
	_check(Beyond58.PROJECTS.size() == 8 and Beyond58.PROFESSIONS.size() == 3,"Eight community projects and three professions")
	_check(Country54.SITES.size() == 8 and Country54.ACTIVITIES.size() == 8,"Two new scenic sites and two regional activities")
	_check(Country54.npc_region("elena",1,9) == "lake" and Country54.npc_region("omar",1,9) == "quarry","Village partners visit both new regions on their schedules")
	_check(Beyond58.valid(farm58.state["countryside54"]["beyond58"]),"Fresh project state validates")
	var initial58: String = farm58.export_text()
	_check(not bool(farm58.act("advanceProject58",{"regionId":"woods"}).get("ok",false)),"Cannot work in a region without travelling")
	_check(farm58.export_text() == initial58,"Rejected work leaves the entire save unchanged")
	_check(bool(farm58.act("chooseProfession58",{"profession":"pathfinder"}).get("ok",false)),"Can select Pathfinder profession")
	var profile58: Dictionary = farm58.state["countryside54"]["beyond58"]
	_check(str(profile58["profession"]) == "pathfinder","Profession saved in farm state")
	_check(not bool(farm58.act("chooseProfession58",{"profession":"naturalist"}).get("ok",false)),"Cannot retrain within twelve game days")
	var trust_before58: int = farm58.npc_trust("ines")
	var cash_before58: float = float(farm58.state["economy"]["cash"])
	_check(bool(farm58.act("advanceProject58",{"regionId":"village","approach":"protect"}).get("ok",false)),"First village chapter uses real resources")
	_check(int(profile58["chapters"].get("village",0)) == 1 and farm58.npc_trust("ines") > trust_before58,"First chapter persists and improves neighbour trust")
	_check(float(farm58.state["economy"]["cash"]) < cash_before58,"Expedition charges money")
	var before_repeat58: String = farm58.export_text()
	_check(not bool(farm58.act("advanceProject58",{"regionId":"village"}).get("ok",false)),"Only one chapter per region per day")
	_check(farm58.export_text() == before_repeat58,"Daily cooldown rolls back cleanly")
	_next_day_fixture(farm58)
	farm58.state["inventory"]["timber"] = 10.0 # Test inventory fixture.
	var old_timber58: float = farm58.stock("timber")
	_check(bool(farm58.act("advanceProject58",{"regionId":"village"}).get("ok",false)),"Second chapter delivers real materials")
	_check(farm58.stock("timber") < old_timber58 and int(profile58["chapters"]["village"]) == 2,"Construction materials are consumed once")
	_next_day_fixture(farm58)
	var rep_before58: int = int(farm58.state["economy"]["reputation"])
	var stock_before58: float = farm58.stock("feed")
	_check(bool(farm58.act("advanceProject58",{"regionId":"village","approach":"protect"}).get("ok",false)),"Third chapter completes regional project")
	_check(int(profile58["completed"]) == 1 and int(profile58["chapters"]["village"]) == 3,"Completed project counted once")
	_check(int(farm58.state["economy"]["reputation"]) > rep_before58 and farm58.stock("feed") > stock_before58,"Protect outcome grants reputation and inventory")
	var after_completed58: String = farm58.export_text()
	_check(not bool(farm58.act("advanceProject58",{"regionId":"village"}).get("ok",false)),"Completed project cannot be exploited for repeat rewards")
	_check(farm58.export_text() == after_completed58,"No duplicated resources on completed project")
	_check(bool(farm58.act("explore",{"regionId":"lake"}).get("ok",false)),"New lake region is reachable by travel")
	_check(bool(farm58.act("discoverSite54",{"siteId":"lake_jetty"}).get("ok",false)),"New lake scenic site can be discovered")
	farm58.state["wildlife"]["energy"] = 100.0
	_check(bool(farm58.act("countrysideActivity54",{"activityId":"lake_clean_up"}).get("ok",false)),"New lake activity uses real inventory")
	farm58.state["wildlife"]["energy"] = 100.0
	_check(bool(farm58.act("explore",{"regionId":"quarry"}).get("ok",false)),"New quarry region is reachable by travel")
	_check(bool(farm58.act("discoverSite54",{"siteId":"quarry_gate"}).get("ok",false)),"New quarry scenic site can be discovered")
	_check(Beyond58.valid(farm58.state["countryside54"]["beyond58"]),"5.8 chapter history and profession remain valid")
	var wire58: String = farm58.export_text()
	var loaded58: Variant = FarmScript.new()
	_check(bool(loaded58.load_text(wire58).get("ok",false)),"Protected 5.8 save round-trip loads")
	_check(loaded58.export_text() == wire58,"Save round-trip retains all expedition choices")
	var old_payload58: Dictionary = farm58.state.duplicate(true)
	old_payload58["countryside54"].erase("beyond58")
	var older_wire58: String = JSON.stringify({"format":"FW_NATIVE_5_4","payload":old_payload58,"sha256":farm58._canonical_json(old_payload58).sha256_text()})
	var old_save58: Variant = FarmScript.new()
	_check(bool(old_save58.load_text(older_wire58).get("ok",false)),"5.7-compatible schema-10 save is importable")
	_check(Beyond58.valid(old_save58.state["countryside54"]["beyond58"]) and old_save58.field_of("plot1") == farm58.field_of("plot1"),"Import fills only new progress and preserves plots")
	var corrupted58: Dictionary = farm58.state.duplicate(true)
	corrupted58["countryside54"]["beyond58"]["chapters"]["village"] = 99
	var corrupted_wire58: String = JSON.stringify({"format":"FW_NATIVE_5_4","payload":corrupted58,"sha256":farm58._canonical_json(corrupted58).sha256_text()})
	_check(not bool(loaded58.load_text(corrupted_wire58).get("ok",false)),"Invalid saved chapters rejected")
	var valley58: Control = ValleyScript.new()
	root.add_child(valley58)
	await process_frame
	valley58.size = Vector2(1366,768)
	valley58.set_farm(farm58)
	_check(valley58.LOCATIONS.size() == 8 and valley58.art.has("region_lake") and valley58.art.has("region_quarry"),"Valley loads eight destinations and two new original icons")
	valley58.queue_free()
	await process_frame
	var main58: Control = MainScene.instantiate()
	root.add_child(main58)
	await process_frame
	main58.farm.new_game({"name":"Beyond UI","seed":58059})
	main58.call("_show_game")
	await process_frame
	main58.call("_change_tab","Expeditions58")
	_check(main58.active_tab == "Expeditions58" and main58.right_body.get_child_count() > 4,"New regional projects UI accessible")
	main58.queue_free()
	print("FIELDWORK 5.8 GODOT TESTS: ",passed," passed, ",failed," failed")
	quit(0 if failed == 0 else 1)
