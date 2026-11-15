extends SceneTree
## Requires Godot 4.4+. Verifies actual native Controls and bilingual UI layout.
## Run: godot --headless --path . --script res://tests/ui_story_smoke.gd
const MainScene = preload("res://Main.tscn")
const BootScene = preload("res://Boot.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(yes: bool, title: String) -> void:
	if yes:
		passed += 1
		print("PASS ", title)
	else:
		failed += 1
		push_error("FAIL " + title)

func _has_label(node: Node, phrase: String) -> bool:
	if node is Label and phrase in str(node.text):
		return true
	for child in node.get_children():
		if _has_label(child,phrase):
			return true
	return false

func _test() -> void:
	var boot: Control = BootScene.instantiate()
	root.add_child(boot)
	await process_frame
	_check(_has_label(boot,"FIELDWORK"),"Native title scene immediately displays visible heading")
	_check(boot.get_node_or_null("Center/Frame/Content/NewGame") != null,"Native title scene has create-farm button")
	boot.queue_free()
	await process_frame
	var game: Control = MainScene.instantiate()
	root.add_child(game)
	await process_frame
	game.farm.new_game({"seed":47291,"name":"Elena","farm":"Mi Valle","language":"es"})
	game.language = "es"
	game._show_game()
	await process_frame
	_check(game.nav_buttons.has("Stories"),"Village Stories navigation button exists")
	game._change_tab("Stories")
	await process_frame
	_check(_has_label(game.right_body,"Historias del pueblo"),"Village Stories panel is localized")
	game._change_tab("Neighbours")
	await process_frame
	_check(_has_label(game.right_body,"Confianza:"),"Neighbour relationship values visible")
	game._change_tab("Stories")
	var invite: Dictionary = game.farm.act("inviteStory",{"arcId":"water"})
	_check(invite.get("ok",false),"Village invitation available through native model")
	game._refresh()
	await process_frame
	_check(game.modal != null,"Urgent invitation opens a visible decision overlay")
	game._close_modal()
	game._change_tab("Journal")
	await process_frame
	_check(_has_label(game.right_body,"Historial de decisiones"),"Spanish decision journal remains accessible")
	game.queue_free()
	print("FIELDWORK 4.8 UI SMOKE: ",passed," PASS, ",failed," FAIL")
	quit(0 if failed == 0 else 1)
