# Fieldwork 5.2 — Gameplay design and technical notes

## Objectives

Expand the existing 5.1 farm while keeping its real save-linked 2D renderer and contextual UI. Different fields should demand different investments, expose clear crop constraints and offer meaningful long-term decisions.

## Core architecture

- `scripts/FieldsOpportunity52.gd` is a pure functional rules module for layout compatibility, localized labels, water and growth multipliers, cultivars and perennial cycle durations.
- `scripts/NativeFarm.gd` owns all cash, water, inventory, crops, land and state mutation. All operations still go through `quote` and `act`; failures roll back the original state.
- `data/catalog.json` now has 27 crop definitions (12 original + 15 new), 50 goods (35 original + 15 new) and unchanged original animal/building/talent data.
- `scripts/Main.gd` exposes a native bilingual crop encyclopedia, price/terrain-safe layout conversions and cultivar choice. `scripts/BeautifulFarm51.gd` retains the farm-first UI navigation.
- `scripts/World.gd` loads individual native PNG sprites dynamically from the crop catalog, draws layouts that match the actual save, and does not mutate game progress.
- `tools/generate_52_crops.py` can regenerate the 15×5 original pixel crop sprites, the three plot textures and contact sheet. Requires Python/Pillow only for asset regeneration; **not** for running the shipped game.

## Plot rules

| ID | Terrain rule | Conversion cost | Water capacity factor | Rain factor | Evap factor | Growth factor |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| open | All | 65 | 1.00 | 1.00 | 1.00 | 1.00 |
| raised | Anything except marsh | 190 | 0.84 | 0.96 | 1.14 | 1.075 |
| orchard | Anything except marsh | 510 | 1.12 | 1.05 | 0.90 | 1.00 |
| paddy | stream, marsh, clay, loam, terrace | 365 | 1.38 | 1.24 | 0.94 | 1.00 |

All price/capacity units are internal game balancing numbers. Paddy fields also lose 3.2 mm of water per simulated day through seepage. Raised beds reduce compaction by 0.002 per game day (plus the base soil model). To change a plot it must be owned, fallow, free of protective covers/solarization and compatible with building placement; conversion deducts cash and cannot be repeated on the same field in one day. `open` conversion is a paid reversal. Capacity changes do not generate additional stored water.

## Crop compatibility

Open/raised fields accept existing crops plus rye, oats, chickpeas, lentils, beetroot, cucumber, aubergine, basil, raspberries and blueberries. Only paddies accept rice. Orchards accept only apples, olives, almonds and grapes. The renderer uses five saved-state growth stages for each new crop; established trees keep canopy appearance after harvest rather than turning visually into seedlings.

Perennial crops stay in place after harvest and begin a shorter regrowth cycle. Winter reduces orchard growth rate to 38% rather than deleting trees. Crops still require water, nutrients and pest control. Varieties:

| Variety | Seed cost factor | Growth factor | Harvest factor | Water need factor |
| --- | ---: | ---: | ---: | ---: |
| Standard | 1.00 | 1.00 | 1.00 | 1.00 |
| Early | 1.17 | 1.19 | 0.88 | 1.00 |
| Resilient | 1.24 | 0.96 | 0.98 | 0.78 |

The crop-guide screen offers information; it does not grant free crops or water.

## Save format and migration

5.2 saves use `FW_NATIVE_5_2`, version/schema 8 and `fieldwork_native_5_2.json` / `fieldwork_slots_52/`. Schema 7 saves upgrade with `plot_type=open`, `last_conversion_day=-9999`, `variety=standard` and `harvest_cycles=0` where crops exist. This preserves legacy plot/soil data, money, animals, NPC decisions, story progression and equipment. Original files remain as import sources and aren't deliberately overwritten.

## QA and release criteria

- Run `python3 tests/qa_52.py` to validate catalog and original-content hashes, byte-level PNG integrity, static script paths, balanced delimiters, duplicate methods, signal collisions and test inclusion.
- Run `godot --headless --path . --editor --quit` in a real Godot 4.4+ environment to compile scripts and import image resources.
- Run `./RUN_NATIVE_TESTS.sh` or `RUN_NATIVE_TESTS.bat` to exercise native gameplay, migration, UI and historical tests. These were included but **not executed** in the environment that created this release.
- Manually inspect map layout at 1320×800 and smaller windows, plant/harvest every new crop, inspect greenhouse constraints and save/load after setting different layouts.
- Do not claim runtime success until Godot exits cleanly, zero source parser errors remain, and screenshots demonstrate actual scene rendering.

## Not in scope for 5.2

Full free-form placement editing, additional climate simulation for greenhouses, automatic irrigation piping, multiplayer and 5.3 full character appearance creation remain future work.
