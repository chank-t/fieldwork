extends SceneTree
## Native 5.4 UI/map smoke, requires Godot with imported project assets.
const MainScene = preload("res://Main.tscn")
const Country = preload("res://scripts/LivingCountryside.gd")
const Farm = preload("res://scripts/NativeFarm.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL "+label)

func _run() -> void:
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"seed":54121,"language":"es","hat":"straw"})
	ui.language = "es"
	ui._show_game()
	await process_frame
	_check(ui.nav_buttons.has("Countryside54"),"Living countryside reachable from sidebar")
	ui._change_tab("Countryside54")
	await process_frame
	_check(ui.right_body != null and ui.right_body.get_child_count() > 7,"Countryside screen displays interactive content")
	ui._picked_countryside_region54(Farm.REGIONS.keys().find("river"),Farm.REGIONS.keys())
	await process_frame
	_check(ui.selected_region == "river","Region selector changes the countryside destination")
	_check(ui.valley_view != null and ui.valley_view.has_method("_draw_countryside54"),"Valley map renders villagers and discovery markers")
	_check(Country.villagers_at("village",7,12).size() == 10,"Market day gathers villagers in the village")
	ui.queue_free()
	print("FIELDWORK 5.4 UI: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
