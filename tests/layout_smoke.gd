extends SceneTree
## Run with: godot --headless --path . --script res://tests/layout_smoke.gd
## Engine-runtime checks. This script is not executed by static_audit.py.
const UI = preload("res://Main.tscn")
const Model = preload("res://scripts/NativeFarm.gd")
const WorldScript = preload("res://scripts/World.gd")
var failures: int = 0
var passed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, title: String) -> void:
	if ok:
		passed += 1
		print("PASS ",title)
	else:
		failures += 1
		push_error("FAIL " + title)

func _options(node: Node, into: Array) -> void:
	if node is OptionButton:
		into.append(node)
	for child in node.get_children():
		_options(child,into)

func _run() -> void:
	var ui: Variant = UI.instantiate()
	root.add_child(ui)
	await process_frame
	for viewport_size in [Vector2i(390,844),Vector2i(768,1024),Vector2i(1440,900)]:
		root.size = viewport_size
		await process_frame
		await process_frame
		ui.call("_show_creator")
		await process_frame
		await process_frame
		var choices: Array = []
		_options(ui,choices)
		_check(choices.size() >= 6, "Creation dropdowns exist at " + str(viewport_size))
		for picker in choices:
			_check(not picker.fit_to_longest_item and picker.clip_text,"Dropdown uses bounded text layout")
			_check(picker.custom_minimum_size.y >= 48.0,"Dropdown has accessible touch height")
			_check(picker.get_popup().max_size.y > 0 and picker.get_popup().max_size.y < 400,"Dropdown popup is scroll-bounded")
		ui.call("_show_start_menu")
		await process_frame
		_check(ui.size.x <= float(viewport_size.x)+2.0,"Main control stays inside viewport")
	ui.farm.new_game({"name":"Layout test","seed":47291})
	ui.call("_show_game")
	await process_frame
	ui.call("_change_tab","Fields")
	await process_frame
	_check(ui.world != null and ui.plot_status_label != null,"Map and selected field badge exist")
	_check(WorldScript.GRID_X.size()*WorldScript.GRID_Y.size() == ui.farm.state["fields"].size(),"All 24 plots fit mapped positions")
	_check(ui.plot_status_label.text.contains("PLOT1"),"Selected field label is visible and correctly identified")
	var plot_options: Array = []
	_options(ui.right_body,plot_options)
	_check(plot_options.size() >= 1 and plot_options[0].item_count == 24,"Every plot is accessible in the bounded dropdown")
	for i in [1,6,12,18,24]:
		ui.call("_picked_field","plot"+str(i))
		await process_frame
		_check(ui.plot_status_label.text.contains("PLOT"+str(i)),"Plot selection label tracks plot"+str(i))
	ui.call("_change_tab","Resources")
	await process_frame
	var labels: Array = []
	_options(ui.right_body,labels)
	_check(labels.size() >= 2,"Resource craft selection controls exist")
	# Screenshot export is optional in headless contexts without a real graphics driver.
	# When launched using a normal renderer, users can capture the farm with Options > Take screenshot.
	print("LAYOUT SMOKE ",passed," passed / ",failures," failed")
	quit(0 if failures == 0 else 1)
