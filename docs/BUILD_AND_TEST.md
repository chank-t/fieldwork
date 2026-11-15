# Build, test and release guide

## Editor setup

1. Install **Godot 4.4 or newer** for your operating system.
2. Extract the ZIP and point Godot **Import** to the root `project.godot`.
3. Allow Godot to import PNG/audio resources, then open the main scene or press **F5**.
4. Do not copy only `.tscn` files: keep `assets/`, `data/`, `scripts/` and `references/` together.

The project uses the Godot Compatibility renderer. There is no Node.js dependency and no network service is required for gameplay.

## Offline source verification (Python 3)

```sh
python3 tests/qa.py
```

This performs resource-path checks, source-shape checks, JSON and PNG validation, preserved-art hash comparison and documentation/test presence checks. It does **not** compile GDScript, render scenes or validate input/device behavior. The audit produces `tests/QA_RESULT.json` when run; that generated file is intentionally absent from the clean distribution.

## Real Godot checks

With a Godot executable available:

```sh
GODOT=/path/to/godot ./RUN_NATIVE_TESTS.sh
```

Windows:

```bat
set GODOT=C:\Path\To\Godot_v4.4-stable_win64.exe
RUN_NATIVE_TESTS.bat
```

Each runner first opens the project headlessly in editor mode to load/import assets, then executes the native smoke scripts from `tests/`, including `complete_experience_smoke.gd`. **Check exit codes and the Godot output**, since source-only Python checks cannot catch all GDScript parser errors.

## Manual layout and interaction matrix

| Target | Resolution example | What to check |
| --- | --- | --- |
| Small PC | 1366 x 768 | HUD, map, inspector, no giant unused side areas |
| Standard PC | 1920 x 1080 | Full-window scaling, keyboard and mouse |
| Large PC | 2560 x 1440 | UI scaling, map quality and readable controls |
| Phone portrait | 390 x 844 | Bottom navigation, tap targets, map vs panel switching |
| Phone landscape | 844 x 390 | Controls remain reachable with limited height |
| Tablet portrait | 820 x 1180 | Safe panel spacing, scrolling and dialogue |

Repeat at least one screen test in **English and Spanish**, with both **2D and 2.5D** maps, Eco and Quality presets, and reduced-motion enabled. Test drag/pinch on actual devices, not only an editor-sized window.

## Exporting to desktop and mobile

This ZIP is **source**, not a precompiled executable. Install official Godot export templates before making Windows/Linux/macOS exports. An Android build additionally requires the configured Android SDK/JDK and export preset; publishing to iOS requires the appropriate Apple toolchain. No `export_presets.cfg` or signed app bundle is included here. Do not claim mobile export compatibility until an Android/iOS build has been tested on its target device.

## Release gate

- Engine parser reports no errors and both `Boot.tscn` and `Main.tscn` load.
- New game, continue, save slots, recovery, purchase, harvest and construction transactions pass.
- A rejected transaction leaves money, inventory, crop state and RNG unchanged.
- Both map views select the correct plots, buildings, NPCs and animals.
- Window resizing and mobile UI scrolling do not hide critical actions.
- No untranslated blocking messages or unreadable contrast in supported languages.
- A clean export runs on each intended delivery platform.

**Current status:** offline checks have passed; Godot engine execution and exported-build tests have **not** been performed in the packaging environment.
