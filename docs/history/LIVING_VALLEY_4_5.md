# Living Valley 4.5 — native interface and decision contracts

## What actually changed

The original 4.4 2D simulation and illustrated farm remain the base. The 4.5 work adds one discoverable navigation path to every major screen, a language selector on the first Boot screen, and the `decisions` schema root for time-limited outcomes. It does **not** create a new 3D engine, change existing crop/animal content counts, or deploy networking.

| Route | Player-facing behavior |
|---|---|
| Explore → Farm | Current field, basic resources, farmer XP and active decision consequences |
| Explore → World guide | Jump to any owned field, enter completed buildings, visit the market and farmhouse, inspect animals and neighbours, select valley destinations, and locate every management screen |
| Explore → Fields | Scrollable 24-field selection; click field in live map; zoom/focus; planting, irrigation, harvest, control options |
| Explore → Valley | Six interactive destinations, travelling and gathering costs, equipment, wildlife encounters |
| Manage | Soil & pests, supplies and decoration, construction, animals, processing, market, offers and contracts |
| Community | Ten neighbours, training, 25 talents, story/tutorial, quests, journal, settings, save/import/export |
| Full-screen Scenic view | Same state-driven live 2D map, with controls and clickable objects |
| Illustrated courtyard | Artistic interactive overlay; hot-spots open real native panels; painting itself remains static |

The interface supports English and Spanish. The preference `user://fieldwork_settings.cfg` is intentionally outside the farm state; changing language never consumes farm resources, simulation time or RNG. Spanish coverage includes the start/character interface, central navigation, dynamic weather and seasons, neighbour advice, all 29 events/87 options, and 174 common action-status/error messages. Some inherited journal logs and technical error details remain English and are not claimed as fully translated.

## Event model

**29** event IDs live in `data/decisions.json`. **19** are preserved and localized; **10** are new. Every event has three options, a reason to consider it, an immediate-effect explanation, a drawback/risk explanation, and a stable choice ID. A choice enters through `NativeFarm.act("eventChoice", {"choice":ID})` and is validated atomically. The UI uses `quote` for the actual cash delta; costs are not fabricated in presentation.

| New event | Example lasting or immediate trade-off |
|---|---|
| Soil research | Pay for soil N/P improvements and temporary nutrient retention, or buy organic reserves, or conserve cash |
| Irrigation cooperative | Pay €95 for 14 days of reduced evaporation or buy water immediately; declining costs reputation |
| Cold storage | Rent 12 days of reduced spoilage, sell perishable stock immediately, or hold inventory without protection |
| Livestock inspection | Improve welfare for eight days, buy feed, or accept condition loss |
| Machinery breakdown | Expensive repair grants labor savings; borrowing costs reputation; waiting raises labor costs for five days |
| Pest hotspot | Specialist inspection lowers pests and slows growth; spraying harms beneficial organisms; ignoring increases pests |
| Pollinator council | Plant flower corridors for ten days of better bee activity, donate flowers, or save resources |
| Soil hardpan | Pay for aeration, spread available compost, or risk reduced field moisture |
| Farm open day | Pay for reputation and ten days of market trust, teach a workshop for XP, or decline visitors |
| Wildfire smoke | Pay for temporary moisture conservation, support village with cash and energy, or accept crop losses |

Temporal modifiers are stored at `state.decisions.effects[id]={amount,until}` and expire according to **simulated hours**, never wall time. They affect actual water, nutrient, pest, animal, market, spoilage, and labor calculations. Repeated modifiers retain the stronger nonnegative effect and the later expiry rather than stack indefinitely. Every choice is recorded at `state.decisions.history` (last 100) with event ID, choice ID, hour, cash delta, water delta and reputation delta. The native quote remains read-only and a failed action must not change inventory, resources, time, or RNG.

## Save migration

- Native 4.1 schema 1 → native 4.2 schema 2 → native 4.3 schema 3 → native 4.5 schema 4.
- Native 4.2 schema 2 → schema 3 → schema 4.
- Native 4.3 schema 3 → schema 4.
- Native 4.5 schema 4 remains unchanged.

The previous native save path remains physically intact on migration. Unknown future versions and invalid checksums are rejected. Web saves are not compatible with native 4.5.

## QA requirements

Run the Python source/content audits, then run all four actual Godot tests in `RUN_NATIVE_TESTS.sh`. Manually inspect the first Boot/seed selectors, the complete responsive interface and decision overlays at desktop/tablet/narrow-window dimensions. In this development environment **Godot was unavailable**; engine parsing, actual rendering, physical device behavior and visual screenshots are not verified.

The simulated pest, climate, nutrient, veterinary and wildlife consequences are simplified game parameters, not real agricultural or medical advice.
