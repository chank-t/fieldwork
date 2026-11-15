# FieldWork

FieldWork is a farming and countryside life game built in Godot. The project combines farm management, valley growth, community life, economic decisions, and narrative progression in a fully local experience without external services.

This repository is intended to run offline and to progress the game from a local Godot installation.

## Key features

- Plot, crop, soil, water, and pest management.
- Farm economy, trading, construction, and resource planning.
- Village life with neighbours, stories, and long-term goals.
- Animals, machinery, processing, and valley activities.
- Desktop and touch-friendly interface.
- English and Spanish language support.
- Local save system with backup compatibility and legacy save support.

## Requirements

- Godot 4.6.x (4.6.2 or newer recommended)
- A complete local copy of this repository with all resources intact

## How to run

1. Open Godot.
2. Import the project by selecting `project.godot`.
3. Wait for the editor to import resources.
4. Press **F5** to run the main scene.
5. Choose a language and create or continue a farm.

No Node.js, web server, internet access, or external accounts are required.

## Project structure

- `assets/` — graphics, fonts, audio, and visual resources
- `data/` — game content and world data
- `docs/` — project manuals and documentation
- `references/` — design notes and reference resources
- `scripts/` — game logic, UI, and simulation code
- `project.godot` — main Godot project file

## Documentation

- [Player guide](docs/PLAYER_GUIDE.md)
- [PDF manual](docs/FIELDWORK_6_0_MANUAL.pdf)

## Save data and compatibility

- Save files are stored in Godot's local user directory (`user://`), not inside the repository.
- The project maintains compatibility with older save formats when supported by the code.
- Backup restoration and legacy save loading are preserved where applicable.

## License

This project is distributed under the MIT license. See [LICENSE](LICENSE) for the full text.

## Notes

- The project is intended for local use and personal development.
- Validation in this environment is limited to project startup checks in Godot.
- Before public distribution or commercial use, review the licensing of any inherited art or third-party resources.
