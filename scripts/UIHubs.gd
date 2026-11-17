extends RefCounted
## Simplified 6-hub navigation replacing 28 sidebar tabs.
## Each hub groups related panels into card-based layouts with icons.

const HUBS = {
	"Farm": {
		"name": {"en": "Farm", "es": "Finca"},
		"icon": "res://assets/icon_farm.png",
		"color": Color("#3f6652"),
		"panels": [
			{"id": "overview", "title": {"en": "Overview", "es": "Resumen"}, "icon": "res://assets/icon_overview.png", "desc": {"en": "Farm status, weather, quick stats", "es": "Estado de la finca, clima, estadísticas rápidas"}},
			{"id": "compass", "title": {"en": "Compass", "es": "Brújula"}, "icon": "res://assets/icon_compass.png", "desc": {"en": "Goals, season progress, mastery tracks", "es": "Metas, progreso de estación, sendas de maestría"}},
			{"id": "explorer", "title": {"en": "Explorer", "es": "Explorador"}, "icon": "res://assets/icon_explorer.png", "desc": {"en": "Full-screen farm, building access, field list", "es": "Finca a pantalla completa, edificios, lista de parcelas"}},
			{"id": "fields_list", "title": {"en": "My Fields", "es": "Mis Parcelas"}, "icon": "res://assets/icon_fields.png", "desc": {"en": "Quick jump to any owned plot", "es": "Acceso rápido a cualquier parcela propia"}},
		]
	},
	"Fields": {
		"name": {"en": "Fields", "es": "Campos"},
		"icon": "res://assets/icon_fields.png",
		"color": Color("#8f7a4b"),
		"panels": [
			{"id": "manage", "title": {"en": "Manage Plot", "es": "Gestionar Parcela"}, "icon": "res://assets/icon_manage.png", "desc": {"en": "Plant, water, harvest, soil actions", "es": "Sembrar, regar, cosechar, acciones de suelo"}},
			{"id": "crop_guide", "title": {"en": "Crop Guide", "es": "Guía de Cultivos"}, "icon": "res://assets/icon_crops.png", "desc": {"en": "All 27 crops with seasons, yields, rotations", "es": "Los 27 cultivos con estaciones, rendimientos, rotaciones"}},
			{"id": "ecology", "title": {"en": "Soil & Pests", "es": "Suelo y Plagas"}, "icon": "res://assets/icon_ecology.png", "desc": {"en": "Soil health, moisture, pests, diseases, treatments", "es": "Salud del suelo, humedad, plagas, enfermedades, tratamientos"}},
			{"id": "planning", "title": {"en": "Daily Plan", "es": "Plan Diario"}, "icon": "res://assets/icon_planning.png", "desc": {"en": "Forecast, soil analysis, rotation suggestions", "es": "Pronóstico, análisis de suelo, sugerencias de rotación"}},
		]
	},
	"Animals": {
		"name": {"en": "Animals", "es": "Animales"},
		"icon": "res://assets/icon_animals.png",
		"color": Color("#b8665a"),
		"panels": [
			{"id": "livestock", "title": {"en": "Livestock", "es": "Ganado"}, "icon": "res://assets/icon_livestock.png", "desc": {"en": "All animals: health, welfare, feeding, production", "es": "Todos los animales: salud, bienestar, alimentación, producción"}},
			{"id": "buildings", "title": {"en": "Buildings", "es": "Edificios"}, "icon": "res://assets/icon_buildings.png", "desc": {"en": "Construct, upgrade, enter farm buildings", "es": "Construir, mejorar, entrar en edificios de la finca"}},
			{"id": "processing", "title": {"en": "Workshop", "es": "Taller"}, "icon": "res://assets/icon_processing.png", "desc": {"en": "Process harvests: flour, oil, cheese, jam, sauces", "es": "Elaborar cosechas: harina, aceite, queso, mermelada, salsas"}},
			{"id": "machinery", "title": {"en": "Machinery", "es": "Maquinaria"}, "icon": "res://assets/icon_machinery.png", "desc": {"en": "Cultivator, pump, harvester, mixer: buy, maintain, efficiency", "es": "Cultivador, bomba, cosechadora, mezcladora: comprar, mantener, eficiencia"}},
		]
	},
	"Village": {
		"name": {"en": "Village", "es": "Pueblo"},
		"icon": "res://assets/icon_village.png",
		"color": Color("#6b7a9e"),
		"panels": [
			{"id": "neighbours", "title": {"en": "Neighbours", "es": "Vecinos"}, "icon": "res://assets/icon_neighbours.png", "desc": {"en": "Talk, help, build trust, unlock perks", "es": "Hablar, ayudar, ganar confianza, desbloquear ventajas"}},
			{"id": "stories", "title": {"en": "Stories", "es": "Historias"}, "icon": "res://assets/icon_stories.png", "desc": {"en": "Village story chains, character arcs, decisions", "es": "Cadenas de historias del pueblo, arcos de personajes, decisiones"}},
			{"id": "community", "title": {"en": "Community", "es": "Comunidad"}, "icon": "res://assets/icon_community.png", "desc": {"en": "Neighbour journeys, festivals, certifications", "es": "Trayectorias vecinales, fiestas, certificaciones"}},
			{"id": "expeditions", "title": {"en": "Expeditions", "es": "Expediciones"}, "icon": "res://assets/icon_expeditions.png", "desc": {"en": "Regional projects, professions, valley regions", "es": "Proyectos regionales, profesiones, regiones del valle"}},
		]
	},
	"Market": {
		"name": {"en": "Market", "es": "Mercado"},
		"icon": "res://assets/icon_market.png",
		"color": Color("#dbb86b"),
		"panels": [
			{"id": "market", "title": {"en": "Market", "es": "Mercado"}, "icon": "res://assets/icon_market.png", "desc": {"en": "Buy/sell goods, contracts, price trends", "es": "Comprar/vender bienes, contratos, tendencias de precios"}},
			{"id": "economy", "title": {"en": "Economy", "es": "Economía"}, "icon": "res://assets/icon_economy.png", "desc": {"en": "Ledger, operating budget, strategy, reputation", "es": "Libro mayor, presupuesto operativo, estrategia, reputación"}},
			{"id": "resources", "title": {"en": "Resources", "es": "Recursos"}, "icon": "res://assets/icon_resources.png", "desc": {"en": "Inventory, storage, gathered materials, decorations", "es": "Inventario, almacenamiento, materiales recogidos, decoraciones"}},
			{"id": "trade", "title": {"en": "Trade", "es": "Comercio"}, "icon": "res://assets/icon_trade.png", "desc": {"en": "Supply orders, delivery contracts, fair trader perks", "es": "Pedidos de suministro, contratos de entrega, ventajas de comerciante justo"}},
		]
	},
	"Me": {
		"name": {"en": "Me", "es": "Yo"},
		"icon": "res://assets/icon_me.png",
		"color": Color("#9b59b6"),
		"panels": [
			{"id": "character", "title": {"en": "Character", "es": "Personaje"}, "icon": "res://assets/icon_character.png", "desc": {"en": "Courses, talents, XP, mastery, avatar", "es": "Cursos, talentos, experiencia, maestría, avatar"}},
			{"id": "wardrobe", "title": {"en": "Wardrobe", "es": "Vestuario"}, "icon": "res://assets/icon_wardrobe.png", "desc": {"en": "Customize farmer appearance, save outfits", "es": "Personalizar apariencia del agricultor, guardar atuendos"}},
			{"id": "story", "title": {"en": "Story", "es": "Historia"}, "icon": "res://assets/icon_story.png", "desc": {"en": "Tutorial, quests, achievements, starter guide", "es": "Tutorial, misiones, logros, guía inicial"}},
			{"id": "journal", "title": {"en": "Journal", "es": "Diario"}, "icon": "res://assets/icon_journal.png", "desc": {"en": "Decision log, events, festival history, stats", "es": "Registro de decisiones, eventos, historial de fiestas, estadísticas"}},
			{"id": "options", "title": {"en": "Settings", "es": "Opciones"}, "icon": "res://assets/icon_options.png", "desc": {"en": "Language, display, audio, saves, accessibility", "es": "Idioma, pantalla, audio, partidas, accesibilidad"}},
		]
	}
}

static func get_hub_order() -> Array[String]:
	return ["Farm", "Fields", "Animals", "Village", "Market", "Me"]

static func get_hub_data(hub_id: String) -> Dictionary:
	return HUBS.get(hub_id, {})

static func get_panel_data(hub_id: String, panel_id: String) -> Dictionary:
	var hub: Dictionary = HUBS.get(hub_id, {})
	for panel in hub.get("panels", []):
		if panel["id"] == panel_id:
			return panel
	return {}

static func find_panel_hub(panel_id: String) -> String:
	for hub_id in HUBS.keys():
		for panel in HUBS[hub_id]["panels"]:
			if panel["id"] == panel_id:
				return hub_id
	return "Farm"

static func get_localized_name(hub_id: String, lang: String) -> String:
	var hub: Dictionary = HUBS.get(hub_id, {})
	var name: Dictionary = hub.get("name", {})
	return str(name.get(lang, name.get("en", hub_id)))

static func get_panel_title(hub_id: String, panel_id: String, lang: String) -> String:
	var panel: Dictionary = get_panel_data(hub_id, panel_id)
	var title: Dictionary = panel.get("title", {})
	return str(title.get(lang, title.get("en", panel_id)))

static func get_panel_desc(hub_id: String, panel_id: String, lang: String) -> String:
	var panel: Dictionary = get_panel_data(hub_id, panel_id)
	var desc: Dictionary = panel.get("desc", {})
	return str(desc.get(lang, desc.get("en", "")))