# Testing

The current testing guide is [Build and tests](BUILD_AND_TEST.md). Previous release test reports and logs have been removed from the clean distribution; original historical evidence is available in the original 6.0 source ZIP.

Quick checks:

```sh
python3 tests/qa.py
GODOT=/path/to/godot ./RUN_NATIVE_TESTS.sh
```

Python checks validate source structure, assets and JSON; they do **not** parse GDScript. The engine runner first imports the project headlessly and then exercises native smoke tests from the previous releases through 6.0. Manual layout and touch testing is still required.
