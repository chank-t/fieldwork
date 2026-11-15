extends SceneTree
## Render actual Godot scenes. Requires a display (e.g. DISPLAY=:99).
## Usage: godot --path . --script tests/capture.gd -- boot /tmp/boot.png
const Backdrop = preload("res://scripts/three_d/Backdrop3D.gd")
const MainScene = preload("res://Main.tscn")
var app: Control

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var shot: String = args[0] if args.size()>0 else "boot"
	var path: String = args[1] if args.size()>1 else "/tmp/fieldwork.png"
	var result: int = 0
	if shot == "all":
		DirAccess.make_dir_recursive_absolute(path)
		for mode in ["boot","farm","detail","valley","interior","portrait","phone","new"]:
			result = maxi(result,await capture(mode,path.path_join(mode+".png")))
	else:
		result = await capture(shot,path)
	quit(result)

func capture(shot: String, path: String) -> int:
	root.size = Vector2i(1440,900)
	root.content_scale_size = Vector2i(1440,900)
	if shot == "boot":
		app = load("res://Boot.tscn").instantiate()
		root.add_child(app)
	else:
		app = MainScene.instantiate()
		root.add_child(app)
		app.language = "es"
		app.farm.new_game({"language":"es","name":"Alex","farm":"Valle del Sauce","hat":"straw"})
		app.ambient_enabled = false
		if shot != "new": populate(app.farm)
		app._show_game()
		if shot == "detail": app.world.focus_field("plot1")
		if shot == "valley": app._change_tab("Valley")
		if shot == "interior": app._enter_building("farmhouse")
		if shot == "portrait": app._change_tab("Wardrobe53")
		if shot == "panorama": app._show_panorama()
		if shot == "phone":
			root.size = Vector2i(440,800)
			root.content_scale_size = Vector2i(440,800)
			app._show_game()
	for i in range(24): await process_frame
	await RenderingServer.frame_post_draw
	var result: int = root.get_texture().get_image().save_png(path)
	print("CAPTURE ",shot," ",path," ",result)
	root.remove_child(app)
	app.free()
	for i in range(3): await process_frame
	return result

static func populate(farm: RefCounted) -> void:
	# Test-only fixture; never saved. Real planting constructs complete crop data.
	farm.state["economy"]["cash"] = 120000
	var crops: Array = ["wheat","lavender","pumpkin","tomato","sunflower","lettuce"]
	for i in range(18):
		var field: Dictionary = farm.state["fields"][i]
		field["owned"] = true
		var result: Dictionary = farm.act("plant",{"fieldId":str(field["id"]),"cropId":crops[i%6]})
		if result.get("ok",false):
			field = farm.field_of(str(field["id"]))
			field["crop"]["development"] = 0.8 if i%3 else 1.0
			field["crop"]["biomass"] = 4000
	farm.state["buildings"] = [{"id":"demo_barn","kind":"barn","field":"","slot":7,"level":1,"target":1,"ready_at":0,"built_at":0},{"id":"demo_greenhouse","kind":"greenhouse","field":"","slot":17,"level":1,"target":1,"ready_at":0,"built_at":0},{"id":"demo_coop","kind":"coop","field":"","slot":3,"level":1,"target":1,"ready_at":0,"built_at":0}]
	farm.act("buyAnimal",{"animalId":"hen","count":3})
	farm.act("buyAnimal",{"animalId":"cow","count":2})
	farm.act("buyMachine",{"machineId":"cultivator"})
