extends RefCounted
## Read-only content catalog derived from Fieldwork's original authored catalogs.
## Data is JSON. No JavaScript interpreter, Node.js, or WebView is involved.

const FILE = "res://data/catalog.json"

static func catalog() -> Dictionary:
	var file = FileAccess.open(FILE, FileAccess.READ)
	if file == null:
		push_error("Missing native catalog: " + FILE)
		return {}
	var decoded: Variant = JSON.parse_string(file.get_as_text())
	if typeof(decoded) != TYPE_DICTIONARY:
		push_error("Native catalog is not a dictionary")
		return {}
	return decoded

static func name_of(entry: Variant, lang: String = "en", key: String = "name") -> String:
	if typeof(entry) != TYPE_DICTIONARY:
		return str(entry)
	var value: Variant = entry.get(key, entry)
	if typeof(value) == TYPE_DICTIONARY:
		return str(value.get(lang, value.get("en", "?")))
	return str(value)

static func money(amount: float) -> float:
	return round(amount * 100.0) / 100.0

static func clamp01(value: float) -> float:
	return clampf(value, 0.0, 1.0)
