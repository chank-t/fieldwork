extends RefCounted
## Simplified 6-hub navigation replacing 28 sidebar tabs.
## Each hub groups related panels into card-based layouts with icons.

const HUBS = {
	"Farm": {
		"name": {"en": "Farm", "es": "Finca"},
		"icon": "res://assets/icons/hubs/icon_farm.svg",
		"color": Color("#3f6652"),
		"panels": [
			{"id": "overview", "title": {"en": "Overview", "es": "Resumen"}, "icon": "res://assets/icons/panels/icon_overview.svg", "desc": {"en": "Farm status, weather, quick stats", "es": "Estado de la finca, clima, estadísticas rápidas"}},
			{"id": "compass", "title": {"en": "Compass", "es": "Brújula"}, "icon": "res://assets/icons/panels/icon_compass.svg", "desc": {"en": "Goals, season progress, mastery tracks", "es": "Metas, progreso de estación, sendas de maestría"}},
			{"id": "explorer", "title": {"en": "Explorer", "es": "Explorador"}, "icon": "res://assets/icons/panels/icon_explorer.svg", "desc": {"en": "Full-screen farm, building access, field list", "es": "Finca a pantalla completa, edificios, lista de parcelas"}},
			{"id": "fields_list", "title": {"en": "My Fields", "es": "Mis Parcelas"}, "icon": "res://assets/icons/panels/icon_fields_list.svg", "desc": {"en": "Quick jump to any owned plot", "es": "Acceso rápido a cualquier parcela propia"}},
		]
	},
	"Fields": {
		"name": {"en": "Fields", "es": "Campos"},
		"icon": "res://assets/icons/hubs/icon_fields.svg",
		"color": Color("#8f7a4b"),
		"panels": [
			{"id": "manage", "title": {"en": "Manage Plot", "es": "Gestionar Parcela"}, "icon": "res://assets/icons/panels/icon_manage.svg", "desc": {"en": "Plant, water, harvest, soil actions", "es": "Sembrar, regar, cosechar, acciones de suelo"}},
			{"id": "crop_guide", "title": {"en": "Crop Guide", "es": "Guía de Cultivos"}, "icon": "res://assets/icons/panels/icon_crops.svg", "desc": {"en": "All 27 crops with seasons, yields, rotations", "es": "Los 27 cultivos con estaciones, rendimientos, rotaciones"}},
			{"id": "ecology", "title": {"en": "Soil & Pests", "es": "Suelo y Plagas"}, "icon": "res://assets/icons/panels/icon_ecology.svg", "desc": {"en": "Soil health, moisture, pests, diseases, treatments", "es": "Salud del suelo, humedad, plagas, enfermedades, tratamientos"}},
			{"id": "planning", "title": {"en": "Daily Plan", "es": "Plan Diario"}, "icon": "res://assets/icons/panels/icon_planning.svg", "desc": {"en": "Forecast, soil analysis, rotation suggestions", "es": "Pronóstico, análisis de suelo, sugerencias de rotación"}},
		]
	},
	"Animals": {
		"name": {"en": "Animals", "es": "Animales"},
		"icon": "res://assets/icons/hubs/icon_animals.svg",
		"color": Color("#b8665a"),
		"panels": [
			{"id": "livestock", "title": {"en": "Livestock", "es": "Ganado"}, "icon": "res://assets/icons/panels/icon_livestock.svg", "desc": {"en": "All animals: health, welfare, feeding, production", "es": "Todos los animales: salud, bienestar, alimentación, producción"}},
			{"id": "buildings", "title": {"en": "Buildings", "es": "Edificios"}, "icon": "res://assets/icons/panels/icon_buildings.svg", "desc": {"en": "Construct, upgrade, enter farm buildings", "es": "Construir, mejorar, entrar en edificios de la finca"}},
			{"id": "processing", "title": {"en": "Workshop", "es": "Taller"}, "icon": "res://assets/icons/panels/icon_processing.svg", "desc": {"en": "Process harvests: flour, oil, cheese, jam, sauces", "es": "Elaborar cosechas: harina, aceite, queso, mermelada, salsas"}},
			{"id": "machinery", "title": {"en": "Machinery", "es": "Maquinaria"}, "icon": "res://assets/icons/panels/icon_machinery.svg", "desc": {"en": "Cultivator, pump, harvester, mixer: buy, maintain, efficiency", "es": "Cultivador, bomba, cosechadora, mezcladora: comprar, mantener, eficiencia"}},
		]
	},
	"Village": {
		"name": {"en": "Village", "es": "Pueblo"},
		"icon": "res://assets/icons/hubs/icon_village.svg",
		"color": Color("#6b7a9e"),
		"panels": [
			{"id": "neighbours", "title": {"en": "Neighbours", "es": "Vecinos"}, "icon": "res://assets/icons/panels/icon_neighbours.svg", "desc": {"en": "Talk, help, build trust, unlock perks", "es": "Hablar, ayudar, ganar confianza, desbloquear ventajas"}},
			{"id": "stories", "title": {"en": "Stories", "es": "Historias"}, "icon": "res://assets/icons/panels/icon_stories.svg", "desc": {"en": "Village story chains, character arcs, decisions", "es": "Cadenas de historias del pueblo, arcos de personajes, decisiones"}},
			{"id": "community", "title": {"en": "Community", "es": "Comunidad"}, "icon": "res://assets/icons/panels/icon_community.svg", "desc": {"en": "Neighbour journeys, festivals, certifications", "es": "Trayectorias vecinales, fiestas, certificaciones"}},
			{"id": "expeditions", "title": {"en": "Expeditions", "es": "Expediciones"}, "icon": "res://assets/icons/panels/icon_expeditions.svg", "desc": {"en": "Regional projects, professions, valley regions", "es": "Proyectos regionales, profesiones, regiones del valle"}},
		]
	},
	"Market": {
		"name": {"en": "Market", "es": "Mercado"},
		"icon": "res://assets/icons/hubs/icon_market.svg",
		"color": Color("#dbb86b"),
		"panels": [
			{"id": "market", "title": {"en": "Market", "es": "Mercado"}, "icon": "res://assets/icons/panels/icon_market_panel.svg", "desc": {"en": "Buy/sell goods, contracts, price trends", "es": "Comprar/vender bienes, contratos, tendencias de precios"}},
			{"id": "economy", "title": {"en": "Economy", "es": "Economía"}, "icon": "res://assets/icons/panels/icon_economy.svg", "desc": {"en": "Ledger, operating budget, strategy, reputation", "es": "Libro mayor, presupuesto operativo, estrategia, reputación"}},
			{"id": "resources", "title": {"en": "Resources", "es": "Recursos"}, "icon": "res://assets/icons/panels/icon_resources.svg", "desc": {"en": "Inventory, storage, gathered materials, decorations", "es": "Inventario, almacenamiento, materiales recogidos, decoraciones"}},
			{"id": "trade", "title": {"en": "Trade", "es": "Comercio"}, "icon": "res://assets/icons/panels/icon_trade.svg", "desc": {"en": "Supply orders, delivery contracts, fair trader perks", "es": "Pedidos de suministro, contratos de entrega, ventajas de comerciante justo"}},
		]
	},
	"Me": {
		"name": {"en": "Me", "es": "Yo"},
		"icon": "res://assets/icons/hubs/icon_me.svg",
		"color": Color("#9b59b6"),
		"panels": [
			{"id": "character", "title": {"en": "Character", "es": "Personaje"}, "icon": "res://assets/icons/panels/icon_character.svg", "desc": {"en": "Courses, talents, XP, mastery, avatar", "es": "Cursos, talentos, experiencia, maestría, avatar"}},
			{"id": "wardrobe", "title": {"en": "Wardrobe", "es": "Vestuario"}, "icon": "res://assets/icons/panels/icon_wardrobe.svg", "desc": {"en": "Customize farmer appearance, save outfits", "es": "Personalizar apariencia del agricultor, guardar atuendos"}},
			{"id": "story", "title": {"en": "Story", "es": "Historia"}, "icon": "res://assets/icons/panels/icon_story.svg", "desc": {"en": "Tutorial, quests, achievements, starter guide", "es": "Tutorial, misiones, logros, guía inicial"}},
			{"id": "journal", "title": {"en": "Journal", "es": "Diario"}, "icon": "res://assets/icons/panels/icon_journal.svg", "desc": {"en": "Decision log, events, festival history, stats", "es": "Registro de decisiones, eventos, historial de fiestas, estadísticas"}},
			{"id": "options", "title": {"en": "Settings", "es": "Opciones"}, "icon": "res://assets/icons/panels/icon_options.svg", "desc": {"en": "Language, display, audio, saves, accessibility", "es": "Idioma, pantalla, audio, partidas, accesibilidad"}},
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