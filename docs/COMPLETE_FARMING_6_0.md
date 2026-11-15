# Fieldwork 6.0 — Complete Farming Experience

## Intended player loop

**Morning:** use Farm Compass to review weather, ripe crops, dry fields, animal care and pending work. **Day:** perform real actions in the existing crop, ecology, animal, construction, valley and market panels. **Evening:** check your seasonal goal, long-term paths, journal and tomorrow's budget. The player can ignore the Compass entirely and play as before.

## Implementation boundaries

`FarmCompass.gd` only reads native simulation state, returns prioritized suggestions and computes six progress indicators. UI buttons jump to existing panels and focus a relevant plot where available. None of these features use random generators, require an account, mutate farms, auto-sell items or bypass existing transaction confirmations.

## Completion paths

- Healthy land: grow to four plots, maintain three healthy plots
- Harvest & trade: 500 kg harvested and 300 kg sold
- Animal welfare: two livestock groups in good condition
- Working farm: three ready buildings, one machine and 100 kg processed
- Valley community: three trusted neighbours and five story chapters
- Valley explorer: five known regions and four regional project chapters

Each pillar uses fractional progress based on its component goals. This is an optional orientation tool, not a new blocking win condition. Current quests and festivals still reward gameplay.

## Quality gates

Run `tests/qa.py`, then run `RUN_NATIVE_TESTS.sh` or `.bat` with Godot installed. Verify full-window UI across desktop and mobile aspect ratios; test nested menu scroll, language changes, quick goals, accessible labels, both map modes and migration of an actual backed-up 5.9 save. A release is not certified until parser, runtime, touch and export checks have been performed in the target engine.
