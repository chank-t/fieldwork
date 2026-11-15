# Player guide — Fieldwork 3D

## Start a farm

Open the game from Godot or a later exported build. On the launcher select English or Spanish; choose **Create a new farm** or **Continue saved farm**. New-game creation includes a name, farm name, difficulty/background choices and appearance settings. The farmer's saved appearance also drives portraits and the world avatar.

## Everyday loop

1. **Inspect:** visit Farm or **Goals / Farm Compass** for ready harvests, dry fields, pests, animal care and useful follow-up screens.
2. **Prepare:** open Fields, choose an owned plot, inspect soil and compare compatible crops and seed varieties.
3. **Work:** plant, water, maintain soil, scout pests and harvest when ripe. Actions may consume money, energy, goods and time.
4. **Develop:** sell or process produce, expand land, keep animals, build structures, service equipment and improve skills.
5. **Connect:** explore the valley, help neighbours, complete regional projects and enter seasonal festivals.
6. **Plan:** review the weather, budgets, journal and goals before advancing the clock.

The Compass is advisory. Its buttons open related screens; it does not automatically spend resources or award progress.

## Main screens

| Area | Screen names in source | Use |
| --- | --- | --- |
| Farm | Farm, Compass60, Fields, Ecology, Planning | Field status, priorities, planting, soil and task planning |
| Production | Machinery, Buildings, Animals, Processing, Resources, GardenStudio57 | Equipment, construction, animal care, recipes, inventory, decorations |
| Trade | Market, Economy | Sell harvests, supplies and economic strategy |
| Countryside | Valley, Countryside54, Expeditions58, Explorer | Travel, discoveries, local activities and regional projects |
| Community | Neighbours, Stories, Community50, Festivals50, Certifications50 | Relationships, chapter stories, festivals and qualifications |
| Farmer | Character, Wardrobe53, Journal, Story, Options | Talents, training, appearance, activity log and settings |

The full set of screens is accessible through **All screens**; on narrow/mobile layouts the map and management controls occupy separate views instead of being forced side-by-side.

## Controls

| Input | Behaviour |
| --- | --- |
| W/A/S/D or arrow keys | Move the farmer on the live 3D farm |
| Left-click / tap a plot | Select it and open its appropriate information or actions |
| Mouse wheel | Zoom the farm map |
| Middle-mouse drag | Pan the farm camera |
| Touch drag / pinch | Pan / zoom in the 3D farm view |
| On-screen arrow buttons | Move the farmer when using the virtual controls |
| Pause, 1x, 4x and 12x* | Control simulated time (*12x is available in the noncompact layout) |
| +1h | Advance one simulated hour |
| Camera | Switch between orthographic and perspective 3D projection |
| Right-mouse drag | Orbit and tilt the 3D camera |
| Escape | Leave an interior or close a relevant overlay |

Some gestures depend on whether a UI panel or a map is active. Mobile layouts offer larger touch targets and a bottom navigation route.

## Crops and land

There are **24 land plots**; not all are owned initially. The catalog has **27 crops** and **10 terrain definitions**. A plot can have an open-field, raised-bed, orchard or paddy layout; crop suitability differs by layout/terrain. Three seed varieties are supported by the 5.2 system. Perennials (including orchard/vine crops) persist through harvest cycles.

For crop selection: select a plot, inspect its type/terrain, choose a compatible seed and confirm the proposed action. Costs and consequences are executed by the farm's transaction engine. Dry soil, pests, fertility, compaction and crop development influence production and are represented through map visuals and overlays.

## Animals, buildings and equipment

The catalog includes **11 animal species**, **24 building definitions**, processing recipes and a machinery system. Animal care includes feeding, health interventions and breeding rules. Buildings take time/resources to construct. Machinery purchase, operation wear and servicing can change performance and costs. Garden Studio lets you place or relocate a limited collection of decorations.

## Community and goals

The valley has eight regions and eight three-part regional projects (24 chapters). There are 10 neighbours and 30 neighbour story chapters, six professional certifications and four seasonal festivals. Explorer professions and farm specializations have different bonuses. See the Goals screen for six long-term farm-development tracks: land, harvesting, animals, production, community and exploration.

## Readability and performance

Options include interface scaling (source range 100%-165%), high-contrast modes, colour-independent plot labels, reduced motion, an optional FPS display and Eco/Balanced/Quality graphics modes. These affect presentation; saved farm progress is unchanged.

## Before relying on a long campaign

Use **Save** or one of three manual slots, keep an external backup of Godot `user://`, and verify that an exported build runs on your target PC or phone.
