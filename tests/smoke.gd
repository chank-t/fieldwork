extends SceneTree
## Integration tests: native transactions, save compatibility, real 3D picking,
## every management screen, touch layouts, presets, interiors and hidden views.
## Run in an isolated XDG_DATA_HOME: this test deliberately exercises saves.
const Farm = preload("res://scripts/NativeFarm.gd")
const MainScene = preload("res://Main.tscn")
const Fixtures = preload("res://tests/capture.gd")
const Models = preload("res://scripts/three_d/Models.gd")
const Compass = preload("res://scripts/FarmCompass.gd")
const Data = preload("res://scripts/NativeData.gd")
const UIHubs = preload("res://scripts/UIHubs.gd")
const UIIntegration = preload("res://scripts/UIIntegration.gd")
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
	var story_path: Array[Dictionary] = farm.story_objectives()
	check(story_path.size() == 4,"Story path shows three chapters and an epilogue")
	check(float(story_path[0]["goals"][0]["target"]) == 150.0 and float(story_path[3]["goals"][0]["target"]) == 3.0 and float(story_path[3]["goals"][1]["target"]) == 10.0,"Campaign objectives match the harvest and ending requirements")
	var briefing_farm := Farm.new()
	briefing_farm.new_game({"language":"en","seed":4570})
	var briefing_field: Dictionary = briefing_farm.field_of("plot1")
	briefing_field["crop"] = {"id":"wheat","development":0.5,"pest_stress":0.1,"disease_stress":0.1}
	briefing_field["soil"]["water"] = 0.0
	briefing_field["soil"]["n"] = 0.0
	briefing_field["pests"]["aphids"] = 20.0
	briefing_farm.state["inventory"]["wheat"] = 40.0
	briefing_farm.state["market"]["contracts"] = [{"id":"daily-test","good":"wheat","kg":25.0,"payout":500.0,"deposit":50.0,"deadline":36,"status":"active"}]
	var briefing_snapshot: String = briefing_farm.export_text()
	var briefing_tasks: Array = Compass.priorities(briefing_farm,"en")
	var briefing_ids: Array[String] = []
	var water_detail: String = ""
	for task in briefing_tasks:
		briefing_ids.append(str(task["id"]))
		if str(task["id"]) == "water":
			water_detail = Compass.label(task,"en","detail")
	check(briefing_ids.has("water") and briefing_ids.has("soil") and briefing_ids.has("pests") and briefing_ids.has("disease"),"Daily priorities identify water, nutrient, pest and disease risks")
	check(briefing_ids.has("contract_deliver") and water_detail.contains("%") and water_detail.contains("tomorrow"),"Daily briefing surfaces a ready contract and rainfall tradeoff")
	check(briefing_farm.export_text() == briefing_snapshot,"Daily briefing leaves the farm state unchanged")
	briefing_farm.state["market"]["contracts"][0]["status"] = "open"
	var offer_tasks: Array = Compass.priorities(briefing_farm,"en")
	var premium_offer_found: bool = false
	for task in offer_tasks:
		premium_offer_found = premium_offer_found or str(task["id"]) == "contract_offer"
	check(premium_offer_found,"Daily briefing compares a premium contract against the market")
	briefing_farm.state["market"]["contracts"][0]["status"] = "active"
	briefing_farm.state["market"]["contracts"][0]["deadline"] = int(briefing_farm.state["time"]["total"])+12
	briefing_farm.state["inventory"]["wheat"] = 0.0
	var deadline_tasks: Array = Compass.priorities(briefing_farm,"en")
	var deadline_warning_found: bool = false
	for task in deadline_tasks:
		deadline_warning_found = deadline_warning_found or str(task["id"]) == "contract_deadline"
	check(deadline_warning_found,"Daily briefing warns before an unfulfillable contract expires")
	var guide_farm := Farm.new()
	guide_farm.new_game({"language":"en","seed":4568})
	var old_onboarding_save: Dictionary = guide_farm.state.duplicate(true)
	old_onboarding_save["story"].erase("guided_onboarding")
	old_onboarding_save["story"]["starter_guide"] = Farm.GUIDED_ONBOARDING_STEP_COUNT
	var old_onboarding_wire: Dictionary = JSON.parse_string(JSON.stringify(old_onboarding_save))
	var old_onboarding_envelope: Dictionary = JSON.parse_string(guide_farm.export_text())
	old_onboarding_envelope["payload"] = old_onboarding_wire
	old_onboarding_envelope["sha256"] = guide_farm._canonical_json(old_onboarding_wire).sha256_text()
	var repaired_onboarding_farm := Farm.new()
	var onboarding_recovery: Dictionary = repaired_onboarding_farm.load_text(JSON.stringify(old_onboarding_envelope))
	check(onboarding_recovery.get("ok",false) and int(repaired_onboarding_farm.state["story"]["starter_guide"]) == Farm.STARTER_GUIDE.size() and int(repaired_onboarding_farm.state["story"]["guided_onboarding"]) == Farm.GUIDED_ONBOARDING_STEP_COUNT,"Legacy guided tutorial save is repaired when loaded")
	var hen_needs: Dictionary = guide_farm.animal_daily_requirements({"kind":"hen","count":2,"feeding":"standard"})
	check(is_equal_approx(float(hen_needs["feed_kg"]),0.24),"Animal feed need matches the simulation")
	check(is_equal_approx(float(hen_needs["water_m3"]),0.0005),"Animal water need matches the simulation")
	check(int(guide_farm.state["story"]["starter_guide"]) == 0,"Starter guide begins with soil preparation")
	check(guide_farm.act("inspect",{"fieldId":"plot1"}).get("ok",false),"Starter guide soil inspection action")
	check(int(guide_farm.state["story"]["starter_guide"]) == 1,"Soil inspection advances starter guide")
	check(guide_farm.act("plant",{"fieldId":"plot1","cropId":"wheat"}).get("ok",false),"Starter guide planting action")
	check(int(guide_farm.state["story"]["starter_guide"]) == 2,"Planting advances starter guide")
	check(guide_farm.act("irrigate",{"fieldId":"plot1","mm":15}).get("ok",false),"Starter guide irrigation action")
	check(int(guide_farm.state["story"]["starter_guide"]) == 3,"Irrigation advances starter guide")
	guide_farm.state["fields"][0]["crop"]["development"] = 1.0
	guide_farm.state["fields"][0]["crop"]["biomass"] = 1.0
	check(guide_farm.act("harvest",{"fieldId":"plot1"}).get("ok",false),"Starter guide harvest action")
	check(int(guide_farm.state["story"]["starter_guide"]) == Farm.STARTER_GUIDE.size(),"Harvest completes starter guide")
	check(int(guide_farm.state["story"]["tutorial"]) == 7,"Existing lessons continue after starter guide")
	var skipped_guide := Farm.new()
	skipped_guide.new_game({"language":"en","seed":4569})
	check(skipped_guide.act("starterGuide",{"skip":true}).get("ok",false),"Starter guide can be skipped")
	check(int(skipped_guide.state["story"]["starter_guide"]) == Farm.STARTER_GUIDE.size(),"Skipping closes starter guide")
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
	var radial: Variant = app.radial_menu
	check(radial.language == "es","Radial action labels follow the game language")
	check(app.info.get_ok_button().get_theme_color("font_color") == Color("#233c32"),"Alert dialog OK button uses a visible dark font")
	radial.close_menu()
	if not app.onboarding.is_active:
		app.onboarding.start(farm,app,app._on_onboarding_complete)
	app.onboarding._highlight_field("plot1")
	check(not radial.is_open,"Tutorial field highlight does not open the radial menu")
	var field_screen_position: Vector2 = app.world.get_field_screen_pos("plot1")
	var field_global_position: Vector2 = app.world.get_global_transform()*field_screen_position
	var expected_highlight_position: Vector2 = app.onboarding._global_to_highlight_local(field_global_position)
	var field_ring: Control = app.onboarding.highlight.get_child(app.onboarding.highlight.get_child_count()-1)
	var actual_highlight_position: Vector2 = field_ring.position+field_ring.size/2.0
	check(field_ring.size == Vector2(100,100) and actual_highlight_position.distance_to(expected_highlight_position) < 1.0,"Tutorial field marker aligns with its map target")
	check(field_ring.mouse_filter == Control.MOUSE_FILTER_IGNORE and field_ring.get_child(0).mouse_filter == Control.MOUSE_FILTER_IGNORE,"Tutorial field marker does not intercept clicks")
	var first_unowned_field: String = ""
	for field in farm.state["fields"]:
		if not bool(field["owned"]):
			first_unowned_field = str(field["id"])
			break
	app.onboarding.current_step = 7
	app.onboarding._show_step()
	await frames(1)
	check(app.selected_field == first_unowned_field,"Land tutorial highlights an unowned field")
	app.onboarding._on_next()
	check(not app.info.visible and farm.owned_count() == 1,"Land tutorial Next does not try to buy the owned starting field")
	app.onboarding._complete()
	check(not app.onboarding.is_active and app.onboarding.overlay == null and not app.info.visible,"Completing the tutorial releases the UI without a blocking dialog")
	var post_tutorial_purchase: Dictionary = farm.act("buyField",{"fieldId":first_unowned_field})
	check(post_tutorial_purchase.get("ok",false) and bool(farm.field_of(first_unowned_field).get("owned",false)) and int(farm.state["story"]["guided_onboarding"]) == Farm.GUIDED_ONBOARDING_STEP_COUNT and int(farm.state["story"]["starter_guide"]) <= Farm.STARTER_GUIDE.size(),"Buying land remains available after completing guided onboarding")
	var radial_test_world: Variant = app.world
	var test_field_point := Vector3(radial_test_world.GRID_X[0]+radial_test_world.FIELD_W/2,0.20,radial_test_world.GRID_Y[0]+radial_test_world.FIELD_H/2)
	var test_field_pixel: Vector2 = radial_test_world.camera.unproject_position(test_field_point)
	var test_field_position: Vector2 = test_field_pixel*radial_test_world.size/Vector2(radial_test_world.viewport_3d.size)
	var field_click := InputEventMouseButton.new()
	field_click.button_index = MOUSE_BUTTON_LEFT
	field_click.pressed = true
	field_click.position = radial_test_world.get_global_transform_with_canvas()*test_field_position
	root.push_input(field_click)
	field_click = InputEventMouseButton.new()
	field_click.button_index = MOUSE_BUTTON_LEFT
	field_click.position = radial_test_world.get_global_transform_with_canvas()*test_field_position
	root.push_input(field_click)
	await frames(12)
	check(radial.is_open and radial.current_target.get("id","") == "plot1","Clicking a 3D field opens its radial menu")
	var has_spanish_radial_label: bool = false
	check(radial.item_captions.size() == radial.item_buttons.size() and not radial.item_captions.is_empty(),"Radial actions have visible captions")
	for caption in radial.item_captions:
		var caption_rect: Rect2 = caption.get_global_rect()
		check(caption.size.x >= 100.0 and caption.size.y >= 30.0,"Radial captions receive an interactive-size rect: "+str(caption.size)+" expected "+str(radial.LABEL_SIZE))
		check(caption_rect.position.x >= 0.0 and caption_rect.end.x <= root.size.x and caption_rect.position.y >= 0.0 and caption_rect.end.y <= root.size.y,"Radial caption stays in viewport")
		has_spanish_radial_label = has_spanish_radial_label or caption.get_child(0).text == "Regar +15mm"
	check(has_spanish_radial_label,"Radial action caption is localized")
	var radial_actions: Array[String] = []
	check(radial.action_selected.is_connected(app._on_radial_action),"Radial actions are connected to the game")
	radial.action_selected.connect(func(action_id: String, _args: Dictionary): radial_actions.append(action_id))
	var first_button: Button = radial.item_buttons[0]
	check(first_button.size == Vector2(radial.ITEM_SIZE,radial.ITEM_SIZE),"Radial buttons receive a clickable rect")
	var button_position: Vector2 = first_button.get_global_transform_with_canvas()*(first_button.size/2.0)
	var mouse_motion := InputEventMouseMotion.new()
	mouse_motion.position = button_position
	root.push_input(mouse_motion)
	await frames(1)
	var hovered_control: Control = root.gui_get_hovered_control()
	check(hovered_control == first_button,"Pointer hit-testing reaches a radial button; hit="+str(hovered_control.get_path() if hovered_control != null else "none")+" button="+str(first_button.get_global_rect())+" point="+str(button_position))
	var button_click := InputEventMouseButton.new()
	button_click.button_index = MOUSE_BUTTON_LEFT
	button_click.pressed = true
	button_click.position = button_position
	root.push_input(button_click)
	await frames(1)
	button_click = InputEventMouseButton.new()
	button_click.button_index = MOUSE_BUTTON_LEFT
	button_click.position = button_position
	root.push_input(button_click)
	await frames(1)
	check(radial_actions.size() == 1 and not radial.is_open,"Clicking a radial action emits and closes the menu")
	check(app.pending.get("type","") == radial_actions[0] and app.confirm.visible,"Clicked radial action reaches native confirmation")
	app.confirm.hide()
	app.pending = {}
	radial.show_at(Vector2(5,5),{"type":"field","id":"plot1"})
	check(radial.is_open and radial.item_buttons.size() == radial.item_captions.size(),"Reopening replaces old radial controls")
	radial.close_menu()
	await frames(10)
	for hub_id in UIHubs.get_hub_order():
		app._on_hub_selected(hub_id)
		for panel in UIHubs.get_hub_data(hub_id).get("panels",[]):
			var panel_id: String = str(panel["id"])
			app._on_panel_selected(panel_id)
			check(app.right_body.get_child_count() > 2,"Hub panel renders "+hub_id+"/"+panel_id)
	var view: Control = app.world
	check(view.viewport_3d.own_world_3d,"Farm is a separate real 3D world")
	check(view.plot_roots.size() == 24,"All plot meshes built")
	view.show_build_slots = true
	view.show_garden_slots57 = true
	view._sync_slots()
	check(view.get_building_screen_pos("market").x >= 0.0,"Building lookup returns the market position")
	check(view.get_garden_slot_screen_pos(0).x >= 0.0,"Garden slot lookup returns its position")
	check(view.get_build_slot_screen_pos(0).x >= 0.0,"Building slot lookup returns its position")
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
	var wheat_vertices: PackedVector3Array = Models.crop_mesh("wheat",3).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var maize_vertices: PackedVector3Array = Models.crop_mesh("maize",3).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var grape_vertices: PackedVector3Array = Models.crop_mesh("grape",3).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var apple_vertices: PackedVector3Array = Models.crop_mesh("apple",3).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(wheat_vertices.size() != maize_vertices.size(),"Maize and small-grain crops use distinct geometry")
	check(grape_vertices.size() != apple_vertices.size(),"Grapes and orchard trees use distinct geometry")
	for id in farm.content["animals"]:
		var animal: Node3D = Models.animal(view.stage,str(id))
		check(animal.get_child_count()>0,"Animal model "+str(id))
		check(animal.get_meta("idle_animation",false),"Animal idle animation "+str(id))
		animal.free()
	var animated_animal: Node3D = Models.animal(view.stage,"cow")
	await create_timer(0.2).timeout
	check(absf(animated_animal.get_child(0).rotation.z)>0.001,"Animal idle animation changes its pose")
	animated_animal.free()
	for id in farm.content["buildings"]:
		var building: Node3D = Models.building(view.stage,str(id))
		check(building.get_child_count()>0,"Building model "+str(id))
		building.free()
	for lang in ["es","en"]:
		app.language = lang
		for tab in ["Farm","Compass60","Explorer","Resources","Valley","Countryside54","Expeditions58","Fields","CropGuide52","Ecology","Planning","GardenStudio57","Economy","Buildings","Animals","Processing","Market","Neighbours","Stories","Community50","Festivals50","Certifications50","Character","Wardrobe53","Story","Journal","Options"]:
			app._change_tab(tab)
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
	view.show_build_slots = true
	view.show_garden_slots57 = true
	view._sync_slots()
	var radial_targets: Array[Dictionary] = [
		{"id":"market","type":"building","pick":func(): app._picked_building("market")},
		{"id":str(farm.state["animals"][0]["id"]),"type":"animal","pick":func(): app._picked_animal(str(farm.state["animals"][0]["id"]))},
		{"id":"0","type":"garden_slot","pick":func(): app._picked_garden_slot57(0)},
		{"id":"0","type":"build_slot","pick":func(): app._picked_build_slot(0)},
		{"id":"cultivator","type":"machine","pick":func(): app._picked_machine57("cultivator")}
	]
	for target in radial_targets:
		target["pick"].call()
		check(radial.is_open and radial.current_target.get("type","") == target["type"] and not radial.item_buttons.is_empty(),"Radial opens for "+str(target["type"]))
		radial.close_menu()
		await frames(10)
	var animal_id: String = str(farm.state["animals"][0]["id"])
	var feed_action: Dictionary = radial._animal_actions(animal_id)[0]
	check(feed_action["action"] == "buyFeed" and farm.quote("buySupply",feed_action["args"]).get("ok",false),"Animal radial feed action maps to feed purchase")
	farm.state["inventory"]["timber"] = 10.0
	var decoration_action: Dictionary = radial._garden_slot_actions("0")[0]
	check(decoration_action["args"].has("decorationId") and farm.quote("craftDecoration",decoration_action["args"]).get("ok",false),"Garden radial action uses a valid decoration id")
	var build_action: Dictionary = radial._build_slot_actions("0")[0]
	check(build_action["args"].has("buildingId") and farm.quote("build",build_action["args"]).get("ok",false),"Construction radial action uses the native building id")
	farm.state["life"]["machines"]["cultivator"]["condition"] = 0.9
	var service_action: Dictionary = radial._machine_actions("cultivator")[0]
	check(service_action["action"] == "serviceMachine" and farm.quote("serviceMachine",service_action["args"]).get("ok",false),"Machine radial action uses the native service operation")
	UIIntegration.on_radial_action(app,"plant",{"fieldId":"plot1"})
	check(app.active_tab == "Fields" and app.selected_field == "plot1","Parameterized planting opens the selected field controls")
	UIIntegration.on_radial_action(app,"build",build_action["args"])
	check(app.pending.get("type","") == "build" and app.pending.get("args",{}).has("buildingId"),"Construction radial action reaches native build confirmation")
	app.confirm.hide()
	app.pending = {}
	UIIntegration.on_radial_action(app,"craftDecoration",decoration_action["args"])
	check(app.pending.get("type","") == "craftDecoration" and app.pending.get("args",{}).has("decorationId"),"Garden radial action reaches decoration confirmation")
	app.confirm.hide()
	app.pending = {}
	UIIntegration.on_radial_action(app,"buyFeed",feed_action["args"])
	check(app.pending.get("type","") == "buySupply","Animal feed radial action reaches supply purchase confirmation")
	app.confirm.hide()
	app.pending = {}
	UIIntegration.on_radial_action(app,"upgradeBuilding",{"buildingId":"demo_coop"})
	check(app.pending.get("type","") == "upgrade" and app.pending.get("args",{}).get("buildingId","") == "coop","Building upgrade routes to the native upgrade action")
	app.confirm.hide()
	app.pending = {}
	UIIntegration.on_radial_action(app,"serviceMachine",service_action["args"])
	check(app.pending.get("type","") == "serviceMachine","Machine servicing opens a valid confirmation")
	app.confirm.hide()
	app.pending = {}
	UIIntegration.on_radial_action(app,"openGarden",{})
	check(app.active_tab == "GardenStudio57","Garden detail action opens garden tools")
	UIIntegration.on_radial_action(app,"openBuildings",{})
	check(app.active_tab == "Buildings","Construction detail action opens building tools")
	UIIntegration.on_radial_action(app,"openMachinery",{})
	check(app.active_tab == "Machinery","Machine detail action opens machinery tools")
	var protected_field: Dictionary = farm.field_of("plot1")
	protected_field["crop"] = {}
	protected_field["cover_until"] = int(farm.state["time"]["total"]) + 24
	protected_field["solarize_until"] = int(farm.state["time"]["total"]) + 48
	app.selected_field = "plot1"
	app._change_tab("Fields")
	var plant_button_found: bool = false
	var plant_button_disabled: bool = false
	var conversion_button_found: bool = false
	for control in app.right_body.find_children("*","Button",true,false):
		var button: Button = control
		if button.text in ["Plant selected crop and variety","Sembrar cultivo y variedad"]:
			plant_button_found = true
			plant_button_disabled = button.disabled
		if button.text in ["Convert plot (confirm price)","Transformar parcela (confirmar precio)"]:
			conversion_button_found = true
	check(plant_button_found and plant_button_disabled,"Planting is disabled while crop protection is active")
	check(not conversion_button_found,"Plot conversion is hidden while crop protection is active")
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
