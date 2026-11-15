@echo off
setlocal
if "%GODOT%"=="" set "GODOT=godot"
"%GODOT%" --headless --path . --editor --quit || exit /b 1
for %%T in (native_smoke layout_smoke decision_45_smoke ui_45_smoke save_46_smoke ui_46_smoke living_world_47_smoke story_48_smoke ui_story_48_smoke farming_life_49_smoke ui_life_49_smoke world_worth_50_smoke ui_world_50_smoke beautiful_farm_51_smoke ui_beautiful_farm_51_smoke fields_opportunity_52_smoke ui_fields_52_smoke farmer_style_53_smoke ui_farmer_53_smoke living_countryside_54_smoke ui_countryside_54_smoke layout_logic_55_smoke ui_interface_55_smoke isometric_56_smoke living_farm_57_smoke beyond_farm_58_smoke performance_accessibility_59_smoke complete_experience_60_smoke) do (
  "%GODOT%" --headless --path . --script res://tests/%%T.gd || exit /b 1
)
echo Godot test suite passed.
