extends Control
const FarmScript = preload("res://scripts/NativeFarm.gd")
const Visual = preload("res://scripts/WorldPresentation.gd")
const Life = preload("res://scripts/FarmingLife49.gd")
const Style53 = preload("res://scripts/FarmerStyle53.gd")
const Beauty51 = preload("res://scripts/BeautifulFarm51.gd")
const Fields52 = preload("res://scripts/FieldsOpportunity52.gd")
const Living57 = preload("res://scripts/LivingFarm57.gd")
const Data52 = preload("res://scripts/NativeData.gd")
const Performance59 = preload("res://scripts/PerformanceAccessibility59.gd")
## Native illustrated 2D farm. No RNG is used for rendering or movement.
## Zoom and panning affect presentation only; simulations use farm.state.
signal selected_field(field_id: String)
signal selected_npc(npc_id: String)
signal selected_building(building_id: String)
signal selected_build_slot(slot: int)
signal selected_animal(animal_id: String)
signal selected_decoration(slot: int)
signal requested_move(x: float, y: float)
signal garden_slot_chosen57(slot: int)
signal machine_chosen57(machine_id: String)

const WIDTH: float = 64.0
const HEIGHT: float = 54.0
const GRID_X = [7.3, 16.6, 25.9, 35.2, 44.5, 53.8]
const GRID_Y = [10.8, 18.6, 26.4, 34.2]
const FIELD_W: float = 8.55
const FIELD_H: float = 6.75
const OUTLINE = Color("#29483e")
const GROUND = Color("#c0d6ae")

var farm: Variant = null
var selected: String = "plot1"
var art: Dictionary = {}
var elapsed: float = 0.0
var redraw_accum: float = 0.0
var move_cooldown: float = 0.0
var touchscreen_dir: Vector2 = Vector2.ZERO
var performance_mode59: String = "balanced"
var overlay_numbers59: bool = true
var touch_points59: Dictionary = {}
var pinch_last59: float = 0.0
var zoom: float = 1.0
var zoom_target: float = 1.0
var camera_offset: Vector2 = Vector2.ZERO
var camera_target: Vector2 = Vector2.ZERO
var overlay_mode: String = "none"
var panning: bool = false
var last_pan: Vector2 = Vector2.ZERO
var labels_on: bool = true
var hovered_field: String = ""
var controls_enabled: bool = true
var show_growth_labels: bool = true
var show_ambient_effects: bool = true
var show_animal_moods: bool = true
var reduced_motion: bool = false
var high_visibility_labels: bool = false
var show_build_slots: bool = false
var show_garden_slots57: bool = false
var active_garden_slot57: int = -1
var work_kind57: String = ""
var work_field57: String = ""
var work_started57: float = -1.0
var active_build_slot: int = -1
var hovered_building: String = ""
var hovered_npc: String = ""
var seasonal_palette: Array = [Color("#b4d7aa"), Color("#c4d5a0"), Color("#c9c09a"), Color("#c4d2c5")]
const SKY_TOP = [Color("#c8e8ff"), Color("#d7efff"), Color("#f3d9b2"), Color("#d7e5ef")]
const SKY_BOTTOM = [Color("#edf7ff"), Color("#eef9ff"), Color("#fbefd8"), Color("#f1f6fb")]
const HILL_FAR = [Color("#a8c7a6"), Color("#b7cda7"), Color("#ceb998"), Color("#b7c4c6")]
const HILL_NEAR = [Color("#8cb087"), Color("#97b887"), Color("#b79d73"), Color("#9fb1b4")]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for id in ["terrain52_raised","terrain52_orchard","terrain52_paddy","terrain51_meadow","terrain51_loam","terrain51_wet","terrain51_dry","terrain51_clay","terrain51_sand","terrain51_marsh","terrain51_rock","terrain51_forest","terrain51_path","grass","soil","tree","water","path","person_player","person_ines","person_mateo", "grass_flowers", "rock", "reed", "wildlife_viper", "wildlife_wasp", "flower_patch", "field_sign", "building_farmhouse","building_market", "building_warehouse","building_coop","building_barn","building_greenhouse","building_pond","building_workshop", "icon_timber", "icon_stone", "icon_clay", "icon_wildflowers", "icon_xp"]:
		_try_asset(id)
	for npc_id in ["ines", "mateo", "rosa", "bruno", "lila", "clara", "elena", "paco", "omar", "sofia"]:
		_try_asset("person_" + npc_id)
	for id in Data52.catalog().get("crops",{}).keys():
		_try_asset("crop_" + id)
		for phase in range(4):
			_try_asset("growth_" + id + "_" + str(phase))
	for id in ["hen", "goat", "duck", "sheep", "rabbit", "turkey", "goose", "cow", "alpaca", "horse", "pig"]:
		_try_asset("animal_" + id)
	for id in ["pasture", "stable", "pigsty", "lookout", "clinic"]:
		_try_asset("building_" + id)
	for id in ["bench", "flower_arch", "birdhouse", "lantern", "stone_path"]:
		_try_asset("decor_" + id)
	for machine_id_57 in Living57.MACHINE_ORDER:
		_try_asset("machine57_" + str(machine_id_57))

func _try_asset(id: String) -> void:
	var path: String = "res://assets/" + id + ".png"
	if ResourceLoader.exists(path):
		art[id] = load(path)

func set_farm(value: Variant) -> void:
	farm = value
	queue_redraw()

func set_selected(id: String) -> void:
	selected = id
	queue_redraw()

func change_zoom(amount: float) -> void:
	zoom_target = clampf(zoom_target + amount, 1.0, 2.6)
	if reduced_motion:
		zoom = zoom_target
	queue_redraw()

func focus_field(field_id: String) -> void:
	var index: int = -1
	for i in range(24):
		if field_id == "plot" + str(i+1):
			index = i
			break
	if index < 0:
		return
	zoom_target = maxf(1.35, zoom_target)
	var world_center: Vector2 = Vector2(GRID_X[index % 6] + FIELD_W * 0.5, GRID_Y[int(index / 6)] + FIELD_H * 0.5)
	var normal: Vector2 = Vector2(world_center.x / WIDTH * size.x, world_center.y / HEIGHT * size.y)
	camera_target = size * 0.5 - (normal * zoom_target + size * (1.0 - zoom_target) * 0.5)
	if reduced_motion:
		zoom = zoom_target
		camera_offset = camera_target
	queue_redraw()

func reset_camera() -> void:
	zoom_target = 1.0
	camera_target = Vector2.ZERO
	if reduced_motion:
		zoom = 1.0
		camera_offset = Vector2.ZERO
	queue_redraw()

func _at(x: float, y: float) -> Vector2:
	return Vector2(x / WIDTH * size.x, y / HEIGHT * size.y) * zoom + size * (1.0 - zoom) * 0.5 + camera_offset

func _unat(pos: Vector2) -> Vector2:
	var source: Vector2 = (pos - camera_offset - size * (1.0 - zoom) * 0.5) / zoom
	return Vector2(source.x / maxf(1.0, size.x) * WIDTH, source.y / maxf(1.0, size.y) * HEIGHT)

func _rect(x: float, y: float, w: float, h: float) -> Rect2:
	return Rect2(_at(x,y), Vector2(w / WIDTH * size.x * zoom, h / HEIGHT * size.y * zoom))

func _sprite(id: String, x: float, y: float, w: float, h: float, tint: Color = Color.WHITE) -> void:
	if art.has(id):
		draw_texture_rect(art[id], _rect(x,y,w,h), false, tint)

func _word(value: String, x: float, y: float, color: Color = OUTLINE, font_size: int = 11) -> void:
	if ThemeDB.fallback_font != null:
		draw_string(ThemeDB.fallback_font, _at(x,y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, maxi(10, int(font_size * minf(1.5,zoom))), color)

func _field_rect(index: int) -> Rect2:
	return _rect(GRID_X[index % 6], GRID_Y[int(index / 6)], FIELD_W, FIELD_H)

func _building_anchor(index: int) -> Vector2:
	var col: int = int(index / 2) % 12
	return Vector2(7.6 + col * 4.42, 7.5 if index % 2 == 0 else 51.8)

func _structure_position(building: Dictionary, index: int) -> Vector2:
	var field_id: String = str(building.get("field",""))
	if field_id.begins_with("plot"):
		var plot_index: int = clampi(int(field_id.trim_prefix("plot"))-1,0,23)
		return Vector2(GRID_X[plot_index%6]+FIELD_W-0.65,GRID_Y[int(plot_index/6)]+FIELD_H-0.75)
	return _building_anchor(int(building.get("slot",index)))

func _npc_position(npc: Dictionary, hour: int) -> Vector2:
	for slot in npc.get("schedule", []):
		if hour >= int(slot.get("from",0)) and hour < int(slot.get("to",24)):
			return Vector2(float(slot.get("x",35)),float(slot.get("y",14)))
	return Vector2(51.0,6.5)

# Everything below is a presentation-only layer. No RandomNumberGenerator,
# randf(), randi(), or simulation actions are called from _draw().
# World-space coordinates are the same as 4.3, so every click target remains valid.
func _paint_meadow(season: int) -> void:
	var base: Color = seasonal_palette[season]
	var sky_top: Color = SKY_TOP[season]
	var sky_bottom: Color = SKY_BOTTOM[season]
	var horizon_y: float = size.y * 0.26
	var bands: int = 22
	for i in range(bands):
		var t: float = float(i) / maxf(1.0, float(bands - 1))
		var band_color: Color = sky_top.lerp(sky_bottom, t)
		var y0: float = horizon_y * t
		draw_rect(Rect2(Vector2(0.0, y0), Vector2(size.x, horizon_y / float(bands) + 2.0)), band_color)
	var far_hills: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, horizon_y * 0.98),
		Vector2(size.x * 0.10, horizon_y * 0.66),
		Vector2(size.x * 0.21, horizon_y * 0.82),
		Vector2(size.x * 0.35, horizon_y * 0.58),
		Vector2(size.x * 0.50, horizon_y * 0.80),
		Vector2(size.x * 0.66, horizon_y * 0.54),
		Vector2(size.x * 0.82, horizon_y * 0.74),
		Vector2(size.x, horizon_y * 0.60),
		Vector2(size.x, horizon_y + 26.0),
		Vector2(0.0, horizon_y + 26.0)
	])
	draw_colored_polygon(far_hills, HILL_FAR[season])
	var near_hills: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, horizon_y + 18.0),
		Vector2(size.x * 0.12, horizon_y - 10.0),
		Vector2(size.x * 0.25, horizon_y + 12.0),
		Vector2(size.x * 0.42, horizon_y - 6.0),
		Vector2(size.x * 0.58, horizon_y + 16.0),
		Vector2(size.x * 0.72, horizon_y - 12.0),
		Vector2(size.x * 0.89, horizon_y + 10.0),
		Vector2(size.x, horizon_y - 4.0),
		Vector2(size.x, size.y),
		Vector2(0.0, size.y)
	])
	draw_colored_polygon(near_hills, HILL_NEAR[season])
	draw_rect(Rect2(Vector2(0.0, horizon_y * 0.85), Vector2(size.x, size.y - horizon_y * 0.85)), base)
	var ground_bands: int = 45
	for i in range(ground_bands):
		var t: float = float(i) / float(ground_bands)
		var shade: Color = base.lerp(Color("#e9e7ba"), 0.12 + 0.12 * sin(t * PI))
		shade.a = 0.44
		draw_rect(Rect2(Vector2(0.0, t * size.y), Vector2(size.x, size.y / float(ground_bands) + 1.0)), shade)
	# Ground textures remain repeatable on every launch and every frame.
	for row in range(0, 14, Performance59.terrain_stride(performance_mode59)):
		for col in range(0, 17, Performance59.terrain_stride(performance_mode59)):
			var x: float = float(col) * 3.9 - 0.8
			var y: float = float(row) * 4.05 - 0.7
			_sprite("terrain51_meadow", x, y, 4.3, 4.3, Color(0.96, 1.0, 0.94, 0.46))
	for i in range(0, 105, Performance59.terrain_stride(performance_mode59)):
		var x: float = 0.6 + fposmod(float(i * 47 + 13) * 0.83, 62.0)
		var y: float = 0.4 + fposmod(float(i * 73 + 17) * 0.43, 52.3)
		if x >= 6.8 and x <= 62.9 and y >= 10.5 and y <= 41.4:
			continue
		var spot: Vector2 = _at(x,y)
		var grass: Color = Color("#739d62") if season != 2 else Color("#a6a06a")
		draw_line(spot, spot+Vector2(-2.0, -4.0),grass,1.0)
		draw_line(spot, spot+Vector2(2.0, -3.0),grass,1.0)
		if i % 6 == 0:
			draw_circle(spot+Vector2(0.0,-4.5),2.0,Color("#f5d576") if i % 2 == 0 else Color("#e7b2c2"))

func _river_x(y: float) -> float:
	return 2.3 + sin(y * 0.23) * 0.68

func _paint_river() -> void:
	var width_px: float = maxf(7.0, 3.25 / WIDTH * size.x * zoom)
	var bank_px: float = width_px + 6.0
	var pts: PackedVector2Array = PackedVector2Array()
	for i in range(111):
		var y: float = float(i) * 54.0 / 110.0
		pts.append(_at(_river_x(y),y))
	draw_polyline(pts,Color("#8caa7d"),bank_px+9.0,true)
	draw_polyline(pts,Color("#d9c895"),bank_px+3.0,true)
	draw_polyline(pts,Color("#559eaa"),width_px+1.0,true)
	draw_polyline(pts,Color("#78c3cc"),width_px*0.78,true)
	for i in range(27):
		var y: float = 0.85 + float(i)*1.96
		var center: Vector2 = _at(_river_x(y),y)
		var drift: float = sin(elapsed * 0.55 + float(i)*1.8) * 3.2
		draw_line(center + Vector2(-6.0+drift, 0.0),center + Vector2(2.0+drift, 0.0),Color(0.94,0.99,0.97,0.48),1.2)
		if i % 4 == 0:
			var lily: Vector2 = center + Vector2(width_px*0.24, 2.0)
			draw_circle(lily, 3.6, Color("#458a66"))
			draw_circle(lily + Vector2(0.5,-1.7), 1.7, Color("#f6e8c5"))
	# Reed beds and rounded stones frame the water instead of square cells.
	for i in range(24):
		var y: float = 0.9 + float(i)*2.2
		var side: float = -1.0 if i % 2 == 0 else 1.0
		var x: float = _river_x(y)+side*2.12
		var point: Vector2 = _at(x,y)
		draw_circle(point, 2.4 + float(i % 3), Color("#9e9b82"))
		if i % 3 == 0:
			_sprite("reed", x-0.40, y-1.40, 0.85, 1.68)
	# Footbridge near the pasture; visual only, the actual movement grid is unchanged.
	var bridge: Rect2 = _rect(0.95, 41.95, 4.2, 1.25)
	draw_rect(bridge,Color("#966d46"))
	for i in range(6):
		var px: float = bridge.position.x + bridge.size.x * (float(i) / 6.0)
		draw_line(Vector2(px,bridge.position.y),Vector2(px,bridge.end.y),Color("#d8ae75"),2.0)
	draw_line(bridge.position+Vector2(0,2),Vector2(bridge.end.x,bridge.position.y+2),Color("#f0d4a3"),2.0)

func _paint_path(x: float, y: float, w: float, h: float, index: int) -> void:
	var r: Rect2 = _rect(x,y,w,h)
	draw_rect(r.grow(1.8),Color(0.33,0.38,0.20,0.10))
	draw_rect(r,Color("#e2ca95"))
	# Natural weathered-path texture without changing the traversable grid.
	for tile in range(maxi(1,int(ceil(w/4.0)))):
		var px: float = x+float(tile)*4.0
		var pw: float = minf(4.0, x+w-px)
		_sprite("terrain51_path",px,y,pw,h,Color(1.0,1.0,1.0,0.76))
	draw_line(Vector2(r.position.x,r.position.y+1.4),Vector2(r.end.x,r.position.y+1.4),Color("#f1dfb7"),1.0)
	var pebbles: int = maxi(12,int(w*1.6))
	for i in range(pebbles):
		var bx: float = x + fposmod(float(i*13+index*7)*0.37,maxf(0.4,w-0.3))
		var by: float = y + 0.21 + fposmod(float(i*17+index*3)*0.08,maxf(0.14,h-0.27))
		draw_circle(_at(bx,by),0.75 + float(i%2)*0.35,Color("#bda97c"))

func _paint_paths() -> void:
	# The center aisles separate every field row; paths remain traversable.
	for i in range(5):
		_paint_path(5.25, 9.55 + float(i)*7.87, 55.2, 0.95, i)
	_paint_path(5.35, 7.9, 1.30, 44.9, 8)
	_paint_path(60.0, 7.9, 1.10, 44.9, 9)
	_paint_path(7.2, 42.3, 51.9, 1.0, 10)
	# Cobblestones mark the farmhouse-to-market walk.
	for i in range(18):
		var x: float = 9.3 + float(i)*2.54
		var y: float = 8.75 + float(i%3)*0.18
		var p: Vector2 = _at(x,y)
		draw_circle(p,2.5,Color("#d9c39c"))
		draw_circle(p+Vector2(2.0,0.5),1.1,Color("#b9a37e"))

func _paint_tree(x: float, y: float, scale_factor: float, season: int, blossom: bool = false) -> void:
	var bw: float = 3.5*scale_factor
	var bh: float = 4.5*scale_factor
	var trunk: Vector2 = _at(x,y)
	draw_circle(trunk+Vector2(1.0,2.5),maxf(3.0,3.8*scale_factor),Color(0.17,0.24,0.12,0.12))
	var foliage: Color = Color.WHITE
	if season == 2:
		foliage = Color("#f0ba85")
	elif season == 3:
		foliage = Color("#d9e6df")
	_sprite("tree",x-bw*0.48,y-bh,bw,bh,foliage)
	if blossom and season == 0:
		for i in range(6):
			var offset: Vector2 = Vector2(sin(float(i)*2.4)*12.0*scale_factor, cos(float(i)*1.7)*6.0*scale_factor-15.0*scale_factor)
			draw_circle(_at(x,y-bh*0.58)+offset,2.4*scale_factor,Color("#f6b9ce"))
	elif blossom and season == 1:
		for i in range(4):
			var offset: Vector2 = Vector2(float(i%2)*12.0-5.0,float(i/2)*7.0-17.0)
			draw_circle(_at(x,y-bh*0.55)+offset,2.2,Color("#f3c35c"))

func _paint_trees(season: int) -> void:
	# Canopies stay in the natural perimeter, so no plot interaction is hidden.
	for i in range(12):
		var y: float = 1.8 + float(i)*4.70
		_paint_tree(5.3 + sin(float(i)*1.2)*0.48,y,0.7 + float(i%3)*0.09,season,i%3 == 0)
	for i in range(11):
		var y: float = 3.2 + float(i)*4.82
		_paint_tree(62.8 + cos(float(i)*1.3)*0.35,y,0.74 + float(i%3)*0.08,season,i%4 == 1)
	for i in range(6):
		_paint_tree(16.5 + float(i)*5.3,3.4 + float(i%2)*0.7,0.93,season,i%2 == 0)
	for i in range(5):
		_paint_tree(16.5 + float(i)*8.3,53.0,0.66,season,i%2 == 1)
	# Hedges around the upper orchard and native pollinator border.
	for i in range(9):
		var x: float = 13.5 + float(i)*5.25
		_sprite("flower_patch",x,6.8,1.6,1.6)
		if i%2 == 0:
			draw_circle(_at(x+0.55,7.55),2.0,Color("#f6d57c"))

func _paint_fences(x: float, y: float, w: float, h: float, owned: bool) -> void:
	var highlight: Color = Color("#e3c695") if owned else Color("#bfc6a4")
	var dark: Color = Color("#8b6f50") if owned else Color("#74947e")
	var top_y: float = y + 0.20
	var low_y: float = y + h-0.20
	for edge_y in [top_y,low_y]:
		draw_line(_at(x+0.15,edge_y),_at(x+w-0.15,edge_y),dark,1.2)
		draw_line(_at(x+0.15,edge_y-0.20),_at(x+w-0.15,edge_y-0.20),highlight,1.1)
	for i in range(5):
		var px: float = x + 0.14 + float(i)*(w-0.28)/4.0
		var py: float = y + h - 0.38
		var post: Rect2 = _rect(px-0.10,py-0.36,0.20,0.68)
		draw_rect(post,dark)
		if i%2 == 0:
			draw_rect(_rect(px-0.07,py-0.34,0.15,0.11),highlight)

func _draw_soil_feedback(f: Dictionary, x: float, y: float, season: int) -> void:
	var soil: Dictionary = f.get("soil", {})
	var condition: String = Visual.soil_visual(soil)
	if condition == "dry":
		for j in range(4):
			var bx: float = x + 0.7 + float(j) * 1.92
			var by: float = y + 1.05 + float(j%2) * 2.3
			var crack: Color = Color("#624f40")
			draw_line(_at(bx,by),_at(bx+0.35,by+0.36),crack,1.4)
			draw_line(_at(bx+0.35,by+0.36),_at(bx+0.20,by+0.69),crack,1.3)
			draw_line(_at(bx+0.35,by+0.36),_at(bx+0.76,by+0.51),crack,1.2)
	elif condition == "wet":
		for j in range(4):
			var cx: float = x + 1.2 + float(j) * 1.85
			var cy: float = y + 4.3 + float(j%2) * 0.62
			var pos: Vector2 = _at(cx,cy)
			draw_circle(pos, maxf(2.3, 3.2 * zoom), Color(0.27,0.59,0.65,0.40))
			draw_line(pos-Vector2(2.3,0.5),pos+Vector2(2.1,-0.3),Color(0.84,0.95,0.96,0.57),1.0)
	if season == 3:
		# Frost on the soil ridge; visual only.
		for j in range(5):
			var px: float = x+0.6+float(j)*1.55
			var py: float = y+0.38+float(j%2)*5.4
			draw_circle(_at(px,py),1.5,Color(0.96,0.99,1.0,0.60))

func _draw_crop_canopy(field: Dictionary, crop: Dictionary, x: float, y: float, index: int) -> void:
	var development: float = clampf(float(crop.get("development",0.0)),0.0,1.0)
	var stage: int = Visual.crop_stage(development)
	var tree_rows: bool = str(field.get("plot_type","open")) == "orchard"
	if tree_rows and int(crop.get("harvest_cycles",0)) > 0:
		stage = maxi(stage,3) # Established trees do not turn back into seedlings.
	var crop_id: String = str(crop.get("id","wheat"))
	var health: float = Visual.plant_health(field)
	var weather_kind: String = str(farm.state["weather"].get("kind","clear"))
	var wind_factor: float = 0.75 if weather_kind in ["rain","storm","windy"] else 0.36
	var shading: Color = Color(1.0,1.0,1.0,1.0)
	if health < 0.52:
		shading = Color(1.0,0.91,0.74,0.88)
	elif health < 0.75:
		shading = Color(1.0,0.96,0.87,0.95)
	for row in range(2 if tree_rows else 3):
		for cc in range(3 if tree_rows else 4):
			var bx: float = x + (0.70 if tree_rows else 0.40) + float(cc)*(2.85 if tree_rows else 2.00)
			var by: float = y + (2.55 if tree_rows else 1.18) + float(row)*(2.75 if tree_rows else 1.77)
			var sway: float = wind_factor * sin(elapsed * 2.2 + float(index)*0.7 + float(row)*0.91 + float(cc)*0.53)
			var wide: float = [0.46,0.83,1.13,1.46,1.72][stage]
			var tall: float = [0.44,0.75,1.20,1.73,2.25][stage]
			if tree_rows:
				wide *= 1.52
				tall *= 1.56
			var asset: String = "growth_" + crop_id + "_" + str(stage) if stage < 4 else "crop_" + crop_id
			var shadow: Vector2 = _at(bx+wide*0.55,by+0.18)
			draw_circle(shadow,maxf(2.1,wide*size.x/WIDTH*zoom*0.40),Color(0.13,0.23,0.12,0.13))
			_sprite(asset,bx+sway*0.15,by+0.35-tall,wide,tall,shading)
			if stage >= 3 and cc % 2 == 0:
				var sparkle: float = 0.28 + 0.20 * sin(elapsed*2.0+float(row+cc))
				draw_circle(_at(bx+wide*0.8,by-0.7),1.4,Color(1.0,0.90,0.55,sparkle))
	if show_growth_labels and zoom > 1.15:
		var spanish: bool = farm.language == "es"
		var label: String = Visual.crop_stage_text(development,spanish)
		_word(label,x+0.40,y+6.20,Color("#2d5844"),11)
	if development >= 0.98:
		var tag: Rect2 = _rect(x+5.0,y+5.25,3.1,0.60)
		draw_rect(tag,Color("#467e58"))
		_word("LISTO" if farm.language == "es" else "READY",x+5.17,y+5.68,Color("#fff6cf"),11)

func _draw_plot_style_52(f: Dictionary, x: float, y: float) -> void:
	var layout: String = str(f.get("plot_type","open"))
	if layout == "open":
		return
	_sprite("terrain52_"+layout,x+0.08,y+0.08,FIELD_W-0.16,FIELD_H-0.16,Color(1.0,1.0,1.0,0.60))
	if layout == "raised":
		for row in range(3):
			var yy: float = y+0.75+float(row)*1.96
			draw_rect(_rect(x+0.35,yy,FIELD_W-0.7,1.5),Color("#ae7a4b"),false,3.0)
			draw_line(_at(x+0.37,yy+1.45),_at(x+FIELD_W-0.39,yy+1.45),Color("#f1c98a"),2.3)
	elif layout == "paddy":
		draw_rect(_rect(x+0.25,y+0.25,FIELD_W-0.50,FIELD_H-0.50),Color(0.21,0.60,0.72,0.22))
		for row in range(4):
			var yy: float = y+1.05+float(row)*1.42
			draw_line(_at(x+0.35,yy),_at(x+FIELD_W-0.35,yy),Color("#aee4de"),1.9)
		draw_rect(_rect(x+0.18,y+0.18,FIELD_W-0.36,FIELD_H-0.36),Color("#d9c9a0"),false,3.1)
	elif layout == "orchard":
		for row in range(2):
			for col in range(3):
				var cx: float = x+1.46+float(col)*2.85
				var cy: float = y+2.1+float(row)*2.75
				draw_circle(_at(cx,cy),5.0,Color(0.27,0.43,0.25,0.22))
		for col in range(4):
			var xx: float = x+0.42+float(col)*2.20
			draw_line(_at(xx,y+0.30),_at(xx,y+FIELD_H-0.30),Color("#e1c79b"),1.5)

func _draw_field(i: int, f: Dictionary, owned: bool) -> void:
	var r: Rect2 = _field_rect(i)
	var x: float = GRID_X[i%6]
	var y: float = GRID_Y[int(i/6)]
	var bevel_h: float = maxf(5.0, r.size.y * 0.12)
	var bevel_w: float = maxf(3.0, r.size.x * 0.04)
	# Shared by the furrow renderer and the later dry-soil marker.
	# Never declare this inside the conditional: GDScript is block-scoped.
	var dry: bool = owned and float(f["soil"]["water"]) < float(f["soil"]["capacity"]) * 0.24
	draw_rect(Rect2(r.position+Vector2(4.0,4.0),r.size),Color(0.10,0.20,0.11,0.16))
	var soil_color: Color = Color("#a9916d") if owned else Color("#8fb78a")
	if owned:
		soil_color = Color(str(farm.content["terrains"][str(f["terrain"])].get("color","#9b815d")))
	var front_face: Rect2 = Rect2(Vector2(r.position.x+1.5,r.end.y-bevel_h),Vector2(maxf(18.0,r.size.x-1.5),bevel_h))
	var right_face: Rect2 = Rect2(Vector2(r.end.x-bevel_w,r.position.y+1.5),Vector2(bevel_w,maxf(16.0,r.size.y-bevel_h-1.5)))
	draw_rect(front_face,soil_color.darkened(0.18 if owned else 0.10))
	draw_rect(right_face,soil_color.darkened(0.10 if owned else 0.05))
	draw_rect(r,soil_color)
	draw_line(r.position+Vector2(2.0,2.0),Vector2(r.end.x-2.0,r.position.y+2.0),soil_color.lightened(0.25),1.4)
	if owned:
		var surface_id: String = Beauty51.soil_texture(str(f["terrain"]),float(f["soil"]["water"]),float(f["soil"]["capacity"]))
		_sprite(surface_id,x,y,FIELD_W,FIELD_H,Color(1.0,1.0,1.0,0.87))
	else:
		_sprite("terrain51_meadow",x,y,FIELD_W,FIELD_H,Color(1.0,1.0,1.0,0.91))
	# A narrow border lets all plot types remain recognizable at 1:1 zoom.
	draw_rect(r.grow(-1.0),Color("#ece1c5") if owned else Color("#c8dcaa"),false,1.5)
	if owned:
		_draw_plot_style_52(f,x,y)
	# Only open fields are ploughed with dry furrows; paddy water, raised
	# beds and orchard paths should keep their own identifiable texture.
	if not owned or str(f.get("plot_type","open")) == "open":
		var field_shade: Color = Color("#775b45") if dry else Color("#695844")
		for rr in range(4):
			var line_y: float = y+1.30+float(rr)*1.23
			draw_line(_at(x+0.25,line_y),_at(x+FIELD_W-0.25,line_y),field_shade if owned else Color("#6f996d"),1.45)
			draw_line(_at(x+0.25,line_y+0.18),_at(x+FIELD_W-0.25,line_y+0.18),Color("#e8d6ad") if owned else Color("#acd49e"),1.0)
	if owned:
		_draw_soil_feedback(f,x,y,int(farm.state["time"]["season"]) % 4)
		var crop: Dictionary = f["crop"]
		if not crop.is_empty():
			_draw_crop_canopy(f,crop,x,y,i)
		else:
			# A fallow plot stays alive with sparse grass instead of a flat rectangle.
			for j in range(6):
				_sprite("grass_flowers",x+0.4+float(j%3)*2.7,y+0.8+float(j/3)*3.0,0.8,0.85,Color(0.94,1.0,0.83,0.52))
		if int(f.get("cover_until",0)) > int(farm.state["time"]["total"]):
			for j in range(12):
				var sx: float = x+0.65+float(j%4)*1.94
				var sy: float = y+0.90+float(int(j/4))*1.86
				draw_circle(_at(sx,sy),2.9,Color("#52965f"))
				draw_line(_at(sx,sy),_at(sx+0.16,sy-0.38),Color("#d2e8a8"),1.6)
		if bool(f.get("hedgerow",false)):
			for j in range(8):
				var hx: float = x+0.38+float(j)*1.12
				var hy: float = y+0.15
				draw_circle(_at(hx,hy),3.6,Color("#3a8253"))
				if j%3 == 0:
					draw_circle(_at(hx,hy-0.15),1.6,Color("#edc9ca"))
		if float(f["soil"].get("erosion",0.0)) > 0.18:
			for j in range(3):
				draw_line(_at(x+1.3+float(j)*2.2,y+0.6),_at(x+1.55+float(j)*2.2,y+5.35),Color("#8d5c42"),2.3)
		if float(f["soil"].get("mulch",0.0)) > 0.05:
			for j in range(6):
				draw_line(_at(x+0.5+float(j)*1.25,y+5.5),_at(x+0.9+float(j)*1.25,y+5.65),Color("#d4ad74"),2.0)
		if dry:
			draw_rect(_rect(x+0.28,y+5.85,2.35,0.24),Color("#f2be88"))
		var high_pests: float = 0.0
		for density in f["pests"].values():
			high_pests = maxf(high_pests,float(density))
		if high_pests > 14.0:
			for j in range(mini(4,int(high_pests/8.0))):
				draw_circle(_at(x+0.78+float(j)*1.4,y+5.45),2.0,Color("#c15b55"))
	else:
		# Unpurchased meadow retains native flowers and scrub.
		for j in range(4):
			_sprite("flower_patch",x+0.35+float(j)*1.88,y+2.0+float(j%2)*1.36,1.13,1.12,Color(0.99,1.0,0.95,0.76))
	_paint_fences(x,y,FIELD_W,FIELD_H,owned)
	var is_selected: bool = str(f.get("id","plot"+str(i+1))) == selected
	var is_hovered: bool = "plot"+str(i+1) == hovered_field
	var border: Color = Color("#ffdb80") if is_selected else (Color("#e9f5d8") if is_hovered else Color("#e0e4cf"))
	draw_rect(r,border,false,3.0 if is_selected else (2.1 if is_hovered else 1.0))
	if labels_on and r.size.x > 23.0 and r.size.y > 24.0:
		var bh: float = clampf(r.size.y*0.29,16.0,22.0)
		var badge: Rect2 = Rect2(r.position+Vector2(3.0,3.0),Vector2(minf(r.size.x-6.0,140.0),bh))
		draw_rect(badge,Color("#fff1be") if is_selected else (Color("#edf8e8") if owned else Color("#e0eadd")))
		var caption: String = "#"+str(i+1)
		if owned and str(f.get("plot_type","open")) != "open" and badge.size.x > 100.0:
			caption += " " + {"raised":"BEDS","orchard":"TREES","paddy":"RICE"}.get(str(f["plot_type"]),"")
		if badge.size.x > 113.0:
			caption += "   " + ("OWNED" if owned else "FOR SALE")
		if ThemeDB.fallback_font != null:
			draw_string(ThemeDB.fallback_font,badge.position+Vector2(5.0,bh-4.0),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12 if r.size.x>52.0 else 11,OUTLINE)
		if owned and high_visibility_labels:
			var moisture: float = float(f["soil"]["water"]) / maxf(1.0,float(f["soil"]["capacity"]))
			var state_text: String = "SECO" if farm.language == "es" else "DRY"
			if moisture > 0.72:
				state_text = "HÚMEDO" if farm.language == "es" else "WET"
			elif moisture >= 0.25:
				state_text = "NORMAL" if farm.language == "es" else "NORMAL"
			var plate: Rect2 = Rect2(r.position+Vector2(3.0,maxf(22.0,r.size.y-28.0)),Vector2(minf(65.0,r.size.x-6.0),17.0))
			draw_rect(plate,Color("#fffdf0"))
			if ThemeDB.fallback_font != null:
				draw_string(ThemeDB.fallback_font,plate.position+Vector2(4.0,12.0),state_text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#243b31"))
		if owned and not f["crop"].is_empty():
			var growth: float = clampf(float(f["crop"].get("development",0.0)),0.0,1.0)
			var progress: Rect2 = Rect2(r.position+Vector2(3.0,r.size.y-6.0),Vector2(maxf(0.0,r.size.x-6.0),3.8))
			draw_rect(progress,Color("#345f49"))
			draw_rect(Rect2(progress.position,Vector2(progress.size.x*growth,progress.size.y)),Color("#ffdf82") if growth>0.995 else Color("#8be3a4"))

func _paint_field_overlay_51(i: int, f: Dictionary) -> void:
	if overlay_mode == "none" or not bool(f.get("owned",false)):
		return
	var metric: float = Beauty51.overlay_value(overlay_mode,f)
	var tint: Color = Beauty51.overlay_tint(overlay_mode,metric)
	var r: Rect2 = _field_rect(i)
	draw_rect(r.grow(-2.0),tint)
	draw_rect(r.grow(-2.0),Color(tint.r,tint.g,tint.b,0.9),false,2.0)
	var label: String = str(int(metric*100.0))+"%"
	if ThemeDB.fallback_font != null and overlay_numbers59:
		var plate: Rect2 = Rect2(r.position+Vector2(4.0,2.0),Vector2(minf(59.0,r.size.x-8.0),21.0))
		draw_rect(plate,Color(0.10,0.22,0.16,0.92))
		draw_string(ThemeDB.fallback_font,plate.position+Vector2(6.0,15.0),label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ffffff"))

func _paint_map_hints_51() -> void:
	if overlay_mode != "none":
		var legend: Rect2 = Rect2(Vector2(maxf(8.0,size.x-202.0),12.0),Vector2(190.0,51.0))
		draw_rect(legend,Color(0.11,0.25,0.19,0.87))
		var heading: String = Beauty51.overlay_name(overlay_mode,farm != null and farm.language == "es")
		if ThemeDB.fallback_font != null:
			draw_string(ThemeDB.fallback_font,legend.position+Vector2(12.0,20.0),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f6f5df"))
			draw_string(ThemeDB.fallback_font,legend.position+Vector2(12.0,38.0),"0%              50%            100%",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#e2f0d6"))
		for i in range(7):
			var ratio: float = float(i)/6.0
			draw_rect(Rect2(legend.position+Vector2(12.0+ratio*163.0,43.0),Vector2(24.0,4.0)),Beauty51.overlay_tint(overlay_mode,ratio).lightened(0.13))
	if hovered_field != "" and farm != null and not farm.state.is_empty():
		var field: Dictionary = farm.field_of(hovered_field)
		if not field.is_empty():
			var crop_name: String = ""
			if not field["crop"].is_empty():
				crop_name = farm.n(farm.content["crops"][str(field["crop"]["id"])])
			var crop_context: String = "FOR SALE" if not bool(field["owned"]) else ("FALLOW" if field["crop"].is_empty() else crop_name)
			var tip: String = hovered_field.to_upper() + "  ·  " + crop_context + " · " + Fields52.localized(Fields52.PLOTS[str(field.get("plot_type","open"))],"en")
			if farm.language == "es":
				tip = hovered_field.to_upper() + "  ·  " + ("EN VENTA" if not bool(field["owned"]) else ("BARBECHO" if field["crop"].is_empty() else crop_name)) + " · " + Fields52.localized(Fields52.PLOTS[str(field.get("plot_type","open"))],"es")
			var tip_area: Rect2 = Rect2(Vector2(10.0,maxf(10.0,size.y-42.0)),Vector2(minf(280.0,size.x-20.0),30.0))
			draw_rect(tip_area,Color(0.12,0.27,0.21,0.90))
			if ThemeDB.fallback_font != null:
				draw_string(ThemeDB.fallback_font,tip_area.position+Vector2(10.0,19.0),tip,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#fbf7e8"))

func _paint_building_pad(x: float, y: float, w: float) -> void:
	var shadow: Rect2 = _rect(x-w*0.5+0.08,y+0.06,w,0.68)
	draw_rect(shadow,Color(0.12,0.18,0.10,0.12))
	var rect: Rect2 = _rect(x-w*0.5,y-0.1,w,0.55)
	draw_rect(rect,Color("#bda780"))
	draw_rect(Rect2(Vector2(rect.position.x+1.0,rect.end.y-3.0),Vector2(maxf(10.0,rect.size.x-1.0),3.0)),Color("#9f8663"))
	draw_line(rect.position+Vector2(1.0,2.0),Vector2(rect.end.x-1.0,rect.position.y+2.0),Color("#ead9bb"),1.2)
	for i in range(4):
		var px: float = x-w*0.40+float(i)*w*0.27
		draw_circle(_at(px,y+0.17),1.4,Color("#e9dcc0"))

func _paint_village(season: int) -> void:
	_paint_building_pad(9.4,7.6,8.7)
	_paint_building_pad(54.2,7.6,8.7)
	_sprite("building_farmhouse",6.8,0.8,5.45,6.3)
	_sprite("building_market",51.35,0.8,5.45,6.3)
	# Garden planters at both entrances.
	for x in [6.9,12.1,51.1,56.8]:
		_sprite("flower_patch",x,6.45,1.55,1.36)
	_word("HOME",8.1,8.2,Color("#325a43"),12)
	_word("MARKET",51.8,8.2,Color("#325a43"),12)
	# Warm village lanterns animate visually but never consume RNG.
	for x in [11.9,15.6,48.2,52.6]:
		var p: Vector2 = _at(x,7.95)
		draw_line(p,p+Vector2(0.0,-11.0),Color("#735844"),2.2)
		draw_circle(p+Vector2(0.0,-13.0),3.0,Color("#ffdc88"))
		if season == 3:
			draw_circle(p+Vector2(0.0,-13.0),7.0,Color(1.0,0.87,0.53,0.17))

func _paint_pasture() -> void:
	var yard: Rect2 = _rect(6.0,43.05,53.4,9.3)
	draw_rect(yard,Color("#a9cc91"))
	for i in range(27):
		var x: float = 7.0 + float(i)*1.85
		_sprite("grass_flowers",x,44.45+float(i%3)*2.0,1.0,1.0,Color(0.98,1.0,0.98,0.63))
	# Low, continuous pasture fences and a hay-feeding station.
	for fence_y in [43.3,51.9]:
		draw_line(_at(6.35,fence_y),_at(59.2,fence_y),Color("#a58159"),2.1)
		draw_line(_at(6.35,fence_y-0.34),_at(59.2,fence_y-0.34),Color("#dfbb86"),1.4)
	for i in range(28):
		var x: float = 6.3 + float(i)*1.96
		draw_rect(_rect(x,43.04,0.20,1.15),Color("#85674a"))
		draw_rect(_rect(x,51.55,0.20,1.05),Color("#85674a"))
	# A shaded feed trough and bundle of straw.
	draw_rect(_rect(6.65,48.15,2.75,0.60),Color("#6c8f84"))
	draw_rect(_rect(6.90,48.02,2.20,0.42),Color("#c7e0d4"))
	for i in range(7):
		var x: float = 9.6 + float(i)*0.21
		draw_line(_at(x,48.9),_at(x+0.36,47.6),Color("#f6cc72"),1.7)

func _animal_world_position(index: int, animal: Dictionary, hour: int) -> Vector2:
	var nominal: Vector2 = Vector2(11.0 + float(index%11)*4.28, 46.9)
	return nominal + Visual.animal_offset(index,hour,elapsed,float(animal.get("condition",1.0)))

func _draw_animal_group(animal: Dictionary, index: int, hour: int) -> void:
	var center: Vector2 = _animal_world_position(index,animal,hour)
	var count: int = maxi(0,int(animal.get("count",0)))
	var mood: String = Visual.animal_behavior(animal,hour,index,elapsed)
	var shown: int = mini(count,3)
	for j in range(shown):
		var shift: float = float(j) * 0.55 - float(shown-1)*0.29
		var bob: float = 0.0
		if mood in ["walking","grazing"]:
			bob = 0.04 * sin(elapsed * (4.8 if mood == "walking" else 2.1) + j*2.1 + index)
		var aw: float = 1.44 if mood == "sleeping" else 1.96
		var ah: float = 1.11 if mood == "sleeping" else 1.95
		var ay: float = center.y - (1.1 if mood == "sleeping" else 2.0) + bob
		var ax: float = center.x - 0.86 + shift
		var shadow: Vector2 = _at(center.x+shift,center.y+0.05)
		draw_circle(shadow, 2.5, Color(0.10,0.22,0.14,0.17))
		var tint: Color = Color.WHITE if mood != "unwell" else Color(0.98,0.78,0.76,0.94)
		_sprite("animal_" + str(animal["kind"]),ax,ay,aw,ah,tint)
		if mood == "grazing":
			var grass: Vector2 = _at(center.x+shift+0.4,center.y-0.1)
			draw_line(grass,grass+Vector2(-1.8,-3.8),Color("#4f9466"),1.2)
		elif mood == "drinking":
			var drink: Vector2 = _at(center.x+shift+0.5,center.y-0.4)
			draw_circle(drink,2.2,Color(0.48,0.79,0.94,0.58))
	if show_animal_moods and labels_on and zoom > 1.18:
		_word(str(animal["kind"]).capitalize() + " x" + str(count),center.x-1.0,center.y+0.53,Color("#355648"),10)
	if show_animal_moods and float(animal.get("condition",1.0)) < 0.42:
		_word("!",center.x+0.65,center.y-1.80,Color("#c75850"),13)

func _draw_building_extras(kind: String, pos: Vector2, pending: bool, hour: int, index: int) -> void:
	var night: bool = Visual.dawn_dusk(hour) in ["dusk", "night"]
	var middle: Vector2 = _at(pos.x,pos.y-1.15)
	if pending:
		# A few planks, safety lantern and incomplete timbers distinguish construction.
		for j in range(3):
			var plank_y: float = pos.y-0.3-float(j)*0.52
			draw_line(_at(pos.x-1.2,plank_y),_at(pos.x+1.2,plank_y-0.22),Color("#b78e60"),2.0)
			draw_line(_at(pos.x-1.10,pos.y-2.2),_at(pos.x-0.99,pos.y+0.16),Color("#6c513c"),1.8)
	else:
		# Real, warm building windows. Chimney smoke is cosmetic.
		if night:
			for off in [-0.42,0.45]:
				var p: Vector2 = _at(pos.x+off,pos.y-1.43)
				draw_circle(p,4.6,Color(1.0,0.86,0.48,0.30))
				draw_rect(Rect2(p-Vector2(1.5,1.5),Vector2(3.0,3.0)),Color("#ffd587"))
		if kind in ["mill","dairy","kitchen","farmhouse","barn"] and (hour < 11 or hour >= 16):
			for j in range(3):
				var drift: float = sin(elapsed*0.65+float(j)+index)*2.3
				var smoke: Vector2 = middle + Vector2(drift-2.0,-14.0-float(j)*5.2)
				draw_circle(smoke,2.8+float(j),Color(0.97,0.98,0.96,0.22-float(j)*0.04))

func _draw_world_weather(st: Dictionary, season: int, hour: int) -> void:
	if not show_ambient_effects:
		return
	var kind: String = str(st["weather"].get("kind","clear"))
	var humidity: float = float(st["weather"].get("humidity",0.4))
	# Moving cloud shadows are drawn below the rain, above the world artwork.
	if hour >= 8 and hour < 18 and kind in ["cloudy", "rain"]:
		for i in range(3):
			var x: float = fposmod(elapsed*12.0+float(i)*size.x*0.45,size.x+size.x*0.45)-size.x*0.23
			var p: Vector2 = Vector2(x, size.y*0.12+float(i)*size.y*0.29)
			var r: Rect2 = Rect2(p,Vector2(size.x*0.31,size.y*0.17))
			draw_rect(r,Color(0.20,0.29,0.28,0.045))
	if Visual.should_show_mist(hour,humidity):
		for i in range(7):
			var fy: float = size.y*(0.13+float(i)*0.13)
			var drift: float = sin(elapsed*0.25+float(i)*1.1)*14.0
			draw_line(Vector2(0,fy+drift),Vector2(size.x,fy+drift),Color(0.94,0.97,0.94,0.15),8.0)
	if hour >= 19 or hour < 6:
		var strength: float = 0.39 if hour >= 21 or hour < 5 else 0.27
		var tint: Color = Color(0.07,0.12,0.24,strength)
		draw_rect(Rect2(Vector2.ZERO,size),tint)
		for i in range(12):
			var light: Vector2 = _at(5.0+float(i)*4.9,8.0 if i%2==0 else 51.85)
			draw_circle(light,7.0,Color(1.0,0.87,0.54,0.34))
			draw_circle(light,2.3,Color("#fff3c4"))
	elif hour >= 17:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.45,0.23,0.12,0.14))
	elif hour < 8:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.45,0.36,0.21,0.09))
	if kind == "rain":
		for i in range(Performance59.rain_particles(performance_mode59, 115)):
			var xx: float = fposmod(float((i*31+7)%113)/113.0*size.x+elapsed*13.0,maxf(1.0,size.x))
			var yy: float = fposmod(float((i*47+11)%101)/101.0*size.y+elapsed*79.0,maxf(1.0,size.y))
			draw_line(Vector2(xx,yy),Vector2(xx-6.0,yy+13.0),Color(0.90,0.96,1.0,0.44),1.0)
	if season == 2:
		for i in range(18):
			var xx: float = fposmod(float(i*47+17)*9.0+elapsed*14.0,maxf(1.0,size.x))
			var yy: float = fposmod(float(i*19+3)*7.0+elapsed*9.0,maxf(1.0,size.y))
			var leaf: Color = Color("#cb9450") if i%2==0 else Color("#d5ac63")
			draw_circle(Vector2(xx,yy),1.4,leaf)
	elif season == 3:
		for i in range(32):
			var xx: float = fposmod(float(i*53+17)*7.0+sin(elapsed*0.35+float(i))*8.0,maxf(1.0,size.x))
			var yy: float = fposmod(float(i*23+5)*7.0+elapsed*4.5,maxf(1.0,size.y))
			draw_circle(Vector2(xx,yy),1.35,Color(1.0,1.0,1.0,0.67))

func _paint_seasonal_festival(season: int) -> void:
	if farm == null or farm.state.is_empty():
		return
	var day: int = int(farm.state["time"]["day"])
	var local_day: int = 1+(day-1)%12
	if local_day < 9:
		return
	# Four entirely procedural decorations linked to the real in-game calendar.
	# This is visual only; the Festival screen owns all transactions and rewards.
	var banner: Color = [Color("#f6bbcb"),Color("#e7ca78"),Color("#f2aa73"),Color("#a7c4ee")][season]
	for i in range(10):
		var x: float = 23.2+float(i)*1.75
		var y: float = 5.15 + 0.22*sin(float(i)*1.4)
		draw_line(_at(x,y-1.0),_at(x,y+0.65),Color("#84705b"),1.0)
		var pennant: PackedVector2Array = PackedVector2Array([_at(x-0.62,y-0.7),_at(x+0.65,y-0.7),_at(x,y+0.15)])
		draw_colored_polygon(pennant,banner if i%2==0 else Color("#f9eed1"))
	for i in range(5):
		var lamp: Vector2 = _at(25.2+float(i)*3.5,6.8)
		draw_circle(lamp,3.0,Color("#ffe49b"))
		draw_arc(lamp,5.5,0.0,TAU,14,Color("#9a7649"),1.2)
	var name: String = ["FLORACIÓN","VERANO","COSECHA","INVIERNO"][season] if farm.language == "es" else ["BLOSSOM","SUMMER FAIR","HARVEST","HEARTH"][season]
	_word(name,29.2,7.3,Color("#67482e"),12)

func trigger_work_effect57(kind: String, field_id: String) -> void:
	# Purely visual. Only successful actions should trigger this from Main.
	if reduced_motion or not ["plant", "irrigate", "harvest", "fertilize", "aerateSoil", "mulch", "compost", "coverCrop", "spreadCompost", "plantHedgerow"].has(kind):
		return
	if not field_id.begins_with("plot"):
		return
	work_kind57 = kind
	work_field57 = field_id
	work_started57 = elapsed
	queue_redraw()

func _draw_work_effect57() -> void:
	if work_started57 < 0.0 or reduced_motion:
		return
	var age57: float = elapsed - work_started57
	if age57 > 1.9:
		return
	var slot57: int = int(work_field57.trim_prefix("plot")) - 1
	if slot57 < 0 or slot57 >= 24:
		return
	var ox57: float = GRID_X[slot57 % 6] + FIELD_W * 0.5
	var oy57: float = GRID_Y[int(slot57 / 6)] + FIELD_H * 0.5
	var particle_tint57: Color = Color("#78d6f5") if work_kind57 == "irrigate" else (Color("#e8c86f") if work_kind57 == "harvest" else Color("#a8e2a2"))
	particle_tint57.a = clampf(1.0 - age57 / 1.9, 0.0, 0.8)
	for particle57 in range(9):
		var theta57: float = float(particle57) * TAU / 9.0
		var rx57: float = cos(theta57) * (0.55 + age57 * 1.5)
		var ry57: float = sin(theta57) * (0.55 + age57 * 0.9)
		draw_circle(_at(ox57 + rx57, oy57 + ry57), maxf(1.6, 3.6 * (1.0 - age57 / 2.1)), particle_tint57)

func _draw_garden_slots57(state_data: Dictionary) -> void:
	var decorations57: Array = state_data.get("decorations", [])
	for garden_index57 in range(Living57.GARDEN_SLOTS):
		var garden_pos57: Vector2 = Living57.garden_anchor(garden_index57)
		var taken57: bool = not Living57.decoration_at(decorations57, garden_index57).is_empty()
		var chosen57: bool = garden_index57 == active_garden_slot57
		var marker57: Vector2 = _at(garden_pos57.x, garden_pos57.y)
		var marker_color57: Color = Color("#f9d77c") if chosen57 else (Color("#b4d6cc") if taken57 else Color("#f6f3df"))
		draw_circle(marker57, 12.5 if chosen57 else 9.0, Color(0.10, 0.20, 0.17, 0.65))
		draw_circle(marker57, 10.0 if chosen57 else 7.0, marker_color57)
		if ThemeDB.fallback_font != null:
			draw_string(ThemeDB.fallback_font, marker57 + Vector2(-5.0, 4.0), str(garden_index57 + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#294338"))

func _draw_machine_yard57(state_data: Dictionary) -> void:
	var owned57: Dictionary = state_data.get("life", {}).get("machines", {})
	var current57: int = int(state_data.get("time", {}).get("total", 0))
	for machine_index57 in range(Living57.MACHINE_ORDER.size()):
		var machine_id57: String = str(Living57.MACHINE_ORDER[machine_index57])
		if not owned57.has(machine_id57):
			continue
		var machine57: Dictionary = owned57[machine_id57]
		var point57: Vector2 = Living57.machine_anchor(machine_index57)
		_paint_building_pad(point57.x, point57.y, 4.3)
		var damaged57: bool = Living57.machine_broken(machine57, current57)
		var tint57: Color = Color("#b7aaa2") if damaged57 else (Color("#eccba2") if float(machine57.get("condition", 1.0)) < 0.4 else Color.WHITE)
		_sprite("machine57_" + machine_id57, point57.x - 2.35, point57.y - 3.15, 4.7, 3.0, tint57)
		if damaged57:
			_word("!", point57.x + 0.9, point57.y - 2.1, Color("#b54b43"), 14)
		elif not reduced_motion and elapsed > 0.0:
			var pulse57: Vector2 = _at(point57.x + 1.25, point57.y - 2.2)
			draw_circle(pulse57, 2.2, Color(0.95, 0.93, 0.62, 0.40 + 0.25 * sin(elapsed * 2.5)))

func _draw() -> void:
	var season: int = 0
	if farm != null and not farm.state.is_empty():
		season = int(farm.state["time"]["season"]) % 4
	_paint_meadow(season)
	if season == 3:
		draw_rect(Rect2(Vector2.ZERO,size),Color(0.83,0.90,0.99,0.13))
	_paint_river()
	_paint_paths()
	_paint_trees(season)
	_paint_village(season)
	_paint_pasture()
	_paint_seasonal_festival(season)
	if farm == null or farm.state.is_empty():
		for i in range(24):
			_draw_field(i,{},false)
		return
	var st: Dictionary = farm.state
	for i in range(st["fields"].size()):
		var f: Dictionary = st["fields"][i]
		_draw_field(i,f,bool(f["owned"]))
		_paint_field_overlay_51(i,f)
	# Material stockpiles near the path are useful visual cues.
	for i in range(4):
		var mid: String = ["timber","stone","clay","wildflowers"][i]
		if farm.stock(mid) > 0.01:
			_paint_building_pad(39.0+float(i)*3.4,46.25,2.5)
			_sprite("icon_"+mid,37.95+float(i)*3.4,43.55,2.65,2.65)
	# Structure pads, construction tint and decorative entry paths.
	for i in range(st["buildings"].size()):
		var b: Dictionary = st["buildings"][i]
		var p: Vector2 = _structure_position(b,i)
		_paint_building_pad(p.x,p.y,3.2 if str(b.get("field",""))=="" else 2.1)
		var icon: String = "building_"+str(b["kind"])
		if not art.has(icon):
			icon = "building_workshop"
		var pending: bool = int(b["target"]) > int(b["level"])
		var scaled: bool = str(b.get("field","")) != ""
		_sprite(icon,p.x-(1.05 if scaled else 1.45),p.y-(1.95 if scaled else 2.75),2.10 if scaled else 2.90,2.25 if scaled else 3.2,Color("#d9c5aa") if pending else Color.WHITE)
		if pending:
			var scaffolding: Rect2 = _rect(p.x-1.15,p.y-2.3,2.25,1.9)
			draw_rect(scaffolding,Color("#b78b58"),false,1.4)
			_word("...",p.x-0.6,p.y-2.6,Color("#f7e2aa"),12)
		_draw_building_extras(str(b["kind"]),p,pending,int(st["time"]["hour"]),i)
		if labels_on:
			_word(str(b["kind"]).substr(0,9),p.x-1.35,p.y+0.70,Color("#325345"),10)
	if show_build_slots:
		var occupied_slots: Dictionary = {}
		for placed in st["buildings"]:
			if str(placed.get("field","")) == "":
				occupied_slots[int(placed.get("slot",-1))] = true
		for empty_slot in range(Life.CONSTRUCTION_SLOT_COUNT):
			if occupied_slots.has(empty_slot):
				continue
			var where: Vector2 = _building_anchor(empty_slot)
			var focused: bool = empty_slot == active_build_slot
			draw_circle(_at(where.x,where.y-0.6),7.5 if focused else 5.4,Color("#f1c75f") if focused else Color(0.97,0.89,0.58,0.80))
			_word(str(empty_slot+1),where.x-0.35,where.y-0.41,Color("#384a36"),10)
	_draw_machine_yard57(st)
	for obj in st.get("decorations",[]):
		var slot: int = int(obj["slot"])
		var dx: float = 12.2+float(slot%12)*4.0
		var dy: float = 9.9 if slot < 12 else 49.0
		var asset: String = str(obj["kind"])
		if FarmScript.DECORATIONS.has(asset):
			asset = str(FarmScript.DECORATIONS[asset]["icon"])
		_sprite("decor_"+asset,dx-1.05,dy-2.1,2.10,2.1,Color.WHITE if obj["completed"] else Color(0.84,0.79,0.65,0.68))
		if not bool(obj["completed"]):
			_word("...",dx-0.55,dy-0.1,Color("#fff1b9"),12)
	# Groups now show their real headcount (up to 3 sprites) and living daily behaviour.
	var hour: int = int(st["time"]["hour"])
	for i in range(st["animals"].size()):
		_draw_animal_group(st["animals"][i],i,hour)
	var npc_ids: Array = farm.content["npcs"].keys()
	for i in range(npc_ids.size()):
		var npc_id: String = str(npc_ids[i])
		var npc: Dictionary = farm.content["npcs"][npc_id]
		var p: Vector2 = _npc_position(npc,hour)
		var bob: float = sin(elapsed*1.6+float(i))*0.07
		_sprite("person_"+npc_id,p.x-0.65,p.y-2.1+bob,1.35,2.10)
		if labels_on and zoom>1.2:
			_word(str(npc.get("name",{}).get("en",npc_id)),p.x-1.25,p.y-2.24,Color("#335a49"),10)
	_draw_player(st["player"])
	# Pollinators and birds use animation time, never the simulation RNG.
	var owned_pollen: float = 0.0
	for f in st["fields"]:
		if f["owned"]:
			owned_pollen += float(f["beneficial"].get("bees",0.0))
	for i in range(mini(20,3+int(owned_pollen*1.4))):
		var px: float = 8.0 + fposmod(float(i)*7.9+sin(elapsed*0.75+float(i))*1.5,51.0)
		var py: float = 10.0 + fposmod(float(i)*4.4+cos(elapsed*0.7+float(i))*0.65,31.0)
		var loc: Vector2 = _at(px,py)
		draw_circle(loc,1.7,Color("#f8d66d"))
		draw_line(loc+Vector2(-2.0,-1.1),loc+Vector2(2.0,-1.1),Color(1.0,1.0,1.0,0.78),1.0)
	for i in range(4):
		var bx: float = fposmod(float(i)*20.0+elapsed*(0.45+float(i)*0.10),65.0)
		var by: float = 4.1+sin(elapsed*0.4+float(i)*2.2)*0.68
		var center: Vector2 = _at(bx,by)
		draw_arc(center,5.4,0.0,PI,8,Color("#415e50"),1.5)
		draw_arc(center+Vector2(7,0),5.4,0.0,PI,8,Color("#415e50"),1.5)
	# Living atmosphere reacts to hour, humidity, season and actual weather.
	_draw_world_weather(st,int(st["time"]["season"]) % 4,hour)
	_draw_work_effect57()
	if show_garden_slots57:
		_draw_garden_slots57(st)
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.09,0.14,0.10,0.045))
	_paint_map_hints_51()
	# Selected field plate is always on top and follows the live field state.
	for i in range(st["fields"].size()):
		if "plot"+str(i+1)==selected:
			var r: Rect2 = _field_rect(i)
			var badge: Rect2 = Rect2(r.position+Vector2(2,2),Vector2(maxf(28.0,minf(100.0,r.size.x-4.0)),21.0))
			draw_rect(badge,Color("#ffedb6"))
			if ThemeDB.fallback_font!=null:
				draw_string(ThemeDB.fallback_font,badge.position+Vector2(5,15),"#"+str(i+1)+" SELECTED" if badge.size.x>95 else "#"+str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,OUTLINE)
			break

func _draw_player(player: Dictionary) -> void:
	# World, interiors and portrait derive every color/accessory from the same
	# state. Rendering never mutates game RNG, crops or the saved appearance.
	var look: Dictionary = Style53.normalize(player)
	var x: float = float(player["x"])
	var y: float = float(player["y"])
	var bob: float = 0.055 * sin(elapsed * 4.0)
	var sx: float = size.x / WIDTH * zoom
	var sy: float = size.y / HEIGHT * zoom
	var head: Vector2 = _at(x,y-1.64+bob)
	var radius: float = maxf(3.0,minf(sx,sy)*0.40)
	var skin: Color = Color(str(look["skin"]))
	var coat: Color = Color(str(look["outfit"]))
	var hair_color: Color = Color(str(look["hair_color"]))
	var pants: Color = Color(str(look["pants"]))
	var boots: Color = Color(str(look["boots"]))
	var width_factor: float = 0.56
	if look["body"] == "compact":
		width_factor = 0.48
	elif look["body"] == "broad":
		width_factor = 0.66
	var feet: Vector2 = _at(x,y)
	draw_ellipse_shadow(feet,radius)
	draw_rect(_rect(x-0.42,y-0.78+bob,0.30,0.69),pants)
	draw_rect(_rect(x+0.12,y-0.78+bob,0.30,0.69),pants)
	draw_rect(_rect(x-0.47,y-0.13+bob,0.35,0.19),boots)
	draw_rect(_rect(x+0.12,y-0.13+bob,0.35,0.19),boots)
	draw_rect(_rect(x-width_factor,y-1.44+bob,width_factor*2.0,0.78),coat)
	draw_line(_at(x-0.06,y-1.34+bob),_at(x+0.06,y-0.75+bob),coat.lightened(0.25),1.5)
	draw_circle(_at(x-width_factor,y-1.17+bob),radius*0.43,skin)
	draw_circle(_at(x+width_factor,y-1.17+bob),radius*0.43,skin)
	draw_circle(head,radius,skin)
	var hair: String = str(look["hair"])
	if hair != "bald":
		draw_arc(head+Vector2(0,-radius*0.20),radius*1.02,PI,TAU,14,hair_color,maxf(2.0,radius*0.43),true)
		match hair:
			"waves", "curly":
				for i in range(5):
					draw_circle(head+Vector2(float(i-2)*radius*0.38,-radius*(0.87+(0.17 if hair=="curly" else 0.0))),radius*0.27,hair_color)
			"braids", "long":
				for side in [-1.0,1.0]:
					for i in range(4):
						draw_circle(head+Vector2(side*radius*0.96,float(i)*radius*0.44),radius*0.21,hair_color)
			"bun", "pony":
				draw_circle(head+Vector2(radius*0.65,-radius*0.83),radius*0.36,hair_color)
			"crop", "undercut":
				draw_circle(head+Vector2(0,-radius*0.82),radius*(0.63 if hair=="crop" else 0.48),hair_color)
	if look["facial_hair"] == "moustache" or look["facial_hair"] == "beard":
		draw_line(head+Vector2(-radius*0.33,radius*0.36),head+Vector2(radius*0.33,radius*0.36),hair_color,maxf(1.0,radius*0.15))
	if look["facial_hair"] == "beard":
		draw_arc(head+Vector2(0,radius*0.18),radius*0.65,0.2,PI-0.2,10,hair_color,maxf(1.0,radius*0.2))
	for side in [-1.0,1.0]:
		draw_circle(head+Vector2(side*radius*0.36,radius*0.03),maxf(1.0,radius*0.10),Color(str(look["eyes"])))
	if look["accessory"] in ["scarf","bandana"]:
		var scarf: Color = Color("#d47a65") if look["accessory"] == "scarf" else Color("#eac46e")
		draw_line(_at(x-0.46,y-1.45+bob),_at(x+0.46,y-1.42+bob),scarf,maxf(2.0,radius*0.25))
	elif look["accessory"] == "glasses":
		for side in [-1.0,1.0]:
			draw_arc(head+Vector2(side*radius*0.36,0),radius*0.25,0,TAU,10,Color("#293b38"),1.1)
	elif look["accessory"] in ["flower","laurel"]:
		draw_circle(head+Vector2(radius*0.79,-radius*0.86),maxf(1.0,radius*0.23),Color("#f09bbb") if look["accessory"] == "flower" else Color("#b8d879"))
	if look["hat"] != "none":
		var hat_color: Color = Color("#d4b36e") if look["hat"] == "straw" else (Color("#597f6a") if look["hat"] == "ranger" else Color("#526c85"))
		draw_rect(_rect(x-0.48,y-2.26+bob,0.96,0.23),hat_color)
		if look["hat"] != "beanie":
			draw_line(_at(x-0.70,y-2.02+bob),_at(x+0.70,y-2.02+bob),hat_color,maxf(2.0,radius*0.31))

func draw_ellipse_shadow(feet: Vector2, r: float) -> void:
	# Simple footprint shadow; independent of zoom or simulation state.
	draw_circle(feet + Vector2(0,3),r*0.87,Color(0.12,0.26,0.14,0.16))

func _gui_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	# Touch taps continue through Godot's mouse emulation for existing plot
	# selection. Drag/pinch is handled separately without changing game state.
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points59[event.index] = event.position
		else:
			touch_points59.erase(event.index)
		if touch_points59.size() < 2:
			pinch_last59 = 0.0
		return
	if event is InputEventScreenDrag:
		touch_points59[event.index] = event.position
		if touch_points59.size() >= 2:
			var pts59: Array = touch_points59.values()
			var pos_a59: Vector2 = pts59[0]
			var pos_b59: Vector2 = pts59[1]
			var distance59: float = pos_a59.distance_to(pos_b59)
			if pinch_last59 > 0.0:
				change_zoom(clampf((distance59 - pinch_last59) * 0.006, -0.12, 0.12))
			pinch_last59 = distance59
		else:
			pinch_last59 = 0.0
			camera_offset += event.relative
			camera_offset = camera_offset.limit_length(0.6 * maxf(size.x,size.y))
			camera_target = camera_offset
			queue_redraw()
		accept_event()
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(0.16)
			accept_event()
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(-0.16)
			accept_event()
			return
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			last_pan = event.position
			return
		if not (event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
			return
		if farm == null or farm.state.is_empty():
			return
		var grid: Vector2 = _unat(event.position)
		if show_garden_slots57:
			for garden_index57 in range(Living57.GARDEN_SLOTS):
				if Living57.garden_anchor(garden_index57).distance_to(grid) < 1.70:
					garden_slot_chosen57.emit(garden_index57)
					accept_event()
					return
		for machine_index57 in range(Living57.MACHINE_ORDER.size()):
			var machine_key57: String = str(Living57.MACHINE_ORDER[machine_index57])
			if farm.state["life"]["machines"].has(machine_key57) and Living57.machine_anchor(machine_index57).distance_to(grid) < 2.4:
				machine_chosen57.emit(machine_key57)
				accept_event()
				return
		if show_build_slots:
			for open_slot in range(Life.CONSTRUCTION_SLOT_COUNT):
				var occupied: bool = false
				for building in farm.state["buildings"]:
					if str(building.get("field","")) == "" and int(building.get("slot",-1)) == open_slot:
						occupied = true
						break
				if not occupied and _building_anchor(open_slot).distance_to(grid) < 1.65:
					selected_build_slot.emit(open_slot)
					accept_event()
					return
		if grid.distance_to(Vector2(9.5,5.3)) < 3.2:
			selected_building.emit("farmhouse")
			return
		if grid.distance_to(Vector2(54.2,5.3)) < 3.5:
			selected_building.emit("market")
			return
		for decoration in farm.state.get("decorations",[]):
			var slot: int = int(decoration["slot"])
			var deco_at: Vector2 = Vector2(12.2+float(slot%12)*4.0,9.9 if slot<12 else 49.0)
			if deco_at.distance_to(grid) < 1.45:
				selected_decoration.emit(slot)
				return
		for i in range(farm.state["animals"].size()):
			var animal_data: Dictionary = farm.state["animals"][i]
			var animal_pos: Vector2 = _animal_world_position(i,animal_data,int(farm.state["time"]["hour"]))
			if animal_pos.distance_to(grid) < 1.85:
				selected_animal.emit(str(animal_data["id"]))
				return
		for i in range(farm.state["buildings"].size()):
			if _structure_position(farm.state["buildings"][i],i).distance_to(grid) < 2.1:
				selected_building.emit(str(farm.state["buildings"][i]["id"]))
				return
		var hour: int = int(farm.state["time"]["hour"])
		for id in farm.content["npcs"].keys():
			var point: Vector2 = _npc_position(farm.content["npcs"][id],hour)
			if point.distance_to(grid) < 1.6:
				selected_npc.emit(str(id))
				return
		for i in range(farm.state["fields"].size()):
			var r: Rect2 = Rect2(Vector2(GRID_X[i%6],GRID_Y[int(i/6)]),Vector2(FIELD_W,FIELD_H))
			if r.has_point(grid):
				selected_field.emit("plot"+str(i+1))
				return
		requested_move.emit(clampf(grid.x,1.0,63.0),clampf(grid.y,1.0,53.0))
	elif event is InputEventMouseMotion:
		if panning:
			camera_offset += event.position-last_pan
			camera_offset = camera_offset.limit_length(0.6*maxf(size.x,size.y))
			camera_target = camera_offset
			last_pan = event.position
			queue_redraw()
		elif farm != null and not farm.state.is_empty():
			var pt: Vector2 = _unat(event.position)
			var hover: String = ""
			for i in range(farm.state["fields"].size()):
				var rect: Rect2 = Rect2(Vector2(GRID_X[i%6],GRID_Y[int(i/6)]),Vector2(FIELD_W,FIELD_H))
				if rect.has_point(pt):
					hover = "plot"+str(i+1)
					break
			if hover != hovered_field:
				hovered_field = hover
				queue_redraw()

func _process(delta: float) -> void:
	# Off-screen worlds must not render or consume CPU. The active world still
	# responds immediately to actions, selection, camera motion and zoom.
	if not is_visible_in_tree():
		return
	# Smooth, purely visual zoom and camera travel. Save data is untouched.
	if not reduced_motion:
		var blend: float = clampf(delta*12.0,0.0,1.0)
		if absf(zoom-zoom_target) > 0.0005 or camera_offset.distance_squared_to(camera_target) > 0.10:
			zoom = lerpf(zoom,zoom_target,blend)
			camera_offset = camera_offset.lerp(camera_target,blend)
			queue_redraw()
	else:
		zoom = zoom_target
		camera_offset = camera_target
	if not reduced_motion:
		elapsed += delta
	move_cooldown -= delta
	if not controls_enabled or farm == null or farm.state.is_empty() or not is_visible_in_tree():
		return
	if move_cooldown <= 0.0:
		var focus: Control = get_viewport().gui_get_focus_owner()
		if not (focus is LineEdit or focus is TextEdit or focus is SpinBox):
			var movement: Vector2 = Vector2(Input.get_axis("move_left","move_right"),Input.get_axis("move_up","move_down")) + touchscreen_dir
			if movement.length_squared() > 0.01:
				move_cooldown = 0.12
				var step: Vector2 = movement.normalized() * 0.6
				var person: Dictionary = farm.state["player"]
				requested_move.emit(clampf(float(person["x"])+step.x,1.0,63.0),clampf(float(person["y"])+step.y,1.0,53.0))
	# 5.9 adaptive redraw cadence. Interactions still call queue_redraw().
	redraw_accum += delta
	if redraw_accum >= Performance59.redraw_seconds(performance_mode59,reduced_motion):
		redraw_accum = 0.0
		queue_redraw()
