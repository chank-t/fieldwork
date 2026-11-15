extends SceneTree
## Requires real Godot 4.4+ and the asset import pass before running.
const MainScene = preload("res://Main.tscn")
const Portrait = preload("res://scripts/FarmerPortrait.gd")
const Interior = preload("res://scripts/Interior.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(condition: bool, title: String) -> void:
	if condition:
		passed += 1
		print("PASS ",title)
	else:
		failed += 1
		push_error("FAIL "+title)

func _count_selectors(node: Node) -> int:
	var found: int = 1 if node is OptionButton else 0
	for child in node.get_children():
		found += _count_selectors(child)
	return found

func _test() -> void:
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.language = "en"
	ui._show_creator()
	await process_frame
	_check(_count_selectors(ui) >= 12,"Creator exposes all 12 appearance choices")
	var portrait: Control = Portrait.new()
	root.add_child(portrait)
	portrait.set_avatar({"hair":"braids","skin":"#503324","hat":"straw","accessory":"flower"})
	_check(portrait.appearance["hair"] == "braids" and portrait.appearance["hat"] == "straw","Procedural portrait previews saved style")
	ui.farm.new_game({"seed":53321,"language":"es","hair":"curly","hair_color":"#bf6c49","pants":"#36596e","boots":"#292b2c"})
	ui.language = "es"
	ui._show_game()
	await process_frame
	_check(ui.nav_buttons.has("Wardrobe53"),"Wardrobe is reachable from sidebar")
	ui._change_tab("Wardrobe53")
	await process_frame
	_check(_count_selectors(ui.right_body) >= 12,"Wardrobe contains live editor and full customization")
	ui.farm.act("setFarmerLook",{"hat":"straw","outfit":"#8b5278"})
	ui._refresh()
	_check(ui.world != null and ui.farm.state["player"]["hat"] == "straw","World renders personalized player state")
	var interior: Control = Interior.new()
	root.add_child(interior)
	interior.call("set_avatar",ui.farm.state["player"])
	_check(interior.farmer_look["outfit"] == "#8b5278","Building interiors inherit personalized look")
	portrait.queue_free()
	interior.queue_free()
	ui.queue_free()
	print("FIELDWORK 5.3 UI: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
