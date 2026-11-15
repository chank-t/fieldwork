extends RefCounted
## Fieldwork 5.0: original bilingual authored content and deterministic reports.
## This module does not alter the simulation or use its random number generator.
const SOURCE: String = "res://data/world_worth_50.json"
const SEASON_KEYS: Array = ["spring", "summer", "autumn", "winter"]
const Data = preload("res://scripts/NativeData.gd")

static func catalog() -> Dictionary:
	return Data.load_dictionary(SOURCE)

static func localized(item: Variant, language: String) -> String:
	if typeof(item) != TYPE_DICTIONARY:
		return str(item)
	return str(item.get(language,item.get("en","")))

static func season_key(day: int) -> int:
	return maxi(0,int((maxi(1,day)-1)/12))

static func season_id(season_index: int) -> String:
	return str(SEASON_KEYS[posmod(season_index,4)])

static func new_state(day: int, stats: Dictionary) -> Dictionary:
	return {"npc_chapters":{},"npc_next_hours":{},"npc_history":[],
		"certifications":[],"festival_history":[],"season_results":[],
		"season_key":season_key(day),"season_snapshot":stats.duplicate(true),"reputation_rewards":0}

static func chapter(data: Dictionary, npc_id: String, chapter_index: int) -> Dictionary:
	var chapters: Array = data.get("npc_chapters",{}).get(npc_id,[])
	if chapter_index < 0 or chapter_index >= chapters.size():
		return {}
	return chapters[chapter_index]

static func goal_progress(data: Dictionary, life: Dictionary, stats: Dictionary) -> float:
	var id: String = season_id(int(life.get("season_key",0)))
	var goal: Dictionary = data.get("season_goals",{}).get(id,{})
	var stat_name: String = str(goal.get("stat",""))
	return maxf(0.0,float(stats.get(stat_name,0.0))-float(life.get("season_snapshot",{}).get(stat_name,0.0)))

static func certificate_ready(data: Dictionary, life: Dictionary, stats: Dictionary, player: Dictionary, progression: Dictionary, id: String) -> bool:
	var certificate: Dictionary = data.get("certifications",{}).get(id,{})
	if certificate.is_empty() or life.get("certifications",[]).has(id):
		return false
	return player.get("courses",[]).has(str(certificate["course"])) and int(progression.get("tracks",{}).get(str(certificate["track"]),0)) >= int(certificate["xp"]) and float(stats.get(str(certificate["stat"]),0.0)) >= float(certificate["target"])

static func festival_rank(score: float) -> String:
	if score >= 82.0:
		return "gold"
	if score >= 64.0:
		return "silver"
	return "participant"
