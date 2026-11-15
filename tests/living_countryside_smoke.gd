extends SceneTree
## Run with Godot 4.4+ --headless --path . --script res://tests/living_countryside_smoke.gd
const Farm = preload("res://scripts/NativeFarm.gd")
const Country = preload("res://scripts/LivingCountryside.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS ",label)
	else:
		failed += 1
		push_error("FAIL "+label)

func _run() -> void:
	var farm: Variant = Farm.new()
	farm.new_game({"seed":54054,"language":"en","hair":"curly","hat":"straw"})
	_check(int(farm.state["schema"]) == 10 and farm.content["crops"].size() == 27,"5.4 starts with inherited 27 crops and schema 10")
	_check(Country.SITES.size() >= 6 and Country.ACTIVITIES.size() >= 6 and Country.NPC_ORDER.size() == 10,"At least six scenic places and activities; ten scheduled villagers")
	_check(Country.valid(farm.state["countryside54"]),"Fresh countryside state validates")
	_check(Country.npc_region("ines",1,8) == "village" and Country.npc_region("ines",1,14) == "orchard","Villagers change regions across the day")
	_check(farm.act("setFarmerLook",{"hair":"braids"}).get("ok",false),"5.3 wardrobe action still runs after parser-scope refactor")
	_check(farm.act("saveOutfitPreset",{"slot":0}).get("ok",false),"Wardrobe slot still saves")
	_check(farm.act("applyOutfitPreset",{"slot":0}).get("ok",false),"Wardrobe slot still equips")
	_check(farm.act("meetNeighbour54",{"npcId":"ines"}).get("ok",false),"Meet a neighbour in their scheduled region")
	var before_repeat: String = farm.export_text()
	_check(not farm.act("meetNeighbour54",{"npcId":"ines"}).get("ok",false) and farm.export_text() == before_repeat,"Daily meeting cooldown rejects without changing state")
	_check(farm.act("discoverSite54",{"siteId":"village_square"}).get("ok",false),"One-time scenic discovery works")
	_check(not farm.act("discoverSite54",{"siteId":"village_square"}).get("ok",false),"Scenic place cannot be discovered twice")
	var reput_before: int = int(farm.state["economy"]["reputation"])
	_check(farm.act("countrysideActivity54",{"activityId":"market_volunteer"}).get("ok",false),"Volunteer at the market")
	_check(int(farm.state["economy"]["reputation"]) == reput_before + 2,"Market volunteer activity affects actual reputation")
	before_repeat = farm.export_text()
	_check(not farm.act("countrysideActivity54",{"activityId":"market_volunteer"}).get("ok",false) and farm.export_text() == before_repeat,"Daily activity limit is transactional")
	_check(not farm.act("discoverSite54",{"siteId":"river_ford"}).get("ok",false),"Regional scenic site cannot be accessed without travel")
	_check(farm.act("explore",{"regionId":"river"}).get("ok",false),"Travel uses existing valley rules")
	_check(farm.act("discoverSite54",{"siteId":"river_ford"}).get("ok",false),"Visit and discover river sight")
	var before_herbs: float = farm.stock("herbs")
	_check(farm.act("countrysideActivity54",{"activityId":"river_herbs"}).get("ok",false),"Riverside activity connects to existing inventory")
	_check(farm.stock("herbs") > before_herbs,"Herb gathering adds genuine inventory")
	_check(Country.valid(farm.state["countryside54"]),"Activity state preserves save invariants")
	var wire: String = farm.export_text()
	_check(farm._verified_envelope(wire) and wire.contains("FW_NATIVE_5_4"),"Current 5.4 save hash and format validate")
	var loaded: Variant = Farm.new()
	_check(loaded.load_text(wire).get("ok",false) and loaded.export_text() == wire,"5.4 save round-trip retains character and countryside progress")
	var older: Dictionary = farm.state.duplicate(true)
	older["schema"] = 9
	older.erase("countryside54")
	var serial: Dictionary = JSON.parse_string(JSON.stringify(older))
	var prior_wire: String = JSON.stringify({"format":"FW_NATIVE_5_3","payload":serial,"sha256":farm._canonical_json(serial).sha256_text()})
	var upgraded: Variant = Farm.new()
	_check(upgraded.load_text(prior_wire).get("ok",false),"Version 5.3 envelope imports successfully")
	_check(int(upgraded.state["schema"]) == 10 and Country.valid(upgraded.state["countryside54"]) and upgraded.field_of("plot1") == farm.field_of("plot1"),"Import only adds countryside fields and preserves farm plots")
	var invalid: Dictionary = loaded.state.duplicate(true)
	invalid["countryside54"]["discovered"] = ["hacker_place"]
	var invalid_serial: Dictionary = JSON.parse_string(JSON.stringify(invalid))
	var invalid_wire: String = JSON.stringify({"format":"FW_NATIVE_5_4","payload":invalid_serial,"sha256":farm._canonical_json(invalid_serial).sha256_text()})
	_check(not upgraded.load_text(invalid_wire).get("ok",false),"Checksum-valid but corrupt countryside state rejected")
	_check(farm.save_file().get("ok",false),"Protected 5.4 native save writes")
	print("FIELDWORK 5.4 GAMEPLAY: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
