# Fieldwork Native 4.3 — Readable Valley

## Release type and compatibility

This is an editable, independent **Godot 4.4+ GDScript** project. It does not require Node.js, an account, a web browser, or a network connection. It is an incremental update to Native 4.2, **not** a replacement for the much larger Fieldwork web simulator. Its ecology and economics are game assumptions, not real agronomic or animal-care advice.

## Fixes for invisible/clipped selection fields

The Godot `OptionButton` controls used in character creation and plot management are now consistently themed. They use opaque warm-white backgrounds, dark font colors (including hover and pressed states), a visible custom dropdown arrow, a minimum height of 52 UI pixels, `fit_to_longest_item=false`, clipped text, and a capped scrollable `PopupMenu` (`Window.max_size`). The large 24-plot picker no longer asks Godot to enlarge its entire parent panel to the width of the longest item. The skin tone names now match their ordered source palette.

The world now draws legible, zoom-aware numbered plot badges in pixel-space, with ownership text only when the available width can accommodate it. There is also a selected-plot label **outside** the map, so it remains legible at small zoom levels and in poor weather. The selected badge is redrawn over the night/weather effect. World pan, zoom, click, and selection stay interactive.

## Resources and garden content

Six new inventory goods bring the authored goods catalog to **35**: timber, stone, clay, wildflower bundles, reeds, and finished compost. The native starting inventory includes 3 kg timber and 2 kg stone in addition to feed. All materials count toward finite storage and may be sold at the existing market.

| Place | Gathered material | Default amount | Cash cost | Game hours | Energy cost |
|---|---|---:|---:|---:|---:|
| Woods | Timber | 9 kg | EUR 6 | 3 | 13 |
| Hills | Stone | 11 kg | EUR 7 | 4 | 16 |
| River | Clay | 8 kg | EUR 5 | 3 | 12 |
| Orchard | Wildflowers | 5 kg | EUR 4 | 2 | 9 |
| Marsh | Reeds | 8 kg | EUR 5 | 3 | 15 |

A site can be gathered only once per simulation day. Gathering costs money, energy, hours, and storage; ecology and random events may advance during the hours. Exploration mastery offers a bounded up-to-12% yield improvement.

New `makeCompost` (8 kg manure + 2 kg wildflowers + EUR 7 -> 7 kg compost), and `spreadCompost` (5 kg compost + EUR 3 labor -> added retained N/P/K organic reserves on an owned field) turn farm inventory into a longer-term choice. The older cash-funded `compost` treatment remains unchanged.

| Decoration | Materials | Labor fee | Build duration | Farmer level |
|---|---|---:|---:|---:|
| Woodland bench | 5 timber + 2 stone | EUR 15 | 8 h | 1 |
| Flower arch | 3 timber + 4 wildflowers | EUR 12 | 10 h | 2 |
| Birdhouse | 3 timber + 2 reeds | EUR 9 | 6 h | 2 |
| Lantern | 2 timber + 2 stone + 1 clay | EUR 20 | 12 h | 3 |
| Stepping stones | 6 stone + 2 clay | EUR 8 | 7 h | 1 |

The garden has 24 fixed, non-overlapping decoration slots. Decorations have construction timers, are stored and validated in the save, and are rendered and selectable on the farm. Decorations currently provide **visual customization**, not undocumented biological bonuses.

## Character progression

The original **220 XP per farmer level** and **one permanent talent point per farmer level** remain. The game now exposes the experience progress bar in the UI, awards a level-up log entry, and records seven native mastery tracks: farming, ecology, livestock, crafting, trading, exploration, and community. Each track starts at level 1 and increases by one every 140 track XP, gained by real actions. Some masteries provide a bounded 2% per-level efficiency bonus, up to 12%, in their related systems (harvest recovery, livestock output, construction, sales, or gathering).

Inspecting a field remains unlimited for education and observation, but awards XP **only once per field per game day**. Additional resource and garden quests and two new tutorial lessons encourage learning the loop.

## World and visual changes

- Native landscape and character-creation screens now use the illustrated valley background.
- Animal yard and construction area are separated from the 24 fields to reduce overlapping sprites.
- Animal groups can be selected on the map, opening their management screen.
- The game includes 16 original illustrated material/progression icons, 5 illustrated decoration icons, and a custom dropdown arrow.
- Plot number labels and crop progress strips scale with the actual available pixel area.
- Hover and selected outlines improve recognition without consuming simulation RNG.
- Animals, constructions, material stockpiles, and decorations are shown in the farm world, where relevant to the current state.

## Save schema

The save envelope is now `FW_NATIVE_4_3`, inner schema `3`. The existing `user://fieldwork_native_4_1.json` save path is retained deliberately. The loader continues to accept checksummed `FW_NATIVE_4_1` (schema 1) and `FW_NATIVE_4_2` (schema 2) files, upgrading them to the new schema before validation. The new `progression`, `decorations`, and `resources` roots, as well as per-plot inspection dates and new statistics, serialize with the farm. The game does not claim compatibility with Fieldwork's web-only save files.

## Validation and reproducibility

The static audit, independent plot-geometry checks, asset inspection, and ZIP extraction/build checks are **available and executed**. Engine-level editor import, GDScript compilation, rendered UI validation, and gameplay smoke tests have **not been executed** in the authoring container because no Godot 4 executable is installed and the network is unavailable. The provided runnable Godot tests are `tests/native_smoke.gd` and `tests/layout_smoke.gd`.

The `tests/visual_layout_preview.py` illustrations are layout projections composed from actual shipped sprites; **they are not Godot runtime screenshots**. See `docs/QA_4_3.md`.
