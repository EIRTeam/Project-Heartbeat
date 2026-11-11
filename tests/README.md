# GDScript tests

This directory contains Project Heartbeat's dependency-free GDScript test runner.

## Running the tests

From the project root:

```bash
tests/run_tests.sh
```

The wrapper uses the development or retail editor from `../../ph-monorepo` by default. To use another build:

```bash
GODOT_BIN=/path/to/godot tests/run_tests.sh
```

The equivalent direct command is:

```bash
godot --headless --path . -s res://tests/test_runner.gd -- --gdscript-tests
```

## Selecting tests

```bash
tests/run_tests.sh --list
tests/run_tests.sh --filter=hb_result
tests/run_tests.sh --file=res://tests/cases/hb_result_test.gd
```

## Writing a test

Test files live below `res://tests/cases`, end in `_test.gd`, and extend the base fixture:

```gdscript
extends "res://tests/test_case.gd"

func test_example() -> void:
	expect_eq(2 + 2, 4)
```

Every zero-argument method beginning with `test_` is run. A fresh fixture is created for each method. Fixtures may override `before_each()` and `after_each()`.

Available checks are `expect_true`, `expect_false`, `expect_eq`, `expect_ne`, `expect_null`, `expect_not_null`, and `fail`.

The runner currently supports synchronous tests only. Running it as a custom `SceneTree` loads project autoloads but does not start the project's normal main scene. The `--gdscript-tests` user argument prevents network, media, and background song-loading startup work while tests are running.

## Exit codes

- `0`: all tests passed
- `1`: one or more tests failed
- `2`: runner configuration, discovery, or fixture-loading error
