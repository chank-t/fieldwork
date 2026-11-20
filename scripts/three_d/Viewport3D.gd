extends Control
## Common embedded 3D stage, orbit camera, ray picking and graphics presets.
const Models = preload("res://scripts/three_d/Models.gd")
var viewport_3d: SubViewport
var stage: Node3D
var camera: Camera3D
var sunlight: DirectionalLight3D
var environment: Environment
var container: SubViewportContainer
var target := Vector3(32,0,27)
var camera_target := Vector3(32,0,27)
var camera_size: float = 58.0
var desired_size: float = 58.0
var yaw: float = 0.12
var pitch: float = 0.88
var perspective: bool = false
var first_person: bool = false
var first_person_yaw: float = PI
var first_person_pitch: float = -0.08
var first_person_fov: float = 72.0
var performance_mode59: String = "balanced"
var reduced_motion: bool = false
var reduced_motion59: bool = false
var controls_enabled: bool = true
var dragging: int = 0
var touch_points: Dictionary = {}
var touch_start: Vector2
var touch_moved: bool = false
var elapsed: float = 0.0
var last_preset: String = ""
var hovered: Dictionary = {}
const HAZE := Color("#cfdcd3")

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	container = SubViewportContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.stretch = true
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_3d = SubViewport.new()
	viewport_3d.own_world_3d = true
	viewport_3d.physics_object_picking = false
	container.add_child(viewport_3d)
	stage = Node3D.new()
	viewport_3d.add_child(stage)
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = HAZE
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#dfe9ec")
	environment.ambient_light_energy = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 1.6
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.12
	environment.adjustment_contrast = 1.06
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	stage.add_child(world_environment)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48,-32,0)
	sunlight.light_color = Color("#fff0d4")
	sunlight.light_energy = 0.50
	sunlight.shadow_enabled = true
	sunlight.shadow_opacity = 0.72
	sunlight.shadow_blur = 1.6
	sunlight.shadow_bias = 0.04
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sunlight.directional_shadow_max_distance = 180.0
	stage.add_child(sunlight)
	camera = Camera3D.new()
	camera.current = true
	camera.far = 500.0
	camera.near = 0.1
	camera.fov = 42.0
	stage.add_child(camera)
	resized.connect(_resize)
	visibility_changed.connect(_visibility_changed)
	_build_scene()
	_resize()
	_apply_preset()
	_update_camera(1.0)
	_visibility_changed()

func _build_scene() -> void:
	pass

func _resize() -> void:
	if viewport_3d == null: return
	_update_camera(1.0)

func _visibility_changed() -> void:
	if viewport_3d != null:
		viewport_3d.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	if not is_visible_in_tree():
		dragging = 0
		touch_points.clear()

func _apply_preset() -> void:
	if viewport_3d == null: return
	last_preset = performance_mode59
	container.stretch_shrink = 2 if performance_mode59 == "eco" else 1
	viewport_3d.msaa_3d = Viewport.MSAA_DISABLED if performance_mode59 == "eco" else (Viewport.MSAA_4X if performance_mode59 == "quality" else Viewport.MSAA_2X)
	sunlight.shadow_enabled = performance_mode59 != "eco"
	viewport_3d.positional_shadow_atlas_size = 1024 if performance_mode59 == "eco" else 2048

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if performance_mode59 != last_preset: _apply_preset()
	if not (reduced_motion or reduced_motion59): elapsed += delta
	_update_camera(delta)
	_tick(delta)

func _tick(_delta: float) -> void:
	pass

func _update_camera(delta: float) -> void:
	if camera == null: return
	if first_person:
		camera.position = camera_target
		camera.rotation = Vector3(first_person_pitch,first_person_yaw,0.0)
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = first_person_fov
		return
	camera.fov = 42.0
	var blend: float = 1.0 if reduced_motion or reduced_motion59 else 1.0-exp(-delta*9.0)
	target = target.lerp(camera_target,blend)
	camera_size = lerpf(camera_size,desired_size,blend)
	var aspect: float = maxf(0.2,size.x/maxf(1.0,size.y))
	var distance: float = camera_size*1.32
	camera.position = target + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
	camera.look_at(target)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE if perspective else Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(camera_size,camera_size*1.30/aspect)
	if perspective:
		camera.position = target + (camera.position-target)*maxf(1.0,1.30/aspect)

func change_zoom(amount: float) -> void:
	if first_person:
		first_person_fov = clampf(first_person_fov*exp(-amount*0.6),50.0,90.0)
		return
	desired_size = clampf(desired_size*exp(-amount*0.6),12.0,110.0)

func reset_camera() -> void:
	if first_person:
		first_person_yaw = PI
		first_person_pitch = -0.08
		first_person_fov = 72.0
	camera_target = Vector3(32,0,27)
	desired_size = 58.0
	yaw = 0.12
	pitch = 0.88

func toggle_projection() -> void:
	perspective = not perspective

func _ray_at(pointer: Vector2) -> Dictionary:
	if camera == null or size.x <= 0 or size.y <= 0: return {}
	var pixel: Vector2 = pointer*Vector2(viewport_3d.size)/size
	var origin: Vector3 = camera.project_ray_origin(pixel)
	var direction: Vector3 = camera.project_ray_normal(pixel)
	var query := PhysicsRayQueryParameters3D.create(origin,origin+direction*600.0)
	return viewport_3d.find_world_3d().direct_space_state.intersect_ray(query)

func _ground_at(pointer: Vector2) -> Variant:
	if camera == null: return null
	var pixel: Vector2 = pointer*Vector2(viewport_3d.size)/size
	return Plane(Vector3.UP,0.0).intersects_ray(camera.project_ray_origin(pixel),camera.project_ray_normal(pixel))

func _pick(pointer: Vector2) -> void:
	var hit: Dictionary = _ray_at(pointer)
	if hit.has("collider"):
		var body: Object = hit["collider"]
		_on_picked(str(body.get_meta("kind","")),str(body.get_meta("id","")))
	else:
		var point: Variant = _ground_at(pointer)
		if point != null: _on_ground(point)

func _on_picked(_kind: String, _id: String) -> void:
	pass

func _on_ground(_point: Vector3) -> void:
	pass

func _pan(relative: Vector2) -> void:
	var right := Vector3(cos(yaw),0,-sin(yaw))
	var forward := Vector3(sin(yaw),0,cos(yaw))
	camera_target -= (right*relative.x+forward*relative.y)*camera_size/maxf(200.0,size.y)
	camera_target.x = clampf(camera_target.x,-15.0,80.0)
	camera_target.z = clampf(camera_target.z,-15.0,70.0)

func _look_first_person(relative: Vector2) -> void:
	first_person_yaw -= relative.x*0.006
	first_person_pitch = clampf(first_person_pitch-relative.y*0.004,-1.15,0.65)

func _gui_input(event: InputEvent) -> void:
	if not controls_enabled: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: change_zoom(0.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: change_zoom(-0.2)
		elif event.button_index in [MOUSE_BUTTON_MIDDLE,MOUSE_BUTTON_RIGHT]: dragging = event.button_index if event.pressed else 0
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed: _pick(event.position)
		accept_event()
	elif event is InputEventMouseMotion:
		if dragging == MOUSE_BUTTON_MIDDLE:
			if first_person: _look_first_person(event.relative)
			else: _pan(event.relative)
		elif dragging == MOUSE_BUTTON_RIGHT:
			if first_person:
				_look_first_person(event.relative)
			else:
				yaw -= event.relative.x*0.006
				pitch = clampf(pitch+event.relative.y*0.004,0.35,1.35)
		else:
			hovered = _ray_at(event.position)
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not hovered.is_empty() else Control.CURSOR_ARROW
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			if touch_points.size() == 1:
				touch_start = event.position
				touch_moved = false
		else:
			if touch_points.size() == 1 and not touch_moved: _pick(event.position)
			touch_points.erase(event.index)
		accept_event()
	elif event is InputEventScreenDrag:
		if touch_points.has(event.index):
			if touch_points.size() >= 2:
				var previous: Array = touch_points.values()
				var old_distance: float = previous[0].distance_to(previous[1])
				touch_points[event.index] = event.position
				var current: Array = touch_points.values()
				var new_distance: float = current[0].distance_to(current[1])
				if old_distance > 1 and new_distance > 1: change_zoom(log(new_distance/old_distance)/0.6)
				touch_moved = true
			else:
				touch_moved = touch_moved or touch_start.distance_to(event.position)>12
				if touch_moved:
					if first_person: _look_first_person(event.relative)
					else: _pan(event.relative)
			touch_points[event.index] = event.position
		accept_event()
