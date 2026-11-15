extends SceneTree
## Execute with Godot 4.4+: godot --headless --path . --script res://tests/living_world_smoke.gd
## This script is deliberately separate from the static QA and must be run in Godot.
const Farm = preload("res://scripts/NativeFarm.gd")
const World = preload("res://scripts/World.gd")
const Visual = preload("res://scripts/WorldPresentation.gd")
const Interior = preload("res://scripts/Interior.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(yes: bool, title: String) -> void:
	if yes:
		passed += 1
		print("PASS ",title)
	else:
		failed += 1
		push_error("FAIL " + title)

func _test() -> void:
	_check(Visual.crop_stage(0.00) == 0,"Sown crop stage")
	_check(Visual.crop_stage(0.10) == 1,"Sprout crop stage")
	_check(Visual.crop_stage(0.36) == 2,"Young crop stage")
	_check(Visual.crop_stage(0.62) == 3,"Flowering crop stage")
	_check(Visual.crop_stage(1.00) == 4,"Mature crop stage")
	_check(Visual.crop_stage_text(0.1,true) == "Germinando","Spanish crop-stage text")
	_check(Visual.soil_visual({"water":15.0,"capacity":150.0}) == "dry","Dry soil appearance")
	_check(Visual.soil_visual({"water":140.0,"capacity":150.0}) == "wet","Waterlogged soil appearance")
	_check(Visual.dawn_dusk(23) == "night","Night lighting state")
	_check(Visual.dawn_dusk(7) == "dawn","Dawn lighting state")
	_check(Visual.animal_behavior({"condition":0.8},22,0,0.0) == "sleeping","Animal sleep routine")
	_check(Visual.animal_behavior({"condition":0.2},12,0,0.0) == "unwell","Animal welfare visual")
	var f: Variant = Farm.new()
	f.new_game({"name":"Avery","seed":42911,"language":"en"})
	var before: String = f.export_text()
	var world: Variant = World.new()
	world.size = Vector2(900,620)
	root.add_child(world)
	world.set_farm(f)
	world.set_selected("plot1")
	await process_frame
	await process_frame
	_check(f.export_text() == before,"Rendering consumes no simulation RNG or resources")
	_check(world.show_ambient_effects and world.show_growth_labels,"Visual options default enabled")
	world.show_ambient_effects = false
	world.queue_redraw()
	await process_frame
	_check(f.export_text() == before,"Turning weather visuals off leaves farm state unchanged")
	var picked: Array = []
	world.selected_field.connect(func(field_id):picked.append(str(field_id)))
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = world._at(float(World.GRID_X[0]) + 4.0, float(World.GRID_Y[0]) + 3.0)
	world._gui_input(click)
	_check(picked.size() == 1 and picked[0] == "plot1","Crop plot remains clickable")
	var inside: Variant = Interior.new()
	inside.size = Vector2(650,330)
	root.add_child(inside)
	inside.set_place("greenhouse",["Seedling beds","Ventilation","Watering can"],false)
	await process_frame
	var selected: Array = []
	inside.prop_selected.connect(func(name):selected.append(str(name)))
	var click_prop: InputEventMouseButton = InputEventMouseButton.new()
	click_prop.button_index = MOUSE_BUTTON_LEFT
	click_prop.pressed = true
	click_prop.position = inside._prop_pos(0)
	inside._gui_input(click_prop)
	_check(selected.size() == 1 and selected[0] == "Seedling beds","Building interior has working prop hotspots")
	_check(f.export_text() == before,"Interior exploration remains read-only")
	world.queue_free()
	inside.queue_free()
	print("LIVING WORLD 4.7: ",passed," PASS, ",failed," FAIL")
	quit(0 if failed == 0 else 1)
