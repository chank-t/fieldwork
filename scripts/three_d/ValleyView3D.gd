extends "res://scripts/three_d/Viewport3D.gd"
## A miniature 3D valley. Region IDs and travel actions stay unchanged.
const RegionData = preload("res://scripts/three_d/Regions.gd")
signal region_selected(region_id: String)
var farm: Variant
var selected: String = "village"
var marker: Node3D
var tags: Dictionary = {}
var restored_sites: Dictionary = {}
var saved_language: String = ""

func set_farm(value: Variant) -> void:
	farm = value

func set_selected(value: String) -> void:
	selected = value
	_update_marker()

func _build_scene() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(360,360)
	ground.mesh = plane
	ground.position = Vector3(32,-0.2,27)
	var ground_material := ShaderMaterial.new()
	ground_material.shader = preload("res://scripts/three_d/ground.gdshader")
	ground_material.set_shader_parameter("grass_color",Color("#80a65c"))
	ground_material.set_shader_parameter("haze_color",HAZE)
	ground_material.set_shader_parameter("haze_start",60.0)
	ground_material.set_shader_parameter("haze_end",130.0)
	ground.material_override = ground_material
	stage.add_child(ground)
	# A ring of soft hills and scattered woodland frames the valley.
	for i in range(12):
		Models.ball(stage,Vector3(-3+i*6.5,-0.3,-3-sin(i)*3),Vector3(13,5+i%4,13),Color("#7fa268").lightened((i%3)*0.04))
	for i in range(9):
		Models.ball(stage,Vector3(-30+i*12,-1.0,-16-sin(i*1.7)*5),Vector3(26,14+(i%3)*5,20),Color("#86a678"))
	for i in range(28):
		var a: float = i*TAU/28.0+0.4
		var r: float = 44.0+fmod(i*9.3,10.0)
		var p := Vector3(32+cos(a)*r,0,27+sin(a)*r*0.85)
		if p.z < 2: continue
		Models.tree(stage,p,Color("#638d52").lightened(fmod(i*0.29,0.10)))
	for i in range(40):
		var p := Vector3(4+fmod(i*17.3,58),0,8+fmod(i*11.9,42))
		var clear: bool = true
		for loc in RegionData.LOCATIONS:
			if Vector2(p.x,p.z).distance_to(Vector2(loc["xy"].x*64,loc["xy"].y*54)) < 7.5: clear = false
		if Vector2(p.x,p.z).distance_to(Vector2(0.52*64,0.42*54)) < 9: clear = false
		if clear: Models.ball(stage,p+Vector3(0,0.2,0),Vector3(1.2,0.7,1.2),Color("#6f9a55"))
	for loc in RegionData.LOCATIONS:
		var point: Vector2 = loc["xy"]
		var pos := Vector3(point.x*64,0,point.y*54)
		var node: Node3D = Models.root(stage,pos)
		Models.cylinder(node,Vector3(0,0.08,0),4.0,0.2,Color(str(loc["color"])))
		Models.hitbox(node,"region",str(loc["id"]),Vector3(0,1.6,0),Vector3(8,4,8))
		match str(loc["id"]):
			"village":
				for i in range(3):
					var building: Node3D = Models.building(node,"market" if i == 0 else "farmhouse")
					building.position = Vector3((i-1)*2.7,0,(i%2)*2)
					building.scale = Vector3.ONE*0.5
			"woods", "orchard":
				for i in range(6): Models.tree(node,Vector3(sin(i*2.1)*2.5,0,cos(i*2.1)*2.4),Color("#547e51"),str(loc["id"]) == "orchard")
			"river", "lake", "marsh":
				var pool: MeshInstance3D = Models.cylinder(node,Vector3(0,0.22,0),3.6,0.12,Color("#609d9d"))
				var mat := ShaderMaterial.new()
				mat.shader = preload("res://scripts/three_d/water.gdshader")
				pool.material_override = mat
				for i in range(8): Models.cylinder(node,Vector3(sin(i)*3.6,0.7,cos(i)*3.6),0.08,1.2,Color("#95a765"))
			"hills", "quarry":
				for i in range(4): Models.ball(node,Vector3((i%2)*2-1,1.0,(i/2)*2-1),Vector3(4,3+i%2,4),Color("#c3b18b") if str(loc["id"]) == "hills" else Color("#aaac9a"))
		if loc["id"] == "village":
			var mill := Models.building(node, "mill")
			mill.position = Vector3(1.5, 0, -2.9)
			mill.scale = Vector3.ONE * 0.49
			mill.hide()
			restored_sites["village"] = mill
		elif loc["id"] == "river":
			var channel := Models.root(node, Vector3(-1.8, 0.32, 1.7))
			Models.box(channel, Vector3.ZERO, Vector3(1.2, 0.20, 4.2), Color("#75c6c6"))
			for bank in [-0.75, 0.75]:
				Models.box(channel, Vector3(bank, 0.14, 0), Vector3(0.30, 0.34, 4.2), Color("#d4bd91"))
			Models.box(channel, Vector3(0, 0.38, -0.8), Vector3(1.9, 0.24, 0.95), Color("#a48054"))
			channel.hide()
			restored_sites["river"] = channel
		var tag: Label3D = Models.label(node,"",Vector3(0,6.2,0),60)
		tag.no_depth_test = true
		Models.refresh_tag(tag)
		tags[str(loc["id"])] = tag
		# Raised roads connect actual destinations; they are scenery only.
		var center := Vector3(0.52*64,0.03,0.42*54)
		var d: float = center.distance_to(pos)
		if d > 1:
			var road: MeshInstance3D = Models.box(stage,(center+pos)/2,Vector3(0.9,0.10,d),Color("#d7c49a"))
			road.rotation.y = atan2(pos.x-center.x,pos.z-center.z)
	marker = Models.root(stage)
	var ring := TorusMesh.new()
	ring.inner_radius = 4.2
	ring.outer_radius = 4.45
	ring.rings = 32
	Models.part(marker,ring,Vector3.ZERO,Color("#ffdf8d"))
	desired_size = 58
	_update_marker()

func _update_marker() -> void:
	if marker == null: return
	for loc in RegionData.LOCATIONS:
		if str(loc["id"]) == selected:
			marker.position = Vector3(loc["xy"].x*64,0.4,loc["xy"].y*54)

func _tick(_delta: float) -> void:
	var lang: String = "en" if farm == null else str(farm.language)
	var translated := lang != saved_language
	saved_language = lang
	for loc in RegionData.LOCATIONS:
		var id := str(loc["id"])
		var tag: Label3D = tags[id]
		if not translated and not restored_sites.has(id):
			continue
		var caption := str(loc["label_es"] if lang == "es" else loc["label"])
		if restored_sites.has(id):
			var reopened: bool = farm != null and farm.project_complete(id)
			restored_sites[id].visible = reopened
			if reopened:
				caption += (" · MOLINO ABIERTO" if lang == "es" else " · MILL OPEN") if id == "village" else (" · ACEQUIA ABIERTA" if lang == "es" else " · CHANNEL OPEN")
		if tag.text != caption:
			tag.text = caption
			Models.refresh_tag(tag)
	if marker != null and not reduced_motion59: marker.position.y = 0.4+sin(elapsed*2)*0.09

func _on_picked(kind: String, id: String) -> void:
	if kind == "region": region_selected.emit(id)
