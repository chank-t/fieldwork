extends RefCounted
## Pure authored bilingual event content. The native simulation executes actions.
const SOURCE = "res://data/decisions.json"
const Data = preload("res://scripts/NativeData.gd")

static func catalog() -> Dictionary:
	return Data.load_dictionary(SOURCE)

static func localized(value: Variant, lang: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return str(value)
	return str(value.get(lang, value.get("en", "")))

static func title(event_id: String, lang: String = "en") -> String:
	return localized(Data.load_dictionary(SOURCE).get(event_id, {}).get("title", {"en":event_id}), lang)

static func description(event_id: String, lang: String = "en") -> String:
	return localized(Data.load_dictionary(SOURCE).get(event_id, {}).get("description", {"en":""}), lang)

static func options(event_id: String, lang: String = "en") -> Array:
	var result: Array = []
	for item in Data.load_dictionary(SOURCE).get(event_id, {}).get("options", []):
		result.append({"id":str(item["id"]), "text":localized(item["title"],lang),
			"effect":localized(item["effect"],lang), "risk":localized(item["risk"],lang)})
	return result
