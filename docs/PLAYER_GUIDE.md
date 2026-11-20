# Player guide — Fieldwork 3D

## Start a farm

Open the game from Godot or a later exported build. On the launcher select English or Spanish; choose **Create a new farm** or **Continue saved farm**. New-game creation includes a name, farm name, difficulty/background choices and appearance settings. The farmer's saved appearance also drives portraits and the world avatar.

The guided tutorial checks that each requested action is available before advancing. It matures the first crop instantly in the growth lesson; if a harvest is still unavailable, it keeps that lesson open and explains why.

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
| Mouse wheel | Zoom the farm map or adjust first-person field of view |
| Middle-mouse drag | Pan the map or look around in first person |
| Touch drag / pinch | Pan / zoom in the map; look / adjust field of view in first person |
| On-screen arrow buttons | Move the farmer when using the virtual controls |
| First person button | Toggle an optional eye-level view; movement follows the view direction |
| Right-mouse drag / touch drag in first person | Look around |
| Pause, 1x, 4x and 12x* | Control simulated time (*12x is available in the noncompact layout) |
| +1h | Advance one simulated hour |
| Camera | Switch between orthographic and perspective 3D projection |
| Right-mouse drag | Orbit and tilt the 3D camera |
| Escape | Exit first person, leave an interior or close a relevant overlay |

Some gestures depend on whether a UI panel or a map is active. Mobile layouts offer larger touch targets and a bottom navigation route.

## Crops and land

There are **24 land plots**; not all are owned initially. The catalog has **27 crops** and **10 terrain definitions**. A plot can have an open-field, raised-bed, orchard or paddy layout; crop suitability differs by layout/terrain. Three seed varieties are supported by the 5.2 system. Perennials (including orchard/vine crops) persist through harvest cycles.

For crop selection: select a plot, inspect its type/terrain, choose a compatible seed and confirm the proposed action. Costs and consequences are executed by the farm's transaction engine. Dry soil, pests, fertility, compaction and crop development influence production and are represented through map visuals and overlays.

From 80% growth, tap a planted plot and choose **Harvest early** if you need stock for a delivery. Picking early yields 25% less at the current biomass and produces standard grade only. At full ripeness the regular harvest rules apply. The confirmation shows how much fits in storage and any overflow you would lose.

The rotation planner checks up to the last three harvested crop families on that plot. Repeating a family reduces biomass yield, increases N/P/K demand and encourages nematodes; legumes return part of their nitrogen use to the soil. Check the planner before planting to compare these long-term effects.

After harvesting, the report shows produced and stored amounts, overflow, crop condition and the main growth factors. Use its suggested next step to plan the next cycle.

## Animals, buildings and equipment

The catalog includes **11 animal species**, **24 building definitions**, processing recipes and a machinery system. Animal care includes feeding, health interventions, breeding and optional grazing plans. Assign a herd to an owned, empty open field and choose a morning, afternoon or daylight schedule. Each paddock supports one group; grazing can reduce feed use and improve welfare and output, while forage recovers naturally when fields rest. Animals move to their paddock during their scheduled hours, so grazing does not require a daily command. Buildings take time/resources to construct. Machinery purchase, operation wear and servicing can change performance and costs. Garden Studio lets you place or relocate a limited collection of decorations.

## Community and goals

The valley has eight regions and eight three-part regional projects (24 chapters). There are 10 neighbours and 30 neighbour story chapters, six professional certifications and four seasonal festivals. At the start of each season, choose one of three optional objectives by day 3; the choice is locked for that season, and targets and rewards scale with the number of owned fields. There is no penalty for passing, and progress begins when you choose. Some objectives require livestock or a completed workshop. Explorer professions and farm specializations have different bonuses. See the Goals screen for six long-term farm-development tracks: land, harvesting, animals, production, community and exploration.

## Readability and performance

Options include interface scaling (source range 100%-165%), high-contrast modes, colour-independent plot labels, reduced motion, an optional FPS display and Eco/Balanced/Quality graphics modes. These affect presentation; saved farm progress is unchanged.

## Before relying on a long campaign

Use **Save** or one of three manual slots, keep an external backup of Godot `user://`, and verify that an exported build runs on your target PC or phone.

## Planning work and sales

- After your first crop sale in Story mode, Inés asks for lettuce and the forecast announces two hot, dry days. Take the order and plan seeds and irrigation around its deadline, or decline it and sell independently.
- Tap a growing plot and choose **Outlook** to see estimated time to maturity, tomorrow’s weather and factors limiting yield. In **Fields** or **Ecology**, mark a visible pest problem to review the following day, treat it, or harvest early if the crop is far enough along.
- Use **Work several fields** in Fields or Planning to select plots to irrigate or harvest. The confirmation shows the combined costs, water use and storage losses. A working cultivator adds batch sowing. A working pump enables a saved daily moisture target per plot.
- Check the seasonal calendar in **Festivals**. The seasonal order is announced at the start of each season, with deliveries open on days 9–12. Urgent orders have short deadlines, and premium orders require a minimum quantity of premium stock. Specialize in cereals, market gardening or livestock to see different opportunities and operating costs.
- Complete the village mill or Silver River channel in **Regional expeditions**. The reopened mill processes wheat for a fee. The restored channel captures more rain and reduces reservoir use. Both appear on the valley map.
- Use **Finish day and save** in Planning to go to the next morning and see the balance. Pending village decisions pause the advance. The latest balance and follow-up tasks are available when you resume.
