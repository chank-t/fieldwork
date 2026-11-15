extends SceneTree
## Safe temporary fixture. Never touches the user's actual primary save slots.
const Farm = preload("res://scripts/NativeFarm.gd")
var failed: int = 0
var passed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS ", description)
	else:
		failed += 1
		push_error("FAIL " + description)

func _test() -> void:
	var model: Variant = Farm.new()
	model.new_game({"seed":47612,"name":"Test farmer","farm":"Recovery QA"})
	var fixture: String = "user://fieldwork_46_qa/recovery_fixture.json"
	var first_save: String = model.export_text()
	_check(model._protected_write(fixture,first_save).get("ok",false),"Create verified test save")
	model.state["economy"]["cash"] = 888.0
	var second_save: String = model.export_text()
	_check(model._protected_write(fixture,second_save).get("ok",false),"Replace with second test save")
	_check(FileAccess.file_exists(fixture+".bak"),"Recovery backup exists")
	_check(FileAccess.get_file_as_string(fixture+".bak") == first_save,"Backup is the prior full farm")
	model.state["economy"]["cash"] = 777.0
	_check(model._protected_write(fixture,model.export_text()).get("ok",false),"Third protected write")
	_check(FileAccess.file_exists(fixture+".bak2"),"Second backup exists")
	_check(FileAccess.get_file_as_string(fixture+".bak2") == first_save,"Older rollback copy retained")
	var bad: FileAccess = FileAccess.open(fixture, FileAccess.WRITE)
	bad.store_string("{\"corrupted\":true}")
	bad.close()
	model.state["economy"]["cash"] = 555.0
	_check(model._protected_write(fixture,model.export_text()).get("ok",false),"Corrupt primary quarantined before replacement")
	_check(FileAccess.file_exists(fixture+".corrupt"),"Corrupt copy retained")
	_check(model._verified_envelope(FileAccess.get_file_as_string(fixture)),"Replaced primary validates")
	var before_failure: String = model.export_text()
	var rejected: Dictionary = model.act("buyField",{"fieldId":"not-a-field"})
	_check(not rejected.get("ok",false) and model.export_text()==before_failure,"Rejected action is atomic")
	_check(model.load_text(first_save).get("ok",false),"Original farm restores byte-equivalent state")
	_check(model.export_text()==first_save,"Farm round-trip is deterministic")
	print("SAVE46 ",passed," PASSED / ",failed," FAILED")
	quit(0 if failed==0 else 1)
