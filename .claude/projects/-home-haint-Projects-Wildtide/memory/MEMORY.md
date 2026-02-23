# Wildtide Project Memory

## Pre-commit Hooks
- `addons/` is excluded from gdformat and gdlint hooks in `.pre-commit-config.yaml` — third-party plugins (GUT, etc.) don't follow our lint rules
- If adding new addons, they're automatically excluded by the `^addons/` pattern

## Project Structure
- `scripts/` root has `mcp-start.sh` and `mcp-stop.sh` (tooling, not game code) alongside game code subdirs
- Memory Bank at `.agent/rules/memory-bank/` — keep updated after major changes for Kilo Code / Antigravity sync
- `.agent/rules/memory-bank.backup.1770801968/` is the original backup (can be cleaned up)

## GUT Testing
- GUT installed from GitHub main branch (not Godot Asset Library)
- Must enable GUT plugin manually in Godot editor (Project Settings → Plugins)
- CLI: `godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd`
- Config: `.gutconfig.json` at project root
- Test naming: `test_*.gd` files extending `GutTest`
- **Autoload testing**: When testing code that emits on global autoloads (e.g. `EventBus`), connect to the GLOBAL autoload in tests, not a local instance. Clean up with `_disconnect_all()` in `after_each()`.

## GDScript Lint
- gdlint enforces `class-definitions-order` — constants must come before functions in global scope
- Max line length: 120, max function: 60 lines, max file: 500 lines (`.gdtoolkit`)

## GDScript Gotchas
- Closures CANNOT modify local value-type variables (int, float, bool) from outer scope — use Array.append() instead of `count += 1`
- Shader uniform arrays can't have default values in Godot — set from GDScript via `set_shader_parameter()`
- `INSTANCE_CUSTOM` only accessible in vertex shader — pass to fragment via `varying`
- gdformat removes `()` from parameterless signals: `signal game_paused` not `signal game_paused()`
