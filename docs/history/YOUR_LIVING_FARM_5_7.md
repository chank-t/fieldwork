# Your Living Farm — 5.7 technical design notes

## Garden Studio behavior

- 24 established garden slots, indexed 0–23, are kept exactly where earlier versions rendered them; save objects keep their prior ids, kinds, ready times and slots.
- The map renderer has `show_garden_slots57` and `active_garden_slot57`. Both 2D and isometric input resolve clicks in original world coordinates using inherited `_unat()`; on the isometric renderer, `_unat()` is the exact inverse of the 5.6 affine projection.
- On desktop, the studio and world coexist. On phone, the editor shows a **Pick a position on the map** action and the player chooses a numbered marker, then returns to the studio inspector.
- New placement continues through `craftDecoration` and its original costs, level requirements and timed construction. Relocation is only for completed decorations, to an unused slot.
- Relocation is implemented in `NativeFarm.gd` as an action, not as UI-state mutation. It charges an actual EUR 18 and 4 wildlife/farmer energy, adds 5 crafting XP, and changes only the existing `slot` key. The `act()` invariant checker restores state after invalid actions.

## Machinery yard

- Four machine identifiers are drawn from `life.machines`, not from catalog availability.
- `machine57_*` sprites are original local PNGs with transparent backgrounds. No downloads, network services or commercial asset packs are required.
- A broken machine is tinted differently and marked. Normal equipment has subtle idle highlights, not a claim that water or fuel is being consumed in real time.
- Clicking a machine opens the existing purchase/maintenance screen; all economic transactions stay in the preexisting machine code.

## Work feedback

- Successful field actions call the renderer's `trigger_work_effect57`. It changes only transient presentation variables, not crop data, wallet, inventory, world RNG or saved files.
- The effect is omitted when reduced-motion accessibility is active.

## Known validation limitation

A Godot 4.4+ binary and Android/Windows runtime are not available in this container. Offline audits validate source links, data, assets, versioned paths and a structural invariant checklist. The included native Godot smoke test must run locally to establish actual parser and UI correctness.
