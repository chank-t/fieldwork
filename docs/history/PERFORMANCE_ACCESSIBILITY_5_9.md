# Fieldwork 5.9 - Implementation notes

## 1. Rendering presets

| Preset | Decorative redraw cadence | Weather | Ground detail |
| --- | --- | --- | --- |
| Eco | Every 125 ms | 40% rain particles | Every other terrain decoration tile |
| Balanced | Every 66 ms | Full | Full |
| Quality | Every 40 ms | Full | Full |
| Reduced motion | Every 750 ms | Mostly static | As selected |

These are *view invalidation cadences*, not guaranteed measured FPS. State changes, zoom and input can request immediate redraw. Rendering never mutates `NativeFarm.state`.

## 2. Accessibility

High-contrast controls, 100%-165% UI scaling, numeric map overlays, reduced motion, field-condition labels and optional FPS are saved in `user://fieldwork_settings.cfg`. Numeric overlays work with color independent metrics in 2D and 2.5D.

No screen-reader integration is claimed. Godot GUI accessibility and Android export need real-device verification.

## 3. Mobile interaction

- Existing movement buttons issue a single step when tapped; pressing and holding drives `World.touchscreen_dir` until release.
- One-finger drag adjusts the visual camera, subject to pan clamp.
- Two fingers adjust `zoom_target` through distance changes; plot and transaction coordinates use the unchanged inverse projection.
- Touch input never changes crop state except via the existing user-initiated gameplay actions.

## 4. Safety checks

- 5.8 primary save and slot paths are read-only sources. 5.9 writes only to its own targets.
- Existing `FW_NATIVE_5_4` envelope and schema 10 are preserved for compatibility.
- ZIP includes both the 5.8 regression suite and dedicated 5.9 smoke checks.
- Engine-level parse/runtime testing is still required; the offline audit does not prove a runnable build.
