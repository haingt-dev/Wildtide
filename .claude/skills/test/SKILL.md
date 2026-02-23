---
name: test
description: Run the GUT test suite and report results
disable-model-invocation: true
argument-hint: "[test filter]"
---

Run the GUT test suite and report results.

1. Run GUT headless:
   ```
   godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit
   ```
   If `$ARGUMENTS` is provided, use as filter:
   - Test name: add `-gtest=$ARGUMENTS`
   - Script path: add `-ginclude=$ARGUMENTS`

2. Parse output and show summary:
   - Total / Passed / Failed / Pending
   - For failures: test name, expected vs actual, file path

3. If tests fail, read the failing test and source files to help diagnose.

Test files are in `test/unit/` (pattern: `test_*.gd`). Source scripts in `scripts/` (core/, data/, buildings/).
