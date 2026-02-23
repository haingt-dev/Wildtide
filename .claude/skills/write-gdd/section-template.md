# GDD Section Template

Use this structure when creating a new GDD section:

```markdown
---
up: "[[GDD - Wildtide]]"
created: YYYY-MM-DD HH:mm
updated: YYYY-MM-DD HH:mm
type: note
status: idea
tags: [gdd]
aliases: []
---

# WT - {Section Name}

## Overview
Brief summary of this design area (2-3 sentences).

## Details
Deep dive into the design. Include:
- Mechanics description
- How it connects to other systems
- Player experience goals

## Data / Metrics
Tables, formulas, numbers if applicable.

| Parameter | Value | Notes |
|-----------|-------|-------|
| ... | ... | ... |

## Open Questions
- [ ] Decision item 1
- [ ] Decision item 2

## References
- [[Related GDD Section]]
- External inspiration links
```

## Index Table Entry Format
Add to `GDD - Wildtide.md` section table:
```
| {Section Name} | [[WT - {Section Name}]] | 🔴 |
```
Status: 🔴 pending, 🟡 in-progress, 🟢 complete
