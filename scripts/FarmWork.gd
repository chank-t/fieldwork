extends RefCounted
## Saved planning data and the public seasonal buying calendar.
const Data = preload("res://scripts/NativeData.gd")
const SEASONAL_ORDERS = [
	{"good":"lettuce", "kg":35.0, "premium":0.0, "buyer":"ines"},
	{"good":"tomato", "kg":45.0, "premium":12.0, "buyer":"clara"},
	{"good":"flour", "kg":40.0, "premium":0.0, "buyer":"bruno"},
	{"good":"cheese", "kg":20.0, "premium":0.0, "buyer":"rosa"}
]
const FIRST_MARKET_DAY := 9
const SEASON_DAYS := 12
const IRRIGATION_TARGETS := [35, 45, 55]

static func totals(state: Dictionary) -> Dictionary:
	return {
		"harvest": float(state["stats"]["harvest_kg"]),
		"revenue": float(state["economy"]["revenue"]),
		"costs": float(state["economy"]["costs"]),
		"water": float(state["hourly_baselines"]["water_out"])
	}

static func initial(state: Dictionary, starter: bool) -> Dictionary:
	return {"starter": "waiting" if starter else "done", "dry_from": 0, "calendar_season": -1,
		"irrigation": {}, "watch": {}, "baseline": totals(state), "last_day": {}}

static func valid(value: Variant, day: int, fields: Array) -> bool:
	if not value is Dictionary:
		return false
	if value.get("starter") not in ["waiting", "offered", "done"]:
		return false
	for key in ["dry_from", "calendar_season"]:
		if not Data.is_json_integer(value.get(key)):
			return false
	if int(value["dry_from"]) < 0 or int(value["dry_from"]) > day + 1:
		return false
	if int(value["calendar_season"]) < -1 or int(value["calendar_season"]) > (day - 1) / SEASON_DAYS:
		return false
	for key in ["baseline", "last_day", "irrigation", "watch"]:
		if not value.get(key) is Dictionary:
			return false
	var owned := {}
	for field in fields:
		if field is Dictionary and field.get("owned") == true:
			owned[str(field.get("id"))] = true
	for id in value["irrigation"]:
		if not owned.has(id) or not Data.is_json_integer(value["irrigation"][id]) or int(value["irrigation"][id]) not in IRRIGATION_TARGETS:
			return false
	for id in value["watch"]:
		var watch_entry: Variant = value["watch"][id]
		if not owned.has(id) or not watch_entry is Dictionary:
			return false
		if not Data.is_json_integer(watch_entry.get("day")) or int(watch_entry["day"]) < 1 or int(watch_entry["day"]) > day:
			return false
		if not Data.is_json_integer(watch_entry.get("pressure")) or int(watch_entry["pressure"]) not in [0, 1, 2]:
			return false
	if not _valid_totals(value["baseline"]):
		return false
	var last: Dictionary = value["last_day"]
	if last.is_empty():
		return true
	return _valid_totals(last) and Data.is_json_integer(last.get("day")) and int(last["day"]) == day - 1

static func _valid_totals(value: Dictionary) -> bool:
	for key in ["harvest", "revenue", "costs", "water"]:
		var amount: Variant = value.get(key)
		if not (amount is float or amount is int) or not is_finite(float(amount)) or float(amount) < 0.0:
			return false
	return true

static func dry_spell(plans: Dictionary, day: int) -> bool:
	var first := int(plans.get("dry_from", 0))
	return first > 0 and day >= first and day < first + 2

static func pest_level(field: Dictionary) -> int:
	if field.get("crop", {}).is_empty():
		return 0
	var peak := 0.0
	for amount in field["pests"].values():
		peak = maxf(peak, float(amount))
	return 2 if peak >= 25.0 else (1 if peak >= 10.0 else 0)
