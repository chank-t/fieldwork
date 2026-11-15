# Cleanup report - Fieldwork 6.0

## Purpose

Convert the accumulated development ZIP into a clean, editable Godot source distribution and a coherent documentation set, **without modifying the farm simulation or presentation scripts**.

## Cleanup actions

- Removed the former `evidence/` directory of historical QA logs, image previews and release manifests. These files are not runtime dependencies and remain accessible in the original 6.0 ZIP.
- Removed version-specific Python audit scripts from `tests/` other than the current `qa_60.py`; historical checks expected old file paths and version labels. All native Godot `*.gd` regression smoke tests were kept.
- Removed old generated QA outputs and preview helper scripts from the runnable test directory.
- Moved older feature guides and two obsolete development data references into `docs/history/`; **the current runtime data files remain in `data/`**.
- Added a clear entrypoint README, consolidated current documentation, and `.gitignore` for temporary/editor-generated files.
- Kept all `.tscn` scenes, runtime GDScript, loaded assets, and referenced artwork **byte-for-byte identical** to the original package. Each is listed with SHA-256 in `docs/CLEANUP_MANIFEST.json`.
- Preserved the current 6.0 offline audit with an updated inherited-art baseline reflecting the deliberate relocation of non-runtime historical reference data.

## Scope and limitations

This is **a packaging/source-tree cleanup, not a risky gameplay rewrite**. A few oversized code modules remain oversized by design for now; refactor them only after Godot parser and gameplay tests can run. No new game mechanics, executable builds, Android export settings or save-schema changes were introduced.

To repeat the offline verification run `python3 tests/qa_60.py`. To test the actual engine run `RUN_NATIVE_TESTS.sh` or `.bat` with Godot installed.
