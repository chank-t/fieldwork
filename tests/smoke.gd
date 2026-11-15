extends SceneTree
## Integration tests: native transactions, save compatibility, real 3D picking,
## every management screen, touch layouts, presets, interiors and hidden views.
## Run in an isolated XDG_DATA_HOME: this test deliberately exercises saves.
const Farm = preload("res://scripts/NativeFarm.gd")
const MainScene = preload("res://Main.tscn")
const Fixtures = preload("res://tests/capture.gd")
const Models = preload("res://scripts/three_d/Models.gd")
const Data = preload("res://scripts/NativeData.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		push_error("FAIL: "+description)

func frames(count: int = 3) -> void:
	for i in range(count): await process_frame

func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	var farm := Farm.new()
	farm.new_game({"language":"es","seed":4567})
	check(farm.state["fields"].size() == 24,"24 plots retained")
	check(farm.owned_count() == 1,"Original starting economy retained")
	check(farm.act("plant",{"fieldId":"plot1","cropId":"wheat"}).get("ok",false),"Plant through native transactions")
	check(farm.act("irrigate",{"fieldId":"plot1","mm":15}).get("ok",false),"Water through native transactions")
	var saved: String = farm.export_text()
	var clone := Farm.new()
	check(clone.load_text(saved).get("ok",false),"Original checksummed save envelope loads")
	check(clone.export_text() == saved,"Save roundtrip preserves all state")
	check(not clone.load_text(saved.replace("FW_NATIVE_5_4","invalid")).get("ok",false),"Invalid save rejected")
	check(farm.save_file().get("ok",false),"Protected local save works")
	check(clone.load_file().get("ok",false),"Continue saved farm works")
	check(clone.state.get("rng",-1) == farm.state["rng"],"Save preserves simulation RNG")
	for value in [1,1.0,-72.0]: check(Data.is_json_integer(value),"Integral JSON number accepted: "+str(value))
	for value in [1.5,"1",true,null,INF,NAN]: check(not Data.is_json_integer(value),"Invalid integer rejected: "+str(value))
	var invalid: Dictionary = farm.state.duplicate(true)
	invalid["decisions"]["last_invitation_hour"] = 0.5
	check(not farm._valid_state(invalid),"Fractional save counters rejected")
	for i in range(24):
		var a: Dictionary = farm.act("tick",{"hours":1})
		var b: Dictionary = clone.act("tick",{"hours":1})
		check(a.get("ok",false) and b.get("ok",false),"Simulation hour after load "+str(i))
	check(clone.export_text() == farm.export_text(),"Loaded simulation stays deterministic for 24 hours")
	# A failed action must roll back the entire transaction.
	var before: String = farm.export_text()
	check(not farm.act("plant",{"fieldId":"plot2","cropId":"wheat"}).get("ok",false),"Cannot plant unowned land")
	check(farm.export_text() == before,"Failed transaction is atomic")
	var app: Control = MainScene.instantiate()
	root.add_child(app)
	app.language = "es"
	app.ambient_enabled = false
	app.farm = farm
	app._show_game()
	await frames(6)
	var view: Control = app.world
	check(view.viewport_3d.own_world_3d,"Farm is a separate real 3D world")
	check(view.plot_roots.size() == 24,"All plot meshes built")
	var state_before: String = farm.export_text()
	view._sync()
	view.change_zoom(0.3)
	view.focus_field("plot1")
	view.toggle_projection()
	view.reset_camera()
	await frames()
	check(farm.export_text() == state_before,"Rendering and camera never mutate state or RNG")
	view.perspective = false
	view._update_camera(10)
	await physics_frame
	# Pick each real field collider from the camera projection.
	for i in range(24):
		var point := Vector3(view.GRID_X[i%6]+view.FIELD_W/2,0.20,view.GRID_Y[i/6]+view.FIELD_H/2)
		var pixel: Vector2 = view.camera.unproject_position(point)
		var hit: Dictionary = view._ray_at(pixel*view.size/Vector2(view.viewport_3d.size))
		check(not hit.is_empty() and str(hit["collider"].get_meta("id","")) == "plot"+str(i+1),"3D picking plot"+str(i+1))
	for mode in ["moisture","growth","soil","pests","none"]:
		view.overlay_mode = mode
		view._sync()
	check(farm.export_text() == state_before,"All overlays preserve state")
	for chip in app.hud_values.values(): check(chip.size.x>20,"HUD values have visible width")
	for preset in ["eco","quality","balanced"]:
		app._set_performance59(preset)
		view._apply_preset()
		check(view.sunlight.shadow_enabled == (preset != "eco"),"Shadows follow "+preset)
	view.show_build_slots = true
	view.show_garden_slots57 = true
	view._sync_slots()
	check(view.slots.get_child_count() == 48,"Construction and garden slots exposed in 3D")
	for id in farm.content["crops"]:
		for phase in range(4):
			check(Models.crop_mesh(str(id),phase).get_surface_count() == 1,"Crop geometry "+str(id)+" "+str(phase))
	for id in farm.content["animals"]:
		var animal: Node3D = Models.animal(view.stage,str(id))
		check(animal.get_child_count()>0,"Animal model "+str(id))
		animal.free()
	for id in farm.content["buildings"]:
		var building: Node3D = Models.building(view.stage,str(id))
		check(building.get_child_count()>0,"Building model "+str(id))
		building.free()
	for lang in ["es","en"]:
		app.language = lang
		for tab in app.nav_buttons.keys():
			app._change_tab(str(tab))
			await frames(1)
			check(app.right_body.get_child_count()>0,"Screen "+str(tab)+" "+lang)
	app._change_tab("Valley")
	await frames()
	check(view.viewport_3d.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden farm stops rendering")
	check(app.valley_view.tags.size() == 8,"Eight 3D valley regions")
	app._change_tab("Farm")
	await frames()
	check(app.valley_view.viewport_3d.render_target_update_mode == SubViewport.UPDATE_DISABLED,"Hidden valley stops rendering")
	app._enter_building("farmhouse")
	await frames()
	check(app.modal != null,"3D interior opens")
	app._close_modal()
	await frames()
	check(app.world.controls_enabled,"Closing modal restores controls")
	app._show_panorama()
	await frames()
	check(app.modal != null,"Fullscreen 3D farm opens")
	app._close_modal()
	Fixtures.populate(farm)
	app._refresh()
	view._sync()
	await frames()
	check(view.entities.get_child_count()>10,"Populated farm renders buildings, animals, machines and neighbours")
	# Alternate sizes through the real responsive reconstruction path.
	for dimensions in [Vector2i(440,800),Vector2i(960,640),Vector2i(1440,900)]:
		root.size = dimensions
		root.content_scale_size = dimensions
		await frames(6)
		app._show_game()
		await frames(6)
		check(app.scene_root.size.x <= dimensions.x+1,"Layout width "+str(dimensions))
		check(app.game_base.get_global_rect().end.y <= dimensions.y+2,"Layout height "+str(dimensions))
	root.remove_child(app)
	app.free()
	await frames(2)
	print("RESULT: ",checks," checks, ",failures.size()," failures")
	for message in failures: print("FAILED: ",message)
	quit(0 if failures.is_empty() else 1)
