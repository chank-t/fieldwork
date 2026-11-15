extends Control
## Interactive scenic illustration of the farmyard.
## The art is hand-painted concept art; the real farm state stays authoritative
## in NativeFarm.gd and is managed through the live World.gd map.
signal hotspot_selected(kind: String, reference: String)

const ART = preload("res://references/living_farm_visual_reference.png")
const HOTSPOTS = [
	{"kind":"building", "ref":"farmhouse", "point":Vector2(0.52,0.17), "radius":0.080, "en":"Farmhouse", "es":"Casa"},
	{"kind":"building", "ref":"barn", "point":Vector2(0.79,0.16), "radius":0.080, "en":"Barn", "es":"Granero"},
	{"kind":"building", "ref":"greenhouse", "point":Vector2(0.23,0.28), "radius":0.055, "en":"Greenhouse", "es":"Invernadero"},
	{"kind":"building", "ref":"workshop", "point":Vector2(0.10,0.34), "radius":0.055, "en":"Workshop", "es":"Taller"},
	{"kind":"building", "ref":"coop", "point":Vector2(0.69,0.40), "radius":0.060, "en":"Chicken coop", "es":"Gallinero"},
	{"kind":"animal", "ref":"yard", "point":Vector2(0.90,0.42), "radius":0.063, "en":"Animal paddock", "es":"Corral"},
	{"kind":"market", "ref":"market", "point":Vector2(0.80,0.59), "radius":0.069, "en":"Farm shop", "es":"Tienda"},
	{"kind":"npc", "ref":"ines", "point":Vector2(0.38,0.48), "radius":0.040, "en":"Farmer", "es":"Agricultora"},
	{"kind":"field", "ref":"plot1", "point":Vector2(0.34,0.42), "radius":0.052, "en":"Field 1", "es":"Parcela 1"},
	{"kind":"field", "ref":"plot2", "point":Vector2(0.47,0.42), "radius":0.047, "en":"Field 2", "es":"Parcela 2"},
	{"kind":"field", "ref":"plot3", "point":Vector2(0.56,0.43), "radius":0.051, "en":"Field 3", "es":"Parcela 3"},
	{"kind":"field", "ref":"plot4", "point":Vector2(0.34,0.55), "radius":0.045, "en":"Field 4", "es":"Parcela 4"},
	{"kind":"field", "ref":"plot5", "point":Vector2(0.45,0.56), "radius":0.047, "en":"Field 5", "es":"Parcela 5"},
	{"kind":"field", "ref":"plot6", "point":Vector2(0.56,0.56), "radius":0.049, "en":"Field 6", "es":"Parcela 6"},
	{"kind":"field", "ref":"plot7", "point":Vector2(0.33,0.65), "radius":0.045, "en":"Field 7", "es":"Parcela 7"},
	{"kind":"field", "ref":"plot8", "point":Vector2(0.46,0.65), "radius":0.042, "en":"Field 8", "es":"Parcela 8"},
	{"kind":"field", "ref":"plot9", "point":Vector2(0.58,0.65), "radius":0.045, "en":"Field 9", "es":"Parcela 9"}
]

var farm: Variant = null
var elapsed: float = 0.0
var hovered: int = -1
var draw_accum: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func set_farm(value: Variant) -> void:
	farm = value
	queue_redraw()

func _view_rect() -> Rect2:
	if ART == null:
		return Rect2(Vector2.ZERO,size)
	var source: Vector2 = ART.get_size()
	var scale: float = minf(size.x / maxf(1.0,source.x), size.y / maxf(1.0,source.y))
	var painted: Vector2 = source * scale
	return Rect2((size-painted)*0.5,painted)

func _normalized_at(point: Vector2) -> Vector2:
	var bounds: Rect2 = _view_rect()
	return bounds.position + point * bounds.size

func _hotspot_at(pointer: Vector2) -> int:
	var bounds: Rect2 = _view_rect()
	if not bounds.has_point(pointer):
		return -1
	for i in range(HOTSPOTS.size()-1,-1,-1):
		var hotspot: Dictionary = HOTSPOTS[i]
		var center: Vector2 = _normalized_at(hotspot["point"])
		var radius: float = maxf(16.0,float(hotspot["radius"])*bounds.size.x)
		if center.distance_to(pointer)<=radius:
			return i
	return -1

func _hotspot_title(hotspot: Dictionary) -> String:
	var lang: String = "en" if farm==null else str(farm.language)
	var title: String = str(hotspot["es"] if lang=="es" else hotspot["en"])
	if str(hotspot["kind"])=="field" and farm!=null and not farm.state.is_empty():
		var f: Dictionary = farm.field_of(str(hotspot["ref"]))
		if not f.is_empty():
			var status: String = "Owned" if f["owned"] else "For sale"
			if not f["crop"].is_empty():
				status = str(f["crop"]["id"]).capitalize() + "  " + str(int(float(f["crop"].get("development",0.0))*100.0)) + "%"
			title += "  |  " + status
	return title

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("#233d30"))
	if ART==null:
		return
	var bounds: Rect2 = _view_rect()
	draw_texture_rect(ART,bounds,false)
	var hour: int = 12
	if farm!=null and not farm.state.is_empty():
		hour = int(farm.state["time"]["hour"])
	if hour>=19 or hour<6:
		draw_rect(bounds,Color(0.07,0.11,0.24,0.34))
	elif hour>=17:
		draw_rect(bounds,Color(0.30,0.10,0.08,0.10))
	if hovered>=0 and hovered<HOTSPOTS.size():
		var h: Dictionary = HOTSPOTS[hovered]
		var center: Vector2 = _normalized_at(h["point"])
		var radius: float = maxf(16.0,float(h["radius"])*bounds.size.x)
		draw_circle(center,radius,Color(1.0,0.91,0.58,0.18))
		draw_arc(center,radius+3.0,0.0,TAU,36,Color("#fff0b7"),3.0)
		var title: String = _hotspot_title(h)
		var font_size: int = 15
		var font: Font = ThemeDB.fallback_font
		if font!=null:
			var label_width: float = maxf(150.0,float(title.length())*8.2+20.0)
			var tag_pos: Vector2 = center + Vector2(0.0,-radius-17.0)
			var tag: Rect2 = Rect2(tag_pos-Vector2(label_width*0.5,28.0),Vector2(label_width,27.0))
			tag.position.x = clampf(tag.position.x,bounds.position.x+5.0,bounds.end.x-tag.size.x-5.0)
			draw_rect(tag,Color(0.13,0.23,0.17,0.93))
			draw_string(font,tag.position+Vector2(9.0,19.0),title,HORIZONTAL_ALIGNMENT_LEFT,tag.size.x-15.0,font_size,Color("#fff9e5"))
	# Small unobtrusive corner label differentiates art from live crop visuals.
	var font: Font = ThemeDB.fallback_font
	if font!=null:
		var caption: String = "ILLUSTRATED FARM  |  CLICK TO EXPLORE"
		if farm!=null and str(farm.language)=="es":
			caption = "FINCA ILUSTRADA  |  PULSA PARA EXPLORAR"
		var panel: Rect2 = Rect2(bounds.position+Vector2(12.0,12.0),Vector2(365.0,28.0))
		draw_rect(panel,Color(0.13,0.24,0.18,0.70))
		draw_string(font,panel.position+Vector2(10.0,19.0),caption,HORIZONTAL_ALIGNMENT_LEFT,345.0,13,Color("#fdf8e6"))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var next: int = _hotspot_at(event.position)
		if next!=hovered:
			hovered=next
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var index: int = _hotspot_at(event.position)
		if index>=0:
			var hotspot: Dictionary = HOTSPOTS[index]
			hotspot_selected.emit(str(hotspot["kind"]),str(hotspot["ref"]))

func _process(delta: float) -> void:
	elapsed += delta
	draw_accum += delta
	if draw_accum>=0.1 and is_visible_in_tree():
		draw_accum=0.0
		queue_redraw()
