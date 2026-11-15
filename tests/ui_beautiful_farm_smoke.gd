extends SceneTree
## Native UI interaction test; use with the Godot 4.4+ editor or --headless binary.
const MainScene = preload("res://Main.tscn")
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
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"seed":51123,"language":"es"})
	ui.language = "es"
	ui.sidebar_open = false
	ui.terrain_overlay = "none"
	ui._show_game()
	await process_frame
	_check(ui.world != null and ui.world.visible,"Large live farm created")
	_check(ui.left_nav_holder != null and not ui.left_nav_holder.visible,"Default sidebar is collapsed for larger farm")
	ui._toggle_sidebar()
	_check(ui.left_nav_holder.visible,"Sidebar can be restored interactively")
	ui._toggle_sidebar()
	_check(not ui.left_nav_holder.visible,"Sidebar can be hidden again")
	_check(ui.hud_values.size() == 5,"Five compact live HUD statistics")
	_check(ui.context_title != null and ui.context_manage != null,"Field context and primary action visible")
	_check(ui.overlay_picker.item_count == 5,"Five map overlay options displayed")
	ui._set_overlay_51(1)
	_check(ui.terrain_overlay == "moisture" and ui.world.overlay_mode == "moisture","Selecting map layer reaches renderer")
	ui._picked_field("plot1")
	_check(ui.context_title.text.contains("PLOT1") and not ui.context_water.disabled,"Owned field displays contextual actions")
	ui._picked_field("plot24")
	_check(ui.context_manage.text == "Comprar" and ui.context_water.disabled,"Unowned field offers purchase rather than watering")
	ui._show_screen_picker()
	_check(ui.modal != null,"Screen-directory modal can be opened")
	ui._select_screen_51("Machinery")
	_check(ui.modal == null and ui.active_tab == "Machinery","Screen picker opens inherited management panel")
	ui._show_panorama()
	_check(ui.modal != null,"Large farm panorama remains available")
	ui._close_modal()
	ui.queue_free()
	print("FIELDWORK 5.1 UI: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
