extends RefCounted
## Shared, original low-poly geometry. No sprites or external model downloads.
## Meshes and materials are cached; crops use instancing in FarmView3D.
const Style = preload("res://scripts/FarmerStyle.gd")
static var materials: Dictionary = {}
static var meshes: Dictionary = {}

static func material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not materials.has(key):
		var result := StandardMaterial3D.new()
		result.albedo_color = color.srgb_to_linear()
		result.roughness = 0.80
		result.metallic = 0.04
		result.specular = 0.35
		result.ao_enabled = true
		result.ao_light_affect = 0.25
		materials[key] = result
	return materials[key]

static func part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, dimensions: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	node.scale = dimensions
	parent.add_child(node)
	return node

static func box(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	if not meshes.has("box"):
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		meshes["box"] = mesh
	return part(parent, meshes["box"], pos, color, dimensions)

static func ball(parent: Node3D, pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
	if not meshes.has("ball"):
		var mesh := SphereMesh.new()
		mesh.radial_segments = 12
		mesh.rings = 6
		meshes["ball"] = mesh
	return part(parent, meshes["ball"], pos, color, dimensions)

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color, top: float = -1.0) -> MeshInstance3D:
	var key: String = "cylinder:%s:%s:%s" % [radius, height, top]
	if not meshes.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius if top < 0.0 else top
		mesh.bottom_radius = radius
		mesh.height = height
		mesh.radial_segments = 12
		mesh.cap_top = true
		mesh.cap_bottom = true
		meshes[key] = mesh
	return part(parent, meshes[key], pos, color)

static func root(parent: Node3D, pos: Vector3 = Vector3.ZERO) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	node.position = pos
	return node

static func label(parent: Node3D, text_value: String, pos: Vector3, font_size: int = 36) -> Label3D:
	var node := Label3D.new()
	node.text = text_value
	node.position = pos
	node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	node.font_size = font_size
	node.pixel_size = 0.020
	node.modulate = Color("#fffae8")
	node.outline_modulate = Color("#203b32")
	node.outline_size = 5
	node.no_depth_test = false
	parent.add_child(node)
	return node

static func hitbox(parent: Node3D, kind: String, id: String, center: Vector3, dimensions: Vector3) -> void:
	var body := StaticBody3D.new()
	body.set_meta("kind", kind)
	body.set_meta("id", id)
	body.position = center
	var shape := CollisionShape3D.new()
	var volume := BoxShape3D.new()
	volume.size = dimensions
	shape.shape = volume
	body.add_child(shape)
	parent.add_child(body)

static func tree(parent: Node3D, pos: Vector3, tint: Color = Color("#63864c"), fruit: bool = false) -> Node3D:
	var node: Node3D = root(parent, pos)
	cylinder(node, Vector3(0, 1.4, 0), 0.28, 2.8, Color("#79543b"), 0.18)
	ball(node, Vector3(0, 3.1, 0), Vector3(3.2, 2.9, 3.1), tint)
	ball(node, Vector3(-0.8, 2.8, 0.5), Vector3(2.1, 1.9, 2.2), tint.darkened(0.08))
	ball(node, Vector3(0.9, 2.9, -0.5), Vector3(1.9, 1.7, 2.0), tint.lightened(0.06))
	for i in range(4):
		var a: float = i * TAU / 4.0
		ball(node, Vector3(cos(a)*0.9, 2.5 + sin(a)*0.3, sin(a)*0.9), Vector3(1.0, 0.9, 1.0), tint.lightened(0.05))
	if fruit:
		for i in range(7):
			var a: float = i * TAU / 7.0
			ball(node, Vector3(cos(a)*1.5, 2.8+sin(a)*0.55, sin(a)*1.5), Vector3.ONE*0.34, Color("#d98948"))
	return node

static func pine(parent: Node3D, pos: Vector3, height: float = 5.0) -> void:
	var node: Node3D = root(parent, pos)
	cylinder(node, Vector3(0, 1, 0), 0.22, 2.0, Color("#70533c"))
	var tiers: Array = [
		[0.36, 0.66, 0.75],
		[0.50, 0.82, 1.00],
		[0.68, 1.00, 1.30],
		[0.86, 1.15, 1.55]
	]
	for i in range(tiers.size()):
		var params: Array = tiers[i]
		cylinder(node, Vector3(0, height*params[0], 0), height*params[1], height*params[2], Color("#4d7658").lightened(i*0.05), 0.0)

static func fence(parent: Node3D, from: Vector3, to: Vector3) -> void:
	var distance: float = from.distance_to(to)
	var count: int = maxi(1, ceili(distance/2.6))
	for i in range(count+1):
		box(parent, from.lerp(to, float(i)/count)+Vector3(0,0.6,0), Vector3(0.17,1.2,0.17), Color("#e1c797"))
	for height in [0.45, 0.94]:
		var rail: MeshInstance3D = box(parent, (from+to)*0.5+Vector3(0,height,0), Vector3(0.10,0.13,distance), Color("#dcc28f"))
		rail.rotation.y = atan2(to.x-from.x, to.z-from.z)

static func roof_mesh() -> ArrayMesh:
	if meshes.has("roof"):
		return meshes["roof"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: Array[Vector3] = [
		Vector3(-0.5,0,-0.5), Vector3(0.5,0,-0.5), Vector3(0,0.68,-0.5),
		Vector3(-0.5,0,0.5), Vector3(0.5,0,0.5), Vector3(0,0.68,0.5),
		Vector3(-0.5,0,-0.5), Vector3(0.5,0,0.5), Vector3(0,0.68,0.5),
		Vector3(-0.5,0,-0.5), Vector3(0,0.68,-0.5), Vector3(-0.5,0,0.5),
		Vector3(0.5,0,-0.5), Vector3(0.5,0,0.5), Vector3(0,0.68,0.5),
		Vector3(0.5,0,-0.5), Vector3(0,0.68,-0.5), Vector3(0,0.68,0.5)
	]
	for vertex in vertices:
		st.add_vertex(vertex)
	st.generate_normals()
	meshes["roof"] = st.commit()
	return meshes["roof"]

static func building(parent: Node3D, kind: String) -> Node3D:
	var node: Node3D = root(parent)
	var wall := Color("#f2dcaf")
	var roof := Color("#b76e4b")
	if kind in ["barn", "stable", "coop", "pigsty", "hutch"]:
		wall = Color("#b7664d")
		roof = Color("#4e6663")
	if kind in ["warehouse", "workshop", "mill", "press", "dairy"]:
		wall = Color("#c0bbaa")
		roof = Color("#587d73")
	if kind in ["pond", "pasture", "wildGarden", "flowers", "fence", "path", "irrigation"]:
		box(node, Vector3(0,0.08,0), Vector3(4.8,0.16,3.6), Color("#5a9c9b") if kind in ["pond","irrigation"] else Color("#87a761"))
		fence(node, Vector3(-2.5,0,-1.9), Vector3(2.5,0,-1.9))
		for i in range(5):
			ball(node, Vector3(-1.8+i*0.9,0.35,0), Vector3(0.7,0.7,0.7), Color("#f0ca75") if kind == "flowers" else Color("#76a866"))
		return node
	box(node, Vector3(0,0.16,0), Vector3(5.8,0.32,4.6), Color("#a99a7d"))
	box(node, Vector3(0,1.72,0), Vector3(5.1,3.1,3.9), wall)
	part(node, roof_mesh(), Vector3(0,3.28,0), roof, Vector3(5.9,2.2,4.9))
	box(node, Vector3(0,1.25,1.95), Vector3(0.95,2.05,0.12), Color("#694d38"))
	for x in [-1.65, 1.65]:
		box(node, Vector3(x,1.95,1.94), Vector3(0.95,0.92,0.15), Color("#fff1cd"))
		box(node, Vector3(x,1.95,2.04), Vector3(0.74,0.72,0.04), Color("#78a9ad"))
		box(node, Vector3(x,1.95,2.08), Vector3(0.055,0.76,0.04), Color("#e5d4b0"))
		box(node, Vector3(x,1.95,2.08), Vector3(0.76,0.055,0.04), Color("#e5d4b0"))
	box(node, Vector3(0,2.16,0), Vector3(0.2,0.18,0.18), Color("#e0c998"))
	if kind == "farmhouse":
		box(node, Vector3(1.5,4.0,-0.6), Vector3(0.65,2.1,0.7), Color("#ccad8d"))
		box(node, Vector3(0,0.25,2.55), Vector3(2.6,0.35,1.2), Color("#d1bc94"))
		box(node, Vector3(1.78,3.1,1.52), Vector3(0.45,0.62,0.1), Color("#7d5d4b"))
	if kind == "greenhouse":
		for x in [-2.0,-1.0,0.0,1.0,2.0]:
			box(node, Vector3(x,1.75,1.98), Vector3(0.75,2.2,0.07), Color("#8ec1b1"))
	if kind == "market":
		for i in range(6):
			box(node, Vector3(-2.25+i*0.9,2.5,2.65), Vector3(0.88,0.15,1.5), Color("#e3a85f") if i%2 else Color("#fff2d2"))
	if kind == "mill":
		var hub: Node3D = root(node, Vector3(0,3.6,2.4))
		for i in range(4):
			var blade: MeshInstance3D = box(hub, Vector3.ZERO, Vector3(0.35,4.0,0.15), Color("#e7d8b3"))
			blade.rotation.z = i*PI/4
	return node

static func farmer(parent: Node3D, source: Dictionary) -> Node3D:
	var look: Dictionary = Style.normalize(source)
	var node: Node3D = root(parent)
	var width: float = 1.18 if look["body"] == "broad" else (0.84 if look["body"] == "compact" else 1.0)
	var skin := Color(str(look["skin"]))
	var hair := Color(str(look["hair_color"]))
	for side in [-1.0,1.0]:
		box(node, Vector3(side*0.19,0.46,0), Vector3(0.31,0.7,0.36), Color(str(look["pants"])))
		box(node, Vector3(side*0.19,0.14,0.08), Vector3(0.35,0.27,0.52), Color(str(look["boots"])))
		ball(node, Vector3(side*0.52*width,1.18,0), Vector3(0.27,0.68,0.32), Color(str(look["outfit"])))
		ball(node, Vector3(side*0.54*width,0.9,0.06), Vector3.ONE*0.24, skin)
	box(node, Vector3(0,1.15,0), Vector3(0.80*width,0.88,0.48), Color(str(look["outfit"])))
	box(node, Vector3(0,1.03,0.25), Vector3(0.52,0.56,0.04), Color(str(look["outfit"])).darkened(0.18))
	box(node, Vector3(0,1.36,0.12), Vector3(0.64,0.18,0.44), Color(str(look["outfit"]).lightened(0.05)))
	ball(node, Vector3(0,1.92,0), Vector3(0.9,0.82,0.74), skin)
	for side in [-1.0,1.0]:
		ball(node, Vector3(side*0.16,1.95,0.35), Vector3.ONE*0.075, Color(str(look["eyes"])))
	ball(node, Vector3(0,1.82,0.41), Vector3(0.12,0.13,0.1), skin.lightened(0.1))
	box(node, Vector3(0,1.73,0.12), Vector3(0.12,0.18,0.18), Color(str(look["outfit"]).darkened(0.2)))
	if look["hair"] != "bald":
		ball(node, Vector3(0,2.19,-0.02), Vector3(0.95,0.42,0.80), hair)
		if look["hair"] in ["long","braids"]:
			for side in [-1.0,1.0]:
				ball(node, Vector3(side*0.38,1.76,-0.13), Vector3(0.24,0.96,0.3), hair)
		if look["hair"] in ["pony","bun"]:
			ball(node, Vector3(0,2.06,-0.46), Vector3(0.36,0.45,0.42), hair)
		if look["hair"] in ["waves","curly"]:
			for i in range(6):
				ball(node, Vector3(-0.34+i*0.14,2.2,-0.02), Vector3.ONE*0.27, hair)
	if look["facial_hair"] != "none":
		ball(node, Vector3(0,1.69,0.26), Vector3(0.5,0.33 if look["facial_hair"] == "beard" else 0.1,0.27), hair)
	if look["hat"] != "none":
		var hat_color := Color("#d9b677") if look["hat"] == "straw" else Color("#506e68")
		cylinder(node, Vector3(0,2.26,0), 0.66 if look["hat"] in ["straw","ranger"] else 0.44, 0.10, hat_color)
		cylinder(node, Vector3(0,2.40,-0.03), 0.36, 0.32, hat_color, 0.28)
		if look["hat"] == "straw":
			box(node, Vector3(0,2.22,0.18), Vector3(0.74,0.08,0.26), Color("#f1d79b"))
	if look["accessory"] in ["scarf","bandana"]:
		box(node, Vector3(0,1.56,0.08), Vector3(0.74,0.18,0.58), Color("#d5815d"))
	if look["accessory"] in ["flower","laurel"]:
		ball(node, Vector3(0.36,2.2,0.15), Vector3.ONE*0.25, Color("#eba6ac") if look["accessory"] == "flower" else Color("#abc76e"))
	if look["accessory"] == "glasses":
		for side in [-1.0,1.0]:
			box(node, Vector3(side*0.16,1.94,0.38), Vector3(0.23,0.18,0.04), Color("#394d4a"))
	return node

static func animal(parent: Node3D, species: String) -> Node3D:
	var node: Node3D = root(parent)
	var bird: bool = species in ["hen","duck","turkey","goose"]
	var tint := Color("#f5e6c5")
	if species in ["cow","horse"]: tint = Color("#a67953")
	if species == "pig": tint = Color("#e4aaa0")
	if species == "goat": tint = Color("#d1b698")
	var s: float = 0.65 if bird else 1.0
	ball(node, Vector3(0,0.92,0), Vector3(1.08,0.95,1.68)*s, tint)
	ball(node, Vector3(0,1.30,0.78)*s, Vector3(0.78,0.72,0.76)*s, tint)
	for side in [-1.0,1.0]:
		ball(node, Vector3(side*0.24,1.40,1.08)*s, Vector3.ONE*0.09*s, Color("#2a3832"))
		for z in [-0.6,0.6]:
			box(node, Vector3(side*0.34,0.34,z)*s, Vector3(0.15,0.62,0.16)*s, Color("#775f40"))
		if species in ["rabbit","horse","goat"]:
			ball(node, Vector3(side*0.32,1.78,0.72)*s, Vector3(0.18,0.65,0.18)*s, tint)
	if bird:
		ball(node, Vector3(0,1.28,1.18)*s, Vector3(0.32,0.2,0.38)*s, Color("#e3a74c"))
		ball(node, Vector3(0,1.7,0.82)*s, Vector3(0.15,0.32,0.42)*s, Color("#c6604a"))
		ball(node, Vector3(0,0.96,1.35)*s, Vector3(0.24,0.14,0.26)*s, Color("#f1d6ab"))
	else:
		box(node, Vector3(0,0.76,1.32)*s, Vector3(0.45,0.35,0.22)*s, Color("#d8c2a2"))
		ball(node, Vector3(0,1.62,1.20)*s, Vector3(0.26,0.24,0.22)*s, tint.lightened(0.08))
	return node

static func decoration(parent: Node3D, kind: String) -> Node3D:
	var node: Node3D = root(parent)
	match kind:
		"bench":
			box(node,Vector3(0,0.6,0),Vector3(1.8,0.18,0.65),Color("#a78251"))
			box(node,Vector3(0,1.05,-0.25),Vector3(1.8,0.7,0.13),Color("#bd9b65"))
			for x in [-0.65,0.65]: box(node,Vector3(x,0.3,0),Vector3(0.15,0.6,0.5),Color("#566b57"))
		"lantern", "birdhouse":
			cylinder(node,Vector3(0,1.1,0),0.10,2.2,Color("#6b5c43"))
			box(node,Vector3(0,2.15,0),Vector3(0.5,0.6,0.5),Color("#f1cc76"))
		"flower_arch":
			for x in [-0.8,0.8]: box(node,Vector3(x,1.2,0),Vector3(0.15,2.4,0.15),Color("#e2d4aa"))
			box(node,Vector3(0,2.4,0),Vector3(1.8,0.2,0.25),Color("#e2d4aa"))
			for i in range(5): ball(node,Vector3(-0.8+i*0.4,2.5,0),Vector3.ONE*0.4,Color("#d5a3a4"))
		_: box(node,Vector3(0,0.1,0),Vector3(2,0.2,1.2),Color("#bebfa7"))
	return node

static func machine(parent: Node3D, kind: String) -> Node3D:
	var node: Node3D = root(parent)
	box(node,Vector3(0,0.8,0),Vector3(1.5,0.8,2.3),Color("#ca8855") if kind == "harvester" else Color("#73917a"))
	box(node,Vector3(0,1.65,0.4),Vector3(1.2,1.0,1.0),Color("#b2d0c6"))
	for x in [-0.85,0.85]:
		for z in [-0.7,0.7]:
			var wheel: MeshInstance3D = cylinder(node,Vector3(x,0.5,z),0.48,0.25,Color("#39483f"))
			wheel.rotation.z = PI/2
	return node

static func crop_mesh(kind: String, stage: int) -> ArrayMesh:
	var group: String = "grain" if kind in ["wheat","oats","barley","rice","corn"] else ("tree" if kind in ["apple","almond","olive","peach"] else ("flower" if kind in ["sunflower","lavender"] else "vegetable"))
	var key: String = "crop:%s:%s:%s" % [group,kind,stage]
	if meshes.has(key): return meshes[key]
	var temp := Node3D.new()
	var height: float = 0.25 + stage*0.30
	var green := Color("#7b9a48")
	if group == "grain":
		for i in range(3):
			cylinder(temp,Vector3((i-1)*0.17,height*0.5,0),0.035,height,green)
			ball(temp,Vector3((i-1)*0.17,height,0),Vector3(0.17,0.38,0.17),Color("#e2bd67") if stage >= 2 else green)
	elif group == "tree":
		tree(temp,Vector3.ZERO,Color("#6a954e"),stage >= 2)
		temp.scale = Vector3.ONE*(0.35+stage*0.15)
	else:
		cylinder(temp,Vector3(0,height*0.5,0),0.045,height,green)
		for side in [-1.0,1.0]:
			ball(temp,Vector3(side*0.18,height*0.55,0),Vector3(0.5,0.16,0.25),green)
		var top := Color("#b8c76b")
		if kind in ["tomato","strawberry","raspberry"]: top = Color("#ce6950")
		if kind in ["pumpkin","carrot","sunflower"]: top = Color("#e8ac53")
		if kind in ["lavender","blueberry","grape"]: top = Color("#a08cb8")
		ball(temp,Vector3(0,height,0),Vector3(0.40,0.30,0.4) if kind != "pumpkin" else Vector3(0.65,0.48,0.65),top if stage >= 2 else green)
	# Bake colored primitives into a single mesh with per-vertex colors.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bake(temp, Transform3D.IDENTITY, st)
	var result: ArrayMesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.vertex_color_is_srgb = false
	mat.roughness = 0.95
	result.surface_set_material(0,mat)
	meshes[key] = result
	temp.free()
	return result

static func _bake(node: Node3D, parent_transform: Transform3D, surface: SurfaceTool) -> void:
	var transform: Transform3D = parent_transform * node.transform
	if node is MeshInstance3D:
		var arrays: Array = node.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(indices.size() if not indices.is_empty() else vertices.size()):
			var index: int = indices[i] if not indices.is_empty() else i
			surface.set_color(node.material_override.albedo_color)
			surface.set_normal((transform.basis.inverse().transposed()*normals[index]).normalized())
			surface.add_vertex(transform*vertices[index])
	for child in node.get_children():
		if child is Node3D: _bake(child,transform,surface)
