# Technical architecture

## Runtime flow

```text
project.godot -> Boot.tscn / scripts/Boot.gd
             -> Main.tscn / scripts/Main.gd
                    |-> NativeFarm.gd (state, simulation, actions, saves)
                    |-> World.gd (classic 2D map)
                    |-> IsometricWorld56.gd (2.5D presentation over World)
                    |-> Overworld.gd (valley map)
                    |-> Interior.gd / FarmerPortrait.gd (interiors and avatar)
                    |-> FarmCompass60.gd (read-only derived priorities)
```

The primary application is native GDScript. Assets and authored content are local; no Node.js server or account is needed. The `project.godot` main scene is `Boot.tscn`. The rendering method is Godot's compatibility renderer.

## File groups

| File or directory | Responsibility |
| --- | --- |
| `scripts/Boot.gd` | Language selection, new/continue startup and scene transition |
| `scripts/Main.gd` | Interface construction, screen navigation, user callbacks and dialogs |
| `scripts/NativeFarm.gd` | Authoritative farm `state`, `act()`, `quote()`, save/migration and rules |
| `scripts/NativeData.gd` | Read-only `data/catalog.json` loader |
| `scripts/DecisionContent.gd`, `ChoiceChains.gd` | Authored decisions and follow-up story chains |
| `scripts/FarmingLife49.gd`, `FieldsOpportunity52.gd` | Pure farming, plot and equipment rules |
| `scripts/WorldWorth50.gd`, `LivingCountryside54.gd`, `BeyondFarm58.gd` | Character/community/regional rule definitions |
| `scripts/FarmerStyle53.gd`, `LivingFarm57.gd` | Avatar and decorative placement helpers |
| `scripts/ResponsiveLayout55.gd`, `PerformanceAccessibility59.gd` | Presentation-only display rules |
| `scripts/FarmCompass60.gd` | Read-only, state-derived tasks and progress paths |
| `assets/` | Sprites, terrain, icons and local audio |
| `references/` | One illustrated farm image loaded by `IllustratedFarm.gd` (must remain) |
| `data/` | Gameplay catalogs, events and translations |
| `tests/` | Godot smoke tests and current offline audit |
| `tools/` | Optional sprite generation, not needed to play |

## Simulation and state mutations

`NativeFarm.gd` is the only authoritative gameplay action engine. UI controls call `farm.act(kind, args)` or show a quote/confirmation first. `act()` duplicates the previous state, applies `_apply()`, validates invariants, and restores the original state on failure. Directly mutating `farm.state` in a renderer or panel would bypass those safeguards; avoid doing it.

`FarmCompass60.gd` calculates `summary()`, `pillars()` and `priorities()` using the current state. It is deliberately non-mutating; a Compass button routes to the existing game panel rather than performing a transaction.

The presentation (`World.gd`, `IsometricWorld56.gd`, `Overworld.gd`) reflects stored state but does not own transaction balances. The 2.5D view uses projected geometry over shared world coordinates so it should not require a different save format.

## UI and responsive layout

`Main.gd` chooses between world and management views and exposes screen-specific `_panel_*()` functions. `ResponsiveLayout55.gd` defines phone/tablet/desktop layout bands and logical design sizes. On portrait/mobile, management panels replace the world view instead of compressing it. Touch targets and render presets are configured by `PerformanceAccessibility59.gd`.

## Extending the game safely

1. Define content in `data/catalog.json` or the corresponding data/rules module.
2. Add rule validation and a case to `NativeFarm._apply()` for stateful mechanics.
3. Update `_valid_state()` and migrations **only if** persistent schema actually changes.
4. Connect a UI control or screen to the action; do not make UI shortcuts spend resources by bypassing `act()`.
5. Add Godot smoke tests for positive cases, rejected actions, and save/load.
6. Test both 2D and 2.5D views, small/large screens and both languages.

## Technical debt (not silently refactored)

The project still contains large monolithic scripts (`Main.gd` and `NativeFarm.gd`, each more than 3,000 lines). Splitting them is a recommended **future code change**, but doing so merely for packaging would risk regressing gameplay and save compatibility. This clean edition preserves their original hashes. Engine-run testing is required before calling this a fully validated release.
