extends SceneTree
## Run in Godot: godot --headless --path . --script res://tests/world_worth_50_smoke.gd
const Farm = preload("res://scripts/NativeFarm.gd")
const World50 = preload("res://scripts/WorldWorth50.gd")
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
	farm.new_game({"seed":50025,"language":"es","difficulty":"relaxed"})
	_check(int(farm.state["schema"]) == 10,"New native 5.0 save uses schema 7")
	_check(farm.world_catalog["npc_chapters"].size() == 10,"Ten authored neighbour journeys exist")
	var chapter_count: int = 0
	for npc in farm.world_catalog["npc_chapters"].keys():
		chapter_count += farm.world_catalog["npc_chapters"][npc].size()
	_check(chapter_count == 30,"Thirty individually localized neighbour chapters exist")
	_check(farm.season_goal_info().has("stat") and World50.season_key(13) == 1,"Seasonal objective and year progression")
	var baseline: String = farm.export_text()
	_check(not farm.act("completeNpcChapter",{"npcId":"ines","approach":"trade"}).get("ok",false) and farm.export_text()==baseline,"Delivery without supplies is rejected atomically")
	farm.state["inventory"]["wheat"] = 30.0
	var first_wheat: float = farm.stock("wheat")
	var first_cash: float = float(farm.state["economy"]["cash"])
	_check(farm.act("completeNpcChapter",{"npcId":"ines","approach":"share"}).get("ok",false),"Share first neighbour chapter")
	_check(farm.stock("wheat") <= first_wheat-11.99 and float(farm.state["economy"]["cash"]) > first_cash and farm.npc_trust("ines") >= 2,"Delivery consumes goods and awards actual cash and trust")
	_check(int(farm.state["world50"]["npc_chapters"]["ines"]) == 1,"Chapter progress permanently advances")
	var locked: String = farm.export_text()
	_check(not farm.act("completeNpcChapter",{"npcId":"ines","approach":"share"}).get("ok",false) and farm.export_text() == locked,"Neighbour progression cannot be repeated immediately")
	farm.state["events"]["next"] = 99999999
	_check(farm.act("tick",{"hours":24}).get("ok",false),"Next chapter unlocks after a simulated day")
	farm.state["inventory"]["berries"] = 9.0
	_check(farm.act("completeNpcChapter",{"npcId":"ines","approach":"trade"}).get("ok",false),"Second chapter supports a different economic choice")
	_check(farm.state["world50"]["npc_history"].size() == 2,"Neighbour decisions preserve history")
	farm.state["player"]["courses"].append("ecology")
	farm.state["progression"]["tracks"]["ecology"] = 180
	farm.state["stats"]["inspections"] = 7
	_check(World50.certificate_ready(farm.world_catalog,farm.state["world50"],farm.state["stats"],farm.state["player"],farm.state["progression"],"soil_specialist"),"Certification requires real accomplishments")
	_check(farm.act("earnCertificate",{"certificateId":"soil_specialist"}).get("ok",false) and farm.has_certificate("soil_specialist"),"Certificate purchase persists")
	var report: Dictionary = farm.quote("scoutField",{"fieldId":"plot1"})
	_check(report.get("ok",false) and is_equal_approx(float(report["cost"]),9.0),"Certificate modifies actual scouting cost")
	var cert_save: String = farm.export_text()
	_check(not farm.act("earnCertificate",{"certificateId":"soil_specialist"}).get("ok",false) and farm.export_text()==cert_save,"Certificate cannot be claimed twice")
	_check(farm.act("setFarmerLook",{"hair":"braids","outfit":"#365f93"}).get("ok",false),"Wardrobe changes appearance in live player state")
	var wardrobe_snapshot: String = farm.export_text()
	_check(not farm.act("setFarmerLook",{"hair":"invalid","outfit":"#365f93"}).get("ok",false) and farm.export_text()==wardrobe_snapshot,"Invalid wardrobe data leaves save intact")
	var restored: Variant = Farm.new()
	_check(restored.load_text(wardrobe_snapshot).get("ok",false) and restored.export_text()==wardrobe_snapshot,"5.0 neighbour, certificate and wardrobe data survive save/load")
	var festival: Variant = Farm.new()
	festival.new_game({"seed":501,"language":"es","difficulty":"relaxed"})
	festival.state["events"]["next"] = 99999999
	for day in range(8):
		festival.act("tick",{"hours":24})
	_check(int(festival.state["time"]["day"]) == 9 and festival.festival_available(),"Festival opens on seasonal day 9")
	festival.state["inventory"]["lettuce"] = 25.0
	var before_quote: String = festival.export_text()
	_check(festival.quote("festivalEnter",{"category":"produce"}).get("ok",false) and festival.export_text()==before_quote,"Festival quote does not advance RNG or consume stock")
	_check(festival.act("festivalEnter",{"category":"produce"}).get("ok",false),"Season festival accepts a genuine delivery")
	_check(not festival.festival_available() and festival.state["world50"]["festival_history"].size() == 1,"Only one festival entry per season")
	var festival_save: String = festival.export_text()
	_check(not festival.act("festivalEnter",{"category":"produce"}).get("ok",false) and festival.export_text() == festival_save,"Duplicate festival entry is refused atomically")
	festival.state["stats"]["inspections"] = 5
	for day in range(4):
		festival.act("tick",{"hours":24})
	_check(int(festival.state["time"]["season"]) == 1 and festival.state["world50"]["season_results"].size()==1,"Seasonal report generated at transition")
	_check(bool(festival.state["world50"]["season_results"][0]["completed"]),"Goal achieved using recorded seasonal activity")
	var original: Variant = Farm.new()
	original.new_game({"seed":47009})
	original.state["economy"]["cash"] = 5010.0
	var old: Dictionary = original.state.duplicate(true)
	old.erase("world50")
	old["schema"] = 6
	var legacy_text: String = JSON.stringify({"format":"FW_NATIVE_4_9","payload":old,"sha256":original._canonical_json(old).sha256_text()})
	var migrated: Variant = Farm.new()
	_check(migrated.load_text(legacy_text).get("ok",false) and int(migrated.state["schema"])==10,"Unmodified 4.9 save migrates to schema 7")
	_check(float(migrated.state["economy"]["cash"]) == 5010.0 and migrated.state["world50"]["npc_history"].is_empty(),"Migration preserves cash and starts new 5.0 systems safely")
	var corrupt: Dictionary = migrated.state.duplicate(true)
	corrupt["world50"]["certifications"].append("unknown")
	_check(not migrated._valid_state(corrupt),"Corrupt 5.0 certification data rejected")
	print("WORLD WORTH RETURNING TO 5.0: ",passed," PASS / ",failed," FAIL")
	quit(0 if failed == 0 else 1)
