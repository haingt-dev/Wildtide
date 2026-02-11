# Wildtide Project Rules

## Engine & Language
- **Godot 4.6** with **GDScript only** — no C#, no .NET
- GDExtension (C++) only as last resort for performance bottlenecks (500+ NPC pathfinding)
- Target: 60fps on integrated AMD Radeon (Steam Deck tier)

## Architecture Conventions
- **Data-driven design**: All game data in Godot Resources (`.tres`)
- **3 planned autoloads**: GameManager (cycle state machine), MetricSystem (metrics + alignment), EventBus (global signal bus). No additional autoloads.
- Prefer composition over inheritance
- Use signals for loose coupling between systems

## GDScript Style
- Follow GDScript style guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html
- Use `gdformat` and `gdlint` before committing (config in `.gdtoolkit`)
- Max line length: 120 characters
- Max function length: 60 lines
- Max file length: 500 lines
- Use type hints everywhere: `var speed: float = 10.0`, `func move(delta: float) -> void:`
- Use `@export` for inspector-editable properties
- Use `@onready` for node references: `@onready var sprite: Sprite3D = $Sprite3D`

## Naming Conventions
- **Files**: `snake_case.gd`, `snake_case.tscn`, `snake_case.tres`
- **Classes**: `PascalCase` — `class_name HexGrid`
- **Functions**: `snake_case` — `func calculate_damage()`
- **Variables**: `snake_case` — `var health_points: int`
- **Constants**: `SCREAMING_SNAKE_CASE` — `const MAX_HEALTH: int = 100`
- **Signals**: `snake_case` past tense — `signal health_changed(new_value: int)`
- **Enums**: `PascalCase` type, `SCREAMING_SNAKE_CASE` values — `enum BiomeType { PLAINS, FOREST }`

## File Organization
- `scripts/` — All GDScript files (subdirs: core, metrics, ai, wave, factions, buildings, ruins, ui, data, shaders, debug)
- `scenes/` — All scene files (.tscn) (subdirs: main, hex, buildings, ui, wave, debug)
- `test/` — GUT tests (subdirs: unit, integration, fixtures)
- `addons/gut/` — GUT test framework plugin
- `assets/` — Art, audio, fonts (subdirectories by type)
- `docs/gdd/` — Game Design Document (read-only reference, do not modify without explicit instruction)

## Hex Grid Specifics
- Flat-top hexagons with cube coordinates (q, r, s where q + r + s = 0)
- Custom `HexGrid` Resource — do NOT use Godot's `GridMap`
- ~200-300 hexes per map

## Testing
- **GUT 9.x** (Godot Unit Testing) — plugin at `addons/gut/`, config at `.gutconfig.json`
- Test files: `test_*.gd` extending `GutTest` in `test/unit/` and `test/integration/`
- CLI run: `godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd`
- `MetricDebugPanel` overlay for runtime metric inspection (debug builds only)
- Print statements for development, remove before commit
