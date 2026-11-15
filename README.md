# Fieldwork 6.0

A native, offline Godot farming and countryside game with classic 2D and isometric-style 2.5D maps, farming, community stories and regional exploration.

**Recommended editor:** Godot 4.6, matching the version marked in `project.godot`. Compatibility with earlier Godot versions has not been verified. This source project does not include a prebuilt desktop or mobile app.

## Play

1. Open Godot and import this folder by selecting `project.godot`.
2. Let Godot import the assets, then press **F5**.
3. Choose English or Spanish, then create a farm or continue a saved game.
4. Open **Farm / Fields / Goals (Farm Compass)** to begin.

Keep the complete project folder together; scenes, scripts, `assets/`, `data/` and `references/` are used by the game.

## Player help

- [Player guide](docs/PLAYER_GUIDE.md)
- [PDF manual](docs/FIELDWORK_6_0_MANUAL.pdf)

## Included

- 24 plots, 27 crops, multiple plot layouts, soil, pests and crop quality.
- Animals, buildings, machinery, processing, market and farm economics.
- Farmer appearance, skills, courses, neighbour stories and festivals.
- Eight valley regions, regional projects and countryside activities.
- Desktop/touch-oriented UI, 2D and 2.5D views, and Eco/Balanced/Quality modes.
- Local saves, recovery backups, three manual slots and legacy save imports.

## Notes

- Saves are stored under Godot `user://`, not in this source folder. Removing or replacing project files does not remove existing saves.
- The save schema remains version 10 with envelope `FW_NATIVE_5_4`; these identifiers are retained for compatibility.
- Godot runtime and device/export verification have not been performed in this environment.
- Artwork and source licensing have not been established; review rights before public distribution.
