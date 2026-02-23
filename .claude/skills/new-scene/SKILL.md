---
name: new-scene
description: Create a new Godot scene with script following Wildtide conventions
disable-model-invocation: true
argument-hint: "[scene_name category]"
---

Create a new Godot scene with script following Wildtide conventions.

1. If `$ARGUMENTS` provided, parse for scene name and category. Otherwise ask:
   - **Scene name** (snake_case, e.g., `resource_depot`)
   - **Category**: buildings, hex, ui, debug, or main

2. Read an existing scene+script in the same category for reference patterns:
   - Check `scripts/{category}/` and `scenes/{category}/`

3. Create the GDScript at `scripts/{category}/{name}.gd`:
   - Correct `extends` base class
   - `##` doc comment
   - Typed variables, signals if needed
   - Follow AGENTS.md conventions: snake_case, data-driven Resources, max 3 autoloads

4. Create the `.tscn` at `scenes/{category}/{name}.tscn`:
   - Root node with script attached
   - Minimal — just the skeleton

5. Show created file paths for confirmation.
