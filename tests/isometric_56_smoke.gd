extends SceneTree
## 5.6 engine smoke test. Requires a real Godot 4.4+ executable.
## Run: godot --headless --path . --script res://tests/isometric_56_smoke.gd
const Isometric = preload("res://scripts/IsometricWorld56.gd")
const Classic = preload("res://scripts/World.gd")
const MainScene = preload("res://Main.tscn")
const FarmScript = preload("res://scripts/NativeFarm.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
		print("PASS 5.6: ", message)
	else:
		failed += 1
		push_error("FAIL 5.6: " + message)

func _run() -> void:
	var farm: Variant = FarmScript.new()
	farm.new_game({"name":"Isometric smoke", "seed":567823})
	var pristine: String = JSON.stringify(farm.state)
	var iso: Variant = Isometric.new()
	root.add_child(iso)
	await process_frame
	iso.set_farm(farm)
	iso.set_selected("plot7")
	for dimensions in [Vector2(1366,768), Vector2(1920,1080), Vector2(960,540), Vector2(390,844)]:
		iso.size = dimensions
		await process_frame
		for pos in [Vector2(1.0,2.0), Vector2(20.0,25.0), Vector2(48.5,33.0), Vector2(62.0,50.0)]:
			_check(iso._unat(iso._at(pos.x,pos.y)).distance_to(pos) < 0.002, "Inverse perspective " + str(dimensions) + " / " + str(pos))
		var corners: PackedVector2Array = iso._corners56(18.0,12.0,6.0,5.0)
		_check(corners.size() == 4 and corners[0].distance_to(corners[2]) > 15.0, "Projected plot polygon " + str(dimensions))
	iso.size = Vector2(1366,768)
	iso.zoom = 1.8
	iso.zoom_target = 1.8
	iso.camera_offset = Vector2(65,-35)
	iso.camera_target = iso.camera_offset
	_check(iso._unat(iso._at(30.0,14.0)).distance_to(Vector2(30.0,14.0)) < 0.002, "Inverse under zoom and pan")
	iso.zoom = 1.0
	iso.camera_offset = Vector2.ZERO
	iso.camera_target = Vector2.ZERO
	var plot_idx: int = 13
	var center: Vector2 = Vector2(16.6 + 8.55 * 0.5, 26.4 + 6.75 * 0.5)
	var selected: Array = []
	iso.selected_field.connect(func(fid: String): selected.append(fid))
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = iso._at(center.x,center.y)
	iso._gui_input(event)
	_check(selected.has("plot14"), "Click on isometric plot selects correct original plot")
	iso.overlay_mode = "moisture"
	iso.queue_redraw()
	await process_frame
	_check(JSON.stringify(farm.state) == pristine, "Rendering and selection never modify saved game state")
	iso.queue_free()
	await process_frame
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"name":"Perspective toggle test","seed":89423})
	ui.use_25d = true
	ui.call("_show_game")
	await process_frame
	_check(ui.world.get_script() == Isometric, "2.5D view is default")
	ui.call("_toggle_perspective56")
	await process_frame
	_check(ui.world.get_script() == Classic, "2D fallback view selectable")
	ui.call("_toggle_perspective56")
	await process_frame
	_check(ui.world.get_script() == Isometric, "Switching back to 2.5D")
	ui.queue_free()
	_check(FarmScript.SAVE_FILE != FarmScript.PREVIOUS_SAVE_FILE and FarmScript.V54_SAVE_FILE != FarmScript.SAVE_FILE, "Old campaigns protected in their old paths")
	print("FIELDWORK 5.6 ENGINE CHECKS: ",passed," PASSED, ",failed," FAILED")
	quit(0 if failed == 0 else 1)
