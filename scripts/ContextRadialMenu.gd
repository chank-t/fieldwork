extends Control
## Radial context menu that appears on tap/click on map entities.
## Supports plots, animals, buildings, and garden slots.

const RADIUS = 90
const ITEM_SIZE = 64
const ANIMATION_TIME = 0.15

signal action_selected(action_id: String, args: Dictionary)

var farm: Variant
var current_target: Dictionary = {}
var menu_items: Array[Dictionary] = []
var item_buttons: Array[Button] = []
var background: Control
var center_pos: Vector2
var is_open: bool = false
var language: String = "en"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	background = ColorRect.new()
	background.color = Color(0, 0, 0, 0)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.gui_input.connect(_on_background_input)

func set_farm(farm_ref: Variant) -> void:
	farm = farm_ref

func show_at(screen_pos: Vector2, target: Dictionary) -> void:
	if is_open:
		close_menu()

	current_target = target
	center_pos = screen_pos
	_build_menu()

	# Position menu at click location (clamped to viewport)
	var viewport_size = get_viewport_rect().size
	var menu_diameter = RADIUS * 2.0 + ITEM_SIZE
	var clamped_x = clampf(screen_pos.x, menu_diameter / 2.0, viewport_size.x - menu_diameter / 2.0)
	var clamped_y = clampf(screen_pos.y, menu_diameter / 2.0, viewport_size.y - menu_diameter / 2.0)
	center_pos = Vector2(clamped_x, clamped_y)

	global_position = Vector2.ZERO
	visible = true
	is_open = true

	# Animate in
	background.color = Color(0, 0, 0, 0)
	var tween = create_tween()
	tween.tween_property(background, "color", Color(0, 0, 0, 0.3), ANIMATION_TIME)

	for i in range(item_buttons.size()):
		var button: Button = item_buttons[i]
		button.scale = Vector2.ZERO
		button.modulate = Color(1, 1, 1, 0)
		var delay = i * 0.03
		tween.tween_property(button, "scale", Vector2.ONE, ANIMATION_TIME).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "modulate", Color(1, 1, 1, 1), ANIMATION_TIME).set_delay(delay)

	# Close on any input outside (handled by background gui_input)
	# get_viewport().gui_input.connect(_on_viewport_input)

func close_menu() -> void:
	if not is_open:
		return
	is_open = false

	var tween = create_tween()
	tween.tween_property(background, "color", Color(0, 0, 0, 0), ANIMATION_TIME)

	for i in range(item_buttons.size()):
		var button: Button = item_buttons[i]
		var delay = (item_buttons.size() - i - 1) * 0.02
		tween.tween_property(button, "scale", Vector2.ZERO, ANIMATION_TIME * 0.7).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(button, "modulate", Color(1, 1, 1, 0), ANIMATION_TIME * 0.7).set_delay(delay)

	tween.finished.connect(func(): _cleanup())

func _cleanup() -> void:
	visible = false
	for button in item_buttons:
		if is_instance_valid(button):
			button.queue_free()
	item_buttons.clear()
	menu_items.clear()
	current_target = {}
	# get_viewport().gui_input.disconnect(_on_viewport_input)

func _build_menu() -> void:
	menu_items = _generate_actions(current_target)

	if menu_items.is_empty():
		return

	var count = menu_items.size()
	var angle_step = TAU / count
	var start_angle = -TAU / 4  # Start at top

	for i in range(menu_items.size()):
		var item: Dictionary = menu_items[i]
		var angle = start_angle + i * angle_step
		var offset = Vector2(cos(angle), sin(angle)) * RADIUS
		var pos = center_pos + offset

		var button = Button.new()
		button.custom_minimum_size = Vector2(ITEM_SIZE, ITEM_SIZE)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.focus_mode = Control.FOCUS_NONE

		# Style
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color("#f7f4e9")
		style_normal.set_corner_radius_all(ITEM_SIZE / 2.0)
		style_normal.border_color = Color("#8baf99")
		style_normal.set_border_width_all(2)
		button.add_theme_stylebox_override("normal", style_normal)

		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color("#ecf7e9")
		style_hover.border_color = Color("#3f6652")
		button.add_theme_stylebox_override("hover", style_hover)

		var style_pressed = style_normal.duplicate()
		style_pressed.bg_color = Color("#dceedd")
		button.add_theme_stylebox_override("pressed", style_pressed)

		# Icon
		if item.has("icon") and item["icon"] != "":
			var icon = TextureRect.new()
			icon.texture = load(item["icon"])
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(ITEM_SIZE * 0.55, ITEM_SIZE * 0.55)
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(icon)
			icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

		# Label (tooltip only, shown on hover)
		button.tooltip_text = _get_localized(item["label"])

		# Position
		button.position = pos - Vector2(ITEM_SIZE / 2.0, ITEM_SIZE / 2.0)

		# Action
		var action_id = item["action"]
		var args = item.get("args", {})
		button.pressed.connect(func(): _on_item_pressed(action_id, args))

		add_child(button)
		item_buttons.append(button)

func _generate_actions(target: Dictionary) -> Array[Dictionary]:
	var type: String = target.get("type", "")
	var id: String = target.get("id", "")
	var actions: Array[Dictionary] = []

	if type == "field":
		actions = _field_actions(id)
	elif type == "animal":
		actions = _animal_actions(id)
	elif type == "building":
		actions = _building_actions(id)
	elif type == "garden_slot":
		actions = _garden_slot_actions(id)
	elif type == "build_slot":
		actions = _build_slot_actions(id)
	elif type == "machine":
		actions = _machine_actions(id)

	return actions

func _field_actions(field_id: String) -> Array[Dictionary]:
	var field: Dictionary = farm.field_of(field_id)
	if field.is_empty():
		return []

	var owned: bool = bool(field.get("owned", false))
	var crop: Dictionary = field.get("crop", {})
	var has_crop: bool = not crop.is_empty()
	var development: float = float(crop.get("development", 0.0))
	var actions: Array[Dictionary] = []

	if not owned:
		actions.append({"action": "buyField", "label": {"en": "Buy Land", "es": "Comprar"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_buy.svg"})
	else:
		if not has_crop:
			actions.append({"action": "plant", "label": {"en": "Plant", "es": "Sembrar"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_plant.svg"})
			actions.append({"action": "coverCrop", "label": {"en": "Cover Crop", "es": "Cubrir"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_cover.svg"})
			actions.append({"action": "aerateSoil", "label": {"en": "Aerate", "es": "Airear"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_aerate.svg"})
		else:
			if development >= 0.99:
				actions.append({"action": "harvest", "label": {"en": "Harvest", "es": "Cosechar"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_harvest.svg"})
			actions.append({"action": "irrigate", "label": {"en": "Water +15mm", "es": "Regar +15mm"}, "args": {"fieldId": field_id, "mm": 15.0}, "icon": "res://assets/icons/actions/icon_water.svg"})
			actions.append({"action": "inspect", "label": {"en": "Inspect", "es": "Inspeccionar"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_inspect.svg"})
			actions.append({"action": "treat", "label": {"en": "Treat Pests", "es": "Tratar Plagas"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_treat.svg"})
			actions.append({"action": "fertilize", "label": {"en": "Fertilize", "es": "Fertilizar"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_fertilize.svg"})
			actions.append({"action": "mulch", "label": {"en": "Mulch", "es": "Acolchar"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_mulch.svg"})
			actions.append({"action": "compost", "label": {"en": "Compost", "es": "Compost"}, "args": {"fieldId": field_id}, "icon": "res://assets/icons/actions/icon_compost.svg"})

	return actions

func _animal_actions(animal_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for animal in farm.state.get("animals", []):
		if str(animal.get("id", "")) == animal_id:
			actions.append({"action": "feed", "label": {"en": "Feed", "es": "Alimentar"}, "args": {"animalId": animal_id}, "icon": "res://assets/icons/actions/icon_feed.svg"})
			actions.append({"action": "animalCare", "label": {"en": "Care", "es": "Cuidar"}, "args": {"animalId": animal_id}, "icon": "res://assets/icons/actions/icon_care.svg"})
			actions.append({"action": "vetVisit", "label": {"en": "Vet Visit", "es": "Veterinario"}, "args": {"animalId": animal_id}, "icon": "res://assets/icons/actions/icon_vet.svg"})
			actions.append({"action": "feedingPlan", "label": {"en": "Feeding Plan", "es": "Plan Alimentación"}, "args": {"animalId": animal_id, "mode": "balanced"}, "icon": "res://assets/icons/actions/icon_feeding.svg"})
			actions.append({"action": "sellAnimal", "label": {"en": "Sell", "es": "Vender"}, "args": {"animalId": animal_id}, "icon": "res://assets/icons/actions/icon_sell.svg"})
			break
	return actions

func _building_actions(building_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []

	if building_id == "farmhouse" or building_id == "market":
		actions.append({"action": "enterBuilding", "label": {"en": "Enter", "es": "Entrar"}, "args": {"building": building_id}, "icon": "res://assets/icons/actions/icon_enter.svg"})
	else:
		for b in farm.state.get("buildings", []):
			if str(b.get("id", "")) == building_id or str(b.get("kind", "")) == building_id:
				var level: int = int(b.get("level", 0))
				if level == 0:
					actions.append({"action": "completeBuilding", "label": {"en": "Finish Build", "es": "Terminar Obra"}, "args": {"buildingId": building_id}, "icon": "res://assets/icons/actions/icon_build.svg"})
				else:
					actions.append({"action": "enterBuilding", "label": {"en": "Enter", "es": "Entrar"}, "args": {"building": str(b["kind"])}, "icon": "res://assets/icons/actions/icon_enter.svg"})
					actions.append({"action": "upgradeBuilding", "label": {"en": "Upgrade", "es": "Mejorar"}, "args": {"buildingId": building_id}, "icon": "res://assets/icons/actions/icon_upgrade.svg"})
				break
	return actions

func _garden_slot_actions(slot_id: String) -> Array[Dictionary]:
	var slot: int = int(slot_id)
	var actions: Array[Dictionary] = []

	# Check if occupied
	var occupied: bool = false
	var decoration: Dictionary = {}
	for d in farm.state.get("decorations", []):
		if int(d.get("slot", -1)) == slot:
			occupied = true
			decoration = d
			break

	if occupied:
		var kind: String = str(decoration.get("kind", ""))
		var completed: bool = bool(decoration.get("completed", false))
		if not completed:
			actions.append({"action": "craftDecoration", "label": {"en": "Continue", "es": "Continuar"}, "args": {"slot": slot, "kind": kind}, "icon": "res://assets/icons/actions/icon_craft.svg"})
		actions.append({"action": "removeDecoration", "label": {"en": "Remove", "es": "Quitar"}, "args": {"slot": slot}, "icon": "res://assets/icons/actions/icon_remove.svg"})
	else:
		# Show available decorations
		for deco_id in farm.content.get("decorations", {}).keys():
			var deco: Dictionary = farm.content["decorations"][deco_id]
			actions.append({"action": "craftDecoration", "label": {"en": farm.n(deco), "es": farm.n(deco)}, "args": {"slot": slot, "kind": deco_id}, "icon": "res://assets/icons/actions/icon_deco.svg"})

	return actions.slice(0, 8)  # Max 8 items

func _build_slot_actions(slot_id: String) -> Array[Dictionary]:
	var slot: int = int(slot_id)
	var actions: Array[Dictionary] = []

	# Check if occupied
	var occupied: bool = false
	for b in farm.state.get("buildings", []):
		if str(b.get("field", "")) == "" and int(b.get("slot", -1)) == slot:
			occupied = true
			break

	if not occupied:
		for building_id in farm.content.get("buildings", {}).keys():
			var building: Dictionary = farm.content["buildings"][building_id]
			if str(building.get("scope", "farm")) == "farm":
				actions.append({"action": "build", "label": {"en": farm.n(building), "es": farm.n(building)}, "args": {"kind": building_id, "slot": slot}, "icon": "res://assets/icons/actions/icon_build.svg"})

	return actions.slice(0, 8)

func _machine_actions(machine_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var machine: Dictionary = farm.state.get("life", {}).get("machines", {}).get(machine_id, {})

	if machine.is_empty():
		# Buy machine
		var def: Dictionary = farm.content.get("machines", {}).get(machine_id, {})
		actions.append({"action": "buyMachine", "label": {"en": "Buy " + farm.n(def), "es": "Comprar " + farm.n(def)}, "args": {"machineId": machine_id}, "icon": "res://assets/icons/actions/icon_buy.svg"})
	else:
		var broken: bool = farm.machine_efficiency(machine_id) <= 0.0
		if broken:
			actions.append({"action": "repairMachine", "label": {"en": "Repair", "es": "Reparar"}, "args": {"machineId": machine_id}, "icon": "res://assets/icons/actions/icon_repair.svg"})
		actions.append({"action": "maintainMachine", "label": {"en": "Maintain", "es": "Mantenimiento"}, "args": {"machineId": machine_id}, "icon": "res://assets/icons/actions/icon_maintain.svg"})
		actions.append({"action": "sellMachine", "label": {"en": "Sell", "es": "Vender"}, "args": {"machineId": machine_id}, "icon": "res://assets/icons/actions/icon_sell.svg"})

	return actions

func _on_item_pressed(action_id: String, args: Dictionary) -> void:
	action_selected.emit(action_id, args)
	close_menu()

func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_menu()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_menu()

func _get_localized(dict_or_str: Variant) -> String:
	if typeof(dict_or_str) == TYPE_DICTIONARY:
		return str(dict_or_str.get(language, dict_or_str.get("en", "")))
	return str(dict_or_str)