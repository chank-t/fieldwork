# Fieldwork 5.4 — The Living Countryside

## In scope

- **Compiler regression:** `NativeFarm.gd` originally defined `field: Dictionary` at the start of `_apply()` and later used `for field in Style53.FIELDS` within wardrobe match branches. Those declarations shared an enclosing name scope and could prevent `NativeFarm.gd` from being resolved. 5.4 extracts wardrobe actions to their own methods and changes their iteration variable to `style_key`. It retains the exact validated appearance and outfit behavior.
- **Six scenery sites:** the village square, river ford, forest clearing, hill lookout, bird hide and orchard lane can be visited once per campaign. Sites require travel, cash, energy and one game hour. Discoveries persist in the journal.
- **Six regional activities:** market volunteering, herb gathering, berry walking, hill surveying, birdwatching and orchard fruit workshop. They consume energy and money, take game time, and grant bounded inventory, XP or reputation. Each has a daily cooldown.
- **Ten NPC schedules:** schedules depend on the simulated day and hour; a weekly market day brings villagers into the village. Encounters require physical travel to the appropriate region and cannot be farmed repeatedly on the same day. Existing trust and NPC stories remain intact.
- **Dynamic valley map:** shows nearby villagers with dots and a discovery check-mark for sites already visited.
- **New UI:** `Living Countryside` in the toolbar/sidebar and as a link from the Valley screen. Spanish and English support for new controls, descriptions, and prompts.
- **Protected save migration:** new schema `10`, wire `FW_NATIVE_5_4`, file `fieldwork_native_5_4.json`, manual slots `fieldwork_slots_54`. Imports 5.3 schema `9` and all earlier supported native migrations. Never overwrites a prior version's primary file.

## Scope and trade-offs

The regional activities are fictional gameplay mechanics, not advice about real forage, wildlife or agriculture. The 5.4 expansion adds local encounters and progression but **does not claim** a fully explorable second world with free-roaming indoor town navigation, fishing equipment, or network multiplayer. Travel remains region-based via the current Valley map; the main farm remains a separate walkable 2D view.

## Testing and recovery

Run `python3 tests/qa_54.py` for an offline integrity audit. With Godot 4.4+ installed, run `GODOT=godot ./RUN_NATIVE_TESTS.sh` (Windows: `RUN_NATIVE_TESTS.bat`), which imports and parses the project before running all native gameplay and UI tests. These tests specifically check the NativeFarm preload, wardrobe regression, 5.3→5.4 checksum migration, daily limits, NPC schedules, visited locations and UI wiring. Without the actual Godot engine, a static audit cannot prove there are no parser errors or visual defects.

The 5.3 save is a read-only import source during 5.4 recovery; active changes go to the new 5.4 save path. Players should retain a backup of their 5.3 user-data folder before migrating.
