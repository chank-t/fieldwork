extends "res://scripts/World.gd"
const FarmLife57 = preload("res://scripts/LivingFarm57.gd")
## FIELDWORK 5.6 — A New Perspective
## A true affine 2.5D projection over the existing 64x54 simulation grid.
## No world-state edits occur in this renderer. The inherited input handler
## uses _unat(), so plot, villager, livestock, building and free-walk clicks
## continue to resolve to the original 5.5 gameplay coordinates.

const ISO_SLOPE56: float = 0.56
const OUTLINE56: Color = Color("#355443")
const SOIL56: Color = Color("#aa8157")
const SKY56: Color = Color("#d2ebdc")
const PASTURE56: Color = Color("#7baf82")
const RIM56: Color = Color("#e3d0a0")
const SHADOW56: Color = Color(0.13, 0.22, 0.16, 0.27)
const PLOT56: Dictionary = {"open": 7.0, "raised": 11.0, "orchard": 7.0, "paddy": 4.0}

func _units56() -> float:
	var min_width: float = maxf(128.0, size.x - 44.0)
	var min_height: float = maxf(128.0, size.y - 38.0)
	return maxf(1.0, minf(min_width / (WIDTH + HEIGHT), min_height / ((WIDTH + HEIGHT) * ISO_SLOPE56)))

func _origin56() -> Vector2:
	var step: float = _units56()
	return Vector2(size.x * 0.5 - (WIDTH - HEIGHT) * step * 0.5, size.y * 0.5 - (WIDTH + HEIGHT) * step * ISO_SLOPE56 * 0.5)

func _at(x: float, y: float) -> Vector2:
	var unit: float = _units56()
	var base: Vector2 = _origin56() + Vector2((x - y) * unit, (x + y) * unit * ISO_SLOPE56)
	return (base - size * 0.5) * zoom + size * 0.5 + camera_offset

func _unat(pos: Vector2) -> Vector2:
	var unit: float = maxf(0.01, _units56())
	var projected: Vector2 = (pos - camera_offset - size * 0.5) / maxf(0.01, zoom) + size * 0.5 - _origin56()
	var u: float = projected.x / unit
	var v: float = projected.y / (unit * ISO_SLOPE56)
	return Vector2((u + v) * 0.5, (v - u) * 0.5)

func focus_field(field_id: String) -> void:
	var field_index: int = -1
	for i in range(24):
		if field_id == "plot" + str(i + 1):
			field_index = i
			break
	if field_index < 0:
		return
	zoom_target = maxf(1.35, zoom_target)
	var x: float = GRID_X[field_index % 6] + FIELD_W * 0.5
	var y: float = GRID_Y[int(field_index / 6)] + FIELD_H * 0.5
	var unzoomed: Vector2 = _origin56() + Vector2((x - y) * _units56(), (x + y) * _units56() * ISO_SLOPE56)
	camera_target = (size * 0.5 - unzoomed) * zoom_target
	if reduced_motion:
		zoom = zoom_target
		camera_offset = camera_target
	queue_redraw()

func _corners56(x: float, y: float, width: float, length: float) -> PackedVector2Array:
	return PackedVector2Array([_at(x, y), _at(x + width, y), _at(x + width, y + length), _at(x, y + length)])

func _polygon56(corners: PackedVector2Array, color: Color, edge: Color = Color.TRANSPARENT, thickness: float = 1.0) -> void:
	draw_colored_polygon(corners, color)
	if edge.a > 0.0:
		var outline: PackedVector2Array = corners.duplicate()
		outline.append(corners[0])
		draw_polyline(outline, edge, thickness, true)

func _diamond56(x: float, y: float, w: float, h: float, color: Color, raised: float = 0.0, edge: Color = OUTLINE56) -> void:
	var corners: PackedVector2Array = _corners56(x, y, w, h)
	var side_bottom: Vector2 = Vector2(0.0, maxf(0.0, raised) * zoom)
	if raised > 0.0:
		_polygon56(PackedVector2Array([corners[3], corners[2], corners[2] + side_bottom, corners[3] + side_bottom]), color.darkened(0.28), edge.darkened(0.12), 1.2)
		_polygon56(PackedVector2Array([corners[1], corners[2], corners[2] + side_bottom, corners[1] + side_bottom]), color.darkened(0.39), edge.darkened(0.12), 1.2)
	_polygon56(corners, color, edge, 1.0)
	if raised > 0.0:
		draw_line(corners[3], corners[2], color.lightened(0.20), maxf(1.0, 1.8 * zoom), true)

func _sprite56(id: String, world_x: float, world_y: float, width: float, height: float, tint: Color = Color.WHITE, bob: float = 0.0) -> void:
	if not art.has(id):
		return
	var point: Vector2 = _at(world_x, world_y)
	var unit: float = _units56() * zoom
	var w: float = maxf(4.0, width * unit)
	var h: float = maxf(5.0, height * unit)
	var shadow: Vector2 = point + Vector2(0, 2.5 * zoom)
	draw_circle(shadow, maxf(2.0, w * 0.15), Color(0.13, 0.21, 0.13, 0.16))
	draw_texture_rect(art[id], Rect2(point + Vector2(-w * 0.5, -h - bob), Vector2(w, h)), false, tint)

func _paint_backdrop56(season: int) -> void:
	var seasonal: Array = [Color("#b9d6a0"), Color("#c2d19a"), Color("#d4bc8f"), Color("#cfdfd8")]
	var base: Color = seasonal[season % 4]
	draw_rect(Rect2(Vector2.ZERO, size), SKY56.lerp(base, 0.63))
	for i in range(0, 32, Performance59.terrain_stride(performance_mode59)):
		var pct: float = float(i) / 32.0
		var blend: float = 0.08 + 0.45 * pct
		draw_rect(Rect2(Vector2(0.0, pct * size.y), Vector2(size.x, size.y / 32.0 + 1.0)), SKY56.lerp(base, blend))
	# The whole island has a convincing lower side, not a flat rectangular backdrop.
	_diamond56(0.8, 0.8, 62.4, 52.4, base.darkened(0.12), 19.0, Color("#6e9878"))
	_diamond56(3.0, 3.0, 58.0, 48.0, base, 4.0, Color("#a8c698"))
	# Layered perimeter vegetation; seeded geometrically, never randomly.
	for i in range(0, 30, Performance59.terrain_stride(performance_mode59)):
		var a: float = float(i) * 1.9
		var nx: float = 2.2 + float(i % 10) * 5.9
		var ny: float = 1.3 if i < 15 else 51.2
		if i >= 10 and i < 15:
			ny = 1.5 + (i - 10) * 2.3
		if i >= 25:
			ny = 42.6 + (i - 25) * 2.1
		if i >= 15:
			nx = 3.0 + float((i - 15) % 10) * 5.9
		var sway: float = 0.0 if reduced_motion else sin(elapsed * 0.32 + a) * 0.08
		_sprite56("tree", nx + sway, ny, 2.3 + 0.12 * float(i % 3), 3.1 + 0.13 * float(i % 4), Color("#daeacf") if season == 3 else (Color("#e4bc86") if season == 2 else Color.WHITE))
	# A meandering perimeter stream has depth and highlights.
	var bank: PackedVector2Array = PackedVector2Array()
	for row in range(56):
		var yy: float = float(row) * 53.0 / 55.0
		bank.append(_at(3.3 + 0.45 * sin(yy * 0.3), yy))
	draw_polyline(bank, Color("#cde1be"), maxf(3.0, _units56() * 1.5 * zoom), true)
	draw_polyline(bank, Color("#559eaf"), maxf(2.0, _units56() * 1.1 * zoom), true)
	draw_polyline(bank, Color("#a0d4d0"), maxf(1.0, _units56() * 0.22 * zoom), true)

func _soil56(field: Dictionary, owned: bool, season: int) -> Color:
	if not owned:
		return PASTURE56
	var ground: String = str(field.get("terrain", "loam"))
	var result: Color = SOIL56
	if farm != null and farm.content.has("terrains") and farm.content["terrains"].has(ground):
		result = Color(str(farm.content["terrains"][ground].get("color", "#a9855d")))
	var soil: Dictionary = field.get("soil", {})
	var moisture: float = float(soil.get("water", 50.0)) / maxf(1.0, float(soil.get("capacity", 100.0)))
	if moisture > 0.70:
		result = result.darkened(0.17)
	elif moisture < 0.23:
		result = result.lightened(0.17)
	if season == 3:
		result = result.lerp(Color("#e4eaf0"), 0.22)
	return result

func _plot56(index: int, field: Dictionary, season: int) -> void:
	var x: float = GRID_X[index % 6]
	var y: float = GRID_Y[int(index / 6)]
	var owned: bool = bool(field.get("owned", false))
	var layout: String = str(field.get("plot_type", "open"))
	var depth: float = float(PLOT56.get(layout, 7.0))
	var soil_color: Color = _soil56(field, owned, season)
	_diamond56(x, y, FIELD_W, FIELD_H, soil_color, depth, Color("#efdcac") if owned else Color("#bdd2ad"))
	var overlay_tint: Color = Color.TRANSPARENT
	if owned and overlay_mode != "none":
		var metric: float = Beauty51.overlay_value(overlay_mode, field)
		overlay_tint = Beauty51.overlay_tint(overlay_mode, metric)
		_polygon56(_corners56(x + 0.15, y + 0.15, FIELD_W - 0.3, FIELD_H - 0.3), overlay_tint)
	# Open fields run along the projected rows; raised beds have their own
	# layered ridges, paddies retain blue standing water, and orchards get trees.
	if layout == "paddy" and owned:
		_polygon56(_corners56(x + 0.38, y + 0.40, FIELD_W - 0.76, FIELD_H - 0.80), Color(0.33, 0.70, 0.78, 0.48), Color("#b0d9cd"), 1.2)
		for k in range(3):
			var yy: float = y + 1.3 + float(k) * 1.8
			draw_line(_at(x + 0.62, yy), _at(x + FIELD_W - 0.62, yy), Color(0.78, 0.95, 0.95, 0.78), 1.2 * zoom, true)
	else:
		for k in range(4):
			var yy: float = y + 1.15 + float(k) * 1.23
			var ridge: Color = soil_color.darkened(0.15 if owned else 0.09)
			draw_line(_at(x + 0.52, yy), _at(x + FIELD_W - 0.52, yy), ridge, (2.6 if layout == "raised" else 1.3) * zoom, true)
			draw_line(_at(x + 0.52, yy + 0.13), _at(x + FIELD_W - 0.52, yy + 0.13), soil_color.lightened(0.24), 1.2 * zoom, true)
	if owned and bool(field.get("hedgerow", false)):
		for k in range(6):
			_sprite56("grass_flowers", x + 0.6 + float(k) * 1.28, y + 0.38, 1.05, 1.10)
	var crop: Dictionary = field.get("crop", {})
	# This value is also used by the label after the crop-drawing branch.
	# GDScript function branches have separate scopes; keep it here.
	var development: float = clampf(float(crop.get("development", 0.0)), 0.0, 1.0)
	if owned and not crop.is_empty():
		var crop_id: String = str(crop.get("id", "wheat"))
		var stage: int = Visual.crop_stage(development)
		if layout == "orchard" and int(crop.get("harvest_cycles", 0)) > 0:
			stage = maxi(3, stage)
		var image_id: String = "growth_" + crop_id + "_" + str(stage) if stage < 4 else "crop_" + crop_id
		var count_x: int = 3 if layout == "orchard" else 4
		var count_y: int = 2 if layout == "orchard" else 3
		var plant_width: float = 2.25 if layout == "orchard" else 1.35
		var plant_height: float = (3.85 if layout == "orchard" else 2.25) * (0.36 + development * 0.65)
		var plant_tint: Color = Color.WHITE if Visual.plant_health(field) > 0.62 else Color("#d5ba81")
		for row in range(count_y):
			for col in range(count_x):
				var px: float = x + (float(col) + 0.55) * FIELD_W / float(count_x)
				var py: float = y + (float(row) + 0.65) * FIELD_H / float(count_y)
				var sway: float = 0.0 if reduced_motion else 2.0 * sin(elapsed * 1.4 + float(col) * 0.8 + float(row) * 1.5)
				_sprite56(image_id, px, py, plant_width, plant_height, plant_tint, sway)
	elif not owned:
		for k in range(3):
			_sprite56("grass_flowers", x + 1.5 + float(k) * 2.6, y + 2.8, 1.25, 1.30, Color("#e4f0d8"))
	if owned and float(field.get("soil", {}).get("erosion", 0.0)) > 0.2:
		for k in range(3):
			var xx: float = x + 1.2 + float(k) * 2.55
			draw_line(_at(xx, y + 1.0), _at(xx + 1.0, y + 4.4), Color("#784f3d"), 1.3 * zoom, true)
	if show_growth_labels or high_visibility_labels or (overlay_numbers59 and overlay_mode != "none"):
		var short_id: String = "#" + str(index + 1)
		var state_text: String = short_id if owned else ("VENTA " if farm.language == "es" else "SALE ") + short_id
		if owned and not crop.is_empty() and development >= 0.995:
			state_text += " +"
		if owned and overlay_numbers59 and overlay_mode != "none":
			var metric59: float = Beauty51.overlay_value(overlay_mode,field)
			state_text += "  " + str(int(metric59 * 100.0)) + "%"
		var label_pos: Vector2 = _at(x + 0.25, y + FIELD_H - 0.20) + Vector2(-4.0, -depth * zoom + 8.0)
		_label56(state_text, label_pos, 11, Color("#f7f2e6"), Color("#29543d"))
	var field_id: String = "plot" + str(index + 1)
	if selected == field_id or hovered_field == field_id:
		var outline: PackedVector2Array = _corners56(x, y, FIELD_W, FIELD_H)
		outline.append(outline[0])
		draw_polyline(outline, Color("#ffe5a0") if selected == field_id else Color("#ffffff"), 3.5 if selected == field_id else 2.0, true)

func _label56(label: String, pos: Vector2, font_size: int = 12, background: Color = Color("#f8f3dc"), foreground: Color = OUTLINE56) -> void:
	if ThemeDB.fallback_font == null:
		return
	var text_width: float = maxf(26.0, float(label.length()) * float(font_size) * 0.59 + 11.0)
	var plate: Rect2 = Rect2(pos - Vector2(4.0, 16.0), Vector2(text_width, 19.0))
	draw_rect(plate, background)
	draw_string(ThemeDB.fallback_font, plate.position + Vector2(5.0, 13.7), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, foreground)

func _building56(kind: String, x: float, y: float, pending: bool = false, scale_factor: float = 1.0) -> void:
	_diamond56(x - 2.0, y - 1.5, 4.0, 3.0, Color("#c2b18c"), 8.0, Color("#d9c9a5"))
	var icon_id: String = "building_" + kind
	if not art.has(icon_id):
		icon_id = "building_workshop"
	_sprite56(icon_id, x, y, 6.9 * scale_factor, 5.6 * scale_factor, Color("#c9b49b") if pending else Color.WHITE)
	if pending:
		_label56("...", _at(x, y) + Vector2(-2.0, -_units56() * 6.0), 13)

func _villager56(npc_id: String, npc: Dictionary, hour: int, index: int) -> void:
	var point: Vector2 = _npc_position(npc, hour)
	var bob: float = 0.0 if reduced_motion else 1.4 * sin(elapsed * 1.7 + float(index))
	_sprite56("person_" + npc_id, point.x, point.y, 1.65, 2.9, Color.WHITE, bob)
	if high_visibility_labels and labels_on:
		_label56(npc_id.capitalize(), _at(point.x, point.y) + Vector2(-14.0, -_units56() * 3.2), 10)

func _animal56(animal: Dictionary, index: int, hour: int) -> void:
	var pos: Vector2 = _animal_world_position(index, animal, hour)
	for n in range(mini(3, maxi(0, int(animal.get("count", 0))))):
		_sprite56("animal_" + str(animal.get("kind", "hen")), pos.x + 0.35 * float(n), pos.y + float(n) * 0.34, 2.1, 2.1, Color.WHITE)

func _player56(player: Dictionary) -> void:
	var style: Dictionary = Style53.normalize(player)
	var at_pos: Vector2 = _at(float(player.get("x", 20.0)), float(player.get("y", 20.0)))
	var u: float = maxf(2.5, _units56() * zoom)
	var bob: float = 0.0 if reduced_motion else sin(elapsed * 3.0) * 1.2
	var head: Vector2 = at_pos + Vector2(0.0, -2.9 * u - bob)
	var body_color: Color = Color(str(style.get("outfit", "#527a61")))
	var skin_color: Color = Color(str(style.get("skin", "#c99e78")))
	var hair_color: Color = Color(str(style.get("hair_color", "#503c30")))
	draw_circle(at_pos + Vector2(0.0, 2.5), maxf(2.0, u * 0.65), SHADOW56)
	draw_colored_polygon(PackedVector2Array([at_pos + Vector2(-0.8 * u, -1.2 * u), at_pos + Vector2(0.8 * u, -1.2 * u), at_pos + Vector2(0.56 * u, -0.1 * u), at_pos + Vector2(-0.6 * u, -0.1 * u)]), body_color)
	draw_circle(head, maxf(2.4, u * 0.60), skin_color)
	if str(style.get("hair", "short")) != "bald":
		draw_arc(head + Vector2(0.0, -0.12 * u), 0.61 * u, PI, TAU, 10, hair_color, maxf(2.0, 0.3 * u), true)
	if str(style.get("hat", "none")) != "none":
		draw_line(head + Vector2(-0.76 * u, -0.58 * u), head + Vector2(0.72 * u, -0.58 * u), Color("#c6a471"), maxf(2.0, 0.24 * u), true)
	draw_line(at_pos + Vector2(-0.30 * u, -0.10 * u), at_pos + Vector2(-0.37 * u, 0.3 * u), Color(str(style.get("boots", "#4d493f"))), maxf(2.0, 0.25 * u), true)
	draw_line(at_pos + Vector2(0.30 * u, -0.10 * u), at_pos + Vector2(0.35 * u, 0.3 * u), Color(str(style.get("boots", "#4d493f"))), maxf(2.0, 0.25 * u), true)

func _weather56(season: int, hour: int) -> void:
	if not show_ambient_effects:
		return
	if hour >= 19 or hour < 6:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.13, 0.25, 0.40 if hour >= 21 or hour < 5 else 0.26))
	elif hour >= 17:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.50, 0.27, 0.11, 0.10))
	elif hour < 8:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.39, 0.42, 0.35, 0.08))
	var weather: String = str(farm.state.get("weather", {}).get("kind", "clear"))
	if weather == "rain":
		for i in range(Performance59.rain_particles(performance_mode59,95)):
			var x: float = fposmod(float((i * 41 + 17) % 101) / 101.0 * size.x + elapsed * 18.0, maxf(1.0, size.x))
			var y: float = fposmod(float((i * 53 + 23) % 107) / 107.0 * size.y + elapsed * 86.0, maxf(1.0, size.y))
			draw_line(Vector2(x, y), Vector2(x - 4.0, y + 13.0), Color(0.92, 0.97, 1.0, 0.48), 1.0)
	elif season == 3:
		for i in range(26):
			var x: float = fposmod(float((i * 33 + 8) % 103) / 103.0 * size.x + sin(elapsed * 0.4 + float(i)) * 7.0, maxf(1.0, size.x))
			var y: float = fposmod(float((i * 39 + 11) % 113) / 113.0 * size.y + elapsed * 5.0, maxf(1.0, size.y))
			draw_circle(Vector2(x, y), 1.5, Color(1.0, 1.0, 1.0, 0.55))

func _draw_machine_yard57(state_data: Dictionary) -> void:
	var owned57: Dictionary = state_data.get("life", {}).get("machines", {})
	var current57: int = int(state_data.get("time", {}).get("total", 0))
	for index57 in range(FarmLife57.MACHINE_ORDER.size()):
		var id57: String = str(FarmLife57.MACHINE_ORDER[index57])
		if not owned57.has(id57):
			continue
		var machine57: Dictionary = owned57[id57]
		var pos57: Vector2 = FarmLife57.machine_anchor(index57)
		_diamond56(pos57.x - 1.8, pos57.y - 1.2, 3.6, 2.4, Color("#c6b795"), 4.5, Color("#d9ceb4"))
		var broken57: bool = FarmLife57.machine_broken(machine57, current57)
		var machine_tint57: Color = Color("#9b9d9a") if broken57 else (Color("#e6c298") if float(machine57.get("condition", 1.0)) < 0.40 else Color.WHITE)
		_sprite56("machine57_" + id57, pos57.x, pos57.y, 5.6, 4.0, machine_tint57)
		var projected57: Vector2 = _at(pos57.x, pos57.y)
		if broken57:
			_label56("!", projected57 + Vector2(4.0, -_units56() * 4.4), 13, Color("#ab4439"), Color.WHITE)
		elif not reduced_motion:
			var live57: float = sin(elapsed * (1.9 + float(index57) * 0.35))
			var accent57: Color = Color(0.90, 0.95, 0.63, 0.28 + 0.25 * (0.5 + live57 * 0.5))
			draw_circle(projected57 + Vector2(_units56() * 0.8, -_units56() * 2.3), 3.0, accent57)
			if id57 == "pump" and int(state_data.get("time", {}).get("hour", 0)) in [6, 7, 8, 9, 16, 17]:
				for drop57 in range(3):
					var drift57: float = fposmod(elapsed * 2.0 + float(drop57) * 0.5, 1.0)
					draw_circle(projected57 + Vector2(12.0 + float(drop57) * 4.0, -15.0 + 20.0 * drift57), 2.0, Color(0.62, 0.87, 1.0, 0.55))

func _draw() -> void:
	var season: int = 0
	if farm != null and not farm.state.is_empty():
		season = int(farm.state.get("time", {}).get("season", 0)) % 4
	_paint_backdrop56(season)
	if farm == null or farm.state.is_empty():
		return
	var st: Dictionary = farm.state
	# A consistent back-to-front painter order keeps crops, animals and roofs
	# visually coherent while leaving all gameplay coordinates untouched.
	for row in range(4):
		for col in range(6):
			var i: int = row * 6 + col
			if i < st["fields"].size():
				_plot56(i, st["fields"][i], season)
	# Village square; clicks remain at the same farmhouse/market coordinates.
	_building56("farmhouse", 9.5, 5.3, false, 1.14)
	_building56("market", 54.2, 5.3, false, 1.14)
	for i in range(st["buildings"].size()):
		var b: Dictionary = st["buildings"][i]
		var pos: Vector2 = _structure_position(b, i)
		_building56(str(b.get("kind", "workshop")), pos.x, pos.y, int(b.get("target", 0)) > int(b.get("level", 0)), 0.88 if str(b.get("field", "")) != "" else 1.0)
	if show_build_slots:
		var occupied: Dictionary = {}
		for b in st["buildings"]:
			if str(b.get("field", "")) == "":
				occupied[int(b.get("slot", -1))] = true
		for i in range(Life.CONSTRUCTION_SLOT_COUNT):
			if occupied.has(i):
				continue
			var pt: Vector2 = _building_anchor(i)
			var target: Vector2 = _at(pt.x, pt.y - 0.6)
			var picked: bool = i == active_build_slot
			draw_circle(target, 8.0 if picked else 5.0, Color("#ffd983") if picked else Color("#f2d499"))
			_label56(str(i + 1), target + Vector2(-5.0, 4.0), 10)
	_draw_machine_yard57(st)
	for decoration in st.get("decorations", []):
		var slot: int = int(decoration.get("slot", 0))
		var deco_id: String = str(decoration.get("kind", "bench"))
		if FarmScript.DECORATIONS.has(deco_id):
			deco_id = str(FarmScript.DECORATIONS[deco_id].get("icon", deco_id))
		_sprite56("decor_" + deco_id, 12.2 + float(slot % 12) * 4.0, 9.9 if slot < 12 else 49.0, 2.4, 2.7)
	var hour: int = int(st["time"].get("hour", 12))
	for i in range(st["animals"].size()):
		_animal56(st["animals"][i], i, hour)
	var npc_ids: Array = farm.content.get("npcs", {}).keys()
	for i in range(npc_ids.size()):
		var id: String = str(npc_ids[i])
		_villager56(id, farm.content["npcs"][id], hour, i)
	_player56(st["player"])
	_weather56(season, hour)
	_draw_work_effect57()
	if show_garden_slots57:
		_draw_garden_slots57(st)
	# Small map legend retains clarity on phones and in panoramic view.
	if size.x > 315.0:
		var legend: String = "ISOMETRIC 2.5D  |  " + ("TOCA PARA ELEGIR" if farm.language == "es" else "CLICK TO SELECT")
		_label56(legend, Vector2(14.0, maxf(30.0, size.y - 27.0)), 11)
