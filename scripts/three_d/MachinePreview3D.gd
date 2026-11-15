extends "res://scripts/three_d/Viewport3D.gd"
var kind: String = "cultivator"

func _build_scene() -> void:
	target = Vector3(0,0.8,0)
	camera_target = target
	desired_size = 4.6
	camera_size = 4.6
	yaw = 0.65
	pitch = 0.5
	Models.machine(stage,kind)
	Models.cylinder(stage,Vector3(0,-0.08,0),2.0,0.1,Color("#c9d2b7"))
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#e6eadb")
	controls_enabled = false
