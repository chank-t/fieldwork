# Interface Reborn — responsive implementation

## Layout ownership

`Main.gd` now installs a full-rect `Control` as the scene layer, then adds a full-rect `MarginContainer` as the **single layout root**. A `VBoxContainer` is its container-managed child. This replaces the previous free-floating VBox, which was not reliably consuming the viewport width in desktop debug windows.

The vertically stacked UI has three major regions: compact HUD/top navigation, expandable game content, and a status region. The game content on desktop is an `HBoxContainer` with an optional grouped sidebar, a flexible world `VBoxContainer` and a fixed-bounds details `PanelContainer`. On mobile, a `VBoxContainer` switches visibility between world and management screen, and the bottom navigation provides persistent access to major areas.

## Breakpoints

Use `ResponsiveLayout55.mode()`; desktop is 2, tablet 1, portrait/phone 0. Portrait recognition uses both window aspect ratio and viewport width. Mobile OS names are checked separately to handle mobile landscape input layout.

`ResponsiveLayout55.configure_window()` sets `Window.content_scale_size` to an appropriate virtual reference: 1280×720 desktop, 440×800 portrait, 960×540 native mobile landscape. This is **a visual/UI setting only**; it never changes game saves, crop growth, event RNG or finances.

## Navigation

Desktop: top-level toolbar for Farm, Fields, Valley, Animals, Market and Buildings; collapsible, categorized left sidebar for the rest. Tablet: horizontal categorized strip, collapsible. Phone: bottom Farm, Fields, Valley, Tasks and More. The More dialog lists all existing features. Tapping an interactive field sends the player to the field inspector on phone, while desktop displays the inspector alongside the map.

## Acceptance and testing

1. 1366×768 and 1920×1080: safe layout fills the full viewport, with a visible map and usable management panel.
2. Small portrait screens: map is initially visible; tapping fields or using nav opens management without clipping; Farm returns to the map.
3. Tablet layout stays usable; resizing reflows the UI and does not mutate farming state.
4. Existing saves from 5.4 and earlier import and receive new 5.5 backups without deleting the original file.
5. Godot project import, GDScript parse, gameplay and phone touch should be tested on real engine builds. They have not been run here.

Native test scripts: `tests/layout_logic_smoke.gd`, `tests/ui_interface_smoke.gd` and inherited gameplay tests. Python release audit: `tests/qa_55.py`.
