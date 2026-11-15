extends SceneTree
## Run with: godot --headless --path . --script res://tests/ui_45_smoke.gd
const UI = preload("res://Main.tscn")
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

func _contains(node: Node, fragment: String) -> bool:
	if node is Label and str(node.text).contains(fragment):
		return true
	if node is Button and str(node.text).contains(fragment):
		return true
	for child in node.get_children():
		if _contains(child,fragment):
			return true
	return false

func _run() -> void:
	set_meta("fieldwork_language","es")
	var ui: Variant = UI.instantiate()
	root.add_child(ui)
	await process_frame
	ui.call("_show_creator")
	await process_frame
	_check(_contains(ui,"Un nuevo comienzo"),"Spanish character creator visible")
	ui.farm.new_game({"name":"María","language":"es","seed":47291})
	ui.call("_show_game")
	await process_frame
	_check(ui.nav_buttons.size()==15,"All 15 management destinations visible")
	_check(_contains(ui,"Guía del mundo"),"World guide appears in Spanish")
	ui.call("_change_tab","Explorer")
	await process_frame
	_check(_contains(ui.right_body,"EXPLORA TODA TU FINCA") or _contains(ui.right_body,"Explora toda tu finca"),"Explorer route opens")
	ui.call("_jump_to_field","plot7")
	await process_frame
	_check(ui.selected_field=="plot7","All plot locations selectable")
	ui.call("_jump_to_region","woods")
	await process_frame
	_check(ui.active_tab=="Valley" and ui.selected_region=="woods","Overworld region navigation is linked")
	ui.farm.state["events"]["active"]={"id":"irrigation_cooperative","title":"test","hour":0}
	ui.call("_show_decision_board")
	await process_frame
	_check(_contains(ui.modal,"Prueba de riego eficiente"),"Spanish event title appears")
	_check(_contains(ui.modal,"Contrapartida:"),"Choice risk displayed")
	ui.call("_close_modal")
	ui.queue_free()
	print("FIELDWORK 4.5 UI: ",passed," passed / ",failed," failed")
	quit(0 if failed==0 else 1)
