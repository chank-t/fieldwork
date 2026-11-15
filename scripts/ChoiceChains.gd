extends RefCounted
## 4.8 authored multi-step storylines. No RNG or farm mutations in this file.
const SOURCE: String = "res://data/event_chains_48.json"
const Data = preload("res://scripts/NativeData.gd")

static func catalog() -> Dictionary:
	return Data.load_dictionary(SOURCE)

static func localized(value: Variant, lang: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return str(value)
	return str(value.get(lang, value.get("en", "")))

static func root_arc(event_id: String) -> String:
	var arcs: Dictionary = Data.load_dictionary(SOURCE).get("arcs",{})
	for arc_id in arcs:
		var arc_data: Dictionary = arcs[arc_id]
		if str(arc_data.get("root", "")) == event_id:
			return str(arc_id)
	return ""

static func arc(arc_id: String) -> Dictionary:
	return Data.load_dictionary(SOURCE).get("arcs",{}).get(arc_id,{})

static func stage(stage_id: String) -> Dictionary:
	return Data.load_dictionary(SOURCE).get("stages",{}).get(stage_id,{})

static func title(stage_id: String, lang: String) -> String:
	return localized(stage(stage_id).get("title", {"en":stage_id}),lang)

static func description(stage_id: String, lang: String) -> String:
	return localized(stage(stage_id).get("description", {"en":""}),lang)

static func arc_name(arc_id: String, lang: String) -> String:
	return localized(arc(arc_id).get("name",{"en":arc_id}),lang)

static func options(stage_id: String, lang: String) -> Array:
	var result: Array = []
	for opt in stage(stage_id).get("options",[]):
		result.append({"id":str(opt["id"]),"text":localized(opt["title"],lang),
			"effect":localized(opt["effect"],lang),"risk":localized(opt["risk"],lang),
			"chance":float(opt.get("chance",1.0))})
	return result

static func option(stage_id: String, option_id: String) -> Dictionary:
	for opt in stage(stage_id).get("options",[]):
		if str(opt.get("id","")) == option_id:
			return opt
	return {}
