extends Control
const Performance59 = preload("res://scripts/PerformanceAccessibility.gd")
## Valley map: travel destinations are chosen here; no simulation advances while viewing.
signal region_selected(region_id: String)
const Country54 = preload("res://scripts/LivingCountryside.gd")
const Beyond58 = preload("res://scripts/BeyondFarm.gd")

const LOCATIONS = [
	{"id":"village", "xy":Vector2(0.52,0.42), "label":"WILLOW VILLAGE", "label_es":"VILLA SAUCE", "color":"#e8c993", "icon":"building_market"},
	{"id":"river", "xy":Vector2(0.24,0.49), "label":"SILVER RIVER", "label_es":"RIO PLATEADO", "color":"#9edcd1", "icon":"water"},
	{"id":"woods", "xy":Vector2(0.18,0.23), "label":"MOSSWOOD", "label_es":"BOSQUE DEL MUSGO", "color":"#76a277", "icon":"tree"},
	{"id":"hills", "xy":Vector2(0.79,0.21), "label":"GOLDEN HILLS", "label_es":"COLINAS DORADAS", "color":"#cbb98f", "icon":"rock"},
	{"id":"marsh", "xy":Vector2(0.25,0.79), "label":"REED MARSH", "label_es":"HUMEDAL DE JUNCOS", "color":"#8daf98", "icon":"reed"},
	{"id":"orchard", "xy":Vector2(0.76,0.73), "label":"OLD ORCHARD", "label_es":"HUERTO ANTIGUO", "color":"#acc28e", "icon":"crop_pumpkin"},
	{"id":"lake", "xy":Vector2(0.88,0.51), "label":"BLUEWATER LAKE", "label_es":"LAGO AZUL", "color":"#99ccd7", "icon":"region_lake"},
	{"id":"quarry", "xy":Vector2(0.56,0.13), "label":"OLD STONE QUARRY", "label_es":"CANTERA VIEJA", "color":"#c8b39a", "icon":"region_quarry"}
]

var farm: Variant = null
var selected: String = "village"
var art: Dictionary = {}
var elapsed: float = 0.0
var redraw_accum59: float = 0.0
var performance_mode59: String = "balanced"
var reduced_motion59: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for id in ["building_market","water","tree","rock","reed","crop_pumpkin","grass_flowers", "flower_patch","region_lake","region_quarry"]:
		var path: String = "res://assets/" + id + ".png"
		if ResourceLoader.exists(path):
			art[id] = load(path)

func set_farm(value: Variant) -> void:
	farm = value
	queue_redraw()

func set_selected(value: String) -> void:
	selected = value
	queue_redraw()

func _label(label: String, pos: Vector2, color: Color, font_size: int = 14, width: float = -1.0) -> void:
	if ThemeDB.fallback_font != null:
		draw_string(ThemeDB.fallback_font,pos,label,HORIZONTAL_ALIGNMENT_CENTER,width,font_size,color)

func _text_width(label: String, font_size: int) -> float:
	return maxf(66.0, float(label.length()) * (float(font_size) * 0.68))

func _draw_tag(label: String, pos: Vector2, active: bool = false) -> void:
	var width: float = _text_width(label, 12)
	var rect: Rect2 = Rect2(pos - Vector2(width * 0.5, 12.0), Vector2(width, 24.0))
	draw_rect(rect.grow(1.0), Color(0.11,0.18,0.14,0.16))
	draw_rect(rect, Color("#fff7df") if active else Color(0.98,0.99,0.96,0.88))
	_label(label, rect.position + Vector2(rect.size.x * 0.5, 17.0), Color("#2d5642"), 12, width)

func _lang_label(loc: Dictionary) -> String:
	var lang: String = "en" if farm == null else str(farm.language)
	return str(loc["label_es"] if lang == "es" else loc["label"])

func _draw_background(bounds: Rect2) -> void:
	draw_rect(bounds,Color("#e7edd1"))
	for y in range(0,52):
		var yy: float = float(y) / 52.0 * size.y
		var tint: float = float(y) / 51.0
		draw_rect(Rect2(Vector2(0,yy),Vector2(size.x,size.y/52.0+1.0)),Color("#bfd8ab").lerp(Color("#efe4bf"),tint*0.72))
	for i in range(14):
		var xx: float = float(i) / 13.0 * size.x
		var ht: float = 0.10 + sin(float(i)*1.22)*0.035
		draw_circle(Vector2(xx,size.y*ht),size.y*0.18,Color("#8bac8c"))
	# quilt-like meadow plots near the village
	var quilt: Array = [
		Rect2(size * Vector2(0.40,0.30), size * Vector2(0.10,0.09)),
		Rect2(size * Vector2(0.51,0.28), size * Vector2(0.11,0.10)),
		Rect2(size * Vector2(0.40,0.41), size * Vector2(0.10,0.08)),
		Rect2(size * Vector2(0.52,0.40), size * Vector2(0.12,0.08)),
		Rect2(size * Vector2(0.47,0.51), size * Vector2(0.14,0.08))
	]
	var quilt_colors: Array = [Color("#d4d08a"), Color("#b7d288"), Color("#c6bf76"), Color("#a8cb99"), Color("#c9d89d")]
	for i in range(quilt.size()):
		draw_rect(quilt[i], quilt_colors[i % quilt_colors.size()])
		draw_rect(quilt[i].grow(-2.0), quilt_colors[i % quilt_colors.size()].lightened(0.05), false, 1.0)
	# decorative flower bands and orchard hints
	for i in range(7):
		var flower_pos: Vector2 = size * Vector2(0.63 + 0.035 * float(i), 0.66 + 0.02 * sin(float(i)))
		draw_circle(flower_pos, 5.0, Color("#d86c8d"))
		draw_circle(flower_pos + Vector2(3.0,2.0), 4.0, Color("#ffcf6d"))
	for i in range(5):
		var orchard_tree: Vector2 = size * Vector2(0.69 + 0.032 * float(i), 0.76 - 0.025 * float(i % 2))
		draw_circle(orchard_tree, 13.0, Color("#89b06e"))
		draw_rect(Rect2(orchard_tree + Vector2(-1.4,10.0), Vector2(2.8,8.5)), Color("#7d5938"))
	# flowing blue river with a bright glimmer
	var points: PackedVector2Array = PackedVector2Array()
	for i in range(72):
		var yy: float = float(i)/71.0*size.y
		var xx: float = size.x*(0.28 + sin(float(i)*0.20)*0.078)
		points.append(Vector2(xx,yy))
	draw_polyline(points,Color("#6db6c2"),maxf(15.0,size.x*0.07),true)
	draw_polyline(points,Color("#c9f0ed"),maxf(3.0,size.x*0.010),true)
	var shimmer_y: float = fmod(elapsed * 80.0, size.y + 120.0) - 60.0
	draw_circle(Vector2(size.x * 0.27, shimmer_y), 11.0, Color(1.0,1.0,1.0,0.26))
	# walking roads and travel dots from the village
	var village: Vector2 = Vector2(size.x*0.52,size.y*0.42)
	for loc in LOCATIONS:
		if str(loc["id"]) == "village":
			continue
		var point: Vector2 = loc["xy"]
		var pos: Vector2 = Vector2(point.x * size.x,point.y*size.y)
		draw_line(village,pos,Color("#ddd0a7"),maxf(7.0,size.x*0.012),true)
		draw_line(village,pos,Color("#b59f77"),1.2,true)
		for step in range(1,6):
			var t: float = float(step) / 6.0
			var bead: Vector2 = village.lerp(pos,t)
			draw_circle(bead,2.2,Color(1.0,0.98,0.90,0.75))
	# ambient valley texture
	for i in range(34):
		var p: Vector2 = Vector2(float((i*43+17)%97)/97.0*size.x,float((i*29+23)%101)/101.0*size.y)
		var r: float = 8.0 + float(i%3)*3.0
		draw_circle(p,r,Color(0.25,0.43,0.29,0.10))

func _draw_location(loc: Dictionary) -> void:
	var p: Vector2 = Vector2(loc["xy"].x*size.x,loc["xy"].y*size.y)
	var active: bool = str(loc["id"]) == selected
	var pulse: float = 1.0 + (0.10 * sin(elapsed * 3.0)) if active else 1.0
	var radius: float = maxf(26.0,minf(size.x,size.y)*(0.054 if not active else 0.060)) * pulse
	draw_circle(p+Vector2(0,5),radius+5.0,Color(0.15,0.27,0.20,0.22))
	if active:
		draw_arc(p, radius + 10.0, 0.0, TAU, 36, Color("#fff6d6"), 4.0)
	draw_circle(p,radius+4.0,Color("#f4e7bd") if active else Color("#f9f6e6"))
	draw_circle(p,radius,Color(str(loc["color"])))
	var icon: String = str(loc["icon"])
	if art.has(icon):
		var s: float = radius * 1.60
		draw_texture_rect(art[icon],Rect2(p-Vector2(s/2,s/2),Vector2(s,s)),false)
	var label_offset: Vector2 = Vector2(0.0, radius + 24.0)
	if str(loc["id"]) in ["marsh","orchard"]:
		label_offset = Vector2(0.0, -radius - 20.0)
	_draw_tag(_lang_label(loc), p + label_offset, active)
	if farm != null and not farm.state.is_empty():
		var visits: int = int(farm.state["overworld"]["visits"].get(str(loc["id"]),0))
		if visits > 0:
			_draw_tag("x" + str(visits), p + Vector2(radius + 20.0, -radius - 12.0), active)

func _draw_countryside54() -> void:
	if farm == null or farm.state.is_empty():
		return
	var day: int = int(farm.state["time"]["day"])
	var hour: int = int(farm.state["time"]["hour"])
	var discoveries: Array = farm.state.get("countryside54",{}).get("discovered",[])
	for region in LOCATIONS:
		var region_id: String = str(region["id"])
		var center: Vector2 = Vector2(region["xy"].x * size.x,region["xy"].y * size.y)
		var villagers: Array = Country54.villagers_at(region_id,day,hour)
		# Four readable marker dots per region, plus a numeric total.
		for marker_index in range(mini(4,villagers.size())):
			var dot: Vector2 = center + Vector2(-29.0 + float(marker_index)*18.0,-42.0)
			draw_circle(dot+Vector2(1.0,2.0),8.0,Color(0.15,0.26,0.17,0.25))
			draw_circle(dot,7.0,Color("#fff4db"))
			draw_circle(dot,5.0,Color("#457965"))
		if villagers.size() > 4:
			_draw_tag("+" + str(villagers.size() - 4),center+Vector2(35.0,-42.0))
		for site_id in Country54.locations_in(region_id):
			if discoveries.has(site_id):
				draw_circle(center+Vector2(37.0,20.0),8.0,Color("#f8d78c"))
				draw_line(center+Vector2(34.0,20.0),center+Vector2(37.0,23.0),Color("#315946"),2.0)
				draw_line(center+Vector2(37.0,23.0),center+Vector2(42.0,16.0),Color("#315946"),2.0)
		# The badge follows persistent 5.8 expedition chapter progress.
		var progress58: int = int(farm.state["countryside54"].get("beyond58",{}).get("chapters",{}).get(region_id,0))
		if progress58 > 0:
			var badge58: Vector2 = center + Vector2(0.0,-47.0)
			draw_circle(badge58,12.0,Color("#ffffff"))
			draw_circle(badge58,10.0,Color("#3f8266") if progress58 < 3 else Color("#e3c56d"))
			_label(str(progress58) + "/3",badge58 + Vector2(0.0,3.0),Color("#1e4134"),10,25.0)

func _draw_compass() -> void:
	var center: Vector2 = Vector2(size.x - 42.0, 42.0)
	draw_circle(center, 20.0, Color(1.0,1.0,1.0,0.45))
	draw_circle(center, 20.0, Color("#9db6a4"), false, 1.2)
	draw_line(center + Vector2(0,-12), center + Vector2(0,12), Color("#335744"), 2.0)
	draw_line(center + Vector2(-12,0), center + Vector2(12,0), Color("#335744"), 2.0)
	_label("N", center + Vector2(0,-18), Color("#335744"), 12, 20.0)

func _draw_title() -> void:
	_draw_tag("FIELDWORK / BEYOND THE FARM 5.8", Vector2(size.x * 0.50, 24.0), true)
	if farm != null and not farm.state.is_empty():
		var hour: int = int(farm.state["time"]["hour"])
		if hour >= 20 or hour < 6:
			draw_rect(Rect2(Vector2.ZERO,size),Color(0.03,0.07,0.18,0.24))

func _draw() -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO,size)
	_draw_background(bounds)
	for loc in LOCATIONS:
		_draw_location(loc)
	_draw_countryside54()
	_draw_compass()
	_draw_title()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	for loc in LOCATIONS:
		var p: Vector2 = Vector2(loc["xy"].x*size.x,loc["xy"].y*size.y)
		if p.distance_to(event.position) <= maxf(34.0,minf(size.x,size.y)*0.085):
			selected = str(loc["id"])
			region_selected.emit(selected)
			queue_redraw()
			return

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if not reduced_motion59:
		elapsed += delta
	redraw_accum59 += delta
	if redraw_accum59 >= Performance59.redraw_seconds(performance_mode59,reduced_motion59):
		redraw_accum59 = 0.0
		queue_redraw()
