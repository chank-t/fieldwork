extends "res://scripts/three_d/Viewport3D.gd"
## Adapts the original 64 x 54 farm coordinates to real 3D world space.
## Rendering never advances time, spends money or consumes simulation RNG.
const Beauty = preload("res://scripts/BeautifulFarm.gd")
const Living = preload("res://scripts/LivingFarm.gd")
const Life = preload("res://scripts/FarmingLife.gd")
const GRID_X = [7.3,16.6,25.9,35.2,44.5,53.8]
const GRID_Y = [10.8,18.6,26.4,34.2]
const FIELD_W: float = 8.55
const FIELD_H: float = 6.75
signal selected_field(field_id: String)
signal selected_npc(npc_id: String)
signal selected_building(building_id: String)
signal selected_build_slot(slot: int)
signal selected_animal(animal_id: String)
signal selected_decoration(slot: int)
signal requested_move(x: float, y: float)
signal garden_slot_chosen57(slot: int)
signal machine_chosen57(machine_id: String)
var farm: Variant
var selected: String = "plot1"
var overlay_mode: String = "none"
var overlay_numbers59: bool = true
var touchscreen_dir := Vector2.ZERO
var show_growth_labels: bool = true
var show_ambient_effects: bool = true
var show_animal_moods: bool = true
var high_visibility_labels: bool = false
var show_build_slots: bool = false
var show_garden_slots57: bool = false
var active_garden_slot57: int = -1
var active_build_slot: int = -1
var plot_roots: Dictionary = {}
var plot_signatures: Dictionary = {}
var plot_tags: Dictionary = {}
var entities: Node3D
var slots: Node3D
var selection: Node3D
var avatar: Node3D
var avatar_signature: String = ""
var entity_signature: String = ""
var slot_signature: String = ""
var sync_accum: float = 0.0
var move_cooldown: float = 0.0
var ground: MeshInstance3D
var water_material: ShaderMaterial
var ground_material: ShaderMaterial
var rain: CPUParticles3D
var feedback: Node3D
var feedback_age: float = 0.0
var scenic: bool = false

func set_farm(value: Variant) -> void:
	farm = value
	plot_signatures.clear()
	entity_signature = ""
	if stage != null: _sync()

func set_selected(value: String) -> void:
	selected = value
	_update_selection()

func focus_field(field_id: String) -> void:
	var index: int = int(field_id.trim_prefix("plot"))-1
	if index < 0 or index >= 24: return
	camera_target = Vector3(GRID_X[index%6]+FIELD_W/2,0,GRID_Y[index/6]+FIELD_H/2)
	desired_size = 24.0

func _build_scene() -> void:
	# One large shaded ground plane that fades into the horizon haze.
	ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(420,420)
	ground.mesh = plane
	ground.position = Vector3(32,-0.15,27)
	ground_material = ShaderMaterial.new()
	ground_material.shader = preload("res://scripts/three_d/ground.gdshader")
	ground_material.set_shader_parameter("haze_color",HAZE)
	ground.material_override = ground_material
	stage.add_child(ground)
	# Roads match the gaps in the saved plot grid.
	Models.box(stage,Vector3(34,-0.09,8.9),Vector3(68,0.12,1.5),Color("#d5bd8b"))
	Models.box(stage,Vector3(33,-0.09,45),Vector3(70,0.12,2.2),Color("#d5bd8b"))
	Models.box(stage,Vector3(4,-0.08,26),Vector3(2.2,0.14,40),Color("#d5bd8b"))
	for i in range(5):
		Models.box(stage,Vector3(34,-0.10,10.0+i*7.8),Vector3(60,0.1,0.65),Color("#c9b17b"))
	for i in range(7):
		Models.box(stage,Vector3(6.9+i*9.3,-0.10,26),Vector3(0.55,0.1,32),Color("#c9b17b"))
	# A real triangulated river, with a wooden bridge.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(45):
		var z0: float = -22+i*2.0
		var z1: float = z0+2.0
		var x0: float = -5.2+sin(z0*0.10)*2.4
		var x1: float = -5.2+sin(z1*0.10)*2.4
		for vertex in [Vector3(x0-2.2,-0.05,z0),Vector3(x1-2.2,-0.05,z1),Vector3(x0+2.2,-0.05,z0),Vector3(x0+2.2,-0.05,z0),Vector3(x1-2.2,-0.05,z1),Vector3(x1+2.2,-0.05,z1)]: st.add_vertex(vertex)
	st.generate_normals()
	var river := MeshInstance3D.new()
	river.mesh = st.commit()
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://scripts/three_d/water.gdshader")
	river.material_override = water_material
	stage.add_child(river)
	for i in range(13): Models.box(stage,Vector3(-10+i*0.65,0.1,8.9),Vector3(0.58,0.20,2.8),Color("#b5935f"))
	Models.fence(stage,Vector3(2,0,48),Vector3(64,0,48))
	Models.fence(stage,Vector3(66,0,10),Vector3(66,0,43))
	for i in range(25):
		var side: bool = i%2 == 0
		var x: float = -12.5+sin(i*2.4)*2.0 if side else 70+sin(i*2.4)*2
		var z: float = -5+(i/2)*5.0
		Models.tree(stage,Vector3(x,0,z),Color("#63874f").lightened((i%3)*0.035))
	for i in range(20):
		Models.pine(stage,Vector3(-12+i*4.7,0,-11-sin(i*1.7)*4),4.2+(i%4)*0.6)
	for i in range(9):
		Models.ball(stage,Vector3(-25+i*13,-0.6,-32-sin(i)*6),Vector3(23,13+(i%3)*5,22),Color("#829b80").lightened((i%3)*0.04))
	# Outer countryside so the edge of the farm reads as more valley, not a cliff.
	for i in range(34):
		var a: float = i*TAU/34.0 + sin(i*3.1)*0.08
		var r: float = 74.0 + fmod(i*13.7,16.0)
		var p := Vector3(32+cos(a)*r,0,27+sin(a)*r*0.92)
		if p.z < -8: continue
		Models.tree(stage,p,Color("#6f9158").lightened(fmod(i*0.37,0.12)))
	for i in range(7):
		Models.ball(stage,Vector3(-48+i*26,-1.2,-58-sin(i*1.3)*8),Vector3(48,24+(i%3)*7,36),Color("#9db394").lightened((i%2)*0.05))
	for i in range(80):
		var x: float = -15+fmod(i*7.371,96)
		var z: float = 50+fmod(i*4.381,14)
		Models.ball(stage,Vector3(x,0.05,z),Vector3(0.7,0.3,0.7),Color("#efcd84") if i%3 else Color("#cda4b4"))
	entities = Models.root(stage)
	slots = Models.root(stage)
	selection = Models.root(stage)
	for offset in [Vector3(-FIELD_W/2,0,0),Vector3(FIELD_W/2,0,0),Vector3(0,0,-FIELD_H/2),Vector3(0,0,FIELD_H/2)]:
		Models.box(selection,offset,Vector3(0.14,0.12,FIELD_H+0.2) if absf(offset.x)>0 else Vector3(FIELD_W+0.2,0.12,0.14),Color("#ffe7a5"))
	rain = CPUParticles3D.new()
	rain.amount = 160
	rain.lifetime = 1.8
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(38,0,30)
	rain.direction = Vector3(0.1,-1,0)
	rain.spread = 0
	rain.initial_velocity_min = 16
	rain.initial_velocity_max = 20
	var drop := BoxMesh.new()
	drop.size = Vector3(0.035,0.6,0.035)
	drop.material = Models.material(Color("#b6d5d8"))
	rain.mesh = drop
	rain.position = Vector3(32,24,27)
	rain.emitting = false
	stage.add_child(rain)
	_sync()

func _plot(field: Dictionary, index: int) -> void:
	var id: String = str(field["id"])
	var crop: Dictionary = field["crop"]
	var phase: int = clampi(int(float(crop.get("development",0))*4),0,3)
	var season: int = int(farm.state["time"]["season"])%4
	var signature: String = str([field["owned"],field.get("plot_type","open"),field["terrain"],crop.get("id",""),phase,int(float(field["soil"]["water"])/10),overlay_mode,int(Beauty.overlay_value(overlay_mode,field)*20),show_growth_labels,high_visibility_labels,overlay_numbers59,season])
	if plot_signatures.get(id,"") == signature: return
	plot_signatures[id] = signature
	if plot_roots.has(id):
		plot_roots[id].free()
	var origin := Vector3(GRID_X[index%6]+FIELD_W/2,0,GRID_Y[index/6]+FIELD_H/2)
	var node: Node3D = Models.root(stage,origin)
	plot_roots[id] = node
	var owned: bool = field["owned"]
	var palette: Array[Color] = [Color("#93ad69"),Color("#abae67"),Color("#b99e6c"),Color("#c5d0b5")]
	var soil_color: Color = Color("#926a46").lerp(Color("#5c4a37"),float(field["soil"]["water"])/maxf(1,float(field["soil"]["capacity"]))) if owned else palette[season]
	if overlay_mode != "none" and owned: soil_color = Beauty.overlay_tint(overlay_mode,Beauty.overlay_value(overlay_mode,field))
	Models.box(node,Vector3(0,0,0),Vector3(FIELD_W,0.18,FIELD_H),soil_color)
	Models.hitbox(node,"field",id,Vector3(0,0.15,0),Vector3(FIELD_W,0.4,FIELD_H))
	if owned:
		for row in range(6): Models.box(node,Vector3(0,0.11,-2.6+row*1.03),Vector3(7.9,0.12,0.26),soil_color.lightened(0.12))
		if str(field.get("plot_type","open")) in ["raised","paddy"]:
			for z in [-FIELD_H/2,FIELD_H/2]: Models.box(node,Vector3(0,0.20,z),Vector3(FIELD_W,0.4,0.14),Color("#c2a071"))
			for x in [-FIELD_W/2,FIELD_W/2]: Models.box(node,Vector3(x,0.20,0),Vector3(0.14,0.4,FIELD_H),Color("#c2a071"))
	elif index%3 == 0:
		for j in range(8): Models.ball(node,Vector3(-3+fmod(j*2.6,6),0.18,-2+fmod(j*1.7,4)),Vector3(0.5,0.4,0.5),palette[season].lightened(0.1))
	if not crop.is_empty():
		var is_tree: bool = str(crop["id"]) in ["apple","almond","olive","peach"]
		var count: int = 6 if is_tree else 48
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = Models.crop_mesh(str(crop["id"]),phase)
		instances.instance_count = count
		for j in range(count):
			var p := Vector3(-3.3+(j%8)*0.94,0.18,-2.6+(j/8)*1.03) if not is_tree else Vector3(-2.7+(j%3)*2.7,0.18,-1.8+(j/3)*3.6)
			instances.set_instance_transform(j,Transform3D(Basis(Vector3.UP,j*0.75),p))
		var plants := MultiMeshInstance3D.new()
		plants.multimesh = instances
		node.add_child(plants)
	Models.box(node,Vector3(-3.4,0.45,2.9),Vector3(0.10,0.9,0.10),Color("#c5ac7c"))
	Models.box(node,Vector3(-3.4,0.93,2.9),Vector3(0.8,0.5,0.12),Color("#ded0a2"))
	var status: String = "%02d" % (index+1)
	if high_visibility_labels: status += "  ✓" if owned else "  +"
	if owned and show_growth_labels and not crop.is_empty():
		status += " · %d%%" % (float(crop.get("development",0))*100)
	if owned and overlay_mode != "none" and overlay_numbers59: status += " · %d%%" % (Beauty.overlay_value(overlay_mode,field)*100)
	if scenic: return
	var tag: Label3D = Models.label(node,status,Vector3(0,1.1,FIELD_H/2+0.2),44)
	# Plot tags are rescaled with the zoom so they stay readable (see _tick).
	tag.set_meta("full_text",status)
	tag.set_meta("short_text","%02d" % (index+1))
	tag.pixel_size = _plot_tag_pixel_size()
	Models.refresh_tag(tag)
	plot_tags[id] = tag

func _building_anchor(index: int) -> Vector3:
	return Vector3(7.6+(index/2%12)*4.42,0,7.5 if index%2 == 0 else 51.8)

func _structure_position(building: Dictionary, index: int) -> Vector3:
	var field_id: String = str(building.get("field",""))
	if field_id.begins_with("plot"):
		var i: int = clampi(int(field_id.trim_prefix("plot"))-1,0,23)
		return Vector3(GRID_X[i%6]+FIELD_W-1.2,0,GRID_Y[i/6]+FIELD_H-1.2)
	return _building_anchor(int(building.get("slot",index)))

func get_field_screen_pos(field_id: String) -> Vector2:
	if not field_id.begins_with("plot"):
		return Vector2(-1.0,-1.0)
	var index: int = int(field_id.trim_prefix("plot"))-1
	if index < 0 or index >= 24:
		return Vector2(-1.0,-1.0)
	var world_position: Vector3 = Vector3(GRID_X[index%6]+FIELD_W/2.0,0.5,GRID_Y[index/6]+FIELD_H/2.0)
	return _screen_position(world_position)

func get_animal_screen_pos(animal_id: String) -> Vector2:
	return _pick_screen_position(entities,"animal",animal_id)

func get_building_screen_pos(building_id: String) -> Vector2:
	return _pick_screen_position(entities,"building",building_id)

func get_garden_slot_screen_pos(slot: int) -> Vector2:
	return _pick_screen_position(slots,"garden_slot",str(slot))

func get_build_slot_screen_pos(slot: int) -> Vector2:
	return _pick_screen_position(slots,"build_slot",str(slot))

func get_machine_screen_pos(machine_id: String) -> Vector2:
	return _pick_screen_position(entities,"machine",machine_id)

func _pick_screen_position(root: Node, kind: String, id: String) -> Vector2:
	if root == null:
		return Vector2(-1.0,-1.0)
	for candidate in root.find_children("*","StaticBody3D",true,false):
		var body: StaticBody3D = candidate
		if str(body.get_meta("kind","")) != kind or str(body.get_meta("id","")) != id:
			continue
		return _screen_position(body.global_position)
	return Vector2(-1.0,-1.0)

func _screen_position(world_position: Vector3) -> Vector2:
	if camera == null or viewport_3d == null or size.x <= 0.0 or size.y <= 0.0:
		return Vector2(-1.0,-1.0)
	var viewport_size: Vector2 = Vector2(viewport_3d.size)
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or camera.is_position_behind(world_position):
		return Vector2(-1.0,-1.0)
	return camera.unproject_position(world_position)*size/viewport_size

func _sync_entities() -> void:
	var signature: String = str([farm.state["buildings"],farm.state["animals"],farm.state.get("decorations",[]),farm.state["life"]["machines"],farm.state["time"]["hour"],show_animal_moods,farm.language])
	if signature == entity_signature: return
	entity_signature = signature
	for child in entities.get_children(): child.free()
	for entry in [["farmhouse",Vector3(9.5,0,3.6)],["market",Vector3(54.2,0,3.6)]]:
		var building: Node3D = Models.building(entities,entry[0])
		building.position = entry[1]
		Models.hitbox(building,"building",entry[0],Vector3(0,2,0),Vector3(5.8,4,4.5))
		Models.label(building,("CASA" if entry[0] == "farmhouse" else "MERCADO") if farm.language == "es" else str(entry[0]).to_upper(),Vector3(0,5.4,0),30)
	for i in range(farm.state["buildings"].size()):
		var data: Dictionary = farm.state["buildings"][i]
		var building: Node3D = Models.building(entities,str(data["kind"]))
		building.position = _structure_position(data,i)
		building.scale = Vector3.ONE*0.63
		Models.hitbox(building,"building",str(data["id"]),Vector3(0,2,0),Vector3(5.8,4.5,4.5))
		if int(data.get("level",0)) == 0:
			Models.label(building,"EN OBRAS" if farm.language == "es" else "BUILDING",Vector3(0,5.5,0),30)
	for i in range(farm.state["animals"].size()):
		var data: Dictionary = farm.state["animals"][i]
		var herd: Node3D = Models.root(entities,Vector3(14+(i%8)*5.4,0,43))
		var count: int = mini(4,int(data.get("count",1)))
		for j in range(count):
			var animal: Node3D = Models.animal(herd,str(data["kind"]))
			animal.position = Vector3((j%2)*1.5,0,(j/2)*1.5)
			animal.rotation.y = sin(i+j)*0.7
		Models.hitbox(herd,"animal",str(data["id"]),Vector3(0.7,1,0.7),Vector3(3.2,2.5,3.2))
		if show_animal_moods: Models.label(herd,"%d · %d%%" % [int(data.get("count",1)),float(data.get("condition",1))*100],Vector3(0.6,2.8,0.6),27)
	for data in farm.state.get("decorations",[]):
		var p: Vector2 = Living.garden_anchor(int(data["slot"]))
		var deco: Node3D = Models.decoration(entities,str(data["kind"]))
		deco.position = Vector3(p.x,0,p.y)
		Models.hitbox(deco,"decoration",str(data["slot"]),Vector3(0,1,0),Vector3(2.0,2.5,1.5))
	for i in range(Living.MACHINE_ORDER.size()):
		var id: String = Living.MACHINE_ORDER[i]
		if not farm.state["life"]["machines"].has(id): continue
		var machine: Node3D = Models.machine(entities,id)
		var p: Vector2 = Living.machine_anchor(i)
		machine.position = Vector3(p.x,0,p.y)
		Models.hitbox(machine,"machine",id,Vector3(0,1,0),Vector3(2.2,2.4,3.0))
	var hour: int = int(farm.state["time"]["hour"])
	var index: int = 0
	for id in farm.content["npcs"]:
		var data: Dictionary = farm.content["npcs"][id]
		var point := Vector2(51,6.5)
		for segment in data.get("schedule",[]):
			if hour >= int(segment.get("from",0)) and hour < int(segment.get("to",24)):
				point = Vector2(float(segment.get("x",35)),float(segment.get("y",14)))
				break
		var npc: Node3D = Models.farmer(entities,{"outfit":["#ac644c","#c49a41","#4f7d9b","#8b5278"][index%4],"hat":"straw" if index%3 == 0 else "none"})
		npc.position = Vector3(point.x,0,point.y)
		npc.rotation.y = index*1.2
		Models.hitbox(npc,"npc",id,Vector3(0,1.2,0),Vector3(1.3,2.6,1.3))
		Models.label(npc,farm.n(data),Vector3(0,2.9,0),25)
		index += 1

func _sync_slots() -> void:
	var signature: String = str([show_build_slots,show_garden_slots57,active_build_slot,active_garden_slot57,farm.state["buildings"],farm.state.get("decorations",[])])
	if signature == slot_signature: return
	slot_signature = signature
	for child in slots.get_children(): child.free()
	if show_build_slots:
		for i in range(Life.CONSTRUCTION_SLOT_COUNT):
			var occupied: bool = false
			for b in farm.state["buildings"]:
				if str(b.get("field","")) == "" and int(b.get("slot",-1)) == i: occupied = true
			if occupied: continue
			var node: Node3D = Models.root(slots,_building_anchor(i))
			Models.box(node,Vector3(0,0.2,0),Vector3(2.4,0.18,2.4),Color("#f3cf7f") if i == active_build_slot else Color("#dfd9b4"))
			Models.hitbox(node,"build_slot",str(i),Vector3(0,0.5,0),Vector3(2.4,1,2.4))
			Models.label(node,"+ %d" % (i+1),Vector3(0,1,0),28)
	if show_garden_slots57:
		for i in range(Living.GARDEN_SLOTS):
			var p: Vector2 = Living.garden_anchor(i)
			var node: Node3D = Models.root(slots,Vector3(p.x,0,p.y))
			Models.cylinder(node,Vector3(0,0.15,0),0.65,0.12,Color("#f3cf7f") if i == active_garden_slot57 else Color("#ccd7be"))
			Models.hitbox(node,"garden_slot",str(i),Vector3(0,0.4,0),Vector3(1.5,0.6,1.5))

func _sync() -> void:
	if farm == null or farm.state.is_empty() or stage == null: return
	for i in range(farm.state["fields"].size()): _plot(farm.state["fields"][i],i)
	_sync_entities()
	_sync_slots()
	var player: Dictionary = farm.state["player"]
	var look: Dictionary = Models.Style.normalize(player)
	var signature: String = str(look)
	if signature != avatar_signature:
		avatar_signature = signature
		if avatar != null: avatar.free()
		avatar = Models.farmer(stage,look)
		avatar.position = Vector3(float(player["x"]),0,float(player["y"]))
	_update_selection()
	var hour: int = int(farm.state["time"]["hour"])
	var night: bool = hour >= 20 or hour < 6
	var golden: bool = hour >= 17 or hour < 8
	sunlight.light_energy = 0.14 if night else (0.46 if golden else 0.50)
	sunlight.light_color = Color("#9fb7d6") if night else (Color("#ffd29a") if golden else Color("#fff0d4"))
	environment.ambient_light_energy = 0.16 if night else 0.22
	environment.ambient_light_color = Color("#9fb0c8") if night else (Color("#f0e2cf") if golden else Color("#dfe9ec"))
	var seasonal: Array[Color] = [Color("#78a25a"),Color("#a1a85c"),Color("#b39a62"),Color("#c4cfbb")]
	ground_material.set_shader_parameter("grass_color",seasonal[int(farm.state["time"]["season"])%4])
	water_material.set_shader_parameter("animate",not reduced_motion)
	rain.emitting = show_ambient_effects and not reduced_motion and str(farm.state["weather"]["kind"]) in ["rain","storm","rainy"] and performance_mode59 != "eco"

func _update_selection() -> void:
	if selection == null: return
	var i: int = int(selected.trim_prefix("plot"))-1
	selection.visible = i >= 0 and i < 24
	if selection.visible: selection.position = Vector3(GRID_X[i%6]+FIELD_W/2,0.23,GRID_Y[floori(float(i)/6.0)]+FIELD_H/2)

func _plot_tag_pixel_size() -> float:
	# Aim for ~14 px tall text whatever the zoom level or panel height.
	var visible_height: float = camera.size if camera != null else camera_size
	return clampf(12.5*visible_height/maxf(200.0,size.y)/44.0,0.008,0.06)

func _tick(delta: float) -> void:
	if farm == null or farm.state.is_empty(): return
	var tag_size: float = _plot_tag_pixel_size()
	# When plots are small on screen (phones, far zoom) show just the number.
	var plot_pixels: float = FIELD_W/maxf(0.0001,tag_size*44.0/12.5)
	var compact_tags: bool = plot_pixels < 62.0
	for tag in plot_tags.values():
		if not is_instance_valid(tag): continue
		var wanted: String = str(tag.get_meta("short_text" if compact_tags else "full_text",tag.text))
		var wanted_size: float = tag_size*(0.85 if compact_tags else 1.0)
		if tag.text != wanted or not is_equal_approx(tag.pixel_size,wanted_size):
			tag.text = wanted
			tag.pixel_size = wanted_size
			Models.refresh_tag(tag)
	sync_accum += delta
	if sync_accum >= 0.25:
		sync_accum = 0
		_sync()
	if avatar != null:
		var p: Dictionary = farm.state["player"]
		var destination := Vector3(float(p["x"]),0,float(p["y"]))
		var difference: Vector3 = destination-avatar.position
		if difference.length_squared() > 0.01:
			avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(difference.x,difference.z),minf(1,delta*12))
			avatar.position = destination if reduced_motion else avatar.position.lerp(destination,1.0-exp(-delta*12))
			if not reduced_motion: avatar.position.y = absf(sin(elapsed*13))*0.10
	move_cooldown -= delta
	if controls_enabled and not scenic and move_cooldown <= 0:
		var focus: Control = get_viewport().gui_get_focus_owner()
		if not (focus is LineEdit or focus is TextEdit or focus is SpinBox):
			var move := Input.get_vector("move_left","move_right","move_up","move_down")+touchscreen_dir
			if move.length_squared() > 0.01:
				move_cooldown = 0.12
				var d: Vector2 = move.normalized()*0.6
				var p: Dictionary = farm.state["player"]
				requested_move.emit(clampf(float(p["x"])+d.x,1,63),clampf(float(p["y"])+d.y,1,53))
	if feedback != null:
		feedback_age += delta
		feedback.position.y += delta*0.8
		if feedback_age >= 1.5:
			feedback.queue_free()
			feedback = null

func _on_picked(kind: String, id: String) -> void:
	match kind:
		"field": selected_field.emit(id)
		"building": selected_building.emit(id)
		"npc": selected_npc.emit(id)
		"animal": selected_animal.emit(id)
		"decoration": selected_decoration.emit(int(id))
		"build_slot": selected_build_slot.emit(int(id))
		"garden_slot": garden_slot_chosen57.emit(int(id))
		"machine": machine_chosen57.emit(id)

func _on_ground(point: Vector3) -> void:
	requested_move.emit(clampf(point.x,1,63),clampf(point.z,1,53))

func trigger_work_effect57(kind: String, field_id: String) -> void:
	var i: int = int(field_id.trim_prefix("plot"))-1
	if i < 0 or i >= 24 or stage == null: return
	if feedback != null: feedback.free()
	feedback = Models.root(stage,Vector3(GRID_X[i%6]+FIELD_W/2,1.5,GRID_Y[i/6]+FIELD_H/2))
	feedback_age = 0
	Models.label(feedback,{"water":"+ AGUA" if farm.language == "es" else "+ WATER","harvest":"COSECHA" if farm.language == "es" else "HARVEST","plant":"SEMBRADO" if farm.language == "es" else "PLANTED"}.get(kind,"✓"),Vector3.ZERO,46)
