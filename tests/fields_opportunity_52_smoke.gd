extends SceneTree
## Fieldwork 5.2 gameplay and save migration; run after headless Godot import.
const Farm = preload("res://scripts/NativeFarm.gd")
const Fields = preload("res://scripts/FieldsOpportunity52.gd")
var passed: int = 0
var failed: int = 0
func _initialize() -> void:
	call_deferred("_test")
func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL " + label)
func _test() -> void:
	var farm: Variant = Farm.new()
	farm.new_game({"seed":52105,"difficulty":"relaxed","language":"es"})
	_check(farm.state["schema"] == 10 and farm.content["crops"].size()==27,"Native 5.2 begins with 27 crops and schema 8")
	_check(farm.content["goods"].size()==50 and Fields.PLOTS.size()==4 and Fields.VARIETIES.size()==3,"New market produce, layouts, seed varieties")
	_check(farm.field_of("plot1")["plot_type"] == "open","Existing starting field defaults to open farming")
	var clean: String = farm.export_text()
	_check(not farm.act("plant",{"fieldId":"plot1","cropId":"rice"}).get("ok",false) and farm.export_text()==clean,"Rice rejected outside paddy without side effects")
	_check(not farm.act("plant",{"fieldId":"plot1","cropId":"apple"}).get("ok",false) and farm.export_text()==clean,"Orchard crop rejected outside orchard without side effects")
	_check(farm.quote("configurePlot",{"fieldId":"plot1","plotType":"orchard"}).get("ok",false) and farm.export_text()==clean,"Orchard quote is read-only")
	var old_cash: float = float(farm.state["economy"]["cash"])
	_check(farm.act("configurePlot",{"fieldId":"plot1","plotType":"orchard"}).get("ok",false),"Build an orchard for a real cost")
	_check(farm.field_of("plot1")["plot_type"] == "orchard" and float(farm.state["economy"]["cash"]) < old_cash,"Orchard persists and subtracts cash")
	var orchard_saved: String = farm.export_text()
	_check(not farm.act("configurePlot",{"fieldId":"plot1","plotType":"open"}).get("ok",false) and farm.export_text()==orchard_saved,"Same-day conversion blocked atomically")
	_check(farm.act("plant",{"fieldId":"plot1","cropId":"apple","variety":"early"}).get("ok",false),"Plant early-maturity apples in orchard")
	_check(str(farm.field_of("plot1")["crop"]["variety"])=="early","Selected cultivar saved")
	_check(not farm.act("build",{"fieldId":"plot1","buildingId":"greenhouse"}).get("ok",false),"No greenhouse placed over orchard")
	farm.field_of("plot1")["crop"]["development"] = 1.0
	farm.field_of("plot1")["crop"]["biomass"] = 9000.0
	_check(farm.act("harvest",{"fieldId":"plot1"}).get("ok",false),"Harvest mature apple fruit")
	_check(farm.stock("apple") > 0.0 and int(farm.field_of("plot1")["crop"].get("harvest_cycles",0)) == 1,"Tree stays alive and fruit is stored for sale")
	var restored: Variant = Farm.new()
	var orchard_wire: String = farm.export_text()
	_check(restored.load_text(orchard_wire).get("ok",false) and restored.export_text()==orchard_wire,"Orchard state survives checksum save/load")
	var rice: Variant = Farm.new()
	rice.new_game({"seed":52106,"difficulty":"relaxed"})
	_check(rice.act("configurePlot",{"fieldId":"plot1","plotType":"paddy"}).get("ok",false),"Suitable loam becomes a paddy")
	_check(rice.act("plant",{"fieldId":"plot1","cropId":"rice"}).get("ok",false),"Paddy accepts rice")
	_check(not rice.act("plant",{"fieldId":"plot1","cropId":"wheat"}).get("ok",false),"Paddy refuses unrelated crops")
	var raised: Variant = Farm.new()
	raised.new_game({"seed":52107,"difficulty":"relaxed"})
	_check(raised.act("configurePlot",{"fieldId":"plot1","plotType":"raised"}).get("ok",false),"Raised beds available")
	_check(raised.act("plant",{"fieldId":"plot1","cropId":"basil","variety":"resilient"}).get("ok",false),"Drought-tolerant basil grows in beds")
	_check(not raised.act("plant",{"fieldId":"plot1","cropId":"apple"}).get("ok",false),"Orchard crop not allowed in raised beds")
	var source: Variant = Farm.new()
	source.new_game({"seed":52108,"difficulty":"relaxed"})
	_check(source.act("plant",{"fieldId":"plot1","cropId":"wheat"}).get("ok",false),"Set up original 5.1 planted farm")
	var payload: Dictionary = source.state.duplicate(true)
	payload["schema"] = 7
	for field in payload["fields"]:
		field.erase("plot_type")
		field.erase("last_conversion_day")
		if not field["crop"].is_empty():
			field["crop"].erase("variety")
			field["crop"].erase("harvest_cycles")
	var older: String = JSON.stringify({"format":"FW_NATIVE_5_1","payload":payload,"sha256":source._canonical_json(payload).sha256_text()})
	var migrated: Variant = Farm.new()
	_check(migrated.load_text(older).get("ok",false),"Authentic schema 7 save migrates from 5.1")
	_check(migrated.state["schema"]==10 and migrated.state["fields"][0]["crop"]["id"]=="wheat" and migrated.state["fields"][0]["crop"]["variety"]=="standard","Migration preserves planted crops and adds safe defaults")
	_check(Farm.SAVE_FILE != Farm.PREVIOUS_SAVE_FILE and Farm.SLOT_DIRECTORY != Farm.PREVIOUS_SLOT_DIRECTORY,"5.2 autosave and slots cannot overwrite 5.1")
	print("FIELDWORK 5.2 GAMEPLAY: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
