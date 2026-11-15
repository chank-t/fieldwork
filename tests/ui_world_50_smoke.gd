extends SceneTree
## UI smoke tests require a real Godot binary and imported assets.
const MainScene = preload("res://Main.tscn")
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

func _contains(node: Node, phrase: String) -> bool:
	if node is Label and str(node.text).contains(phrase):
		return true
	if node is Button and str(node.text).contains(phrase):
		return true
	for child in node.get_children():
		if _contains(child,phrase):
			return true
	return false

func _test() -> void:
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.farm.new_game({"seed":5015,"language":"es"})
	ui.language = "es"
	ui._show_game()
	await process_frame
	for tab in ["Community50","Festivals50","Certifications50"]:
		_check(ui.nav_buttons.has(tab),"Native navigation includes "+tab)
	ui._change_tab("Community50")
	await process_frame
	_check(_contains(ui.right_body,"Historias vecinales"),"Thirty-stage native bilingual neighbour board displays")
	ui._change_tab("Festivals50")
	await process_frame
	_check(_contains(ui.right_body,"Objetivo de la estación"),"Seasonal objective and festival screen displays in Spanish")
	ui._change_tab("Certifications50")
	await process_frame
	_check(_contains(ui.right_body,"Acreditaciones profesionales"),"Advanced qualifications screen displays")
	ui._change_tab("Character")
	await process_frame
	_check(_contains(ui.right_body,"Vestuario de la finca"),"Playable wardrobe available after creation")
	ui._change_tab("Options")
	await process_frame
	_check(_contains(ui.right_body,"Movimiento reducido"),"Reduced-motion setting available")
	_check(_contains(ui.right_body,"Mostrar siempre etiquetas"),"Textual high-visibility soil-status setting available")
	ui._set_accessibility(true,"motion")
	ui._set_accessibility(true,"labels")
	_check(ui.world.reduced_motion and ui.world.high_visibility_labels,"Accessibility settings reach native 2D renderer")
	_check(ui.ambient_player != null,"Seasonal native audio player has been created")
	ui.queue_free()
	print("WORLD WORTH 5.0 UI: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
