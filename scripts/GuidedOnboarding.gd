extends RefCounted
## Step-by-step guided onboarding with highlighted UI elements.
## Replaces the text-heavy starter guide with interactive highlighting.

const ThemeKit = preload("res://scripts/three_d/GameTheme.gd")

const STEPS = [
	{
		"id": "welcome",
		"title": {"en": "Welcome to FieldWork!", "es": "¡Bienvenido a FieldWork!"},
		"message": {"en": "Your farm starts with one field. Let's learn the basics in a few minutes.", "es": "Tu finca empieza con una parcela. Aprenderemos lo básico en unos minutos."},
		"target": null,
		"action": "none",
		"skipable": true
	},
	{
		"id": "inspect_field",
		"title": {"en": "Inspect Your Field", "es": "Inspecciona tu Parcela"},
		"message": {"en": "Tap your field on the map to see its soil, moisture, and pests.", "es": "Toca tu parcela en el mapa para ver su suelo, humedad y plagas."},
		"target": {"type": "field", "id": "plot1"},
		"action": "inspect",
		"skipable": false
	},
	{
		"id": "plant_crop",
		"title": {"en": "Plant Your First Crop", "es": "Siembra tu Primer Cultivo"},
		"message": {"en": "Open the radial menu on your field and choose 'Plant'. Pick wheat — it's hardy and quick.", "es": "Abre el menú radial en tu parcela y elige 'Sembrar'. Escoge trigo: es resistente y rápido."},
		"target": {"type": "field", "id": "plot1"},
		"action": "plant",
		"args": {"cropId": "wheat"},
		"skipable": false
	},
	{
		"id": "water_crop",
		"title": {"en": "Water Thoughtfully", "es": "Riega con Cuidado"},
		"message": {"en": "Your reservoir is limited. Water +15mm to give your crop a good start.", "es": "Tu depósito es limitado. Riega +15mm para dar buen inicio a tu cultivo."},
		"target": {"type": "field", "id": "plot1"},
		"action": "irrigate",
		"args": {"mm": 15.0},
		"skipable": false
	},
	{
		"id": "advance_time",
		"title": {"en": "Let Time Pass", "es": "Deja Pasar el Tiempo"},
		"message": {"en": "Use the speed controls (1×, 4×, 12×) to advance days. Watch your crop grow!", "es": "Usa los controles de velocidad (1×, 4×, 12×) para avanzar días. ¡Mira crecer tu cultivo!"},
		"target": {"type": "speed_controls"},
		"action": "speed",
		"args": {"speed": 4},
		"skipable": true
	},
	{
		"id": "harvest_crop",
		"title": {"en": "Harvest When Ready", "es": "Cosecha Cuando Esté Listo"},
		"message": {"en": "When growth reaches 100%, open the radial menu and harvest.", "es": "Cuando el crecimiento llegue al 100%, abre el menú radial y cosecha."},
		"target": {"type": "field", "id": "plot1"},
		"action": "harvest",
		"skipable": false
	},
	{
		"id": "sell_harvest",
		"title": {"en": "Sell at the Market", "es": "Vende en el Mercado"},
		"message": {"en": "Go to the Market hub → Market panel. Sell your wheat for cash.", "es": "Ve al hub Mercado → panel Mercado. Vende tu trigo por dinero."},
		"target": {"type": "hub", "id": "Market", "panel": "market"},
		"action": "navigate",
		"skipable": true
	},
	{
		"id": "buy_land",
		"title": {"en": "Expand Your Farm", "es": "Amplía tu Finca"},
		"message": {"en": "Tap an unowned field on the map and buy it. More fields = more options.", "es": "Toca una parcela sin dueño en el mapa y cómprala. Más parcelas = más opciones."},
		"target": {"type": "field", "owned": false},
		"action": "buyField",
		"skipable": true
	},
	{
		"id": "build_structure",
		"title": {"en": "Build a Structure", "es": "Construye un Edificio"},
		"message": {"en": "Open the Buildings panel (Animals hub). Place a Barn or Coop for animals.", "es": "Abre el panel Edificios (hub Animales). Coloca un Establo o Gallinero para animales."},
		"target": {"type": "hub", "id": "Animals", "panel": "buildings"},
		"action": "navigate",
		"skipable": true
	},
	{
		"id": "complete",
		"title": {"en": "You're Ready!", "es": "¡Estás Listo!"},
		"message": {"en": "You know the basics. Explore the 6 hubs, talk to villagers, and make the valley yours.", "es": "Conoces lo básico. Explora los 6 hubs, habla con los vecinos y haz tuyo el valle."},
		"target": null,
		"action": "complete",
		"skipable": true
	}
]

var current_step: int = 0
var farm: Variant
var main_ui: Variant
var highlight: Control
var overlay: Control
var step_card: PanelContainer
var title_label: Label
var message_label: Label
var next_button: Button
var skip_button: Button
var progress_bar: ProgressBar
var is_active: bool = false
var on_complete: Callable

func start(farm_ref: Variant, main_ui_ref: Variant, callback: Callable) -> void:
	farm = farm_ref
	main_ui = main_ui_ref
	on_complete = callback
	current_step = _get_saved_step()
	is_active = true
	_build_ui()
	_show_step()

func _get_saved_step() -> int:
	var step: int = int(farm.state.get("story", {}).get("starter_guide", 0))
	if step >= STEPS.size():
		step = 0
	return step

func _build_ui() -> void:
	# Full-screen overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_ui.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Highlight layer (draws rings around targets)
	highlight = Control.new()
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(highlight)
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Step card (bottom center)
	step_card = PanelContainer.new()
	step_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	step_card.size_flags_vertical = Control.SIZE_SHRINK_END
	step_card.custom_minimum_size = Vector2(0, 180)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color("#f7f4e9")
	card_style.set_corner_radius_all(16)
	card_style.border_color = Color("#3f6652")
	card_style.set_border_width_all(2)
	card_style.content_margin_left = 20
	card_style.content_margin_right = 20
	card_style.content_margin_top = 16
	card_style.content_margin_bottom = 16
	step_card.add_theme_stylebox_override("panel", card_style)
	overlay.add_child(step_card)

	var card_layout = VBoxContainer.new()
	card_layout.add_theme_constant_override("separation", 10)
	step_card.add_child(card_layout)

	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.max_value = STEPS.size() - 1
	progress_bar.value = 0
	progress_bar.custom_minimum_size = Vector2(300, 6)
	var pb_style = StyleBoxFlat.new()
	pb_style.bg_color = Color("#e1e5d6")
	pb_style.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("background", pb_style)
	var pb_fill = StyleBoxFlat.new()
	pb_fill.bg_color = Color("#3f6652")
	pb_fill.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("fill", pb_fill)
	card_layout.add_child(progress_bar)

	# Title
	title_label = Label.new()
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("#263a32"))
	title_label.add_theme_font_override("font", ThemeKit.SERIF)
	card_layout.add_child(title_label)

	# Message
	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 15)
	message_label.add_theme_color_override("font_color", Color("#4a5d50"))
	card_layout.add_child(message_label)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	card_layout.add_child(button_row)

	skip_button = Button.new()
	skip_button.text = "Skip"
	skip_button.custom_minimum_size = Vector2(100, 44)
	skip_button.add_theme_font_size_override("font_size", 14)
	var skip_style = StyleBoxFlat.new()
	skip_style.bg_color = Color("#e1e5d6")
	skip_style.set_corner_radius_all(8)
	skip_button.add_theme_stylebox_override("normal", skip_style)
	skip_button.add_theme_color_override("font_color", Color("#687e70"))
	skip_button.pressed.connect(_on_skip)
	button_row.add_child(skip_button)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	next_button = Button.new()
	next_button.text = "Next"
	next_button.custom_minimum_size = Vector2(120, 44)
	next_button.add_theme_font_size_override("font_size", 14)
	var next_style = StyleBoxFlat.new()
	next_style.bg_color = Color("#3f6652")
	next_style.set_corner_radius_all(8)
	next_button.add_theme_stylebox_override("normal", next_style)
	next_button.add_theme_color_override("font_color", Color("#f7f4e9"))
	next_button.pressed.connect(_on_next)
	button_row.add_child(next_button)

	# Initially hidden
	overlay.visible = false

func _show_step() -> void:
	if current_step >= STEPS.size():
		_complete()
		return

	var step_data: Dictionary = STEPS[current_step]
	var lang: String = farm.language

	title_label.text = str(step_data["title"].get(lang, step_data["title"]["en"]))
	message_label.text = str(step_data["message"].get(lang, step_data["message"]["en"]))
	progress_bar.value = current_step

	skip_button.visible = bool(step_data.get("skipable", true))
	next_button.text = "Complete" if current_step == STEPS.size() - 1 else "Next"

	overlay.visible = true
	is_active = true

	# Show/hide highlight (deferred to ensure overlay is fully in scene tree)
	call_deferred("_highlight_target", step_data.get("target"))

	# Auto-advance for non-interactive steps
	if step_data["action"] in ["none", "complete"]:
		call_deferred("_auto_advance")

func _auto_advance() -> void:
	await main_ui.get_tree().create_timer(3.0).timeout
	if is_active and current_step < STEPS.size():
		_on_next()

func _highlight_target(target: Variant) -> void:
	# Clear previous highlight
	for child in highlight.get_children():
		child.queue_free()

	if target == null:
		return

	var target_type: String = target.get("type", "")

	if target_type == "field":
		_highlight_field(target.get("id", "plot1"))
	elif target_type == "speed_controls":
		_highlight_speed_controls()
	elif target_type == "hub":
		_highlight_hub_tab(target.get("id", "Farm"))
	elif target_type == "animal":
		_highlight_animal(target.get("id", ""))
	elif target_type == "building":
		_highlight_building(target.get("id", ""))

func _highlight_field(field_id: String) -> void:
	var world: Variant = main_ui.world
	if world == null or not is_instance_valid(world):
		return

	# Find field index
	var index: int = int(field_id.trim_prefix("plot")) - 1
	if index < 0 or index >= 24:
		return

	# Get field screen position
	var GRID_X = [7.3, 16.6, 25.9, 35.2, 44.5, 53.8]
	var GRID_Y = [10.8, 18.6, 26.4, 34.2]
	var FIELD_W: float = 8.55
	var FIELD_H: float = 6.75

	var world_pos: Vector3 = Vector3(GRID_X[index % 6] + FIELD_W / 2, 0.5, GRID_Y[index / 6] + FIELD_H / 2)
	var screen_pos: Vector2 = world.camera.unproject_position(world_pos) * world.size / Vector2(world.viewport_3d.size)

	# Draw pulsing ring
	var ring = _create_pulsing_ring(screen_pos, 50, Color("#3f6652"))
	highlight.add_child(ring)

	# Also ensure field is selected in world
	world.set_selected(field_id)
	main_ui._picked_field(field_id)

func _highlight_speed_controls() -> void:
	var speed_box: Variant = main_ui.speed_box
	if speed_box == null or not is_instance_valid(speed_box):
		return

	var global_rect: Rect2 = speed_box.get_global_rect()
	var center: Vector2 = global_rect.position + global_rect.size / 2
	var local_pos: Vector2 = _global_to_highlight_local(center)

	var ring = _create_pulsing_ring(local_pos, 40, Color("#dbb86b"))
	highlight.add_child(ring)

func _highlight_hub_tab(hub_id: String) -> void:
	# Find the nav button for this hub
	var nav_buttons: Dictionary = main_ui.nav_buttons
	if nav_buttons.has(hub_id):
		var button: Button = nav_buttons[hub_id]
		if is_instance_valid(button):
			var global_rect: Rect2 = button.get_global_rect()
			var center: Vector2 = global_rect.position + global_rect.size / 2
			var local_pos: Vector2 = _global_to_highlight_local(center)
			var ring = _create_pulsing_ring(local_pos, max(global_rect.size.x, global_rect.size.y) / 2.0 + 10.0, Color("#6b7a9e"))
			highlight.add_child(ring)

	# Also highlight mobile nav
	var mobile_nav: Dictionary = main_ui.mobile_nav_buttons
	if mobile_nav.has(hub_id):
		var button: Button = mobile_nav[hub_id]
		if is_instance_valid(button):
			var global_rect: Rect2 = button.get_global_rect()
			var center: Vector2 = global_rect.position + global_rect.size / 2
			var local_pos: Vector2 = _global_to_highlight_local(center)
			var ring = _create_pulsing_ring(local_pos, max(global_rect.size.x, global_rect.size.y) / 2.0 + 10.0, Color("#6b7a9e"))
			highlight.add_child(ring)

func _global_to_highlight_local(global_position: Vector2) -> Vector2:
	return highlight.get_global_transform().affine_inverse() * global_position

func _highlight_animal(animal_id: String) -> void:
	# Similar to field but for animal positions
	pass

func _highlight_building(building_id: String) -> void:
	pass

func _create_pulsing_ring(position: Vector2, radius: float, color: Color) -> Control:
	var container = Control.new()
	container.position = position - Vector2(radius, radius)
	container.custom_minimum_size = Vector2(radius * 2, radius * 2)

	var ring = Control.new()
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(ring)

	# Store draw data in the node's metadata
	ring.set_meta("_draw_radius", radius)
	ring.set_meta("_draw_color", color)

	# Connect to draw signal
	ring.connect("draw", _draw_ring.bind(ring, radius, color))

	# Simple pulsing via script - animate modulate:a on process
	ring.set_script(preload("res://scripts/GuidedOnboardingRing.gd"))
	ring.call("_init_pulse", 0.3, 0.8, 1.0)

	return container

func _draw_ring(canvas: Control, radius: float, color: Color) -> void:
	var center: Vector2 = canvas.size / 2
	canvas.draw_circle(center, radius, Color(color.r, color.g, color.b, canvas.modulate.a), 3)

func _on_next() -> void:
	var step_data: Dictionary = STEPS[current_step]

	# Execute step action if needed
	if step_data["action"] != "none" and step_data["action"] != "complete" and step_data["action"] != "navigate":
		_execute_action(step_data)

	current_step += 1

	# Save progress
	farm.state["story"]["starter_guide"] = current_step
	farm.save_file()

	if current_step >= STEPS.size():
		_complete()
	else:
		_show_step()

func _execute_action(step_data: Dictionary) -> void:
	var action: String = step_data["action"]
	var args: Dictionary = step_data.get("args", {})

	match action:
		"inspect":
			main_ui._direct("inspect", args)
		"plant":
			main_ui._ask("plant", args)
		"irrigate":
			main_ui._direct("irrigate", args)
		"speed":
			main_ui._set_speed(args.get("speed", 1))
		"harvest":
			main_ui._ask("harvest", args)
		"buyField":
			main_ui._ask("buyField", args)
		_:
			pass

func _on_skip() -> void:
	if current_step < STEPS.size() - 1:
		# Skip to completion
		current_step = STEPS.size() - 1
		farm.state["story"]["starter_guide"] = current_step
		farm._direct("starterGuide", {"skip": true})
		farm.save_file()
		_show_step()
	else:
		_complete()

func _complete() -> void:
	is_active = false
	overlay.visible = false

	# Mark tutorial as complete
	farm.state["story"]["starter_guide"] = STEPS.size()
	farm.save_file()

	if on_complete != null:
		on_complete.call()

func skip_entire_tutorial() -> void:
	if is_active:
		_complete()

func is_running() -> bool:
	return is_active