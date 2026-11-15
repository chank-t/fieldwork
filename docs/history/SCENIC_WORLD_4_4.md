# Fieldwork Native 4.4 — Scenic world implementation

**Scope:** A presentation-only revision of Fieldwork Native 4.3. It does not change the farming model, the catalogue, plot IDs, save format, movement boundaries, plot hitboxes, or any game actions. The Godot project remains native GDScript and offline.

## What you will see in the game

| Element | Implemented in Godot | Live source |
|---|---|---|
| Rolling meadow and ground detail | `World._paint_meadow` uses seasonal palettes and stable asset tiling | Farm season |
| Riverbank, moving shimmer, reeds, stone edge and bridge | `World._paint_river` | Rendering clock (never gameplay RNG) |
| Earth paths, borders and cobble details | `World._paint_paths` | Deterministic fixed placement |
| Trees, blossom accents and hedgerows | `World._paint_trees` | Season + authored locations |
| Crop rows and plant movement | `World._draw_field` reuses each actual crop sprite and development | Each field's crop and growth state |
| Soil moisture and pest indicators | Baked into each owned plot visual | Soil water, field pests and mulch |
| Field borders, plot badges and progress | Keeps 24 existing plot hit regions | Ownership, growth and selection |
| Farmhouse, market and buildings | `World._paint_village` and actual buildings in state | Construction level / progress |
| Animals and paddock | `World._paint_pasture`; the animal drawing loop | Actual animal groups |
| Workers and other characters | Authored NPC schedule positions and actual player appearance | World schedule / avatar settings |
| Wildlife, rain and night | Weather, clock, bee densities and visual animation time | Actual weather/hour/beneficial state |
| Full-screen Scenic view | `Main._show_panorama`, backed by another instance of `World.gd` | The **same live farm** |

All crops and animals are **actually placed and updated from farm state**. The previous illustration is included at `references/living_farm_visual_reference.png` as an **optional clickable scenic courtyard**. It is explicitly labelled as an illustration and is **not substituted for the live interactive farm**. The live world is still a 2D illustrated scene, not a 3D recreation of the reference illustration.

## Controls

From the farm, press **Scenic view** (also available in the Farm panel). You can then use WASD/arrows to walk, mouse wheel to zoom, middle mouse drag to pan, and click a field, farmer, animal, or building to jump to its existing management/visit action. Zoom/reset and photo buttons are provided.

## Editor files

- `scripts/World.gd`: Native renderer and existing click/gameplay signal boundaries.
- `scripts/Main.gd`: Full-screen live panorama, illustrated courtyard, and navigation.
- `scripts/IllustratedFarm.gd`: Optional clickable illustration hotspots; its art is not game-state-dependent.
- `assets/`: Existing shipped textures reused as live art.
- `references/living_farm_visual_reference.png`: User-established art direction, also shown as a texture in the optional illustrated courtyard only.
- `tests/scenic_world_audit.py`: Static source, asset, geometry, and nondeterminism checks.
- `tests/scenic_world_preview.py`: Asset-composition preview, **not** a Godot screenshot.

## Compatibility / determinism

The native save is still schema 3 (`FW_NATIVE_4_3`). `NativeFarm.gd`, `NativeData.gd`, and the content catalog were not edited. The renderer does not call the game PRNG or run actions. Animation uses only presentation-local elapsed time. No Internet, Node.js, or JavaScript is required.

## Performance and test limits

`World.gd` caps ambient redraws to roughly 15 FPS, while interactions and map camera changes redraw immediately. This is a pragmatic resource mitigation, not a guaranteed device benchmark.

The Python checks validate source, art files, and world geometry. **The Godot editor/runtime, native smoke tests, interactive screenshots, physical Android, and performance on a real device are NOT VERIFIED** because the Godot executable is unavailable in the authoring environment. Open the project in Godot 4.4+, run F5, and verify this checklist on your own machine:

- [ ] Main title/creator screen and world-seed selector fit at 1280×720 and 1920×1080.
- [ ] New farm opens with one owned field and no parser errors.
- [ ] Select field #1, plant a crop and inspect its growth sprite.
- [ ] Buy a second plot; verify selection and ownership colours.
- [ ] Construct a building and confirm it appears only when construction starts.
- [ ] Buy an animal after completing housing and verify it appears in the pasture.
- [ ] Open Scenic view, zoom/pan, click a plot and visit farmhouse/market.
- [ ] Advance simulated hours to nighttime and rain.
- [ ] Save and reload the game without any loss of state.

### Test commands

```bash
python3 tests/static_audit.py
python3 tests/scenic_world_audit.py
python3 tests/scenic_world_preview.py
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/native_smoke.gd
godot --headless --path . --script res://tests/layout_smoke.gd
```

**Educational simulation:** The farm models and fictional environmental hazards are gameplay mechanics, not agricultural, veterinary or wildlife advice.
