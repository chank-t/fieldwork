extends RefCounted
## Shared, original low-poly geometry. No sprites or external model downloads.
## Meshes and materials are cached; crops use instancing in FarmView3D.
const Style = preload("res://scripts/FarmerStyle.gd")
const GameFont = preload("res://assets/fonts/FieldSans.ttf")
const CropWind = preload("res://scripts/three_d/crop_wind.gdshader")
static var materials: Dictionary = {}
static var meshes: Dictionary = {}
static var crop_material: ShaderMaterial

static func material(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html()
	if not materials.has(key):
		var result := StandardMaterial3D.new()
		# albedo_color is already interpreted as sRGB by the engine; converting
		# here as well darkened and over-saturated every model.
		result.albedo_color = color
		result.roughness = 0.85
		result.metallic = 0.0
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
	node.modulate = Color("#fffcf0")
	node.outline_modulate = Color("#14261e")
	node.outline_size = 4
	node.render_priority = 2
	node.outline_render_priority = 1
	node.no_depth_test = false
	parent.add_child(node)
	# A rounded backing keeps names readable on bright grass and crops.
	var pill := MeshInstance3D.new()
	pill.mesh = QuadMesh.new()
	pill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pill.position = pos
	parent.add_child(pill)
	node.set_meta("pill",pill)
	_fit_pill(node)
	return node

## Use after changing a tag's text, pixel size or depth test.
static func refresh_tag(node: Label3D) -> void:
	_fit_pill(node)

static func _fit_pill(node: Label3D) -> void:
	var pill: MeshInstance3D = node.get_meta("pill",null)
	if pill == null or not is_instance_valid(pill): return
	pill.visible = node.text.strip_edges() != "" and node.visible
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,-1,node.font_size)
	var reference: float = 0.020
	var dimensions := Vector2(text_size.x + node.font_size*0.9, node.font_size*1.35) * reference
	var mat: ShaderMaterial = pill.material_override
	var shader_path: String = "res://scripts/three_d/pill_nodepth.gdshader" if node.no_depth_test else "res://scripts/three_d/pill.gdshader"
	if mat == null or mat.shader.resource_path != shader_path:
		mat = ShaderMaterial.new()
		mat.shader = load(shader_path)
		mat.render_priority = 0
		pill.material_override = mat
	(pill.mesh as QuadMesh).size = dimensions
	mat.set_shader_parameter("size",dimensions)
	pill.scale = Vector3.ONE * (node.pixel_size/reference)
	pill.position = node.position

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

static func tree(parent: Node3D, pos: Vector3, tint: Color = Color("#63864c"), fruit: bool = false, fruit_color: Color = Color("#d98948")) -> Node3D:
	var node: Node3D = root(parent, pos)
	var foliage: Array[MeshInstance3D] = []
	cylinder(node, Vector3(0, 1.4, 0), 0.28, 2.8, Color("#79543b"), 0.18)
	var crown: MeshInstance3D = ball(node, Vector3(0, 3.1, 0), Vector3(3.2, 2.9, 3.1), tint)
	crown.set_meta("foliage_base",tint)
	foliage.append(crown)
	var left_crown: Color = tint.darkened(0.08)
	var left_leaf: MeshInstance3D = ball(node, Vector3(-0.8, 2.8, 0.5), Vector3(2.1, 1.9, 2.2), left_crown)
	left_leaf.set_meta("foliage_base",left_crown)
	foliage.append(left_leaf)
	var right_crown: Color = tint.lightened(0.06)
	var right_leaf: MeshInstance3D = ball(node, Vector3(0.9, 2.9, -0.5), Vector3(1.9, 1.7, 2.0), right_crown)
	right_leaf.set_meta("foliage_base",right_crown)
	foliage.append(right_leaf)
	for i in range(4):
		var a: float = i * TAU / 4.0
		var detail_color: Color = tint.lightened(0.05)
		var detail_leaf: MeshInstance3D = ball(node, Vector3(cos(a)*0.9, 2.5 + sin(a)*0.3, sin(a)*0.9), Vector3(1.0, 0.9, 1.0), detail_color)
		detail_leaf.set_meta("foliage_base",detail_color)
		foliage.append(detail_leaf)
	node.set_meta("foliage_parts",foliage)
	if fruit:
		for i in range(7):
			var a: float = i * TAU / 7.0
			ball(node, Vector3(cos(a)*1.5, 2.8+sin(a)*0.55, sin(a)*1.5), Vector3.ONE*0.34, fruit_color)
	return node

static func set_tree_season(tree_node: Node3D, season: int) -> void:
	var palettes: Array[Color] = [Color("#96cb70"),Color("#63864c"),Color("#c87945"),Color("#b4c3c6")]
	var strengths: Array[float] = [0.60,0.08,0.70,0.90]
	var season_index: int = posmod(season,4)
	for part in tree_node.get_meta("foliage_parts",[]):
		var base: Color = part.get_meta("foliage_base",Color("#63864c"))
		part.material_override = material(base.lerp(palettes[season_index],strengths[season_index]))

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
	if kind in ["pond","irrigation"]:
		box(node,Vector3(0,0.08,0),Vector3(4.8,0.16,3.6),Color("#57999d") if kind == "pond" else Color("#a88a5e"))
		if kind == "pond":
			for i in range(4):
				var x: float = -1.7+i*1.05
				cylinder(node,Vector3(x,0.72,-1.2),0.045,1.2,Color("#658b54"),0.02)
				ball(node,Vector3(x+0.28,0.2,-0.5),Vector3(0.65,0.08,0.42),Color("#82a866"))
				ball(node,Vector3(x,0.17,1.15),Vector3.ONE*0.28,Color("#d7c399"))
		else:
			for z in [-1.0,0.0,1.0]:
				box(node,Vector3(0,0.19,z),Vector3(4.5,0.10,0.18),Color("#6f9d99"))
		return node
	if kind in ["pasture","wildGarden","flowers","fence","path"]:
		box(node,Vector3(0,0.08,0),Vector3(4.8,0.16,3.6),Color("#87a761") if kind != "path" else Color("#d2b988"))
		if kind != "path":
			fence(node,Vector3(-2.5,0,-1.9),Vector3(2.5,0,-1.9))
		for i in range(7):
			var color: Color = Color("#f0ca75") if i%3 == 0 else (Color("#c9829d") if i%3 == 1 else Color("#f2e3b2"))
			var plant_pos := Vector3(-1.8+fmod(i*1.37,3.7),0.35,-1.1+fmod(i*0.83,2.1))
			ball(node,plant_pos,Vector3(0.45,0.52,0.45),Color("#76a866"))
			if kind == "flowers":
				ball(node,plant_pos+Vector3(0,0.32,0),Vector3.ONE*0.22,color)
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
	if kind == "coop":
		box(node,Vector3(0,0.28,2.55),Vector3(1.2,0.52,0.85),Color("#8e6042"))
		box(node,Vector3(0,0.78,2.98),Vector3(1.1,0.08,0.8),Color("#d8b96f"))
		for x in [-1.1,1.1]:
			box(node,Vector3(x,0.65,2.05),Vector3(0.62,0.36,0.12),Color("#e5c986"))
	if kind == "hutch":
		for x in [-1.4,1.4]:
			for z in [-0.8,0.8]:
				box(node,Vector3(x,0.65,z),Vector3(0.12,1.3,0.12),Color("#765c43"))
		for i in range(5):
			box(node,Vector3(-1.1+i*0.55,1.15,1.98),Vector3(0.07,1.4,0.07),Color("#c3b28e"))
	if kind == "barn":
		box(node,Vector3(0,2.2,-2.0),Vector3(1.5,0.75,0.12),Color("#ead4a6"))
		box(node,Vector3(0,1.05,2.04),Vector3(2.2,1.7,0.16),Color("#824e3e"))
	if kind == "stable":
		for x in [-2.0,0.0,2.0]:
			box(node,Vector3(x,0.75,2.08),Vector3(0.95,1.5,0.14),Color("#785b42"))
	if kind == "pigsty":
		box(node,Vector3(0,0.52,2.12),Vector3(2.4,0.75,0.18),Color("#a98567"))
		for x in [-1.3,1.3]:
			cylinder(node,Vector3(x,0.72,2.28),0.12,0.55,Color("#cfc2aa"))
	if kind == "warehouse":
		for i in range(3):
			box(node,Vector3(-1.7+i*1.7,0.58,2.62),Vector3(1.15,1.0,0.75),Color("#a87d4d").lightened(i*0.05))
	if kind == "workshop":
		box(node,Vector3(-1.85,4.0,-1.15),Vector3(0.75,1.8,0.8),Color("#867565"))
		cylinder(node,Vector3(-1.85,5.0,-1.15),0.34,0.24,Color("#5e6761"))
		cylinder(node,Vector3(1.8,2.0,2.12),0.55,0.18,Color("#d6b66e"))
	if kind == "dairy":
		for x in [-1.45,1.45]:
			cylinder(node,Vector3(x,0.95,2.6),0.52,1.6,Color("#d6dfd3"),0.42)
			cylinder(node,Vector3(x,1.79,2.6),0.18,0.12,Color("#768e83"))
	if kind == "academy":
		box(node,Vector3(0,3.55,2.08),Vector3(1.0,0.7,0.16),Color("#6d897a"))
		cylinder(node,Vector3(0,3.58,2.2),0.34,0.08,Color("#e2ca84"))
	return node

static func farmer(parent: Node3D, source: Dictionary, animate_idle: bool = true) -> Node3D:
	var look: Dictionary = Style.normalize(source)
	var node: Node3D = root(parent)
	var width: float = 1.18 if look["body"] == "broad" else (0.84 if look["body"] == "compact" else 1.0)
	var skin := Color(str(look["skin"]))
	var hair := Color(str(look["hair_color"]))
	var outfit := Color(str(look["outfit"]))
	var torso: Node3D = root(node,Vector3(0,1.12,0))
	torso.name = "torso"
	var upper: Node3D = root(torso,Vector3(0,-1.12,0))
	upper.name = "upper"
	for side in [-1.0,1.0]:
		var leg: Node3D = root(node,Vector3(side*0.19,0.79,0))
		leg.name = "leg_left" if side < 0 else "leg_right"
		box(leg,Vector3(0,-0.33,0),Vector3(0.31,0.7,0.36),Color(str(look["pants"])))
		box(leg,Vector3(0,-0.65,0.08),Vector3(0.35,0.27,0.52),Color(str(look["boots"])))
		var arm: Node3D = root(upper,Vector3(side*0.4*width,1.52,0))
		arm.name = "arm_left" if side < 0 else "arm_right"
		ball(arm,Vector3(side*0.12,-0.34,0),Vector3(0.27,0.68,0.32),outfit)
		ball(arm,Vector3(side*0.14,-0.62,0.06),Vector3.ONE*0.24,skin)
	box(upper, Vector3(0,1.15,0), Vector3(0.80*width,0.88,0.48), outfit)
	box(upper, Vector3(0,1.03,0.25), Vector3(0.52,0.56,0.04), outfit.darkened(0.18))
	box(upper, Vector3(0,1.36,0.12), Vector3(0.64,0.18,0.44), outfit.lightened(0.05))
	ball(upper, Vector3(0,1.92,0), Vector3(0.9,0.82,0.74), skin)
	for side in [-1.0,1.0]:
		ball(upper, Vector3(side*0.16,1.95,0.35), Vector3.ONE*0.075, Color(str(look["eyes"])))
	ball(upper, Vector3(0,1.82,0.41), Vector3(0.12,0.13,0.1), skin.lightened(0.1))

	if look["hair"] != "bald":
		ball(upper, Vector3(0,2.19,-0.02), Vector3(0.95,0.42,0.80), hair)
		if look["hair"] in ["long","braids"]:
			for side in [-1.0,1.0]:
				ball(upper, Vector3(side*0.38,1.76,-0.13), Vector3(0.24,0.96,0.3), hair)
		if look["hair"] in ["pony","bun"]:
			ball(upper, Vector3(0,2.06,-0.46), Vector3(0.36,0.45,0.42), hair)
		if look["hair"] in ["waves","curly"]:
			for i in range(6):
				ball(upper, Vector3(-0.34+i*0.14,2.2,-0.02), Vector3.ONE*0.27, hair)
	if look["facial_hair"] != "none":
		ball(upper, Vector3(0,1.69,0.26), Vector3(0.5,0.33 if look["facial_hair"] == "beard" else 0.1,0.27), hair)
	if look["hat"] != "none":
		var hat_color := Color("#d9b677") if look["hat"] == "straw" else Color("#506e68")
		cylinder(upper, Vector3(0,2.26,0), 0.66 if look["hat"] in ["straw","ranger"] else 0.44, 0.10, hat_color)
		cylinder(upper, Vector3(0,2.40,-0.03), 0.36, 0.32, hat_color, 0.28)
		if look["hat"] == "straw":
			box(upper, Vector3(0,2.22,0.18), Vector3(0.74,0.08,0.26), Color("#f1d79b"))
	if look["accessory"] in ["scarf","bandana"]:
		box(upper, Vector3(0,1.56,0.08), Vector3(0.74,0.18,0.58), Color("#d5815d"))
	if look["accessory"] in ["flower","laurel"]:
		ball(upper, Vector3(0.36,2.2,0.15), Vector3.ONE*0.25, Color("#eba6ac") if look["accessory"] == "flower" else Color("#abc76e"))
	if look["accessory"] == "glasses":
		for side in [-1.0,1.0]:
			box(upper, Vector3(side*0.16,1.94,0.38), Vector3(0.23,0.18,0.04), Color("#394d4a"))
	node.set_meta("idle_animation",false)
	if animate_idle and node.is_inside_tree():
		var idle: Tween = node.create_tween().set_loops()
		idle.tween_property(torso,"rotation:x",0.018,1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle.tween_property(torso,"rotation:x",-0.018,1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		node.set_meta("idle_animation",true)
	return node

static func pose_farmer(node: Node3D, phase: float, walk_weight: float, work_action: String = "", work_weight: float = 0.0) -> void:
	var arm_left: Node3D = node.get_node_or_null("torso/upper/arm_left") as Node3D
	var arm_right: Node3D = node.get_node_or_null("torso/upper/arm_right") as Node3D
	var leg_left: Node3D = node.get_node_or_null("leg_left") as Node3D
	var leg_right: Node3D = node.get_node_or_null("leg_right") as Node3D
	var torso: Node3D = node.get_node_or_null("torso") as Node3D
	if arm_left == null or arm_right == null or leg_left == null or leg_right == null or torso == null: return
	var swing: float = sin(phase)*0.48*clampf(walk_weight,0.0,1.0)
	arm_left.rotation.x = swing
	arm_right.rotation.x = -swing
	leg_left.rotation.x = -swing*0.8
	leg_right.rotation.x = swing*0.8
	torso.rotation.x = 0.0
	var reach: float = clampf(work_weight,0.0,1.0)
	if reach <= 0.0: return
	match work_action:
		"plant":
			torso.rotation.x = 0.18*reach
			arm_left.rotation.x = lerpf(arm_left.rotation.x,-0.45,reach)
			arm_right.rotation.x = lerpf(arm_right.rotation.x,-1.05,reach)
			leg_left.rotation.x += 0.12*reach
			leg_right.rotation.x += 0.12*reach
		"irrigate","water":
			torso.rotation.x = 0.10*reach
			arm_left.rotation.x = lerpf(arm_left.rotation.x,-0.58,reach)
			arm_right.rotation.x = lerpf(arm_right.rotation.x,-0.88,reach)
		"harvest":
			torso.rotation.x = 0.27*reach
			arm_left.rotation.x = lerpf(arm_left.rotation.x,-0.82,reach)
			arm_right.rotation.x = lerpf(arm_right.rotation.x,-0.92,reach)
			leg_left.rotation.x += 0.22*reach
			leg_right.rotation.x += 0.22*reach

static func animal(parent: Node3D, species: String, variant: int = 0, animate_idle: bool = true) -> Node3D:
	var node: Node3D = root(parent)
	var body: Node3D = root(node)
	var limbs: Array[Node3D] = []
	var bird: bool = species in ["hen","duck","turkey","goose"]
	var tint: Color = {
		"cow":Color("#eee5d2"),"horse":Color("#9a6948"),"pig":Color("#e4aaa0"),
		"goat":Color("#cdb596"),"sheep":Color("#e6dfc9"),"alpaca":Color("#ddc9a7"),
		"rabbit":Color("#dfd5c5"),"duck":Color("#e0c65e"),"turkey":Color("#8d6550"),
		"goose":Color("#ece8dc")
	}.get(species,Color("#b98550") if species == "hen" else Color("#f5e6c5"))
	var shade: float = fposmod(float(variant)*0.19,0.12)
	tint = tint.lightened(shade)
	var scale_factor: float = 0.94 + fposmod(float(variant)*0.13,0.12)
	node.scale = Vector3.ONE*scale_factor
	if bird:
		var bird_scale: float = 0.66 if species != "turkey" else 0.76
		var bird_body: Vector3 = Vector3(1.08,0.92,1.35)
		if species == "duck": bird_body = Vector3(1.28,0.78,1.48)
		if species == "goose": bird_body = Vector3(0.98,1.02,1.6)
		ball(body,Vector3(0,0.9,0),bird_body*bird_scale,tint)
		for side in [-1.0,1.0]:
			var wing_color: Color = tint.darkened(0.08)
			var wing: MeshInstance3D = ball(body,Vector3(side*0.43,1.0,0.1)*bird_scale,Vector3(0.24,0.42,0.88)*bird_scale,wing_color)
			wing.rotation.x = side*0.16
			limbs.append(wing)
			var bird_leg: Node3D = root(body,Vector3(side*0.18,0.28,0.25)*bird_scale)
			box(bird_leg,Vector3.ZERO,Vector3(0.11,0.42,0.12)*bird_scale,Color("#d49c43"))
			limbs.append(bird_leg)
		if species == "goose":
			cylinder(body,Vector3(0,1.32,0.62)*bird_scale,0.16*bird_scale,0.72*bird_scale, tint)
			ball(body,Vector3(0,1.73,0.72)*bird_scale,Vector3(0.48,0.46,0.48)*bird_scale,tint)
		else:
			ball(body,Vector3(0,1.34,0.62)*bird_scale,Vector3(0.52,0.55,0.52)*bird_scale,tint)
		for side in [-1.0,1.0]:
			ball(body,Vector3(side*0.13,1.42,0.84)*bird_scale,Vector3.ONE*0.075*bird_scale,Color("#27352e"))
		var beak_color: Color = Color("#e39c3c") if species == "duck" else Color("#d9ad4b")
		var beak_size: Vector3 = Vector3(0.38,0.14,0.38) if species == "duck" else Vector3(0.20,0.18,0.34)
		ball(body,Vector3(0,1.27,0.98)*bird_scale,beak_size*bird_scale,beak_color)
		if species == "hen":
			for i in range(3):
				ball(body,Vector3(-0.12+i*0.12,1.69,0.57)*bird_scale,Vector3(0.14,0.24,0.12)*bird_scale,Color("#c85d48"))
		elif species == "turkey":
			for i in range(5):
				var feather: MeshInstance3D = ball(body,Vector3(-0.4+i*0.2,1.18,-0.75)*bird_scale,Vector3(0.22,0.58,0.18)*bird_scale,Color("#b78b54").darkened(float(i%2)*0.12))
				feather.rotation.z = (float(i)-2.0)*0.16
		else:
			for i in range(3):
				ball(body,Vector3(-0.18+i*0.18,1.0,-0.78)*bird_scale,Vector3(0.16,0.32,0.15)*bird_scale,tint.darkened(0.06))
	else:
		var body_size: Vector3 = Vector3(1.08,0.95,1.68)
		if species == "cow": body_size = Vector3(1.48,1.25,1.92)
		if species == "horse": body_size = Vector3(0.92,1.18,1.82)
		if species == "pig": body_size = Vector3(1.24,0.92,1.48)
		if species == "goat": body_size = Vector3(0.94,1.02,1.48)
		if species == "sheep": body_size = Vector3(1.3,1.20,1.6)
		if species == "alpaca": body_size = Vector3(1.0,1.38,1.32)
		if species == "rabbit": body_size = Vector3(0.78,0.76,1.08)
		ball(body,Vector3(0,0.92,0),body_size,tint)
		for side in [-1.0,1.0]:
			for z in [-0.56,0.56]:
				var leg_height: float = 0.66 if species != "horse" else 0.88
				var leg: Node3D = root(body,Vector3(side*body_size.x*0.31,leg_height*0.5,z))
				box(leg,Vector3.ZERO,Vector3(0.17,leg_height,0.18),Color("#775f40"))
				limbs.append(leg)
			ball(body,Vector3(side*body_size.x*0.18,1.35,0.74),Vector3.ONE*0.08,Color("#27352e"))
		var head_pos: Vector3 = Vector3(0,1.34,0.85)
		if species == "alpaca": head_pos = Vector3(0,1.85,0.76)
		if species == "horse": head_pos = Vector3(0,1.45,0.92)
		var head_size: Vector3 = Vector3(0.72,0.7,0.72)
		if species == "horse": head_size = Vector3(0.52,0.84,0.6)
		if species == "pig": head_size = Vector3(0.78,0.72,0.65)
		if species == "rabbit": head_size = Vector3(0.58,0.58,0.58)
		ball(body,head_pos,head_size,tint)
		if species == "cow":
			for spot in [Vector3(-0.45,1.2,-0.12),Vector3(0.5,0.72,-0.5),Vector3(0.42,1.3,0.26)]:
				ball(body,spot,Vector3(0.36,0.32,0.25),Color("#6e5748"))
			for side in [-1.0,1.0]:
				cylinder(body,head_pos+Vector3(side*0.3,0.37,0),0.11,0.34,Color("#e9d8b6"),0.02)
			ball(body,Vector3(0,0.48,0.1),Vector3(0.48,0.35,0.42),Color("#d69582"))
		elif species == "horse":
			box(body,Vector3(0,1.53,0.45),Vector3(0.55,0.88,0.15),Color("#5d4538"))
			var tail: Node3D = root(body,Vector3(0,1.1,-0.9))
			cylinder(tail,Vector3(0,-0.38,-0.12),0.11,0.8,Color("#5d4538"),0.03)
		elif species == "pig":
			ball(body,Vector3(0,1.28,1.18),Vector3(0.55,0.4,0.3),Color("#c98078"))
			for side in [-1.0,1.0]:
				var ear: MeshInstance3D = ball(body,Vector3(side*0.28,1.75,0.62),Vector3(0.3,0.44,0.16),tint.darkened(0.08))
				ear.rotation.z = side*0.35
		elif species in ["goat","sheep","alpaca"]:
			if species == "sheep" or species == "alpaca":
				for i in range(7):
					var angle: float = float(i)*TAU/7.0
					ball(body,Vector3(cos(angle)*0.42,1.28,sin(angle)*0.55),Vector3.ONE*0.42,Color("#f1ead8") if species == "sheep" else Color("#eee0c7"))
			if species == "goat":
				for side in [-1.0,1.0]:
					cylinder(body,head_pos+Vector3(side*0.26,0.44,-0.02),0.12,0.48,Color("#8c7257"),0.015)
				ball(body,Vector3(0,0.82,1.08),Vector3(0.2,0.34,0.2),Color("#a88c69"))
		elif species == "rabbit":
			for side in [-1.0,1.0]:
				var ear: MeshInstance3D = ball(body,Vector3(side*0.2,2.0,0.78),Vector3(0.18,0.72,0.16),tint)
				ear.rotation.z = side*0.2
			ball(body,Vector3(0,0.72,-0.65),Vector3.ONE*0.28,Color("#f6efe3"))
		else:
			ball(body,Vector3(0,1.3,1.18),Vector3(0.3,0.28,0.24),tint.lightened(0.08))
	var idle_duration: float = 1.25+fposmod(float(variant)*0.17,0.45)
	node.set_meta("idle_animation",false)
	if animate_idle and node.is_inside_tree():
		var idle: Tween = node.create_tween().set_loops()
		idle.tween_property(body,"position:y",0.07,idle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle.parallel().tween_property(body,"rotation:z",0.04,idle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle.tween_property(body,"position:y",0.0,idle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		idle.parallel().tween_property(body,"rotation:z",-0.04,idle_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		for i in range(limbs.size()):
			var limb_tween: Tween = node.create_tween().set_loops()
			var angle: float = 0.11 if i%2 == 0 else -0.11
			limb_tween.tween_property(limbs[i],"rotation:x",angle,idle_duration*0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			limb_tween.tween_property(limbs[i],"rotation:x",-angle,idle_duration*0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		node.set_meta("idle_animation",true)
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
	var group: String = "grain" if kind in ["wheat","oats","barley","rice","maize","rye"] else ("orchard" if kind in ["apple","almond","olive"] else ("vine" if kind == "grape" else ("flower" if kind in ["sunflower","lavender"] else ("root" if kind in ["carrot","beetroot","potato"] else ("leafy" if kind in ["lettuce","basil"] else "fruiting")))))
	var key: String = "crop:%s:%s:%s" % [group,kind,stage]
	if meshes.has(key): return meshes[key]
	var temp := Node3D.new()
	var height: float = 0.28+stage*0.38
	match group:
		"grain":
			_crop_grain(temp,kind,stage,height)
		"orchard":
			var leaf_color: Color = Color("#698f4b") if kind == "apple" else (Color("#82965b") if kind == "olive" else Color("#81a45e"))
			var fruit_color: Color = Color("#d45e4b") if kind == "apple" else (Color("#87964d") if kind == "olive" else Color("#d8c29a"))
			tree(temp,Vector3.ZERO,leaf_color,stage >= 2,fruit_color)
			temp.scale = Vector3.ONE*(0.27+stage*0.12)
			if kind == "almond" and stage == 1:
				for i in range(9):
					var angle: float = float(i)*TAU/9.0
					ball(temp,Vector3(cos(angle)*0.85,3.0+sin(angle)*0.5,sin(angle)*0.85),Vector3.ONE*0.24,Color("#e7b6b0"))
		"vine":
			_crop_vine(temp,stage,height)
		"flower":
			_crop_flower(temp,kind,stage,height)
		"root":
			_crop_root(temp,kind,stage,height)
		"leafy":
			_crop_leafy(temp,kind,stage,height)
		_:
			_crop_fruiting(temp,kind,stage,height)
	# Bake colored primitives into a single mesh with per-vertex colors.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bake(temp, Transform3D.IDENTITY, st)
	var result: ArrayMesh = st.commit()
	if crop_material == null:
		crop_material = ShaderMaterial.new()
		crop_material.shader = CropWind
	result.surface_set_material(0,crop_material)
	meshes[key] = result
	temp.free()
	return result

static func _crop_grain(parent: Node3D, kind: String, stage: int, height: float) -> void:
	var stem_color: Color = Color("#6f9c4e")
	var head_color: Color = Color("#d9b653") if stage >= 2 else stem_color.lightened(0.1)
	if kind == "maize":
		cylinder(parent,Vector3(0,height*0.52,0),0.11,height,stem_color,0.07)
		for side in [-1.0,1.0]:
			for i in range(3):
				var leaf: MeshInstance3D = ball(parent,Vector3(side*(0.28+i*0.08),height*(0.3+i*0.2),0),Vector3(0.78,0.1,0.24),Color("#78a952"))
				leaf.rotation.z = side*(0.22+float(i)*0.09)
		if stage >= 2:
			for y in [0.52,0.83]:
				ball(parent,Vector3(0.17,y,0.04),Vector3(0.22,0.48,0.24),Color("#e1c468"))
		return
	var stems: int = 5 if kind in ["oats","rice"] else 4
	if kind == "rye": stems = 3
	for i in range(stems):
		var x: float = (float(i)-float(stems-1)*0.5)*0.16
		var z: float = sin(float(i)*1.7)*0.08
		var stalk_height: float = height*(0.82+fposmod(float(i)*0.23,0.18))
		cylinder(parent,Vector3(x,stalk_height*0.5,z),0.035,stalk_height,stem_color,0.022)
		for side in [-1.0,1.0]:
			var leaf: MeshInstance3D = ball(parent,Vector3(x+side*0.16,stalk_height*0.43,z),Vector3(0.40,0.10,0.16),stem_color.lightened(0.05))
			leaf.rotation.z = side*0.24
		if stage >= 2:
			var grain_size: Vector3 = Vector3(0.17,0.42,0.16)
			if kind == "barley" or kind == "rye": grain_size = Vector3(0.12,0.52,0.12)
			if kind == "oats" or kind == "rice": grain_size = Vector3(0.13,0.28,0.13)
			var seed_head: MeshInstance3D = ball(parent,Vector3(x,stalk_height+0.12,z),grain_size,head_color)
			if kind == "rice" or kind == "oats":
				for branch in [-1.0,1.0]:
					ball(parent,Vector3(x+branch*0.15,stalk_height+0.03,z),Vector3(0.13,0.23,0.13),head_color)
			elif kind == "barley" or kind == "rye":
				for side in [-1.0,1.0]:
					var awn: MeshInstance3D = cylinder(parent,Vector3(x+side*0.12,stalk_height+0.37,z),0.018,0.34,head_color,0.006)
					awn.rotation.z = side*0.28
			seed_head.rotation.z = sin(float(i))*0.12

static func _crop_vine(parent: Node3D, stage: int, height: float) -> void:
	for x in [-0.38,0.38]:
		cylinder(parent,Vector3(x,height*0.6,0),0.045,height*1.2,Color("#866344"),0.025)
		box(parent,Vector3(x,height*1.08,0),Vector3(0.12,0.12,1.2),Color("#a27d50"))
	for i in range(5):
		var x: float = -0.5+float(i)*0.25
		var vine: MeshInstance3D = cylinder(parent,Vector3(x,height*0.73,0),0.035,height*0.72,Color("#638c4a"),0.018)
		vine.rotation.z = (float(i)-2.0)*0.1
		ball(parent,Vector3(x,height*1.18,0.25),Vector3(0.42,0.18,0.3),Color("#72984e"))
		if stage >= 2 and i%2 == 0:
			for berry in range(4):
				ball(parent,Vector3(x+(float(berry%2)-0.5)*0.14,height*0.92-float(berry/2)*0.14,0.34),Vector3.ONE*0.14,Color("#735b9f"))

static func _crop_flower(parent: Node3D, kind: String, stage: int, height: float) -> void:
	var stem_color := Color("#6e9a4f")
	var bloom_color: Color = Color("#e8bf43") if kind == "sunflower" else Color("#a28abd")
	var stalks: int = 1 if kind == "sunflower" else 4
	for i in range(stalks):
		var x: float = (float(i)-float(stalks-1)*0.5)*0.17
		var stalk_height: float = height*(0.85+fposmod(float(i)*0.19,0.14))
		cylinder(parent,Vector3(x,stalk_height*0.5,0),0.045,stalk_height,stem_color,0.022)
		for side in [-1.0,1.0]:
			var leaf: MeshInstance3D = ball(parent,Vector3(x+side*0.18,stalk_height*0.42,0),Vector3(0.48,0.12,0.24),stem_color)
			leaf.rotation.z = side*0.3
		if stage >= 2 and kind == "sunflower":
			ball(parent,Vector3(x,stalk_height+0.12,0),Vector3(0.42,0.42,0.28),Color("#694b35"))
			for petal in range(9):
				var angle: float = float(petal)*TAU/9.0
				ball(parent,Vector3(x+cos(angle)*0.32,stalk_height+0.12+sin(angle)*0.32,0),Vector3(0.16,0.24,0.10),bloom_color)
		elif stage >= 2:
			for bud in range(4):
				ball(parent,Vector3(x+(float(bud%2)-0.5)*0.11,stalk_height-0.18-float(bud/2)*0.12,0),Vector3(0.12,0.2,0.12),bloom_color)

static func _crop_root(parent: Node3D, kind: String, stage: int, height: float) -> void:
	var foliage := Color("#72a451")
	var root_color: Color = Color("#e6954a") if kind == "carrot" else (Color("#a85068") if kind == "beetroot" else Color("#b89969"))
	cylinder(parent,Vector3(0,height*0.48,0),0.055,height,Color("#638e46"),0.025)
	for leaf_index in range(5):
		var angle: float = float(leaf_index)*TAU/5.0
		var leaf: MeshInstance3D = ball(parent,Vector3(cos(angle)*0.22,height*0.78,sin(angle)*0.22),Vector3(0.48,0.12,0.20),foliage)
		leaf.rotation.y = angle
		leaf.rotation.z = sin(angle)*0.18
	if stage >= 2:
		if kind == "potato":
			for tuber in range(4):
				ball(parent,Vector3((float(tuber%2)-0.5)*0.22,0.25+float(tuber/2)*0.12,(float(tuber/2)-0.5)*0.28),Vector3(0.34,0.24,0.26),root_color.lightened(float(tuber%2)*0.08))
		else:
			var root_size: Vector3 = Vector3(0.25,0.7,0.25) if kind == "carrot" else Vector3(0.48,0.45,0.46)
			ball(parent,Vector3(0,0.28,0),root_size,root_color)

static func _crop_leafy(parent: Node3D, kind: String, stage: int, height: float) -> void:
	var leaf_color: Color = Color("#70a34d") if kind == "lettuce" else Color("#548a4d")
	var leaves: int = 9 if kind == "lettuce" else 6
	for i in range(leaves):
		var angle: float = float(i)*TAU/float(leaves)
		var spread: float = 0.22+stage*0.08
		var leaf: MeshInstance3D = ball(parent,Vector3(cos(angle)*spread,height*(0.38+float(i%3)*0.13),sin(angle)*spread),Vector3(0.54,0.13,0.3),leaf_color.lightened(float(i%3)*0.035))
		leaf.rotation.y = angle
		leaf.rotation.z = sin(angle)*0.22
	if kind == "basil":
		for i in range(3):
			var x: float = (float(i)-1.0)*0.16
			cylinder(parent,Vector3(x,height*0.42,0),0.035,height*0.84,Color("#55874a"),0.02)

static func _crop_fruiting(parent: Node3D, kind: String, stage: int, height: float) -> void:
	var stem_color := Color("#6b984d")
	var fruit_color: Color = Color("#d7644e")
	if kind in ["blueberry","grape"]: fruit_color = Color("#77649d")
	if kind == "aubergine": fruit_color = Color("#80568f")
	if kind == "cucumber": fruit_color = Color("#59894b")
	if kind in ["chickpea","lentil"]: fruit_color = Color("#bea46c")
	if kind == "pumpkin": fruit_color = Color("#df9d43")
	var stems: int = 3 if kind in ["bean","chickpea","lentil"] else 1
	for i in range(stems):
		var x: float = (float(i)-float(stems-1)*0.5)*0.2
		cylinder(parent,Vector3(x,height*0.48,0),0.045,height,stem_color,0.02)
		for side in [-1.0,1.0]:
			var leaf: MeshInstance3D = ball(parent,Vector3(x+side*0.2,height*0.58,0),Vector3(0.45,0.14,0.28),stem_color.lightened(0.04))
			leaf.rotation.z = side*0.18
	if stage < 2:
		return
	if kind == "pumpkin":
		ball(parent,Vector3(0,0.34,0),Vector3(0.78,0.56,0.76),fruit_color)
		for i in range(5):
			var angle: float = float(i)*TAU/5.0
			ball(parent,Vector3(cos(angle)*0.22,0.67,sin(angle)*0.22),Vector3(0.26,0.12,0.22),Color("#72a14c"))
	elif kind == "cucumber":
		for side in [-1.0,1.0]:
			var cucumber: MeshInstance3D = cylinder(parent,Vector3(side*0.22,height*0.62,0.05),0.12,0.72,fruit_color,0.09)
			cucumber.rotation.z = side*0.45
	elif kind == "aubergine":
		for side in [-1.0,1.0]:
			var fruit: MeshInstance3D = ball(parent,Vector3(side*0.19,height*0.72,0.08),Vector3(0.26,0.68,0.3),fruit_color)
			fruit.rotation.z = side*0.36
	elif kind in ["bean","chickpea","lentil"]:
		for i in range(4):
			var pod: MeshInstance3D = ball(parent,Vector3((float(i%2)-0.5)*0.3,height*(0.38+float(i/2)*0.18),0.12),Vector3(0.14,0.48,0.13),fruit_color)
			pod.rotation.z = (float(i%2)-0.5)*0.42
	else:
		var fruit_count: int = 5 if kind in ["strawberry","raspberry","blueberry"] else 3
		var size: Vector3 = Vector3.ONE*0.18
		if kind == "tomato": size = Vector3.ONE*0.24
		if kind == "strawberry": size = Vector3(0.22,0.28,0.22)
		for i in range(fruit_count):
			var angle: float = float(i)*TAU/float(fruit_count)
			ball(parent,Vector3(cos(angle)*0.24,height*(0.58+float(i%2)*0.18),sin(angle)*0.24),size,fruit_color.lightened(float(i%3)*0.06))

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
