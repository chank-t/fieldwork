extends SceneTree
## Native engine test for Fieldwork 4.8 (not merely a source check).
## Run: godot --headless --path . --script res://tests/story_48_smoke.gd
const Farm = preload("res://scripts/NativeFarm.gd")
const Chains = preload("res://scripts/ChoiceChains.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_test")

func _check(condition: bool, title: String) -> void:
	if condition:
		passed += 1
		print("PASS ", title)
	else:
		failed += 1
		push_error("FAIL " + title)

func _advance_to_event(farm: Variant, maximum_hours: int = 360) -> void:
	for i in range(maximum_hours):
		if not farm.state["events"]["active"].is_empty():
			return
		var response: Dictionary = farm.act("tick",{"hours":1})
		if not response.get("ok",false):
			return

func _test() -> void:
	var content: Dictionary = Chains.catalog()
	_check(content["arcs"].size() == 6,"Six linked story arcs")
	_check(content["stages"].size() == 12,"Twelve additional chapters")
	var options: int = 0
	for chapter in content["stages"].values():
		options += chapter["options"].size()
	_check(options == 36,"Thirty-six authored responses")
	var farm: Variant = Farm.new()
	farm.new_game({"seed":47291,"name":"Alex","farm":"The Valley","language":"es"})
	_check(int(farm.state["schema"]) == 10,"Existing 4.8 story engine retained with schema 7")
	_check(farm.owned_count() == 1 and farm.content["crops"].size() == 27,"4.7 crops and starting field preserved")
	var initial: String = farm.export_text()
	var quote: Dictionary = farm.quote("inviteStory",{"arcId":"water"})
	_check(quote.get("ok",false) and float(quote["cost"]) == 20.0,"Village invitation costs exactly 20 euros")
	_check(farm.export_text() == initial,"Quoting a village invitation is read-only")
	var invited: Dictionary = farm.act("inviteStory",{"arcId":"water"})
	_check(invited.get("ok",false) and str(farm.state["events"]["active"]["id"]) == "irrigation_cooperative","Invitation opens original irrigation event")
	var pending: String = farm.export_text()
	var second_invite: Dictionary = farm.act("inviteStory",{"arcId":"soil"})
	_check(not second_invite.get("ok",false) and farm.export_text() == pending,"Conflicting invitations rejected atomically")
	var root: Dictionary = farm.act("eventChoice",{"choice":"join"})
	_check(root.get("ok",false),"Original event still resolves through native action")
	_check(farm.npc_trust("mateo") == 2,"Initial choice changes Mateo relationship")
	_check(farm.pending_story_events().size() == 1,"First delayed chapter scheduled")
	var migrated_copy: Variant = Farm.new()
	var snapshot: String = farm.export_text()
	_check(migrated_copy.load_text(snapshot).get("ok",false) and migrated_copy.state == JSON.parse_string(snapshot)["payload"],"4.8 save round-trip preserves delayed chapter")
	farm.state["events"]["next"] = 99999999
	_advance_to_event(farm,120)
	_check(str(farm.state["events"]["active"].get("id","")) == "water_vote","Delayed chapter opens at the correct time")
	var before_invalid: String = farm.export_text()
	var invalid: Dictionary = farm.act("eventChoice",{"choice":"invented_choice"})
	_check(not invalid.get("ok",false) and farm.export_text() == before_invalid,"Unknown storyline choice does not alter resources or RNG")
	var advice_quote: Dictionary = farm.quote("eventResearch",{})
	_check(advice_quote.get("ok",false) and float(advice_quote.get("cost",0.0)) == 18.0,"Consulting a neighbour is a quoted action")
	_check(farm.export_text() == before_invalid,"Quote does not reveal or alter random outcome")
	var prior_rng: int = int(farm.state["rng"])
	var advice: Dictionary = farm.act("eventResearch",{})
	_check(advice.get("ok",false) and int(farm.state["rng"]) == prior_rng,"Research costs money but draws no random result")
	_check(is_equal_approx(farm.option_probability("water_vote","test"),0.75),"Research improves uncertain odds by ten percentage points")
	var after_advice: String = farm.export_text()
	var risky_a: Variant = Farm.new()
	var risky_b: Variant = Farm.new()
	_check(risky_a.load_text(after_advice).get("ok",false) and risky_b.load_text(after_advice).get("ok",false),"Both replay farms restore the same pending decision")
	var trial_a: Dictionary = risky_a.act("eventChoice",{"choice":"test"})
	var trial_b: Dictionary = risky_b.act("eventChoice",{"choice":"test"})
	_check(trial_a.get("ok",false) and trial_b.get("ok",false) and risky_a.export_text() == risky_b.export_text(),"Uncertain outcome is deterministic for the saved seed")
	_check(risky_a.state["decisions"]["history"].back().has("result"),"Outcome and cash/relationship changes recorded")
	var decided: Dictionary = farm.act("eventChoice",{"choice":"sensors"})
	_check(decided.get("ok",false) and farm.npc_trust("mateo") == 4,"Funding sensors unlocks trusted-neighbour relationship")
	_check(farm.pending_story_events().size() == 1,"Second chapter scheduled after first resolution")
	var trusting: String = farm.talk("mateo","relationship")
	_check(trusting.contains("confianza") and trusting.contains("4/10"),"Neighbour comments reflect actual trust in Spanish")
	_advance_to_event(farm,180)
	_check(str(farm.state["events"]["active"].get("id","")) == "water_audit","Second chapter opens later")
	var final_choice: Dictionary = farm.act("eventChoice",{"choice":"maintain"})
	_check(final_choice.get("ok",false),"Final chapter accepts costed maintenance decision")
	_check(str(farm.state["decisions"]["branches"]["water"]["status"]) == "completed","Water storyline reaches completed state")
	_check(farm.pending_story_events().is_empty(),"Completed storyline schedules no duplicate follow-ups")
	_check(farm.npc_trust("mateo") == 6,"Two later decisions build lasting trust")
	_check(farm._effect("water_saver") > 0.13,"Existing irrigation equations receive real story bonus")
	var last_json: String = farm.export_text()
	var restored: Variant = Farm.new()
	_check(restored.load_text(last_json).get("ok",false) and restored.export_text() == last_json,"Completed stories and consequences persist losslessly")
	# Build an authentic 4.7-format envelope from an isolated clean state.
	var legacy_source: Variant = Farm.new()
	legacy_source.new_game({"seed":77123,"language":"en"})
	legacy_source.state["economy"]["cash"] = 1234.56
	var old: Dictionary = legacy_source.state.duplicate(true)
	old["schema"] = 4
	for key in ["branches","followups","relationships","relationship_history","clues","last_invitation_hour"]:
		old["decisions"].erase(key)
	var legacy_text: String = JSON.stringify({"format":"FW_NATIVE_4_5","payload":old,"sha256":legacy_source._canonical_json(old).sha256_text()})
	var upgraded: Variant = Farm.new()
	_check(upgraded.load_text(legacy_text).get("ok",false) and int(upgraded.state["schema"]) == 10,"Authentic 4.7 envelope migrates to schema 6")
	var previous_field_data_preserved: bool = true
	for index in range(old["fields"].size()):
		var before: Dictionary = old["fields"][index]
		var after: Dictionary = upgraded.state["fields"][index]
		for key in before.keys():
			if key == "soil":
				for soil_key in before["soil"].keys():
					if after["soil"].get(soil_key) != before["soil"][soil_key]:
						previous_field_data_preserved = false
			elif before[key] != after.get(key):
				previous_field_data_preserved = false
	_check(is_equal_approx(float(upgraded.state["economy"]["cash"]),1234.56) and previous_field_data_preserved and upgraded.state["rng"] == old["rng"],"Migration preserves original cash, historic field values and RNG")
	_check(upgraded.state["decisions"]["branches"].is_empty() and upgraded.state["decisions"]["followups"].is_empty(),"Migration does not invent relationships or unfinished stories")
	# Protected test-only save, never the player's real autosave file.
	var fixture: String = "user://fieldwork_48_qa/story48.json"
	var first: Dictionary = upgraded._protected_write(fixture,upgraded.export_text())
	_check(first.get("ok",false) and FileAccess.file_exists(fixture),"Verified temporary v4.8 save written")
	_check(upgraded._verified_envelope(FileAccess.get_file_as_string(fixture)),"Temporary save validates the checksum")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture))
	print("FIELDWORK 4.8 STORY SMOKE: ",passed," PASS, ",failed," FAIL")
	quit(0 if failed == 0 else 1)
