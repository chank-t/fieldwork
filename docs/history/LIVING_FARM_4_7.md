# Fieldwork Native 4.7 — Living Farm visual system

This document describes **actual additions to the editable Godot 4 project**, not a concept spec. The **4.6 farming model and on-disk save schema are unchanged**; all new animated elements use render time and already saved data, never simulation RNG.

## Feature inventory

| Area | Implementation | Game state source |
|---|---|---|
| Crop growth | Five visual stages on all 12 crops: sown, sprout, young, flowering, mature. Four hand-generated stage assets per species; maturity uses existing sprite. | `field.crop.development` |
| Field health | Dry cracks, wet puddles, winter frost, lower-vigor plant palette, readiness marks. | `field.soil.water/capacity`, pests, diseases, season |
| Livestock | Up to three visible individuals per actual owned group, with `xN` display at higher zoom. Sleeping at night, resting, grazing, drinking, moving, low-welfare indicator. | `animal.count`, `animal.condition`, game hour |
| Structures | Construction scaffolds, animated chimney smoke for suitable completed buildings, glowing windows at night. | `building.level`, `target`, `kind`, game hour |
| Characters | NPCs follow original schedules; no new dialogue or schedule data. Cosmetic idle animation. | `content.npcs`, time |
| Atmosphere | Four seasonal ground palettes and tree tints, autumn leaves, winter frost particles, river shimmer, morning fog, dusk/night tint, rain, and window glow. | season, hour, weather.kind, humidity |
| Interiors | A distinct palette and object shapes for farmhouses, market, animal housing, processing facilities, learning and ecological spaces. Click-to-walk and inspect existing props. | selected completed building, existing visit flow |
| Interface | Crop-stage description and animal-activity notes in existing management panels; three optional visual controls stored in local presentation preferences. | `user://fieldwork_settings.cfg` (not in farm save) |
| Panoramic view | New visuals appear both in the embedded live farm and the existing full-screen scenic mode. | same `World.gd` |

## Visual rules, not simulation rules

`WorldPresentation.gd` centralizes deterministic presentation values:

- Crop stage thresholds: development `<0.05` sown; `<0.23` sprout; `<0.52` young; `<0.82` flowering; otherwise maturing. This does **not** alter harvest readiness, which remains decided by the original model.
- Dry/wet appearance: soil water `<24%` or `>82%` of field capacity. The inspector continues to show actual measurements. These are deliberately **presentation thresholds** only, not agronomic advice.
- Plant vigour: a bounded, cosmetic approximation using water, highest pest pressure and disease pressure. It never replaces the core `crop.health` or `crop.biomass` calculations.
- Animal activities: deterministic schedule derived from game hour, index, and group condition. They are **visual activities**; not full animal agent pathfinding or new resource consumption.
- World ambience is animated by elapsed render time and does not generate or consume model RNG.

## Project structure

- `scripts/WorldPresentation.gd`: presentation-only crop, soil, animal and time helpers.
- `scripts/World.gd`: real-time native 2D visual world, click targets, field overlays and weather.
- `scripts/Interior.gd`: building-specific walkable visit scenes.
- `scripts/Main.gd`: visual toggles and bilingual living-state summaries.
- `assets/growth_<crop>_<stage>.png`: 48 transparent PNGs; stage indices 0 through 3.
- `tools/generate_growth_sprites.py`: deterministic, build-time Pillow generator; the shipped game **does not require Python**.
- `tests/living_world_47_smoke.gd`: **included** engine-level smoke tests; run with Godot.
- `tests/qa_47.py`: offline static/asset/compatibility audit.

## Compatibility

`NativeFarm.gd`, `data/catalog.json`, and `data/decisions.json` are byte-identical to the Fieldwork Native **4.6** release. Visual flags are not serialized in farms. Existing 4.5/4.6 saves, three save slots and the two rolling recovery backups keep their established paths and semantics. This version adds no new crop economics, prestige bonuses, online service, or save migration requirements.

## Limitations

**Not in-engine verified in this environment.** Do not claim parser or live rendering success before running the native test suite and viewing a real Godot window. Plant sprites are small 2D illustrations, not procedural growth meshes. Animal routines are cosmetic rather than independent locomotion AI. Interior props offer contextual inspection; individual buildings do not become independent production mini-games. A physical Android export is not included.

## Manual visual QA

Run the full project in Godot 4.4+ and test at 1440×900, 1280×720, 960×720, and 720×540. Confirm the following:

1. Title screen and **Spanish choice** before new game; character preview, seed control, and starting bonuses visible.
2. Start with one plot; inspect, plant and advance through the five visual stages without altering the original harvest formula.
3. Compare dry and wet fields, pest pressure, spring/summer/autumn/winter and rain/night/fog.
4. Buy an appropriate building, complete construction, check smoke/glow, enter and inspect its props.
5. Raise and care for animals, confirm that groups respond visually to condition and daily hour, and that clicking an actual animal selects it.
6. Open **Vista amplia / Scenic view** and use WASD, zoom, click, mouse-wheel and pan.
7. Turn each option off in Settings; restart and verify it persists without modifying the farm save.
8. Save/load, save slots and recovery remain functional. Test old 4.6 saves.
9. Check English and Spanish at every resolution and inspect the debugger for errors.

Run `RUN_NATIVE_TESTS.bat` on Windows or `RUN_NATIVE_TESTS.sh` on Linux/macOS. Included Godot scripts are not a substitute for screenshot inspection.
