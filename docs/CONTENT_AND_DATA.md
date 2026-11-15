# Content and data reference

The counts below were taken from the source catalog and rule definitions in the cleaned 6.0 project.

## Catalog inventory

| Category | Count | Source |
| --- | ---: | --- |
| Land plots | 24 | `NativeFarm.MAX_FIELDS` |
| Crops | 27 | `data/catalog.json` (`crops`) |
| Animal species | 11 | `data/catalog.json` (`animals`) |
| Building definitions | 24 | `data/catalog.json` (`buildings`) |
| Terrain definitions | 10 | `data/catalog.json` (`terrains`) |
| Talents | 25 | `data/catalog.json` (`talents`) |
| Courses | 8 | `data/catalog.json` (`courses`) |
| Villagers/NPCs | 10 | `data/catalog.json` (`npcs`) |
| Base decision scenarios | 29 | `data/decisions.json` |
| Multi-stage event arcs | 6 | `data/event_chains_48.json` |
| Neighbour story chapters | 30 | `data/world_worth_50.json` |
| Professional certifications | 6 | `data/world_worth_50.json` |
| Seasonal festivals | 4 | `data/world_worth_50.json` |
| Explorable regions | 8 | `NativeFarm.REGIONS` |
| Regional project chapters | 24 | `BeyondFarm58.PROJECTS` (8 x 3) |
| Explorer professions | 3 | `BeyondFarm58.PROFESSIONS` |
| Manual save slots | 3 | `NativeFarm.SAVE_SLOT_COUNT` |

### Crops in version 6.0

Almond, apple, aubergine, barley, basil, bean, beetroot, blueberry, carrot, chickpea, cucumber, grape, lavender, lentil, lettuce, maize, oats, olive, potato, pumpkin, raspberry, rice, rye, strawberry, sunflower, tomato and wheat.

### Plot layouts

`open`, `raised`, `orchard` and `paddy` are defined in `scripts/FieldsOpportunity.gd`. Compatibility rules, capacity changes and conversion costs live in the code; not every terrain allows each layout.

### Regions and activities

`village`, `river`, `woods`, `hills`, `marsh`, `orchard`, `lake` and `quarry`. See `NativeFarm.REGIONS`, `LivingCountryside.gd` and `BeyondFarm.gd` for times, costs, available goods, risks, partners and regional projects. Costs and amounts are **fictional gameplay values**, not real-world agricultural benchmarks.

## Data files used at runtime

- `data/catalog.json`: crops, pests, diseases, buildings, animals, goods, talents, NPCs, terrains, courses, starting backgrounds and avatar defaults.
- `data/decisions.json`: choice scenarios and authored choices.
- `data/event_chains_48.json`: linked story arcs and their stages.
- `data/world_worth_50.json`: NPC story chapters, qualifications, festivals and seasonal goals.
- `data/messages_es.json`: translated gameplay feedback for Spanish play.

Two old development-reference JSON files were moved to `docs/history/`; they are **not** required by the runtime.

## Artwork and optional generators

`assets/` holds crops/growth-stage sprites, terrain textures, building/animal/NPC images, icons and audio. `references/living_farm_visual_reference.png` is loaded by `IllustratedFarm.gd` and was retained despite being a large image. Do not remove a sprite merely because it lacks an explicit `preload()`; many art paths are loaded dynamically from catalog IDs.

`tools/` contains optional Python asset generators. They are not startup dependencies; running them may overwrite artwork. Use version control/backups before regeneration. Review source image/licence rights before commercial distribution.
