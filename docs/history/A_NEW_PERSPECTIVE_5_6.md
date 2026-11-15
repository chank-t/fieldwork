# Architecture: the new 2.5D renderer

The existing `World.gd` and all simulation/saves remain in place. `IsometricWorld56.gd` extends `World.gd`, overriding its projection and drawing functions while inheriting signals and click/walk/camera input. View selection in `Main.gd` is a presentation setting only; changing views reconstructs the UI using the same live `farm` instance.

## Coordinates

For simulation point `(x,y)` and unit `u`, before zoom/offset, the new view is:

- `screen_x = origin_x + (x-y) * u`
- `screen_y = origin_y + (x+y) * 0.56 * u`

The inverse subtracts origin/zoom/offset, then solves:

- `x = (screen_x/u + screen_y/(0.56*u)) / 2`
- `y = (screen_y/(0.56*u) - screen_x/u) / 2`

The map calculates its unit from its current Control size, allowing desktop, tablet and phone sizes without changing world grid units. Camera focus, hover, wheel zoom and mouse selection all use the same coordinates. The rectangular selection logic inherited from 5.5 remains correct because inputs are mapped *back* to original world space first.

## Artwork

Fields use projected four-point top faces, darkened front/right side faces and light rims. Their individual 5.2 plot rules determine the vegetation and water overlay; real crop state determines sprite stage and shading. Structures sit on projected foundations and use the original 2D assets for a deliberately illustrated pseudo-3D style. Weather and seasons are visual overlays; all presentation animations are deterministic and do not call the simulation RNG.

## Mobile and accessibility

Godot's 5.5 `ResponsiveLayout55` remains the authoritative layout component. The new map listens to its own Control dimensions. Reduced motion disables crop sway and animal idle movement. The previous 2D renderer is available for players who prefer a simple overhead view.

## Known test boundaries

Check 1366×768 and 1920×1080 desktop, 960×540 small window, and 390×844 portrait, then test actual phone input and orientation. All snapshots should be taken **from running Godot**; offline visual concepts are not evidence of a working build.
