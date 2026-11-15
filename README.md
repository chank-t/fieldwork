# FIELDWORK 6.0 - Clean & Documented Edition

A native, offline Godot farming and countryside game with 2D and isometric-style 2.5D views, farming economics, character customization, community stories, and regional exploration.

**Requirements:** Godot 4.4 or later. The source can be opened on a PC; it includes responsive touch-oriented UI code for mobile, but no prebuilt Android APK, iOS app, or export preset.

## Quick start

1. Extract the entire `Fieldwork-6.0-Clean` folder, not only `project.godot`.
2. In Godot 4.4+, choose **Import** and select `project.godot`.
3. Press **F5**, select English or Spanish, and create a new farm or continue a previous save.
4. Open **Farm / Fields / Goals (Farm Compass)** to start working. Use **All screens** for other systems.

## What is included

- **Farming:** 24 plots, 27 crops, four plot layouts, 10 terrain types, pests, soil and crop quality.
- **Farm management:** 11 animal species, 24 building definitions, machinery, processing, market and economy.
- **Life and progression:** farmer creator/wardrobe, 25 talents, eight courses, six certifications, 30 neighbour story chapters and four seasonal festivals.
- **Exploration:** eight valley regions, 24 regional project chapters, three explorer professions and countryside activities.
- **Presentation:** classic 2D map, isometric-style 2.5D map, desktop/mobile interface paths, touch input and Eco/Balanced/Quality modes.
- **6.0 Farm Compass:** read-only recommendations plus six farm-development indicators.
- **Persistence:** checksummed local JSON save, two recovery backups, three manual slots, and legacy save imports.

## Documentation

| Document | Purpose |
| --- | --- |
| [PDF manual](docs/FIELDWORK_6_0_MANUAL.pdf) | Standalone player/developer handbook |
| [Documentation index](docs/INDEX.md) | Where to start |
| [Player guide](docs/PLAYER_GUIDE.md) | Controls, interface and gameplay loop |
| [Architecture](docs/ARCHITECTURE.md) | Main scenes, scripts, boundaries and data flow |
| [Action API](docs/ACTION_API.md) | Transaction actions and their argument keys |
| [Content and data](docs/CONTENT_AND_DATA.md) | Catalogs, assets and extension points |
| [Saves and migration](docs/SAVES_AND_MIGRATION.md) | Save files, backups and safe upgrades |
| [Build and tests](docs/BUILD_AND_TEST.md) | Editor steps, headless tests and release checklist |
| [Limitations and roadmap](docs/LIMITATIONS_AND_ROADMAP.md) | Known gaps and next steps |
| [Cleanup record](docs/CLEANUP_REPORT.md) | What changed and what was preserved |

Older release notes are kept separately in [`docs/history/`](docs/history/). They are for reference, not the current setup guide.

## Verify the project

Python 3 (does **not** parse GDScript):

```sh
python3 tests/qa_60.py
```

Godot engine checks (requires Godot installed):

```sh
GODOT=/path/to/godot ./RUN_NATIVE_TESTS.sh
```

On Windows, set `GODOT` to your Godot executable and run `RUN_NATIVE_TESTS.bat` from the project directory. See [Build and tests](docs/BUILD_AND_TEST.md).

## Important notes

- All gameplay source, currently loaded assets, scenes, and native Godot smoke tests are preserved. Cleaning did **not** refactor or change the simulation.
- Saves are stored under Godot `user://`, **not** inside the source folder. Cleaning the source directory does not delete them.
- Save schema version remains `10`; the JSON envelope format remains `FW_NATIVE_5_4`. This is expected and should not be casually renamed.
- This edition is **not runtime-verified**: the Godot engine is unavailable in the packaging environment. Offline checks are not a substitute for launching in Godot and testing on devices.
- Rights and licences for preexisting game artwork are not established by this packaging pass. Review them before public distribution.

**Release identification:** Fieldwork 6.0 - Clean & Documented Edition. This is a maintenance/distribution cleanup of 6.0, not version 6.1 and not a new save schema.
