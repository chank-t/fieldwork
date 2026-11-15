# Fieldwork 4.5 release verification

## Checks executed in the authoring container

| Check | Outcome | What this proves |
| --- | --- | --- |
| `python3 tests/static_audit.py` | 133/133 passed | Original static source/catalog checks |
| `python3 tests/scenic_world_audit.py` | 180/180 passed | 2D world assets, references and static scenic rules |
| `python3 tests/qa_45.py` | 64/64 passed | New bilingual event catalog, code references, expected UI routes, versioned schema, save migration source paths |
| Source archive checksum and clean extraction | See `evidence/RELEASE_VERIFICATION_4_5.json` | Delivered ZIP contains files that were actually checked |

These are source, asset, and content checks **only**. They do not prove an actual Godot parser invocation, working scene, visual alignment, or executing gameplay.

## Engine-level tests shipped but NOT executed in this environment

1. `godot --headless --path . --editor --quit`
2. `godot --headless --path . --script res://tests/native_smoke.gd`
3. `godot --headless --path . --script res://tests/layout_smoke.gd`
4. `godot --headless --path . --script res://tests/decision_45_smoke.gd`
5. `godot --headless --path . --script res://tests/ui_45_smoke.gd`

**BLOCKER:** The Godot 4 executable is not installed here and external package download is unavailable. The project is an editable native GDScript build candidate, **not a runtime-verified release**. Test on an actual Godot 4.4+ editor before distribution.

## Visual and gameplay review required on a real Godot editor

- Test English/Spanish on the very first Boot scene. Open the character creator and inspect hair, skin, outfit, mode, world-seed input and Start button, especially at 1280x720.
- Start a new campaign, walk with WASD, zoom and pan the 24-plot map; open full-screen Scenic view and illustrated courtyard. The courtyard is static art with interactive hot spots.
- Navigate all 15 tabs with the grouped sidebar and World guide. In narrow windows, check the scrollable horizontal sidebar and the 24-field dropdown.
- Advance until the event board opens; inspect all 3 option cards, long Spanish labels, quoted costs, disabled choices, and event effects.
- Save with a timed effect, quit and continue, confirm it remains and expires on simulated time. Import a legacy native 4.3 save only after making a backup.
- Verify building interiors, neighbours, animals, markets, courses, talents, menus and photo export. Check debug error output.

The simplified ecology, weather and wildlife risk parameters are fictional game mechanics, not real agricultural, veterinary or medical advice.
