extends RefCounted
## Read-only content catalog derived from Fieldwork's original authored catalogs.
## Data is JSON. No JavaScript interpreter, Node.js, or WebView is involved.

const FILE = "res://data/catalog.json"
static var _json_cache: Dictionary = {}

static func catalog() -> Dictionary:
	return load_dictionary(FILE)

static func load_dictionary(path: String) -> Dictionary:
	if _json_cache.has(path):
		return _json_cache[path]
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing project data: " + path)
		_json_cache[path] = {}
		return {}
	var decoded: Variant = JSON.parse_string(file.get_as_text())
	if typeof(decoded) != TYPE_DICTIONARY:
		push_error("Project data is not a dictionary: " + path)
		_json_cache[path] = {}
		return {}
	_json_cache[path] = decoded
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
