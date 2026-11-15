extends SceneTree
## Visual/UI integration requires a real Godot executable; smoke, not screenshot QA.
const MainScene = preload("res://Main.tscn")
const World = preload("res://scripts/World.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(yes: bool, label: String) -> void:
	if yes:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL "+label)

func _has_text(node: Node, needle: String) -> bool:
	if node is Label and str(node.text).contains(needle):
		return true
	if node is Button and str(node.text).contains(needle):
		return true
	for child in node.get_children():
		if _has_text(child,needle):
			return true
	return false

func _test() -> void:
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"seed":47291,"language":"es","name":"Elena"})
	ui.language="es"
	ui._show_game()
	await process_frame
	for tab in ["Planning","Machinery","Economy","Fields","Ecology","Buildings","Animals"]:
		_check(ui.nav_buttons.has(tab),"Reachable sidebar: "+tab)
	ui._change_tab("Planning")
	await process_frame
	_check(_has_text(ui.right_body,"El manana empieza hoy"),"Spanish planning screen is populated")
	ui._change_tab("Economy")
	await process_frame
	_check(_has_text(ui.right_body,"Estrategia actual"),"Spanish business screen renders")
	ui._change_tab("Machinery")
	await process_frame
	_check(_has_text(ui.right_body,"Parque de maquinaria"),"Spanish machinery yard renders")
	ui._change_tab("Ecology")
	await process_frame
	_check(_has_text(ui.right_body,"Inspeccion tecnica"),"Pest scouting requires explicit in-game action")
	ui._change_tab("Buildings")
	await process_frame
	_check(ui.world != null and ui.world.show_build_slots,"Construction position map markers enabled")
	ui._picked_build_slot(9)
	_check(ui.selected_build_slot == 9 and ui.world.active_build_slot == 9,"Interactive map construction position persists in native UI")
	ui._change_tab("Farm")
	await process_frame
	_check(not ui.world.show_build_slots,"Construction markers hidden outside construction tab")
	var world: Variant = World.new()
	_check(world._structure_position({"field":"","slot":9},0) == world._building_anchor(9),"Map uses chosen farm building slot")
	ui.queue_free()
	print("FIELDWORK 4.9 UI: ",passed," PASS, ",failed," FAIL")
	quit(0 if failed == 0 else 1)
