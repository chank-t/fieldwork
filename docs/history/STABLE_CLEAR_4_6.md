# UI and save contract — Fieldwork 4.6

## Layout

Band 2 (`width >= 1340`): sidebar navigation, live map and management inspector. Band 1 (`900 <= width < 1340`): scrollable top navigation; map and inspector remain side-by-side. Band 0 (`width < 900`): scrollable top navigation plus vertically stacked live map and inspector. Switching bands rebuilds presentation but must preserve the farm state and selected plot.

The live map keeps all 24 plots. The six field filters derive from real simulation state; they do not mutate gameplay. Alerts are observational, not prediction algorithms. The UI text scale and contrast settings are stored in `user://fieldwork_settings.cfg`, not the farm save.

## Save compatibility

The current filename is `user://fieldwork_native_4_5.json`; format `FW_NATIVE_4_5`, schema 4. This decision maintains compatibility with existing 4.5 campaigns. The new slot directory is `user://fieldwork_slots/slot_N.json`, `N=1..3`.

- `.tmp`: staged candidate for verification.
- `.bak`: previous verified version.
- `.bak2`: second previous verified version.
- `.corrupt`: preserved damaged bytes when replacing an invalid primary.

A save is not written if its JSON envelope/checksum fails validation. A prior valid file must be backed up before replacement. On load, first valid file in `[primary, backup1, backup2, legacy]` is accepted; other files are not silently merged.

**Potential filesystem boundary:** `DirAccess.rename_absolute` may fail to overwrite an existing file on Windows. The code falls back to a copy after verification and backup; crash-atomicity of that fallback requires OS-specific testing. No cloud sync is implied.

## Quality gates

1. Run Godot 4.4+ headless editor parse.
2. Run `tests/save_smoke.gd` and `tests/ui_save_smoke.gd`, alongside prior test suite.
3. Verify original existing saves load without modifying gameplay.
4. Test corrupt primary, valid backup, invalid slot, overwriting a manual slot, and recovery after an interrupted write.
5. Inspect actual Godot screenshots at all requested widths. Check long Spanish labels and event cards, file dialogs and creator seed input.
6. Confirm accepted actions and rejected actions preserve conserved state, money and RNG contracts.

The engine executable is not present in the build environment, so gates 1–6 are **still pending in-engine validation**.
