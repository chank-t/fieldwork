extends SceneTree
## Engine-level smoke checks; run with Godot 4.4+ headless.
const Perf = preload("res://scripts/PerformanceAccessibility59.gd")
const Farm = preload("res://scripts/NativeFarm.gd")
const Classic = preload("res://scripts/World.gd")
const Iso = preload("res://scripts/IsometricWorld56.gd")
const Valley = preload("res://scripts/Overworld.gd")
const GameScene = preload("res://Main.tscn")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(valid: bool, caption: String) -> void:
	checks += 1
	if valid:
		print("PASS 5.9: ",caption)
	else:
		failures += 1
		push_error("FAIL 5.9: " + caption)

func _run() -> void:
	_check(Perf.normalize_preset("unknown") == "balanced", "Invalid quality value falls back to Balanced")
	_check(Perf.redraw_seconds("eco",false) > Perf.redraw_seconds("balanced",false), "Eco redraws less often")
	_check(Perf.redraw_seconds("quality",false) < Perf.redraw_seconds("balanced",false), "Quality redraws more often")
	_check(Perf.redraw_seconds("balanced",true) > Perf.redraw_seconds("eco",false), "Reduced motion avoids cosmetic repaints")
	_check(Perf.rain_particles("eco",115) < Perf.rain_particles("balanced",115), "Eco reduces particle count")
	_check(Perf.touch_target(0.7) >= 52.0 and Perf.touch_target(3.0) <= 70.0, "Touch targets stay usable")
	_check(Farm.V59_SAVE_FILE == "user://fieldwork_native_5_9.json" and Farm.V58_SAVE_FILE == "user://fieldwork_native_5_8.json", "5.8 saves are read-only migration sources")
	_check(Farm.V59_SLOT_DIRECTORY == "user://fieldwork_slots_59" and Farm.V58_SLOT_DIRECTORY == "user://fieldwork_slots_58", "5.9 manual saves remain a read-only import source")
	var farm: Variant = Farm.new()
	farm.new_game({"name":"Performance test", "seed":59059})
	var snapshot: String = farm.export_text()
	var classic: Control = Classic.new()
	root.add_child(classic)
	classic.size = Vector2(960,540)
	await process_frame
	classic.set_farm(farm)
	classic.performance_mode59 = "eco"
	classic.overlay_numbers59 = true
	_check(classic.performance_mode59 == "eco" and classic.overlay_numbers59, "Classic map receives 5.9 preferences")
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.index = 0
	tap.position = Vector2(80,80)
	tap.pressed = true
	classic._gui_input(tap)
	_check(classic.touch_points59.size() == 1, "Single touch tracked")
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(100,100)
	drag.relative = Vector2(20,20)
	classic._gui_input(drag)
	_check(classic.camera_offset.length() > 0.0, "Touch drag pans camera")
	tap.pressed = false
	classic._gui_input(tap)
	_check(classic.touch_points59.is_empty(), "Touch release clears pointer state")
	classic.queue_free()
	await process_frame
	var iso: Control = Iso.new()
	root.add_child(iso)
	iso.size = Vector2(1366,768)
	await process_frame
	iso.set_farm(farm)
	iso.performance_mode59 = "eco"
	iso.overlay_mode = "moisture"
	iso.overlay_numbers59 = true
	var position: Vector2 = Vector2(25.0,18.0)
	_check(iso._unat(iso._at(position.x,position.y)).distance_to(position) < 0.01, "Isometric click projection preserved")
	_check(iso.overlay_numbers59 and iso.performance_mode59 == "eco", "2.5D map accepts numeric overlays and quality preset")
	iso.queue_free()
	await process_frame
	var valley: Control = Valley.new()
	root.add_child(valley)
	await process_frame
	valley.performance_mode59 = "quality"
	valley.reduced_motion59 = true
	_check(valley.performance_mode59 == "quality" and valley.reduced_motion59, "Valley supports adaptive redraw and reduced motion")
	valley.queue_free()
	await process_frame
	var ui: Control = GameScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"name":"Performance UI test", "seed":59060})
	ui.call("_show_game")
	await process_frame
	ui.call("_set_performance59", "eco")
	_check(ui.world.performance_mode59 == "eco" and ui.valley_view.performance_mode59 == "eco", "Settings propagate to both maps")
	ui.call("_set_accessibility", true, "numbers")
	_check(ui.world.overlay_numbers59, "Accessible numeric overlays enabled")
	ui.call("_toggle_fps59",true)
	_check(ui.fps_label59 != null and ui.fps_label59.visible, "FPS HUD is optional")
	ui.call("_touch_direction59", Vector2.RIGHT, true)
	_check(ui.world.touchscreen_dir == Vector2.RIGHT, "Hold-to-walk sets movement")
	ui.call("_touch_direction59", Vector2.ZERO, false)
	_check(ui.world.touchscreen_dir == Vector2.ZERO, "Release stops walking")
	ui.queue_free()
	await process_frame
	_check(farm.export_text() == snapshot, "Presentation testing never changes simulation state")
	print("FIELDWORK 5.9 ENGINE CHECKS: ",checks-failures,"/",checks," passed")
	quit(0 if failures == 0 else 1)
