extends RefCounted
## Integration helpers for the new simplified UI system.
## Shows how to wire UIHubs, ContextRadialMenu, and GuidedOnboarding into Main.gd.

const UIHubs = preload("res://scripts/UIHubs.gd")
const ContextRadialMenu = preload("res://scripts/ContextRadialMenu.gd")
const GuidedOnboarding = preload("res://scripts/GuidedOnboarding.gd")
const ThemeKit = preload("res://scripts/three_d/GameTheme.gd")

## ============================================================================
## MAIN.GD INTEGRATION POINTS
## ============================================================================

# 1. In _ready(), add these preloads alongside existing ones:
#
# const UIHubs = preload("res://scripts/UIHubs.gd")
# const ContextRadialMenu = preload("res://scripts/ContextRadialMenu.gd")
# const GuidedOnboarding = preload("res://scripts/GuidedOnboarding.gd")
#
# var radial_menu: Variant
# var onboarding: Variant
# var current_hub: String = "Farm"
# var current_panel: String = "overview"

# 2. In _show_game(), after creating the world, instantiate the radial menu:
#
# radial_menu = ContextRadialMenu.new()
# radial_menu.set_farm(farm)
# radial_menu.action_selected.connect(_on_radial_action)
# scene_root.add_child(radial_menu)  # Top-level so it draws over everything
#
# onboarding = GuidedOnboarding.new()

# 3. Connect 3D view selection signals to radial menu:
# Replace the existing _picked_field, _picked_animal, etc. with versions that
# show the radial menu instead of switching tabs.

# 4. Replace the sidebar navigation (lines 1072-1090) with hub bar:
# Call _build_hub_bar() instead of the groups loop.

# 5. Replace _render_panel() match statement with hub-based panel rendering:
# Call _render_hub_panel(current_hub, current_panel)

# 6. In _ready() or _show_game(), start onboarding for new games:
# if farm.state["story"]["starter_guide"] < UIHubs.STARTER_GUIDE.size():
#     onboarding.start(farm, self, _on_onboarding_complete)

## ============================================================================
## HUB BAR BUILDER (replaces sidebar groups)
## ============================================================================

static func build_hub_bar(parent: Node, main_ui: Variant, language: String, ui_scale: float, current_hub: String, on_hub_selected: Callable) -> Dictionary:
    var hub_buttons: Dictionary = {}
    var bar: HBoxContainer = HBoxContainer.new()
    bar.add_theme_constant_override("separation", 4)
    bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(bar)

    for hub_id in UIHubs.get_hub_order():
        var hub_data: Dictionary = UIHubs.get_hub_data(hub_id)
        var hub_color: Color = hub_data.get("color", Color("#3f6652"))
        var is_active: bool = hub_id == current_hub

        var btn: Button = Button.new()
        btn.custom_minimum_size = Vector2(56, 56) * ui_scale
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.tooltip_text = UIHubs.get_localized_name(hub_id, language)
        btn.focus_mode = Control.FOCUS_ALL

        # Icon
        var icon_path: String = hub_data.get("icon", "")
        if icon_path != "" and ResourceLoader.exists(icon_path):
            var icon: TextureRect = TextureRect.new()
            icon.texture = load(icon_path)
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.custom_minimum_size = Vector2(28, 28) * ui_scale
            icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
            icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            btn.add_child(icon)
            icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

        # Style
        var style_normal = StyleBoxFlat.new()
        style_normal.bg_color = hub_color if is_active else Color("#f7f4e9")
        style_normal.set_corner_radius_all(12)
        style_normal.border_color = hub_color if is_active else Color("#dce9d8")
        style_normal.set_border_width_all(0 if is_active else 2)
        btn.add_theme_stylebox_override("normal", style_normal)

        var style_hover = style_normal.duplicate()
        style_hover.bg_color = hub_color.lightened(0.15) if is_active else Color("#ecf7e9")
        btn.add_theme_stylebox_override("hover", style_hover)

        var style_pressed = style_normal.duplicate()
        style_pressed.bg_color = hub_color.darkened(0.15) if is_active else Color("#dceedd")
        btn.add_theme_stylebox_override("pressed", style_pressed)

        btn.pressed.connect(on_hub_selected.bind(hub_id))
        bar.add_child(btn)
        hub_buttons[hub_id] = btn

    return hub_buttons

## ============================================================================
## PANEL CARD BUILDER (replaces list-of-buttons panels)
## ============================================================================

static func build_panel_cards(parent: Node, hub_id: String, main_ui: Variant, language: String, ui_scale: float, current_panel: String, on_panel_selected: Callable) -> void:
    var hub_data: Dictionary = UIHubs.get_hub_data(hub_id)
    var panels: Array = hub_data.get("panels", [])

    var grid: GridContainer = GridContainer.new()
    grid.columns = 2
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 12)
    grid.add_theme_constant_override("v_separation", 12)
    parent.add_child(grid)

    for panel_data in panels:
        var panel_id: String = panel_data["id"]
        var is_active: bool = panel_id == current_panel
        var panel_color: Color = hub_data.get("color", Color("#3f6652"))

        var card: PanelContainer = PanelContainer.new()
        card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        card.custom_minimum_size = Vector2(0, 110) * ui_scale
        grid.add_child(card)

        var card_style = StyleBoxFlat.new()
        card_style.bg_color = Color("#fbf8eb") if not is_active else panel_color.lightened(0.35)
        card_style.set_corner_radius_all(12)
        card_style.border_color = panel_color if is_active else Color("#dce9d8")
        card_style.set_border_width_all(2 if is_active else 1)
        card_style.content_margin_left = 16
        card_style.content_margin_right = 16
        card_style.content_margin_top = 14
        card_style.content_margin_bottom = 14
        card.add_theme_stylebox_override("panel", card_style)

        var card_layout: VBoxContainer = VBoxContainer.new()
        card_layout.add_theme_constant_override("separation", 6)
        card.add_child(card_layout)

        # Icon row
        var icon_row: HBoxContainer = HBoxContainer.new()
        card_layout.add_child(icon_row)

        var icon_path: String = panel_data.get("icon", "")
        if icon_path != "" and ResourceLoader.exists(icon_path):
            var icon: TextureRect = TextureRect.new()
            icon.texture = load(icon_path)
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.custom_minimum_size = Vector2(32, 32) * ui_scale
            icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
            icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            icon.modulate = panel_color
            icon_row.add_child(icon)

        var title: Label = Label.new()
        title.text = UIHubs.get_panel_title(hub_id, panel_id, language)
        title.autowrap_mode = TextServer.AUTOWRAP_OFF
        title.clip_text = true
        title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        title.add_theme_font_size_override("font_size", maxi(14, int(16 * ui_scale)))
        title.add_theme_color_override("font_color", Color("#263a32") if not is_active else Color.WHITE)
        if is_active:
            title.add_theme_font_override("font", ThemeKit.SERIF)
        icon_row.add_child(title)

        # Description
        var desc: Label = Label.new()
        desc.text = UIHubs.get_panel_desc(hub_id, panel_id, language)
        desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        desc.add_theme_font_size_override("font_size", maxi(11, int(12 * ui_scale)))
        desc.add_theme_color_override("font_color", Color("#687e70") if not is_active else Color("#f7f4e9"))
        card_layout.add_child(desc)

        # Make whole card clickable
        var btn: Button = Button.new()
        btn.custom_minimum_size = Vector2(0, 110) * ui_scale
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
        btn.mouse_filter = Control.MOUSE_FILTER_STOP
        btn.focus_mode = Control.FOCUS_ALL
        var transparent_style = StyleBoxFlat.new()
        transparent_style.bg_color = Color(0, 0, 0, 0)
        transparent_style.set_corner_radius_all(12)
        btn.add_theme_stylebox_override("normal", transparent_style)
        btn.add_theme_stylebox_override("hover", transparent_style)
        btn.add_theme_stylebox_override("pressed", transparent_style)
        btn.pressed.connect(on_panel_selected.bind(panel_id))
        card.add_child(btn)
        btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

## ============================================================================
## RADIAL MENU HANDLERS (connect to 3D view signals)
## ============================================================================

static func on_field_picked(main_ui: Variant, radial_menu: Variant, field_id: String) -> void:
    main_ui.selected_field = field_id
    if main_ui.world != null:
        main_ui.world.set_selected(field_id)

    # Show radial menu at field position on screen
    var world: Variant = main_ui.world
    if world != null and is_instance_valid(world):
        var screen_pos: Vector2 = world.get_field_screen_pos(field_id)
        _show_pick_radial(world, radial_menu, screen_pos, "field", field_id)

static func on_animal_picked(main_ui: Variant, radial_menu: Variant, animal_id: String) -> void:
    var world: Variant = main_ui.world
    if world != null and is_instance_valid(world):
        _show_pick_radial(world, radial_menu, world.get_animal_screen_pos(animal_id), "animal", animal_id)

static func on_building_picked(main_ui: Variant, radial_menu: Variant, building_id: String) -> void:
    var world: Variant = main_ui.world
    if world != null and is_instance_valid(world):
        _show_pick_radial(world, radial_menu, world.get_building_screen_pos(building_id), "building", building_id)

static func on_garden_slot_picked(main_ui: Variant, radial_menu: Variant, slot: int) -> void:
    var world: Variant = main_ui.world
    if world != null and is_instance_valid(world):
        _show_pick_radial(world, radial_menu, world.get_garden_slot_screen_pos(slot), "garden_slot", str(slot))

static func on_build_slot_picked(main_ui: Variant, radial_menu: Variant, slot: int) -> void:
    var world: Variant = main_ui.world
    if world != null and is_instance_valid(world):
        _show_pick_radial(world, radial_menu, world.get_build_slot_screen_pos(slot), "build_slot", str(slot))

static func on_machine_picked(main_ui: Variant, radial_menu: Variant, machine_id: String) -> void:
    var world: Variant = main_ui.world
    if world != null and is_instance_valid(world):
        _show_pick_radial(world, radial_menu, world.get_machine_screen_pos(machine_id), "machine", machine_id)

static func _show_pick_radial(world: Variant, radial_menu: Variant, local_position: Vector2, kind: String, id: String) -> void:
    if radial_menu == null or not is_instance_valid(radial_menu):
        return
    if local_position.x < 0.0 or local_position.y < 0.0 or local_position.x > world.size.x or local_position.y > world.size.y:
        return
    var global_position: Vector2 = world.get_global_transform() * local_position
    var menu_position: Vector2 = radial_menu.get_global_transform().affine_inverse() * global_position
    radial_menu.show_at(menu_position, {"type": kind, "id": id})

static func on_radial_action(main_ui: Variant, action_id: String, args: Dictionary) -> void:
    match action_id:
        "plant", "treat", "fertilize":
            main_ui.selected_field = str(args.get("fieldId", main_ui.selected_field))
            main_ui._change_tab("Fields")
        "buyField", "harvest", "irrigate", "inspect", "mulch", "compost", "coverCrop", "aerateSoil":
            main_ui._ask(action_id, args)
        "buyFeed":
            main_ui._ask("buySupply", args)
        "animalCare", "vetVisit", "feedingPlan":
            main_ui._ask(action_id, args)
        "enterBuilding":
            main_ui._enter_building(args.get("building", ""))
        "openBuildings":
            main_ui._change_tab("Buildings")
        "openGarden":
            main_ui._change_tab("GardenStudio57")
        "openMachinery":
            main_ui._change_tab("Machinery")
        "upgradeBuilding":
            var instance_id: String = str(args.get("buildingId", ""))
            for building in main_ui.farm.state.get("buildings", []):
                if str(building.get("id", "")) == instance_id:
                    main_ui._ask("upgrade", {"buildingId": str(building.get("kind", "")), "fieldId": str(building.get("field", ""))})
                    return
            main_ui._ask("upgrade", {"buildingId": instance_id})
        "build":
            main_ui._ask("build", args)
        "craftDecoration":
            main_ui._ask("craftDecoration", args)
        "buyMachine", "serviceMachine":
            main_ui._ask(action_id, args)
        _:
            main_ui._direct(action_id, args)

## ============================================================================
## ONBOARDING INTEGRATION
## ============================================================================

static func start_onboarding(main_ui: Variant, farm: Variant, onboarding: Variant) -> void:
    var step: int = int(farm.state.get("story", {}).get("starter_guide", 0))
    if step < 10:  # STARTER_GUIDE.size()
        onboarding.start(farm, main_ui, func(): _on_onboarding_complete(main_ui))

static func _on_onboarding_complete(main_ui: Variant) -> void:
    # Onboarding finished - could show a celebration, unlock something, etc.
    main_ui._notify("Tutorial complete! Explore the 6 hubs at your own pace.")

## ============================================================================
## MIGRATION MAP: OLD TABS → NEW HUBS + PANELS
## ============================================================================

# Old Tab ID          → New Hub    → New Panel ID
# ------------------------------------------------------------
# Farm                → Farm       → overview
# Compass60           → Farm       → compass
# Explorer            → Farm       → explorer
# Fields              → Fields     → manage (contextual) / fields_list
# CropGuide52         → Fields     → crop_guide
# Ecology             → Fields     → ecology
# Planning            → Fields     → planning
# Machinery           → Animals    → machinery
# Resources           → Market     → resources
# GardenStudio57      → Fields     → (integrated into manage)
# Buildings           → Animals    → buildings
# Animals             → Animals    → livestock
# Processing          → Animals    → processing
# Market              → Market     → market
# Economy             → Market     → economy
# Neighbours          → Village    → neighbours
# Stories             → Village    → stories
# Community50         → Village    → community
# Festivals50         → Village    → (integrated into community)
# Certifications50    → Village    → (integrated into community)
# Character           → Me         → character
# Wardrobe53          → Me         → wardrobe
# Story               → Me         → story
# Journal             → Me         → journal
# Options             → Me         → options
# Valley              → (special)  → Map view in Farm hub
# Countryside54       → Village    → expeditions
# Expeditions58       → Village    → expeditions