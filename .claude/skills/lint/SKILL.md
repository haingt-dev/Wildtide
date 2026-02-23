---
name: lint
description: Run gdformat and gdlint on changed GDScript files
disable-model-invocation: true
argument-hint: "[file or directory]"
---

Run GDScript formatting and linting checks.

1. Find target files:
   - If `$ARGUMENTS` provided: use as specific file/directory
   - Otherwise: git-changed `.gd` files (`git diff --name-only HEAD -- '*.gd'`)
   - If no git changes: all `.gd` files excluding `.godot/` and `addons/`

2. Run **gdformat** check:
   ```
   gdformat --check <files>
   ```
   Report files needing formatting. Offer to auto-fix with `gdformat <files>`.

3. Run **gdlint**:
   ```
   gdlint <files>
   ```
   Report warnings/errors grouped by file.

4. Show summary: files checked, formatting issues, lint errors, overall pass/fail.
