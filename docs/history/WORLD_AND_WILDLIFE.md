# World, inhabitants and wildlife — 4.2 design and implementation

## Two connected illustrated spaces

The **farm world** (`scripts/World.gd`) draws a 6×4 field grid, timed buildings, crops, animals, neighbours, the character, paths, river, weather and day/night tint. WASD/touch/click moves and mouse wheel/middle drag control the camera. A click on one of the 24 fields selects it in the native farming panel. Render animation consumes **no** farm RNG.

The **valley map** (`scripts/Overworld.gd`) depicts the village, river, woods, hills, marsh and orchard. Each region has authored travel hours, expense, foraged good, and an encounter probability in `NativeFarm.REGIONS`. Selecting a region is read-only; **confirming travel** applies `act("explore",{"regionId":...})` and actually consumes energy/money and advances some game hours.

## Land and growth

The 24 plots use ten authored terrain IDs. Rain capture and evaporation are affected by terrain coefficients; some types additionally change starting root-zone capacity, while temperatures, pest habitat and pollination vary. Crop growth is hourly and harvestable only after maturity. Native rules are **not** a one-to-one port of the web simulation.

## People and animals

Ten scheduled farmers appear using distinct PNG sprites: Inés, Mateo, Rosa, Bruno, Lila, Clara, Elena, Paco, Omar and Sofia. Conversation topics show current simulated weather, soil water, pest populations, market prices, region information and village favor scores. Helping a neighbour costs game money, adds reputation and is limited to once per NPC per 24 game hours.

Eleven animal types require completed compatible buildings. The native housing calculation uses normalized shares: `sum(count/species.capacityPerLevel) <= completedBuildingLevel`, so hens, geese and turkeys cannot each occupy the entire coop independently. Animals consume water/feed, have welfare values and produce goods at daily model updates.

## Wildlife and venom mechanic

The marsh, forest and river have different **fictional** encounter rates. An owned field kit, lookout and a wildlife-watcher talent reduce an encounter's game probability. An encounter applies an abstract `venom_hours` labor penalty (up to recovery) and records an observation. This is **not a realistic venom model** and provides no wildlife, medical or animal-care instructions. Recovery happens by elapsed game hours/rest and supported fictional farm buildings. The game does not contain antidote recipes, treatment advice or real-world survival guidance.

## Event decisions

19 seeded scenario categories offer three alternatives. Four new categories: soil erosion, pollinator migration, market shortage and wetland rescue. Every effect uses `act("eventChoice")`, and failed choices roll back the entire mutable state including RNG and ledger; the event remains pending. Event rendering and previews do not alter the RNG sequence.

## Exploration limits

The farm supports illustrated walking and clickable buildings/interiors. The overworld is **a map with explicit travel actions**, not seamless cross-country walking or a physical simulation of hundreds of autonomous farms. NPC relationships are authored and favor-based, not emergent dialogue generation. These distinctions are deliberate performance/production scope boundaries and appear in `FEATURE_PARITY.md`.
