# Current limitations and recommended maintenance

These points are grounded in the source structure and the release's actual validation status.

## Verified cleanup scope

- Runtime `.gd` scripts, scene files, all original sprites/audio and the referenced illustrated farm image are unchanged.
- Historical screenshots/audit output were removed from the player distribution.
- Older feature documentation is archived in `docs/history/`; current docs are gathered at the top level.
- The current Python QA script and **all** original Godot smoke tests remain present.
- No save schema, crop balance, gameplay rules, input bindings or camera geometry were deliberately changed in this cleanup.

## Still requiring attention

1. **Actual Godot runtime verification.** A static check cannot prove that every GDScript parses. Install Godot and execute the native smoke runner before release.
2. **Large scripts.** `Main.gd` is more than 3,000 lines and `NativeFarm.gd` is more than 3,000 lines. Refactor into focused scenes/services only with regression tests running.
3. **Visual/device testing.** Responsive branches exist, but real desktop, tablet and phone screenshots and touch tests are still required.
4. **2.5D presentation.** Current implementation is isometric-style 2D drawing, not 3D geometry. Further art direction, occlusion sorting and animation polish are separate work.
5. **Release exports.** No Windows installer, Android APK/AAB, or iOS app is built as part of this project cleanup.
6. **Licensing and attribution.** Existing artwork and source licences must be reviewed before publishing or selling the game. None are inferred here.
7. **Balance and tutorials.** Content is substantial; full-season playtesting, economy pacing, and translation QA remain important.

## Sensible next coding sequence

- Run/fix the actual Godot parser and native tests; capture a reproducible runtime baseline.
- Extract screen and presentation components from `Main.gd` without changing navigation behavior.
- Extract domain-specific transaction services from `NativeFarm.gd` without changing public `act()` behavior or the save schema.
- Add screenshot/regression checks for 1366x768, 1920x1080 and mobile portrait/landscape.
- Revisit art production, 2.5D consistency and mobile input after stability is established.

Do not treat offline QA totals as runtime certification.
