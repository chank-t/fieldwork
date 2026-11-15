# Saves, migration and recovery

## Where files live

The project **does not** save campaigns into the source directory. It uses Godot's `user://` application data directory, resolved on each operating system by Godot. To locate it, use the Godot editor's **Open User Data Folder** action or query `ProjectSettings.globalize_path("user://")` from an editor script.

| Path in `user://` | Purpose |
| --- | --- |
| `fieldwork_native_6_0.json` | Active 6.0 campaign |
| `fieldwork_native_6_0.json.bak` | Recovery copy of active save |
| `fieldwork_native_6_0.json.bak2` | Additional recovery copy |
| `fieldwork_slots_60/slot_1.json` to `slot_3.json` | Three manual save slots (with corresponding backups) |
| `fieldwork_settings.cfg` | Local presentation/language preferences |
| `fieldwork_photo.png` | Optional photo-mode output |

The loader can import older native save files (including versions 5.9, 5.8, 5.7 and earlier), and searches backup candidates. Old source paths are not directly overwritten; when a valid older save is loaded, the game can create a **new 6.0 save** in `user://`.

## Save envelope and schema

`NativeFarm.export_text()` stores a JSON envelope with `format`, `payload`, and `sha256`. The payload is canonicalized before hashing. The **current save envelope ID is `FW_NATIVE_5_4`** and `NativeFarm.VERSION` is **10**. These identifiers deliberately remain from an earlier compatible schema. Renaming them to `FW_NATIVE_6_0` without a migration would break compatibility.

Before accepting a save, the game checks JSON structure, checksum and state invariants. An invalid file does not become a valid save merely because the file exists. Save writes use a protected temporary-file and backup workflow.

## Safe upgrade procedure

1. Close the game, open the Godot user-data directory and make an external copy of **all** `fieldwork_native_*`, `fieldwork_slots_*`, and `fieldwork_settings.cfg` files.
2. Keep the old version installed until the upgrade has been played and verified.
3. Open 6.0, select **Continue saved farm**, and inspect farm funds, crop growth, animals, current season, wardrobe and story progress.
4. Make a new **6.0 manual slot** after confirming the imported campaign is correct.
5. If load fails, stop and retain the original backup copies; do not edit JSON payloads by hand unless you understand canonical checksums and state migrations.

## Troubleshooting corrupted saves

- If the primary save is invalid, check whether `.bak` or `.bak2` can be loaded. The game attempts valid candidates automatically.
- If all copies are invalid, restore from an external backup; the checksummed format is intentionally strict.
- Never try to fix checksum errors by deleting the `sha256` field. The loader will reject the file.
- Changing the project folder does not automatically migrate `user://` data; the app's user-data directory depends on its Godot project identity and platform settings.

## Safety invariants

Game-changing operations should go through `farm.act(kind, args)`. Rejected actions restore the previous state; save migration upgrades older payloads and then validates the new schema before committing. The Farm Compass is intentionally read-only.
