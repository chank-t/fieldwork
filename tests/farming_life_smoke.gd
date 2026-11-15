extends SceneTree
## Godot 4.4+ runtime invariants for Farming Life 4.9.
## Run: godot --headless --path . --script res://tests/farming_life_smoke.gd
const Farm = preload("res://scripts/NativeFarm.gd")
const Life = preload("res://scripts/FarmingLife.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(yes: bool, title: String) -> void:
	if yes:
		passed += 1
		print("PASS ",title)
	else:
		failed += 1
		push_error("FAIL " + title)

func _test() -> void:
	var farm: Variant = Farm.new()
	farm.new_game({"seed":62937,"language":"es","difficulty":"relaxed"})
	_check(int(farm.state["schema"]) == 10,"4.9 mechanics retained in 5.0 schema 7")
	_check(farm.state["life"]["machines"].is_empty() and str(farm.state["life"]["path"]) == "balanced","Initial farm is un-specialized and owns no machines")
	_check(farm.field_of("plot1")["soil"].has("organic_matter"),"Soil stores organic matter, compaction and erosion")
	var forecast_before: String = farm.export_text()
	_check(farm.farm_forecast().size() == 3 and farm.operating_budget().has("fixed_daily"),"Read-only three-day climate and budget forecasts")
	_check(farm.export_text() == forecast_before,"Forecast and budget never change state or RNG")
	var quoted: Dictionary = farm.quote("scoutField",{"fieldId":"plot1"})
	_check(quoted.get("ok",false) and farm.export_text() == forecast_before,"Scouting quote does not reveal or persist data")
	var surveyed: Dictionary = farm.act("scoutField",{"fieldId":"plot1"})
	_check(surveyed.get("ok",false) and farm.field_of("plot1")["scout_report"].has("pests"),"Paid scout creates a dated report")
	var before_repeat: String = farm.export_text()
	_check(not farm.act("scoutField",{"fieldId":"plot1"}).get("ok",false) and farm.export_text() == before_repeat,"Duplicate same-day scouting rejected atomically")
	var original_compaction: float = float(farm.field_of("plot1")["soil"]["compaction"])
	_check(farm.act("aerateSoil",{"fieldId":"plot1"}).get("ok",false) and float(farm.field_of("plot1")["soil"]["compaction"]) < original_compaction,"Aeration changes persistent soil state")
	_check(farm.act("plantHedgerow",{"fieldId":"plot1"}).get("ok",false) and bool(farm.field_of("plot1")["hedgerow"]),"Permanent hedgerow planted on field")
	var pre_cover: float = float(farm.field_of("plot1")["soil"]["organic_matter"])
	_check(farm.act("coverCrop",{"fieldId":"plot1"}).get("ok",false),"Cover crop can start on fallow land")
	var cover_before: String = farm.export_text()
	_check(not farm.act("plant",{"fieldId":"plot1","cropId":"wheat"}).get("ok",false) and farm.export_text()==cover_before,"Cover crop prevents premature planting")
	farm.state["events"]["next"] = 99999999
	for i in range(4):
		farm.act("tick",{"hours":24})
	_check(float(farm.field_of("plot1")["soil"]["organic_matter"]) > pre_cover,"Cover crop raises soil organic matter after four days")
	_check(farm.act("plant",{"fieldId":"plot1","cropId":"wheat"}).get("ok",false),"Cash crop can be planted after cover matures")
	var machines: Variant = Farm.new()
	machines.new_game({"seed":88171,"difficulty":"relaxed"})
	var control: Variant = Farm.new()
	control.new_game({"seed":88171,"difficulty":"relaxed"})
	_check(machines.act("buyMachine",{"machineId":"pump"}).get("ok",false),"Efficient irrigation machine purchased")
	var before_machine: String = machines.export_text()
	_check(not machines.act("buyMachine",{"machineId":"pump"}).get("ok",false) and machines.export_text()==before_machine,"Duplicate machine purchase rolls back")
	var before_control_water: float = float(control.state["water"]["stored"])
	var before_machine_water: float = float(machines.state["water"]["stored"])
	control.act("irrigate",{"fieldId":"plot1","mm":20.0})
	machines.act("irrigate",{"fieldId":"plot1","mm":20.0})
	_check(float(machines.state["water"]["stored"]) > float(control.state["water"]["stored"]),"Working pump conserves actual reservoir water")
	_check(before_control_water==before_machine_water,"Machine comparison starts with equal water volumes")
	_check(int(machines.state["life"]["machines"]["pump"]["hours_used"]) >= 1,"Irrigation use wears the pump")
	_check(machines.act("serviceMachine",{"machineId":"pump"}).get("ok",false) and is_equal_approx(float(machines.state["life"]["machines"]["pump"]["condition"]),1.0),"Paid machine service restores condition")
	var strategy: Variant = Farm.new()
	strategy.new_game({"seed":125,"difficulty":"relaxed"})
	var start_cash: float = float(strategy.state["economy"]["cash"])
	_check(strategy.act("choosePath",{"path":"crops"}).get("ok",false) and is_equal_approx(float(strategy.state["economy"]["cash"]),start_cash),"First specialization is free")
	var locked: String = strategy.export_text()
	_check(not strategy.act("choosePath",{"path":"artisan"}).get("ok",false) and strategy.export_text()==locked,"Specialization cooldown is enforced atomically")
	strategy.state["time"]["total"] = 288
	_check(strategy.act("choosePath",{"path":"artisan"}).get("ok",false) and float(strategy.state["economy"]["cash"]) < start_cash,"Later specialization switch charges retraining cost")
	var constructor: Variant = Farm.new()
	constructor.new_game({"seed":91812,"difficulty":"relaxed"})
	_check(constructor.act("build",{"buildingId":"warehouse","slot":6}).get("ok",false),"Farm building uses explicit construction position")
	var existing: String = constructor.export_text()
	_check(not constructor.act("build",{"buildingId":"coop","slot":6}).get("ok",false) and constructor.export_text()==existing,"Overlapping construction positions are rejected")
	_check(constructor.act("tick",{"hours":24}).get("ok",false) and constructor.ready("warehouse"),"Placed construction completes in simulated time")
	var bid: String = str(constructor.state["buildings"][0]["id"])
	_check(constructor.act("relocateBuilding",{"buildingId":bid,"slot":9}).get("ok",false) and int(constructor.state["buildings"][0]["slot"])==9,"Completed building can be relocated for an actual cost")
	var saver: String = constructor.export_text()
	var restored: Variant = Farm.new()
	_check(restored.load_text(saver).get("ok",false) and restored.export_text()==saver,"New layout and all 4.9 state survive deterministic save/load")
	var animals: Variant = Farm.new()
	animals.new_game({"seed":442,"difficulty":"relaxed"})
	_check(animals.act("build",{"buildingId":"coop"}).get("ok",false),"Animal shelter construction starts")
	animals.act("tick",{"hours":24})
	_check(animals.act("buyAnimal",{"animalId":"hen","count":2}).get("ok",false),"New group records age and health")
	var group: Dictionary = animals.state["animals"][0]
	_check(group.has("nutrition") and group.has("pregnancy_due"),"Livestock nutrition and reproduction save fields exist")
	_check(animals.act("feedingPlan",{"animalId":str(group["id"]),"mode":"balanced"}).get("ok",false),"Livestock feeding plan is interactive")
	_check(animals.act("vetVisit",{"animalId":str(group["id"])}).get("ok",false) and int(group["vet_until"]) > 0,"Vet care consumes money and creates timed protection")
	_check(animals.act("breedAnimal",{"animalId":str(group["id"])}).get("ok",false),"Healthy herd may reserve housing for offspring")
	animals.state["events"]["next"] = 99999999
	var expected: int = int(group["count"])+1
	for i in range(4):
		animals.act("tick",{"hours":24})
	_check(int(group["count"]) == expected and int(group["pregnancy_due"]) == 0,"Newborn only appears after four actual game days")
	var grade: Variant = Farm.new()
	grade.new_game({"seed":92374,"difficulty":"relaxed"})
	grade.state["fields"][0]["crop"]={"id":"wheat","age":500.0,"development":1.0,"biomass":4000.0,"health":1.0,"planted_at":0,"water_stress":0.0,"pest_stress":0.0,"disease_stress":0.0}
	_check(grade.act("harvest",{"fieldId":"plot1"}).get("ok",false) and grade.premium_stock("wheat") > 0.1,"High-grade real harvest creates bounded premium stock")
	var premium_before: float = grade.premium_stock("wheat")
	var price: float = grade.market_price("wheat")
	var cash_before: float = float(grade.state["economy"]["cash"])
	var amount: float = minf(10.0,grade.stock("wheat"))
	_check(grade.act("sell",{"goodId":"wheat","kg":amount}).get("ok",false),"Premium harvest can be sold at market")
	_check(float(grade.state["economy"]["cash"]) - cash_before > amount*price,"Premium sale earns a real quality bonus")
	_check(grade.premium_stock("wheat") < premium_before,"Sale consumes the sold premium goods")
	var old_source: Variant = Farm.new()
	old_source.new_game({"seed":71321})
	var old: Dictionary = old_source.state.duplicate(true)
	old["schema"] = 5
	old.erase("life")
	for field in old["fields"]:
		for key in ["organic_matter","compaction","erosion"]:
			field["soil"].erase(key)
		for key in ["cover_until","hedgerow","scouted_day","scout_report"]:
			field.erase(key)
	var old_text: String = JSON.stringify({"format":"FW_NATIVE_4_8","payload":old,"sha256":old_source._canonical_json(old).sha256_text()})
	var migrated: Variant = Farm.new()
	_check(migrated.load_text(old_text).get("ok",false) and int(migrated.state["schema"])==10,"Unmodified valid 4.8 game migrates through 4.9 to 5.0 in memory")
	_check(migrated.state["rng"]==old["rng"] and migrated.state["economy"]==old["economy"] and migrated.state["decisions"]==old["decisions"],"4.8 migration preserves random seed, economy and story consequences")
	var protected_state: String = migrated.export_text()
	var invalid: Dictionary = migrated.state.duplicate(true)
	invalid["life"]["quality_stock"]["wheat"] = 999999.0
	_check(not migrated._valid_state(invalid) and migrated.export_text()==protected_state,"Corrupt premium inventory rejected without altering farm")
	print("FIELDWORK FARMING LIFE 4.9: ",passed," PASS, ",failed," FAIL")
	quit(0 if failed == 0 else 1)
