extends "res://scripts/three_d/Viewport3D.gd"
## Cutaway rooms with ray-picked furnishings and a moving 3D visitor.
signal prop_selected(label: String)
var title: String = "farmhouse"
var items: Array = []
var outdoors: bool = false
var appearance: Dictionary = {}
var room: Node3D
var visitor: Node3D
var destination := Vector3(0,0,3)
var language: String = "en"

func set_place(value: String, props: Array, is_outdoors: bool = false) -> void:
	title = value
	items = props.duplicate()
	outdoors = is_outdoors
	if stage != null: _rebuild()

func set_avatar(value: Dictionary) -> void:
	appearance = value
	if stage != null: _rebuild()

func _build_scene() -> void:
	camera_target = Vector3(0,0,0)
	target = camera_target
	yaw = 0.22
	pitch = 0.72
	desired_size = 17
	camera_size = 17
	_rebuild()

func _rebuild() -> void:
	if room != null: room.free()
	room = Models.root(stage)
	Models.box(room,Vector3(0,-0.15,0),Vector3(15,0.3,11),Color("#a3b87f") if outdoors else Color("#c29b71"))
	if not outdoors:
		Models.box(room,Vector3(0,1.8,-5.3),Vector3(15,3.6,0.3),Color("#e6d5b0"))
		Models.box(room,Vector3(-7.4,1.8,0),Vector3(0.25,3.6,11),Color("#d2c19e"))
		for i in range(12): Models.box(room,Vector3(-7+i*1.2,0.015,0),Vector3(0.025,0.02,10.6),Color("#ad895f"))
		Models.box(room,Vector3(0,2.1,-5.05),Vector3(3.6,2.1,0.14),Color("#778e86"))
		Models.box(room,Vector3(0,2.1,-4.94),Vector3(3.2,1.8,0.08),Color("#aad0cc"))
		Models.box(room,Vector3(0,2.1,-4.87),Vector3(0.12,1.85,0.05),Color("#efdfb7"))
		Models.box(room,Vector3(0,2.1,-4.87),Vector3(3.2,0.12,0.05),Color("#efdfb7"))
	for i in range(items.size()):
		var x: float = -5.0+i*(10.0/maxi(1,items.size()-1))
		var node: Node3D = Models.root(room,Vector3(x,0,-1.5))
		if title in ["greenhouse","flowers","wildGarden","pond","apiary"]:
			Models.box(node,Vector3(0,0.35,0),Vector3(2.2,0.7,1.4),Color("#a98b5b"))
			for j in range(3):
				Models.cylinder(node,Vector3(-0.7+j*0.7,1.0,0),0.06,0.7,Color("#6e984b"))
				Models.ball(node,Vector3(-0.7+j*0.7,1.4,0),Vector3.ONE*0.6,Color("#e2c16e"))
		elif title in ["barn","coop","stable","pigsty","hutch","pasture"]:
			Models.fence(node,Vector3(-1.2,0,-0.6),Vector3(1.2,0,-0.6))
			Models.box(node,Vector3(0,0.25,0.5),Vector3(1.8,0.5,0.6),Color("#b79b64"))
			var animal: Node3D = Models.animal(node,{"coop":"hen","barn":"cow","stable":"horse","pigsty":"pig","hutch":"rabbit"}.get(title,"goat"))
			animal.position = Vector3(0,0,-0.3)
		elif "bookshelf" in str(items[i]).to_lower() or "library" in str(items[i]).to_lower():
			Models.box(node,Vector3(0,1.05,-0.2),Vector3(2.0,2.1,0.55),Color("#936d4b"))
			for shelf in range(3):
				Models.box(node,Vector3(0,0.35+shelf*0.65,0.17),Vector3(1.85,0.08,0.5),Color("#caa779"))
				for book in range(5): Models.box(node,Vector3(-0.7+book*0.33,0.62+shelf*0.65,0.04),Vector3(0.23,0.45,0.35),Color("#638777") if book%2 else Color("#b17b57"))
		elif "chair" in str(items[i]).to_lower() or "bench" in str(items[i]).to_lower():
			Models.decoration(node,"bench")
		else:
			Models.box(node,Vector3(0,0.85,0),Vector3(2.2,0.2,1.4),Color("#ab8155"))
			for side in [-0.8,0.8]: Models.box(node,Vector3(side,0.4,0),Vector3(0.15,0.8,1.0),Color("#886746"))
			if i%2 == 0:
				for j in range(3): Models.box(node,Vector3(-0.65+j*0.6,1.15,0),Vector3(0.4,0.4,0.65),Color("#75938a").lightened(j*0.05))
			else: Models.cylinder(node,Vector3(0,1.3,0),0.45,0.7,Color("#c7b27e"))
		Models.hitbox(node,"prop",str(i),Vector3(0,0.8,0),Vector3(2.5,2,2))
		Models.label(node,_localized(str(items[i])),Vector3(0,2.8,0),36)
	visitor = Models.farmer(room,appearance)
	visitor.position = destination

func _tick(delta: float) -> void:
	if visitor != null:
		var diff: Vector3 = destination-visitor.position
		if diff.length_squared()>0.01:
			visitor.rotation.y = atan2(diff.x,diff.z)
			visitor.position = destination if reduced_motion else visitor.position.move_toward(destination,delta*3.0)

func _on_ground(point: Vector3) -> void:
	destination = Vector3(clampf(point.x,-6.5,6.5),0,clampf(point.z,-3.5,4.7))

func _on_picked(kind: String, id: String) -> void:
	if kind == "prop" and int(id) < items.size(): prop_selected.emit(_localized(str(items[int(id)])))

func _localized(value: String) -> String:
	if language != "es": return value
	return {"Workbench":"Mesa de trabajo","Bookshelf":"Estantería","Resting chair":"Banco de descanso","Market stalls":"Puestos","Contracts desk":"Contratos","Village map":"Mapa del valle","Nesting boxes":"Nidos","Feed trough":"Comedero","Clean straw":"Paja limpia","Hay racks":"Forraje","Water trough":"Bebedero","Milking stand":"Ordeño","Seedling beds":"Semilleros","Ventilation":"Ventilación","Watering can":"Regadera","Crop crates":"Cajas de cosecha","Drying shelves":"Secadero","Ledger":"Libro de cuentas","Course desk":"Mesa de estudio","Soil samples":"Muestras de suelo","Library":"Biblioteca"}.get(value,value)

func reset_camera() -> void:
	camera_target = Vector3.ZERO
	desired_size = 17
	yaw = 0.22
	pitch = 0.72
