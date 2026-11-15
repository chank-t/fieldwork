extends SceneTree
## Engine runtime checks for the full-window / mobile interface introduced in 5.5.
## Execute: godot --headless --path . --script res://tests/ui_interface_55_smoke.gd
const MainScene = preload("res://Main.tscn")
const FarmScript = preload("res://scripts/NativeFarm.gd")
const Layout55 = preload("res://scripts/ResponsiveLayout55.gd")

var pass_count: int = 0
var fail_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		pass_count += 1
		print("PASS: ",label)
	else:
		fail_count += 1
		push_error("FAIL: "+label)

func _run() -> void:
	_check(Layout55.mode(Vector2i(1366,768),Vector2(1366,768)) == 2, "1366x768 uses desktop")
	_check(Layout55.mode(Vector2i(1920,1080),Vector2(1920,1080)) == 2, "1920x1080 uses desktop")
	_check(Layout55.mode(Vector2i(820,1180),Vector2(820,1180)) == 1, "tablet uses stacked/horizontal navigation")
	_check(Layout55.mode(Vector2i(390,844),Vector2(390,844)) == 0, "390x844 uses phone UI")
	_check(FarmScript.SAVE_FILE != FarmScript.PREVIOUS_SAVE_FILE, "5.4 autosave preserved")
	for dims in [Vector2i(1366,768),Vector2i(1920,1080),Vector2i(820,1180),Vector2i(390,844)]:
		root.size = dims
		await process_frame
		var ui: Control = MainScene.instantiate()
		root.add_child(ui)
		await process_frame
		ui.farm.new_game({"name":"Layout verification","seed":47291})
		ui.call("_show_game")
		await process_frame
		await process_frame
		var safe: MarginContainer = ui.game_safe_area
		_check(safe != null and is_instance_valid(safe), "Responsive root exists "+str(dims))
		if safe != null and is_instance_valid(safe):
			_check(safe.size.x >= ui.size.x-3.0 and safe.size.y >= ui.size.y-3.0, "Safe area fills viewport "+str(dims))
			_check(ui.game_base.size.x >= ui.size.x - 30.0, "Game layout uses screen width "+str(dims))
		_check(ui.world != null and ui.right_body != null, "World and inspector built "+str(dims))
		if ui.compact_mode:
			_check(ui.mobile_map_pane.visible and not ui.mobile_detail_pane.visible, "Phone shows map first "+str(dims))
			_check(ui.mobile_nav_buttons.size() == 4, "Four mobile navigation destinations")
			ui.call("_change_tab","Fields")
			await process_frame
			_check(ui.mobile_detail_pane.visible and not ui.mobile_map_pane.visible, "Plot inspector replaces map on phone")
			ui.call("_change_tab","Farm")
			await process_frame
			_check(ui.mobile_map_pane.visible and not ui.mobile_detail_pane.visible, "Back to map works on phone")
		else:
			_check(ui.mobile_map_pane.visible and ui.mobile_detail_pane.visible, "Desktop keeps both panels")
			_check(ui.primary_nav_buttons.size() >= 5, "Desktop top navigation available")
			_check(ui.mobile_map_pane.size.x >= 220.0, "World panel is not squashed")
		ui.queue_free()
		await process_frame
	print("FIELDWORK 5.5 UI ENGINE TESTS: ",pass_count," passed / ",fail_count," failed")
	quit(0 if fail_count == 0 else 1)
