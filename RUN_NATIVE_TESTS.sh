#!/usr/bin/env sh
set -eu
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --editor --quit
for t in native_smoke layout_smoke decision_smoke ui_decision_smoke save_smoke ui_save_smoke living_world_smoke story_smoke ui_story_smoke farming_life_smoke ui_life_smoke world_worth_smoke ui_world_smoke beautiful_farm_smoke ui_beautiful_farm_smoke fields_opportunity_smoke ui_fields_smoke farmer_style_smoke ui_farmer_smoke living_countryside_smoke ui_countryside_smoke layout_logic_smoke ui_interface_smoke isometric_smoke living_farm_smoke beyond_farm_smoke performance_accessibility_smoke complete_experience_smoke; do
  "$GODOT" --headless --path . --script "res://tests/$t.gd"
done
