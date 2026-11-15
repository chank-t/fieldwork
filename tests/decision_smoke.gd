extends SceneTree
## Engine test: godot --headless --path . --script res://tests/decision_smoke.gd
const Farm = preload("res://scripts/NativeFarm.gd")
const Decisions = preload("res://scripts/DecisionContent.gd")
const BootScene = preload("res://Boot.tscn")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, title: String) -> void:
	if ok:
		passed += 1
		print("PASS ",title)
	else:
		failed += 1
		push_error("FAIL "+title)

func _has_label(node: Node, needle: String) -> bool:
	if node is Button and str(node.text).contains(needle):
		return true
	for child in node.get_children():
		if _has_label(child,needle):
			return true
	return false

func _run() -> void:
	var boot: Control = BootScene.instantiate() as Control
	root.add_child(boot)
	await process_frame
	_check(_has_label(boot,"Español"),"Spanish selectable from native title screen")
	boot.call("_set_language","es")
	_check(_has_label(boot,"Crear una finca nueva"),"Spanish title buttons immediately translate")
	boot.queue_free()
	await process_frame
	var metadata: Dictionary = Decisions.catalog()
	_check(metadata.size()==29,"Bilingual catalog has 29 decision situations")
	var good: bool = true
	for id in metadata.keys():
		if Decisions.title(str(id),"es").is_empty() or Decisions.options(str(id),"es").size()!=3:
			good = false
	_check(good,"All 87 choices have localized Spanish labels")
	var farm = Farm.new()
	farm.new_game({"language":"es","seed":47291,"name":"Elena","farm":"Valle de prueba"})
	_check(int(farm.state["schema"])==10,"Schema 6 native campaign")
	_check(farm.weather_text().contains("Lluvia"),"Weather localized at model level")
	farm.state["events"]["active"] = {"id":"irrigation_cooperative","title":"test","hour":0}
	var before: String = farm.export_text()
	var quote: Dictionary = farm.quote("eventChoice",{"choice":"join"})
	_check(quote.get("ok",false) and farm.export_text()==before,"Quoting a choice does not change cash or RNG")
	var action: Dictionary = farm.act("eventChoice",{"choice":"join"})
	_check(action.get("ok",false) and farm._effect("water_saver") > 0.10,"Irrigation decision grants real timed water saving")
	_check(int(farm.state["economy"]["reputation"])==2,"Irrigation decision grants reputation")
	var json: String = farm.export_text()
	var recovered = Farm.new()
	var loaded: Dictionary = recovered.load_text(json)
	_check(loaded.get("ok",false) and recovered.state==JSON.parse_string(json)["payload"],"Save/load preserves decision modifiers and history")
	var failed_quote: String = recovered.export_text()
	recovered.state["events"]["active"]={"id":"machinery_breakdown","title":"test","hour":int(recovered.state["time"]["total"])}
	var wait_result: Dictionary = recovered.act("eventChoice",{"choice":"wait"})
	_check(wait_result.get("ok",false) and recovered._effect("labor_slowdown")>0,"Unrepaired tools create a real labor penalty")
	var before_risk: Dictionary = recovered.state.duplicate(true)
	var invalid: Dictionary = recovered.act("eventChoice",{"choice":"invented"})
	_check(not invalid.get("ok",false) and recovered.state==before_risk,"Rejected decision is atomic")
	# Old compatible native schema 3 can be imported into 4.5 while preserving stock and fields.
	var old: Dictionary = farm.state.duplicate(true)
	old["schema"] = 3
	old.erase("decisions")
	var legacy: String = JSON.stringify({"format":"FW_NATIVE_4_3","payload":old,"sha256":farm._canonical_json(old).sha256_text()})
	var migration = Farm.new()
	var migrated: Dictionary = migration.load_text(legacy)
	_check(migrated.get("ok",false) and int(migration.state["schema"])==10 and migration.state["inventory"]==old["inventory"],"4.3 save migrates and retains inventory")
	print("FIELDWORK 4.5 DECISION TESTS: ",passed," passed / ",failed," failed")
	quit(0 if failed==0 else 1)
