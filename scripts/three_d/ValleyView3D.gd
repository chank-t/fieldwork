extends "res://scripts/three_d/Viewport3D.gd"
## A miniature 3D valley. Region IDs and travel actions stay unchanged.
const RegionData = preload("res://scripts/three_d/Regions.gd")
signal region_selected(region_id: String)
var farm: Variant
var selected: String = "village"
var marker: Node3D
var tags: Dictionary = {}
var saved_language: String = ""

func set_farm(value: Variant) -> void:
	farm = value

func set_selected(value: String) -> void:
	selected = value
	_update_marker()

func _build_scene() -> void:
	Models.box(stage,Vector3(32,-1.2,27),Vector3(77,2,65),Color("#89a773"))
	for i in range(12):
		Models.ball(stage,Vector3(-3+i*6.5,-0.3,-3-sin(i)*3),Vector3(13,5+i%4,13),Color("#9aad85"))
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
		var tag: Label3D = Models.label(node,"",Vector3(0,6.2,0),72)
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
	if lang != saved_language:
		saved_language = lang
		for loc in RegionData.LOCATIONS: tags[str(loc["id"])].text = str(loc["label_es"] if lang == "es" else loc["label"])
	if marker != null and not reduced_motion59: marker.position.y = 0.4+sin(elapsed*2)*0.09

func _on_picked(kind: String, id: String) -> void:
	if kind == "region": region_selected.emit(id)
