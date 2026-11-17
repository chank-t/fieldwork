extends RefCounted
## Version 5.3: one allow-listed appearance schema for creation, wardrobe,
## saved presets, field rendering and interior rendering. No gameplay bonuses.
const FIELDS = ["hair", "skin", "outfit", "hair_color", "pants", "boots", "hat", "accessory", "facial_hair", "body", "eyes", "pronouns"]
const PRESET_FIELDS = ["hair", "skin", "outfit", "hair_color", "pants", "boots", "hat", "accessory", "facial_hair", "body", "eyes"]
const OPTIONS = {
	"hair":["crop","waves","braids","bald","curly","pony","bun","long","undercut"],
	"skin":["#f3d1b0","#deb58e","#c78d62","#a66a43","#794b34","#503324","#e3a982","#94654d"],
	"outfit":["#42684b","#c49a41","#ac644c","#4f7d9b","#8b5278","#365f93","#a55c41","#6f548a","#d4a54b","#e6d6ae","#567b75"],
	"hair_color":["#4a342c","#2d2928","#74503a","#ad7948","#d9b06b","#bf6c49","#a8a6a0","#f1e3b9","#743f50"],
	"pants":["#4f584d","#36596e","#6b4c39","#343b47","#9a8363","#606052"],
	"boots":["#614a3a","#292b2c","#936a45","#d2aa70"],
	"hat":["none","straw","cap","beanie","ranger"],
	"accessory":["none","scarf","bandana","glasses","flower","laurel"],
	"facial_hair":["none","stubble","moustache","beard"],
	"body":["regular","compact","broad"],
	"eyes":["#382920","#477f64","#4c7299","#88633c"],
	"pronouns":["they","she","he"]
}
const NAMES = {
	"hair":["Short crop|Corto", "Waves|Ondulado", "Braids|Trenzas", "Bald|Sin pelo", "Curly|Rizado", "Ponytail|Coleta", "Bun|Recogido", "Long|Largo", "Undercut|Degradado"],
	"skin":["Fair|Claro", "Warm beige|Beige cálido", "Golden tan|Bronceado", "Warm brown|Moreno cálido", "Deep brown|Moreno oscuro", "Rich brown|Marrón profundo", "Peach|Melocotón", "Olive|Oliva"],
	"outfit":["Forest green|Verde bosque", "Harvest gold|Oro cosecha", "Brick red|Rojo teja", "River blue|Azul río", "Plum|Ciruela", "Denim|Vaquero", "Terracotta|Terracota", "Violet|Violeta", "Ochre|Ocre", "Linen|Lino", "Sage|Salvia"],
	"hair_color":["Dark brown|Castaño oscuro", "Black|Negro", "Chestnut|Castaño", "Light brown|Castaño claro", "Blonde|Rubio", "Copper|Cobrizo", "Silver|Plateado", "Platinum|Platino", "Aubergine|Berenjena"],
	"pants":["Field green|Verde campo", "Denim|Vaquero", "Earth brown|Marrón tierra", "Charcoal|Carbón", "Canvas|Lona", "Olive|Oliva"],
	"boots":["Leather|Cuero", "Black|Negro", "Tan|Canela", "Sand|Arena"],
	"hat":["None|Ninguno", "Straw hat|Sombrero de paja", "Work cap|Gorra de trabajo", "Beanie|Gorro", "Ranger hat (certificate)|Sombrero explorador (certificado)"],
	"accessory":["None|Ninguno", "Scarf|Bufanda", "Bandana|Pañuelo", "Glasses|Gafas", "Flower|Flor", "Festival laurel (festival)|Laurel festivo (festival)"],
	"facial_hair":["None|Ninguno", "Stubble|Barba corta", "Moustache|Bigote", "Full beard|Barba"],
	"body":["Regular|Normal", "Compact|Compacto", "Broad|Ancho"],
	"eyes":["Brown|Marrones", "Green|Verdes", "Blue|Azules", "Hazel|Avellana"],
	"pronouns":["They/them|Elle", "She/her|Ella", "He/him|Él"]
}

static func defaults() -> Dictionary:
	return {"hair":"crop","skin":"#deb58e","outfit":"#42684b","hair_color":"#4a342c", "pants":"#4f584d","boots":"#614a3a","hat":"none","accessory":"none", "facial_hair":"none","body":"regular","eyes":"#382920","pronouns":"they"}

static func normalize(source: Dictionary) -> Dictionary:
	var answer: Dictionary = defaults()
	for field in FIELDS:
		var candidate: String = str(source.get(field,answer[field]))
		if OPTIONS[field].has(candidate):
			answer[field] = candidate
	return answer

static func valid(source: Dictionary) -> bool:
	for field in FIELDS:
		if not source.has(field) or typeof(source[field]) != TYPE_STRING or not OPTIONS[field].has(source[field]):
			return false
	return true

static func preset(source: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var clean: Dictionary = normalize(source)
	for field in PRESET_FIELDS:
		result[field] = clean[field]
	return result

static func valid_preset(source: Dictionary) -> bool:
	if source.is_empty():
		return true
	for field in PRESET_FIELDS:
		if not source.has(field) or typeof(source[field]) != TYPE_STRING or not OPTIONS[field].has(source[field]):
			return false
	return true

static func new_wardrobe() -> Dictionary:
	return {"presets":[{},{},{}]}

static func unlocked(field: String, value: String, game_state: Dictionary) -> bool:
	if field == "hat" and value == "ranger":
		return game_state.get("world50",{}).get("certifications",[]).size() > 0
	if field == "accessory" and value == "laurel":
		return game_state.get("world50",{}).get("festival_history",[]).size() > 0
	return true

static func available(field: String, game_state: Dictionary) -> Array:
	var result: Array = []
	for id in OPTIONS.get(field,[]):
		if unlocked(field,str(id),game_state):
			result.append(id)
	return result

static func display_name(field: String, id: String, spanish: bool) -> String:
	var options: Array = OPTIONS.get(field,[])
	var index: int = options.find(id)
	if index < 0:
		return id
	var names: Array = NAMES.get(field,[])
	if index >= names.size():
		return id
	var parts: PackedStringArray = str(names[index]).split("|")
	return parts[1] if spanish and parts.size() > 1 else parts[0]

static func allowed_in_state(appearance: Dictionary, game_state: Dictionary) -> bool:
	if not valid(appearance):
		return false
	for field in FIELDS:
		if not unlocked(field,str(appearance[field]),game_state):
			return false
	return true
