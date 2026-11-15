extends "res://scripts/three_d/Viewport3D.gd"
## One shared 3D avatar for creation, wardrobe, world and interior.
var appearance: Dictionary = Models.Style.defaults()
var model: Node3D

func set_look(hair: String, skin: String, coat: String) -> void:
	set_avatar({"hair":hair,"skin":skin,"outfit":coat})

func set_avatar(value: Dictionary) -> void:
	var combined: Dictionary = appearance.duplicate()
	combined.merge(value,true)
	appearance = Models.Style.normalize(combined)
	if stage != null: _rebuild()

func _build_scene() -> void:
	target = Vector3(0,1.2,0)
	camera_target = target
	camera_size = 3.3
	desired_size = 3.3
	pitch = 0.15
	yaw = 0.25
	Models.cylinder(stage,Vector3(0,-0.09,0),1.25,0.15,Color("#adc1a4"))
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#dce5d4")
	_rebuild()

func _rebuild() -> void:
	if model != null: model.free()
	model = Models.farmer(stage,appearance)

func _tick(_delta: float) -> void:
	if model != null and not reduced_motion: model.rotation.y = sin(elapsed*0.5)*0.12

func change_zoom(_amount: float) -> void:
	pass

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		yaw -= event.relative.x*0.01
