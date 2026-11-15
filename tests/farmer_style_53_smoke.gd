extends SceneTree
## Native 5.3 gameplay, customization, protected saves and schema 8 migration.
const Farm = preload("res://scripts/NativeFarm.gd")
const Style = preload("res://scripts/FarmerStyle53.gd")
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

func _test() -> void:
	var farm: Variant = Farm.new()
	farm.new_game({"seed":53032,"language":"es","hair":"curly","hair_color":"#bf6c49","hat":"straw","pants":"#36596e","pronouns":"she"})
	_check(int(farm.state["schema"]) == 10 and farm.content["crops"].size() == 27,"Schema 9 preserves the 27-crop simulation")
	_check(Style.valid(farm.state["player"]) and farm.state["player"]["hair"] == "curly" and farm.state["player"]["hat"] == "straw","Creator appearance is saved on player")
	_check(farm.state["wardrobe53"]["presets"].size() == 3,"Three blank wardrobe slots")
	_check(not Style.available("hat",farm.state).has("ranger") and not Style.available("accessory",farm.state).has("laurel"),"Achievement cosmetics start locked")
	var before_invalid: String = farm.export_text()
	_check(not farm.act("setFarmerLook",{"hair":"../../bad"}).get("ok",false) and farm.export_text() == before_invalid,"Invalid style rejected without altering game state")
	_check(not farm.act("setFarmerLook",{"hat":"ranger"}).get("ok",false) and farm.export_text() == before_invalid,"Locked reward cannot be equipped early")
	_check(farm.act("setFarmerLook",{"hair":"bun","accessory":"glasses","facial_hair":"beard","eyes":"#477f64"}).get("ok",false),"Appearance may be edited after creation")
	_check(farm.state["player"]["accessory"] == "glasses" and farm.state["player"]["eyes"] == "#477f64","Appearance changes persist on player")
	_check(farm.act("saveOutfitPreset",{"slot":0,"look":{"hair":"pony","outfit":"#d4a54b","hat":"straw"}}).get("ok",false),"Save preview appearance into slot one")
	_check(farm.state["wardrobe53"]["presets"][0]["hair"] == "pony","Preset includes current face and chosen new clothing")
	_check(farm.act("setFarmerLook",{"hair":"long","hat":"none"}).get("ok",false),"Change current look after saving outfit")
	_check(farm.act("applyOutfitPreset",{"slot":0}).get("ok",false) and farm.state["player"]["hair"] == "pony" and farm.state["player"]["outfit"] == "#d4a54b","Stored outfit restores appearance")
	_check(not farm.act("applyOutfitPreset",{"slot":2}).get("ok",false),"Empty outfit slot cannot equip")
	_check(farm.act("clearOutfitPreset",{"slot":0}).get("ok",false) and farm.state["wardrobe53"]["presets"][0].is_empty(),"Wardrobe slot can be cleared")
	var wire: String = farm.export_text()
	_check(farm._verified_envelope(wire) and wire.contains("FW_NATIVE_5_4"),"5.3 checksum validator accepts its own saves")
	var restored: Variant = Farm.new()
	_check(restored.load_text(wire).get("ok",false) and restored.export_text() == wire,"Full appearance and farm round-trip through 5.3 save")
	_check(restored.save_file().get("ok",false),"Protected 5.3 autosave can actually be written")
	_check(Farm.SAVE_FILE != Farm.PREVIOUS_SAVE_FILE and Farm.SLOT_DIRECTORY != Farm.PREVIOUS_SLOT_DIRECTORY,"5.2 saves and slots never overwritten")
	# Build an authentic schema-8 style payload, including an existing crop.
	farm.act("plant",{"fieldId":"plot1","cropId":"wheat"})
	var older: Dictionary = farm.state.duplicate(true)
	older["schema"] = 8
	older.erase("wardrobe53")
	for field in Style.FIELDS:
		if not ["hair","skin","outfit"].has(field):
			older["player"].erase(field)
	var normalized_wire: Dictionary = JSON.parse_string(JSON.stringify(older))
	var envelope: String = JSON.stringify({"format":"FW_NATIVE_5_2","payload":normalized_wire,"sha256":farm._canonical_json(normalized_wire).sha256_text()})
	var migrated: Variant = Farm.new()
	_check(migrated.load_text(envelope).get("ok",false),"Authentic version 5.2 save imports")
	if migrated.state.is_empty():
		_check(false,"Save-migration result nonempty")
	else:
		_check(int(migrated.state["schema"]) == 10 and migrated.field_of("plot1")["crop"]["id"] == "wheat" and migrated.state["player"]["hair"] == "pony","Migration keeps crops and old appearance and adds default fields")
	var invalid_payload: Dictionary = restored.state.duplicate(true)
	invalid_payload["player"]["hair_color"] = "red;invalid"
	var invalid_wire: Dictionary = JSON.parse_string(JSON.stringify(invalid_payload))
	var invalid_envelope: String = JSON.stringify({"format":"FW_NATIVE_5_3","payload":invalid_wire,"sha256":restored._canonical_json(invalid_wire).sha256_text()})
	_check(not migrated.load_text(invalid_envelope).get("ok",false),"Checksum-valid malformed appearance rejected")
	print("FIELDWORK 5.3 GAMEPLAY: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
