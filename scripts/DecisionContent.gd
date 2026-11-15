extends RefCounted
## Pure authored bilingual event content. The native simulation executes actions.
const SOURCE = "res://data/decisions.json"

static func catalog() -> Dictionary:
	var file: FileAccess = FileAccess.open(SOURCE, FileAccess.READ)
	if file == null:
		push_error("Missing bilingual decisions catalog")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func localized(value: Variant, lang: String) -> String:
	if typeof(value) != TYPE_DICTIONARY:
		return str(value)
	return str(value.get(lang, value.get("en", "")))

static func title(event_id: String, lang: String = "en") -> String:
	return localized(catalog().get(event_id, {}).get("title", {"en":event_id}), lang)

static func description(event_id: String, lang: String = "en") -> String:
	return localized(catalog().get(event_id, {}).get("description", {"en":""}), lang)

static func options(event_id: String, lang: String = "en") -> Array:
	var result: Array = []
	for item in catalog().get(event_id, {}).get("options", []):
		result.append({"id":str(item["id"]), "text":localized(item["title"],lang),
			"effect":localized(item["effect"],lang), "risk":localized(item["risk"],lang)})
	return result
