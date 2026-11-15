extends SceneTree
## Run with Godot 4.4+: godot --headless --path . --script res://tests/living_farm_57_smoke.gd
const FarmScript = preload("res://scripts/NativeFarm.gd")
const IsoScript = preload("res://scripts/IsometricWorld56.gd")
const ClassicScript = preload("res://scripts/World.gd")
const Living57 = preload("res://scripts/LivingFarm57.gd")
const MainScene = preload("res://Main.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS 5.7 ", label)
	else:
		failed += 1
		push_error("FAIL 5.7 " + label)

func _run() -> void:
	var farm57: Variant = FarmScript.new()
	farm57.new_game({"name":"Garden QA","seed":57091,"language":"en"})
	_check(FarmScript.SAVE_FILE != FarmScript.PREVIOUS_SAVE_FILE, "5.7 saves isolated from 5.6")
	_check(Living57.open_slots(farm57.state["decorations"]).size() == 24, "24 selectable garden positions")
	var machine_buy57: Dictionary = farm57.act("buyMachine", {"machineId":"cultivator"})
	_check(bool(machine_buy57.get("ok",false)), "Purchasing a machine uses existing economy")
	_check(farm57.state["life"]["machines"].has("cultivator"), "Machinery is stored in original game state")
	# Add materials as a deterministic test fixture, not through a gameplay cheat.
	farm57.state["inventory"]["timber"] = 20.0
	farm57.state["inventory"]["stone"] = 20.0
	var craft57: Dictionary = farm57.act("craftDecoration", {"decorationId":"bench","slot":0})
	_check(bool(craft57.get("ok",false)), "Garden Studio crafting uses original rules")
	var obj57: Dictionary = farm57.state["decorations"][0]
	var first_id57: String = str(obj57["id"])
	var premature57: Dictionary = farm57.act("relocateDecoration", {"decorationId":first_id57,"slot":1})
	_check(not bool(premature57.get("ok",false)), "Unfinished decorations cannot be relocated")
	var tick57: Dictionary = farm57.act("tick", {"hours":9})
	_check(bool(tick57.get("ok",false)), "Simulated construction time advances")
	_check(bool(farm57.state["decorations"][0]["completed"]), "Decoration completes before relocation")
	var before_cash57: float = float(farm57.state["economy"]["cash"])
	var before_energy57: float = float(farm57.state["wildlife"]["energy"])
	var move57: Dictionary = farm57.act("relocateDecoration", {"decorationId":first_id57,"slot":1})
	_check(bool(move57.get("ok",false)) and int(farm57.state["decorations"][0]["slot"]) == 1, "Relocation changes saved position")
	_check(is_equal_approx(float(farm57.state["economy"]["cash"]),before_cash57-Living57.MOVE_CASH), "Relocation charges correct price")
	_check(is_equal_approx(float(farm57.state["wildlife"]["energy"]),before_energy57-Living57.MOVE_ENERGY), "Relocation charges energy")
	var snapshot57: String = JSON.stringify(farm57.state)
	var blocked57: Dictionary = farm57.act("relocateDecoration", {"decorationId":first_id57,"slot":-1})
	_check(not bool(blocked57.get("ok",false)), "Out-of-range garden destination rejected")
	_check(JSON.stringify(farm57.state) == snapshot57, "Rejected relocation cannot mutate state")
	var second57: Dictionary = farm57.act("craftDecoration", {"decorationId":"bench","slot":3})
	_check(bool(second57.get("ok",false)), "Second decoration is created")
	var state_again57: String = JSON.stringify(farm57.state)
	var collision57: Dictionary = farm57.act("relocateDecoration", {"decorationId":first_id57,"slot":3})
	_check(not bool(collision57.get("ok",false)), "Occupied destination rejected")
	_check(JSON.stringify(farm57.state) == state_again57, "No resources lost on collision")
	_check(Living57.open_slots(farm57.state["decorations"]).size() == 22, "Open slot list reflects real decorations")
	for view_script57 in [IsoScript,ClassicScript]:
		var map57: Variant = view_script57.new()
		root.add_child(map57)
		await process_frame
		map57.size = Vector2(1366,768)
		map57.set_farm(farm57)
		map57.show_garden_slots57 = true
		var selected57: Array = []
		map57.garden_slot_chosen57.connect(func(index57: int): selected57.append(index57))
		var tap57: InputEventMouseButton = InputEventMouseButton.new()
		tap57.button_index = MOUSE_BUTTON_LEFT
		tap57.pressed = true
		var where57: Vector2 = Living57.garden_anchor(6)
		tap57.position = map57._at(where57.x,where57.y)
		map57._gui_input(tap57)
		_check(selected57.has(6), "Tap selects garden slot in " + str(view_script57))
		_check(map57.art.has("machine57_cultivator"), "New machinery asset is loaded")
		map57.queue_free()
		await process_frame
	var main57: Control = MainScene.instantiate()
	root.add_child(main57)
	await process_frame
	main57.farm.new_game({"name":"UI garden", "seed":57092})
	main57.call("_show_game")
	await process_frame
	main57.call("_change_tab", "GardenStudio57")
	_check(main57.active_tab == "GardenStudio57", "Garden Studio accessible in game")
	_check(bool(main57.world.show_garden_slots57), "Clickable garden markers visible on studio tab")
	main57.call("_picked_garden_slot57", 9)
	_check(main57.selected_garden_slot57 == 9, "Map selection updates garden panel")
	main57.queue_free()
	print("FIELDWORK 5.7 GODOT TESTS: ",passed," passed, ",failed," failed")
	quit(0 if failed == 0 else 1)
