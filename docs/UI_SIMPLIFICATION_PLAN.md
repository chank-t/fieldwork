# FieldWork UI Simplification Plan

## Overview
Reduce 28 sidebar tabs → 6 hubs with card-based panels, add radial context menus on the map, and replace text-heavy tutorial with guided onboarding.

---

## 1. Six Hubs Structure

| Hub | Icon | Color | Panels (4-5 each) |
|-----|------|-------|-------------------|
| **Farm** | 🌾 | `#3f6652` | Overview, Compass, Explorer, My Fields |
| **Fields** | 🌱 | `#8f7a4b` | Manage Plot, Crop Guide, Soil & Pests, Daily Plan |
| **Animals** | 🐄 | `#b8665a` | Livestock, Buildings, Workshop, Machinery |
| **Village** | 🏘️ | `#6b7a9e` | Neighbours, Stories, Community, Expeditions |
| **Market** | 🏪 | `#dbb86b` | Market, Economy, Resources, Trade |
| **Me** | 👤 | `#9b59b6` | Character, Wardrobe, Story, Journal, Settings |

---

## 2. Files Created

| File | Purpose |
|------|---------|
| `scripts/UIHubs.gd` | Hub/panel definitions, localized names, navigation logic |
| `scripts/ContextRadialMenu.gd` | Radial menu appearing on map entity tap/click |
| `scripts/GuidedOnboarding.gd` | 10-step interactive tutorial with UI highlighting |
| `scripts/UIIntegration.gd` | Helper functions to wire into Main.gd |

---

## 3. Main.gd Changes Required

### A. Add Preloads (near line 5-26)
```gdscript
const UIHubs = preload("res://scripts/UIHubs.gd")
const ContextRadialMenu = preload("res://scripts/ContextRadialMenu.gd")
const GuidedOnboarding = preload("res://scripts/GuidedOnboarding.gd")
```

### B. Add Member Variables (near line 38-114)
```gdscript
var radial_menu: Variant
var onboarding: Variant
var current_hub: String = "Farm"
var current_panel: String = "overview"
var hub_buttons: Dictionary = {}
```

### C. In `_show_game()` - After World Creation
```gdscript
# Radial menu (top-level overlay)
radial_menu = ContextRadialMenu.new()
radial_menu.set_farm(farm)
radial_menu.action_selected.connect(_on_radial_action)
scene_root.add_child(radial_menu)

# Onboarding
onboarding = GuidedOnboarding.new()
if int(farm.state["story"].get("starter_guide", 0)) < 10:
    call_deferred("_start_onboarding")
```

### D. Replace Sidebar Groups (lines 1072-1090)
```gdscript
# OLD: 3 groups × ~9 tabs each = 27 buttons
# NEW: Hub bar + panel cards
hub_buttons = UIIntegration.build_hub_bar(nav_list, self, language, ui_scale, current_hub, _on_hub_selected.callable())
```

### E. Replace `_render_panel()` Match (lines 1584-1618)
```gdscript
func _render_panel() -> void:
    if not game_running or right_body == null: return
    for child in right_body.get_children():
        right_body.remove_child(child); child.queue_free()

    UIIntegration.build_panel_cards(right_body, current_hub, self, language, ui_scale, current_panel, _on_panel_selected.callable())
```

### F. New Handler Functions
```gdscript
func _on_hub_selected(hub_id: String) -> void:
    current_hub = hub_id
    current_panel = UIHubs.get_hub_data(hub_id)["panels"][0]["id"]
    _update_nav_state()
    _render_panel()

func _on_panel_selected(panel_id: String) -> void:
    current_panel = panel_id
    _render_hub_panel(current_hub, panel_id)

func _render_hub_panel(hub_id: String, panel_id: String) -> void:
    # Map panel_id to actual panel rendering functions
    match hub_id:
        "Farm":
            match panel_id:
                "overview": _panel_farm()
                "compass": _panel_compass60()
                "explorer": _panel_explorer()
                "fields_list": _panel_fields_list()
        "Fields":
            match panel_id:
                "manage": _panel_field_manage()      # Contextual to selected_field
                "crop_guide": _panel_crop_guide52()
                "ecology": _panel_ecology()
                "planning": _panel_planning()
        "Animals":
            match panel_id:
                "livestock": _panel_animals()
                "buildings": _panel_buildings()
                "processing": _panel_processing()
                "machinery": _panel_machinery()
        "Village":
            match panel_id:
                "neighbours": _panel_neighbours()
                "stories": _panel_stories()
                "community": _panel_community_combined()
                "expeditions": _panel_expeditions58()
        "Market":
            match panel_id:
                "market": _panel_market()
                "economy": _panel_economy()
                "resources": _panel_resources()
                "trade": _panel_trade()
        "Me":
            match panel_id:
                "character": _panel_character()
                "wardrobe": _panel_wardrobe53()
                "story": _panel_story()
                "journal": _panel_journal()
                "options": _panel_options()
```

### G. Radial Menu Action Handler
```gdscript
func _on_radial_action(action_id: String, args: Dictionary) -> void:
    UIIntegration.on_radial_action(self, action_id, args)
```

### H. Connect 3D View Signals to Radial Menu
```gdscript
# In _show_game(), replace signal connections:
world.selected_field.connect(_on_field_picked_radial)
world.selected_animal.connect(_on_animal_picked_radial)
world.selected_building.connect(_on_building_picked_radial)
world.selected_decoration.connect(_on_decoration_picked_radial)
world.selected_build_slot.connect(_on_build_slot_picked_radial)
world.machine_chosen57.connect(_on_machine_picked_radial)

func _on_field_picked_radial(field_id: String) -> void:
    UIIntegration.on_field_picked(self, radial_menu, field_id)

func _on_animal_picked_radial(animal_id: String) -> void:
    UIIntegration.on_animal_picked(self, radial_menu, animal_id)

# ... similar for building, decoration, build_slot, machine
```

### I. Onboarding Start
```gdscript
func _start_onboarding() -> void:
    UIIntegration.start_onboarding(self, farm, onboarding)
```

---

## 4. Asset Requirements

Create these icons (64×64 recommended) in `assets/`:
```
icon_farm.png           icon_fields.png         icon_animals.png
icon_village.png        icon_market.png         icon_me.png
icon_overview.png       icon_compass.png        icon_explorer.png
icon_manage.png         icon_crops.png          icon_ecology.png
icon_planning.png       icon_livestock.png      icon_buildings.png
icon_processing.png     icon_machinery.png      icon_neighbours.png
icon_stories.png        icon_community.png      icon_expeditions.png
icon_economy.png        icon_resources.png      icon_trade.png
icon_character.png      icon_wardrobe.png       icon_story.png
icon_journal.png        icon_options.png
icon_buy.png            icon_plant.png          icon_harvest.png
icon_water.png          icon_inspect.png        icon_treat.png
icon_fertilize.png      icon_mulch.png          icon_compost.png
icon_cover.png          icon_aerate.png         icon_feed.png
icon_care.png           icon_vet.png            icon_feeding.png
icon_sell.png           icon_enter.png          icon_build.png
icon_upgrade.png        icon_craft.png          icon_remove.png
icon_deco.png           icon_repair.png         icon_maintain.png
```

---

## 5. Migration Map (Old → New)

| Old Tab | New Hub | New Panel |
|---------|---------|-----------|
| Farm | Farm | overview |
| Compass60 | Farm | compass |
| Explorer | Farm | explorer |
| Fields | Fields | manage / fields_list |
| CropGuide52 | Fields | crop_guide |
| Ecology | Fields | ecology |
| Planning | Fields | planning |
| Machinery | Animals | machinery |
| Resources | Market | resources |
| GardenStudio57 | Fields | (in manage) |
| Buildings | Animals | buildings |
| Animals | Animals | livestock |
| Processing | Animals | processing |
| Market | Market | market |
| Economy | Market | economy |
| Neighbours | Village | neighbours |
| Stories | Village | stories |
| Community50 | Village | community |
| Festivals50 | Village | (in community) |
| Certifications50 | Village | (in community) |
| Character | Me | character |
| Wardrobe53 | Me | wardrobe |
| Story | Me | story |
| Journal | Me | journal |
| Options | Me | options |
| Valley | Farm | (map view toggle) |
| Countryside54 | Village | expeditions |
| Expeditions58 | Village | expeditions |

---

## 6. Onboarding Steps (10 Steps)

1. **Welcome** - Introduction
2. **Inspect Field** - Tap plot1, radial menu → Inspect
3. **Plant Crop** - Radial menu → Plant → Wheat
4. **Water** - Radial menu → Water +15mm
5. **Advance Time** - Speed controls → 4×
6. **Harvest** - Radial menu → Harvest (when 100%)
7. **Sell** - Navigate to Market hub → Market panel
8. **Buy Land** - Tap unowned field → Buy
9. **Build** - Animals hub → Buildings panel
10. **Complete** - Celebration

Each step highlights the relevant UI element with a pulsing ring.

---

## 7. Testing Checklist

- [ ] All 6 hubs switch correctly
- [ ] Panel cards render with icons, titles, descriptions
- [ ] Radial menu appears on field/animal/building/decoration/build_slot/machine tap
- [ ] Radial actions execute correct `_ask`/`_direct` calls
- [ ] Onboarding runs for new games, highlights correct elements
- [ ] Onboarding can be skipped
- [ ] Save/load preserves `current_hub` and `current_panel`
- [ ] Mobile layout works (hub bar at bottom, cards stack)
- [ ] Keyboard navigation works (Tab between hubs, Enter to select panel)
- [ ] High contrast mode respected
- [ ] Reduced motion disables pulsing animations

---

## 8. Estimated Effort

| Task | Effort |
|------|--------|
| Create icon assets | 1-2 days |
| Integrate hub bar + panel cards | 1 day |
| Integrate radial menu + 3D signal connections | 1-2 days |
| Integrate onboarding + UI highlighting | 1 day |
| Migrate panel rendering functions | 2-3 days |
| Testing & polish | 2 days |
| **Total** | **~1-2 weeks** |