# Fieldwork 6.0 - Clean & Documented Edition

## Cleanup (maintenance packaging)

- Consolidated player, architecture, content, save/migration and development documentation.
- Archived earlier feature guides and non-runtime historical parameter data under `docs/history/`.
- Excluded historical audit output and obsolete version-specific Python QA scripts.
- Kept the current 6.0 Python audit, all native Godot smoke tests, ready-to-use game assets and the optional sprite generator tools.
- Verified that the game scripts, runtime art, referenced illustration and scenes have unchanged SHA-256 hashes.
- No 6.1 feature changes, no altered saves and no gameplay-balance changes.

## Original 6.0 feature

Farm Compass provides state-derived suggested tasks, progress in six farm-development areas and jump buttons into the existing game screens. Version-specific detail: `docs/COMPLETE_FARMING_6_0.md`.

**Testing status:** static/offline verification only; Godot parser, full runtime and export verification pending.
