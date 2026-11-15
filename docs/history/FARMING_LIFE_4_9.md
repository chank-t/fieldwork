# Fieldwork 4.9 — The Farming Life / La vida en la granja

## Design target

4.9 follows the supplied roadmap: deepen existing systems **without turning each day into a checklist**. Every new system updates true saved farm data; read-only dashboards or previews do not consume random numbers or resources. Play remains strictly 2D and all earlier choice-driven NPC stories remain playable.

## Persistent data changes

Schema **6** adds `state.life`: `path`, `last_change`, `machines`, `quality_stock`, `vet_visits`, `machine_breakdowns`. Each field adds `soil.organic_matter` (initial 2.8%), `soil.compaction`, `soil.erosion`, `cover_until`, `hedgerow`, `scouted_day` and `scout_report`. Each animal group adds `age_days`, `health`, `nutrition`, `feeding`, `vet_until`, `pregnancy_due`. Farm-wide buildings store a `slot` from 0 to 23; plot-specific buildings store `-1`. Migration upgrades in memory; original 4.8 save remains available as a separate file. Purchased machines and premium stock have validator bounds.

## Soil, crops and scouting

| Action | Base cost | Benefit / restriction |
|---|---:|---|
| Aerate plot / Airear | €54 | Uses 6 farmer energy; reduces compaction by 0.2, or more with a functioning cultivator; cannot airate land not owned |
| Cover crop / Cubierta | €28 | Four simulated days of soil protection; slowly increases organic matter and reduces compaction; delays commercial planting |
| Hedgerow / Seto | €95 | Permanent plot habitat, less rain erosion and more pollinators |
| Scout plot / Inspección | €14 | One fresh exact pest/disease report per plot per game day; old reports are visibly dated |

Crop growth responds to organic quality, terrain, nutrients, water and pests, and a repeated crop family is discouraged by rotation advice. Harvests compute a premium-grade fraction from measured crop condition and soil quality. Only the accepted (stored) portion can become premium. Premium goods sell first with a 28% price bonus; ecological stewardship multiplies that bonus by 1.12. Storage spoilage and consumption reduce premium stock to prevent selling fictional goods.

The three-day weather view is **a probability forecast**, not a peek at future RNG; the actual weather is generated only when time advances. The farm budget reports buildings + machinery fixed costs separately from seeds, labour, water and other variable costs.

## Equipment

| Machine | Purchase | Maintenance/day | Benefit when operational |
|---|---:|---:|---|
| Compact cultivator | €620 | €1.25 | Reduced planting and aeration labour |
| Irrigation pump | €780 | €1.50 | 12% less reservoir water; pumping cost lower |
| Light harvester | €1,150 | €2.30 | Harvest labour lower |
| Feed mixer | €560 | €1.10 | Feed consumption lower; nutrition higher |

Usage reduces condition. Broken/failed machines cease to provide bonuses until the player pays for a service. Maintenance is charged daily; unpaid maintenance accelerates deterioration. These are game-balance parameters, not real agricultural cost estimates.

## Animals and long-term planning

Each animal group records age, condition, health and nutrition. It uses actual stored feed and reservoir water daily, and yields change with these needs. The optional balanced feeding plan costs 10% extra feed but improves nutrition faster. A veterinary visit costs €27 + €8 per animal (10% more for livestock specialists), restores health and provides seven-day protection. Breeding requires at least two healthy animals, reserves one capacity unit, costs €44 and produces one offspring after four days of simulated time. Space is checked across species sharing housing.

## Business paths

- **Independent**: flexible baseline.
- **Crop producer**: +8% harvest, +5% seed expenditure.
- **Livestock keeper**: −12% feed, +9% animal output, +10% veterinary cost.
- **Artisan processor**: +12% processed output, +8% processing charge.
- **Ecological steward**: lower erosion and better premium prices, +8% field-care costs.

First change is free. Further changes cost €240 and require 12 simulated days after the last selection.

## 2D construction

The Buildings screen exposes 24 numbered positions along the north/south margins of the illustrated farmland. New farm-wide construction checks for unoccupied slots and reserves immediately. It draws while underway and persists that placement across saves; plot-specific structures remain anchored to their plots. Relocation of finished farm-wide buildings costs €45 and respects occupied slots. This is layout placement for structures, **not** a freeform drag-and-drop terrain editor.

## Interfaces

The new **Planning** screen shows forecast, soil summary, crop rotation and costs; **Machinery** shows all machines and condition; **Economy** shows all business paths, effects, cooldown rules, premium stock and fixed-cost runway. Existing Fields, Ecology, Animals and Buildings screens have new action buttons and details. UI strings for these screens are bilingual and new model action results have entries in `data/messages_es.json`.

## Acceptance checks / known limits

`tests/farming_life_smoke.gd` targets schema migration, budgets, scouting, cover crops, machinery, livestock, construction, grade sales, and atomic rejection. `tests/ui_life_smoke.gd` targets main navigation, Spanish screens, map construction locations and selection. `tests/qa_49.py` audits version, content, asset links and expected features without claiming Godot execution. Inherited native tests remain in `RUN_NATIVE_TESTS`.

**Known limits:** This release includes a probabilistic forecast, not a meteorological physics model; specialized budgets exclude many variable costs; livestock reproduction is deliberately simplified; native 2D art is stylized, not photorealistic; some inherited technical logs remain English. Godot parsing, actual gameplay and screenshot QA require execution in a real installed engine, which was not available during package authoring.
