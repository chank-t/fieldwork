extends SceneTree
## Real Godot 4.4+ smoke checks for the 6.0 Farm Compass and save compatibility.
## All gameplay changes are test-local; no files are written to user://.
const Farm = preload("res://scripts/NativeFarm.gd")
const Compass = preload("res://scripts/FarmCompass60.gd")
const Iso = preload("res://scripts/IsometricWorld56.gd")
const MainScene = preload("res://Main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS 6.0: ",description)
	else:
		failed += 1
		push_error("FAIL 6.0: " + description)

func _run() -> void:
	_check(Farm.SAVE_FILE == "user://fieldwork_native_6_0.json", "6.0 uses its own primary save")
	_check(Farm.V59_SAVE_FILE == "user://fieldwork_native_5_9.json", "5.9 remains an import source")
	_check(Farm.SLOT_DIRECTORY == "user://fieldwork_slots_60" and Farm.V59_SLOT_DIRECTORY == "user://fieldwork_slots_59", "6.0 manual slots are isolated")
	var farm: Variant = Farm.new()
	farm.new_game({"name":"6.0 test", "farm":"Compass Hills", "seed":60060,"language":"es"})
	var before: String = farm.export_text()
	var initial: Dictionary = Compass.summary(farm)
	_check(int(initial.get("owned",0)) == 1 and int(initial.get("fallow",0)) == 1, "New farm is recognized as one fallow field")
	_check(Compass.pillars(farm).size() == 6 and Compass.overall_progress(farm) >= 0.0, "Six farm progression paths are available")
	_check(Compass.priorities(farm,"es").size() >= 1, "Contextual tasks are available in Spanish")
	_check(farm.export_text() == before, "Compass queries never mutate save or RNG")
	var field: Dictionary = farm.field_of("plot1")
	field["soil"]["water"] = 1.0
	field["pests"]["aphids"] = 30.0
	var tasks: Array = Compass.priorities(farm,"es")
	var has_water: bool = false
	var has_pest: bool = false
	for task in tasks:
		if str(task["id"]) == "water":
			has_water = str(task.get("field","")) == "plot1"
		if str(task["id"]) == "pests":
			has_pest = str(task.get("field","")) == "plot1"
	_check(has_water and has_pest, "Dry soil and pest alerts route to the correct field")
	var adjusted: String = farm.export_text()
	var copy: Variant = Farm.new()
	_check(bool(copy.load_text(adjusted).get("ok",false)), "6.0 save loads using the protected inherited schema")
	_check(copy.export_text() == adjusted, "6.0 round-trip does not alter existing gameplay data")
	var perspective: Control = Iso.new()
	root.add_child(perspective)
	perspective.size = Vector2(1000,600)
	await process_frame
	perspective.set_farm(farm)
	var selected: Vector2 = Vector2(21.2,17.3)
	_check(perspective._unat(perspective._at(selected.x,selected.y)).distance_to(selected)<0.1, "2.5D projection remains invertible")
	perspective.queue_free()
	await process_frame
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"name":"Compass UI", "seed":60061,"language":"en"})
	ui.call("_show_game")
	await process_frame
	ui.call("_change_tab","Compass60")
	_check(ui.active_tab == "Compass60" and ui.right_body.get_child_count() >= 10, "Farm Compass screen opens and displays goal widgets")
	ui.call("_change_tab","Farm")
	_check(ui.active_tab == "Farm", "Players can return to the main farm")
	ui.queue_free()
	await process_frame
	print("FIELDWORK 6.0 GODOT TESTS: ",passed," passed, ",failed," failed")
	quit(0 if failed == 0 else 1)
