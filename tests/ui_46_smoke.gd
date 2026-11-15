extends SceneTree
## Real native UI assertions when launched with Godot, not executed in packaging.
const UI = preload("res://Main.tscn")
var passed: int = 0
var failed: int = 0
func _initialize() -> void:
	call_deferred("_test")
func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL "+label)
func _find(node: Node, search: String) -> bool:
	if node is Label and str(node.text).contains(search):
		return true
	if node is Button and str(node.text).contains(search):
		return true
	for child in node.get_children():
		if _find(child,search):
			return true
	return false
func _test() -> void:
	set_meta("fieldwork_language","es")
	var ui: Variant = UI.instantiate()
	root.add_child(ui)
	await process_frame
	ui.call("_show_creator")
	await process_frame
	_check(_find(ui,"Semilla del mundo"),"World seed label readable in Spanish creator")
	_check(_find(ui,"Ventaja inicial") or _find(ui,"VENTAJA INICIAL"),"Creator shows starting bonus")
	ui.farm.new_game({"name":"Lucía","seed":51231,"language":"es"})
	ui.call("_show_game")
	await process_frame
	_check(ui.nav_buttons.size()==15,"All fifteen navigation routes")
	ui.call("_change_tab","Fields")
	await process_frame
	_check(_find(ui.right_body,"Buscar parcela"),"Field search visible")
	_check(_find(ui.right_body,"Tus parcelas"),"Filterable plot panel visible")
	ui.call("_change_tab","Options")
	await process_frame
	_check(_find(ui.right_body,"tres espacios"),"Three manual save slots exposed")
	_check(_find(ui.right_body,"Controles de alto contraste"),"Contrast toggle exposed")
	_check(_find(ui.right_body,"Aplicar tamaño"),"UI size control exposed")
	ui.call("_change_tab","Farm")
	await process_frame
	_check(_find(ui.right_body,"Tareas de hoy"),"Daily work board visible")
	_check(_find(ui,"Gestionar parcela"),"Context quick field action visible")
	ui.queue_free()
	print("UI46 ",passed," PASSED / ",failed," FAILED")
	quit(0 if failed==0 else 1)
