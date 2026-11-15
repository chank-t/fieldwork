# Implementation notes — Fieldwork 5.3

## Scope

The 5.3 work is deliberately restricted to avatar customization, presentation and save safety. The existing 27-crop catalog, economic model and 5.2 plot mechanics are not modified.

## Parser repair

`World.gd::_draw_field(i, f, owned)` referenced a `dry` boolean after its enclosing `if` block had ended. GDScript declared that variable only inside the block; the later `if dry:` therefore could not resolve it. The dryness calculation is now performed once near the top of `_draw_field` and is available to both furrow shading and the drought marker.

## Appearance contract

`FarmerStyle53.gd` is the sole source for legal appearance fields, option IDs, labels, normalization, unlocks and preset storage. The public fields are:

- `hair`, `skin`, `outfit`, `hair_color`, `pants`, `boots`, `hat`, `accessory`, `facial_hair`, `body`, `eyes`, `pronouns`.
- A 5.2 farmer had the first three fields. On migration, only missing cosmetic keys are filled with defaults. The name, farm name, XP, farming background, location and existing inventory remain unchanged.
- The wardrobe stores three preset Dictionaries with the first 11 fields. Pronouns are not part of outfit presets. Empty Dictionaries represent unused slots.
- Changes go through `farm.act`, which validates option identifiers and unlocks. Raw colors, paths or code cannot be provided as custom values.
- Rewards: `hat=ranger` requires at least one `world50.certifications` entry; `accessory=laurel` requires at least one `world50.festival_history` entry. Those are the existing certified/festival gameplay records, not simulated with UI-only flags.

## Actions

- `setFarmerLook`: accepts a partial/full Dictionary of appearance fields, merges valid selections with current state.
- `saveOutfitPreset`: `slot` zero-based 0–2, optional `look` Dictionary; saves selected appearance without equipping it.
- `applyOutfitPreset`: `slot`; equips the saved appearance without changing pronouns or background.
- `clearOutfitPreset`: `slot`; clears it.

Each action is available through the wardrobe UI and native farm model, and updates the protected 5.3 save via Main's action dispatcher.

## Graphics

The existing procedural portrait (`FarmerPortrait.gd`) was expanded; map character graphics (`World.gd::_draw_player`) and interiors (`Interior.gd::_draw_farmer`) now read the same normalized appearance. They render only and do not mutate simulation state or RNG.

## Save upgrade

Save writes use `FW_NATIVE_5_3` and schema 9. `NativeFarm._upgrade_state` migrates schema 7 via 5.2's migration to schema 8, then migrates schema 8 to 9. Files remain in version-specific `user://` names and three version-specific slots, preserving originals. The previous `NativeFarm._verified_envelope()` did not recognize the 5.2 format; its allowlist now includes 5.2 and 5.3.

## Verification

`tests/qa_53.py` checks source and resources offline. `tests/farmer_style_53_smoke.gd` covers real engine save/load, old-save migration, reward locks, invalid options and outfit transactions. `tests/ui_farmer_53_smoke.gd` covers live native creator/wardrobe rendering and avatar transfer to interiors. Godot binary execution was unavailable during release construction.
