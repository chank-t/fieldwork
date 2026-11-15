extends "res://scripts/three_d/FarmView3D.gd"
## The menu owns a private illustrative farm; it never reads or writes a save.
const Farm = preload("res://scripts/NativeFarm.gd")

func _ready() -> void:
	scenic = true
	controls_enabled = false
	farm = Farm.new()
	farm.new_game()
	for i in range(24):
		var field: Dictionary = farm.state["fields"][i]
		field["owned"] = i < 18
		if i < 18: field["crop"] = {"id":["wheat","lavender","pumpkin","tomato","sunflower","apple"][i%6],"development":0.8}
	farm.state["buildings"] = [{"id":"scenic_barn","kind":"barn","field":"","slot":7,"level":1},{"id":"scenic_greenhouse","kind":"greenhouse","field":"","slot":17,"level":1}]
	farm.state["animals"] = [{"id":"scenic_hens","kind":"hen","count":3},{"id":"scenic_sheep","kind":"sheep","count":3}]
	super._ready()
	camera_target = Vector3(28,0,23)
	target = camera_target
	desired_size = 63
	camera_size = 63
	yaw = -0.22
	pitch = 0.72

func _tick(delta: float) -> void:
	super._tick(delta)
	if not reduced_motion: yaw = -0.22+sin(elapsed*0.035)*0.10
