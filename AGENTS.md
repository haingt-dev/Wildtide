# Wildtide — Project Context

> Soul & identity: see global ~/.claude/CLAUDE.md

## Project Values
- Think like a **game dev partner** — consider gameplay implications, player experience, and performance
- When proposing solutions, reference the GDD sections for alignment
- **GDD is the design authority** — Do not invent or change game mechanics without explicit approval. Files in `docs/gdd/` are read-only unless told otherwise
- **Performance-first** — Target is AMD integrated GPU at 60fps. Prefer simple solutions over elegant-but-heavy ones
- **Data-driven architecture** — Use Godot Resources (`.tres`) for data, keep logic in scripts. Don't hardcode values that belong in resources
- **Ship over polish** — Working code that can be iterated is better than perfect code that takes weeks
- **No dirty state** — Don't leave the project broken. Verify changes work before completing a task
- **Reversibility** — Ensure significant changes can be undone if needed

### Boundaries
- GDScript only — no C# proposals, no GDExtension unless explicitly for optimization
- Stay within the 3 autoloads limit (GameManager, MetricSystem, EventBus)
- Follow the coding conventions in this file strictly (naming, style, patterns)
- Do not add dependencies or plugins beyond what's in the tech stack

## Memory Bank
Auto-loaded at session start (brief, context, tech). Full files in `.memory-bank/`:
- `brief.md` — Project goals and scope
- `product.md` — Product context and constraints
- `context.md` — Current focus and recent changes
- `architecture.md` — System architecture
- `tech.md` — Tech stack and tooling

After major tasks or architectural changes, update relevant Memory Bank files (use `/update-mb`).

## Auto-Commit After Tasks
When a task is completed (marked done in todo list), **automatically commit** the changes:
1. Run `gdformat` + `gdlint` on modified `.gd` files
2. Run GUT tests to verify nothing is broken
3. Stage only the files related to the completed task
4. Commit using the format from `commit-protocol.md` — include test count if tests were added
5. Do NOT push unless the user explicitly asks

## Security
**CRITICAL**: NEVER commit, push, or expose secrets, API keys, tokens, or credentials to version control.

- NEVER hardcode secrets in code — use environment variables and `.env` files
- NEVER commit files containing secrets — verify with `git diff --cached` before committing
- ALWAYS check `.gitignore` has `.env*`, `credentials.*`, `secrets.*`, `*.key`, `*.pem`
- ASK before committing sensitive-looking files (`config.json`, `.env*`, `credentials.*`)
- If secrets are accidentally committed: STOP, alert user to revoke, remove from history, add to `.gitignore`

## Quick Facts

| Field | Value |
|-------|-------|
| **Genre** | Auto-City Builder / Indirect Management / Strategy |
| **Engine** | Godot 4.6 stable (pinned via `.godot-version`) |
| **Language** | GDScript only (GDExtension C++ only for surgical optimization) |
| **Renderer** | Forward+ |
| **Platform** | PC — Linux Native (primary) |
| **Target HW** | AMD integrated GPU (Steam Deck tier), 60 fps |
| **Campaign** | ~2 hours (16 cycles x ~8 min/cycle) |
| **Dev Team** | Solo developer |


