extends SceneTree
## Godot runtime smoke test for 5.1 farm visualization and 5.0 save import.
const Farm = preload("res://scripts/NativeFarm.gd")
const World = preload("res://scripts/World.gd")
const Beauty = preload("res://scripts/BeautifulFarm51.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL "+label)

func _test() -> void:
	var farm: Variant = Farm.new()
	farm.new_game({"seed":51051,"language":"en","difficulty":"relaxed"})
	var start: String = farm.export_text()
	_check(start.contains("FW_NATIVE_5_4"),"5.2 creates a new separate checksum save format")
	_check(Farm.SAVE_FILE != Farm.PREVIOUS_SAVE_FILE and Farm.SLOT_DIRECTORY != Farm.PREVIOUS_SLOT_DIRECTORY,"5.1 save files are not overwritten")
	var old: Dictionary = JSON.parse_string(start)
	old["format"] = "FW_NATIVE_5_1"
	old["payload"]["schema"] = 7
	for field in old["payload"]["fields"]:
		field.erase("plot_type")
		field.erase("last_conversion_day")
	old["sha256"] = farm._canonical_json(old["payload"]).sha256_text()
	var original_51: String = JSON.stringify(old)
	var migrated: Variant = Farm.new()
	_check(bool(migrated.load_text(original_51).get("ok",false)),"Real 5.1 schema migrates to 5.2")
	_check(migrated.state["economy"] == farm.state["economy"] and migrated.state["fields"] == farm.state["fields"],"Economy and plots preserved in 5.1 import")
	_check(Beauty.OVERLAYS.size() == 5 and Beauty.overlay_labels(true).size() == 5,"Five bilingual map layers")
	var first: Dictionary = farm.field_of("plot1")
	_check(Beauty.soil_texture(str(first["terrain"]),10.0,200.0) == "terrain51_dry","Dry field uses dry-ground texture")
	_check(Beauty.soil_texture(str(first["terrain"]),180.0,200.0) == "terrain51_wet","Wet field uses wet-ground texture")
	var moisture: float = Beauty.overlay_value("moisture",first)
	_check(moisture >= 0.0 and moisture <= 1.0,"Moisture overlay bounded")
	var saved: String = farm.export_text()
	for mode in Beauty.OVERLAY_ORDER:
		var sample: float = Beauty.overlay_value(str(mode),first)
		_check(sample >= 0.0 and sample <= 1.0,"Overlay range: "+str(mode))
	_check(farm.export_text() == saved,"Presentation layer never changes simulation state")
	var scene: Control = World.new()
	root.add_child(scene)
	scene.size = Vector2(1080.0,610.0)
	scene.set_farm(farm)
	scene.overlay_mode = "soil"
	scene.focus_field("plot4")
	_check(scene.zoom_target >= 1.35 and scene.camera_target.length() > 0.0,"Focus starts smooth visual camera movement")
	scene.reset_camera()
	_check(scene.zoom_target == 1.0 and scene.camera_target == Vector2.ZERO,"Camera reset returns to full farm")
	_check(scene._unat(scene._at(14.0,20.0)).distance_to(Vector2(14.0,20.0)) < 0.02,"Mouse projection remains reversible")
	scene.queue_free()
	print("FIELDWORK 5.1 FARM: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
