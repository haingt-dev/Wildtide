---
name: update-mb
description: Sync and compact the Memory Bank after major changes
argument-hint: "[section to focus on]"
---

Sync and compact the Wildtide Memory Bank (`.memory-bank/`).

1. Read all memory bank files and Claude auto-memory:
   - `.memory-bank/brief.md` (stable, rarely needs changes)
   - `.memory-bank/context.md` (current phase, timeline, active systems)
   - `.memory-bank/tasks.md` (open tasks, backlog, recently completed)
   - `.memory-bank/architecture.md` (system descriptions, HexCell extensions)
   - `.memory-bank/product.md` (design pillars, GDD status)
   - `.memory-bank/tech.md` (save system, testing, tooling)
   - Claude auto-memory at `~/.claude/projects/-home-haint-Projects-Wildtide/memory/MEMORY.md`

2. If `$ARGUMENTS` provided, focus update on that section only (e.g., `context`, `tasks`, `architecture`).

3. Identify stale data by cross-referencing:
   - Test count: compare across context.md, tech.md, MEMORY.md
   - System count: compare context.md active systems vs architecture.md sections
   - GDD section count: compare product.md vs `docs/gdd/GDD - Wildtide.md`
   - Timeline: check if recent git commits have corresponding entries
   - Tasks: check if completed items should be pruned or moved

4. Update stale sections:
   - context.md `## Current Phase`: update test count, system count, latest milestone
   - context.md `## Project Timeline`: add missing milestones, merge same-day entries into single lines
   - context.md `## Active Systems`: add/update system entries
   - tasks.md: prune `## Recently Completed` (keep only last 5-8 items), move done items out of In Progress
   - architecture.md: add new systems, update HexCell extensions
   - tech.md: update test count, save system files
   - product.md: update GDD status section count

5. Sync MEMORY.md with memory bank:
   - If MEMORY.md has info not in memory bank: add to appropriate memory bank file
   - If memory bank has newer info than MEMORY.md: update MEMORY.md
   - Keep MEMORY.md concise (<200 lines) — it's loaded into system prompt

6. Show summary of changes made:
   - Files updated and line counts before/after
   - Stale items found and fixed
   - Any items that need manual attention
