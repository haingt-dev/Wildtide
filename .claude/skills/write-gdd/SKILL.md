---
name: write-gdd
description: Write or update a Wildtide GDD section. Use when the user asks to document game design, add mechanics, or update the design document.
argument-hint: "[section name or topic]"
---

Write or update a Wildtide GDD section.

1. Read the GDD index to understand the current state:
   - `docs/gdd/GDD - Wildtide.md`

2. Determine the target section from `$ARGUMENTS` (section name or topic).
   If not provided, ask what section to write/update.

3. **If section exists** (e.g., `docs/gdd/WT - Metric System.md`):
   - Read the current file
   - Ask what to add/change
   - Update while preserving existing content and structure

4. **If new section**:
   - Use the section template format from [section-template.md](section-template.md)
   - Create `docs/gdd/WT - {Section Name}.md`
   - Frontmatter: `up: "[[GDD - Wildtide]]"`, `type: note`, `status: idea`, `tags: [gdd]`

5. Update the index table in `docs/gdd/GDD - Wildtide.md` to include/update the section entry.

6. Respect the 4 design pillars:
   - Indirect Sovereignty (Edicts, not direct building)
   - Emergent Growth (AI self-builds based on Metrics)
   - Living Diorama (rich visual style)
   - The Wave (periodic pressure system)

7. Show a summary of what was written/changed.
