---
up: "[[Project - Wildtide]]"
created: [2026-02-01 01:02]
aliases: [GDD]
updated: 2026-02-11 00:40
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# 🏗️ Game Design Document: Project Wildtide

**Vibe:** _WorldBox_ meets _Frostpunk_ in a _Terra Nil_ aesthetic.  
**Genre:** Auto-City Builder / Indirect Management / Strategy.  
**Platform:** PC (Linux Native - Godot 4.4).

---

## 🎯 Core Vision

Một kỷ nguyên hậu tận thế. Người chơi gián tiếp điều hành thành phố qua chính sách, đối mặt với các đợt Wave định kỳ, dẫn dắt nền văn minh đến con đường Khoa học hoặc Phép thuật.

→ Chi tiết: [[WT - Core Vision & Lore]]

## 🏛️ Design Pillars

1. **Indirect Sovereignty** — Tác động qua Edicts, Tax, Quest Approval
2. **Emergent Growth** — AI tự xây dựng dựa trên Metrics
3. **Living Diorama** — Low Poly trù phú, chi tiết
4. **The Wave** — Áp lực định kỳ, "Unit Test" cho hệ thống

→ Chi tiết: [[WT - Design Pillars]]

## 🔄 Core Loop

Observe (3min) → Influence (3min) → Wave (1min) → Evolve (1min) — ~8 phút/cycle, ~16 cycles tới endgame (~2 giờ campaign).

→ Chi tiết: [[WT - Core Loop]]

---

## 📑 Sections

| Section         | Note                        | Status |
| --------------- | --------------------------- | ------ |
| Lore & Setting  | [[WT - Core Vision & Lore]] | 🟢     |
| Design Pillars  | [[WT - Design Pillars]]     | 🟢     |
| Core Loop       | [[WT - Core Loop]]          | 🟢     |
| Metric System   | [[WT - Metric System]]      | 🟢     |
| Quest System    | [[WT - Quest System]]       | 🟢     |
| The Wave        | [[WT - The Wave]]           | 🟢     |
| Art Direction   | [[WT - Art Direction]]      | 🟢     |
| Hex Terrain     | [WT - Hexagonal Terrain](WT - Hexagonal Terrain.md) | 🟢     |
| Biomes          | [WT - Biomes](WT - Biomes.md)                       | 🟢     |
| Ancient Ruins   | [WT - Ancient Ruins](WT - Ancient Ruins.md)          | 🟢     |
| Technical Stack | [[WT - Technical Stack]]    | 🟢     |

---

## 📊 All GDD Notes

```dataview
TABLE status, tags
FROM "20 Projects/Wildtide"
WHERE file.name != this.file.name AND file.name != "Project - Wildtide"
SORT file.name ASC
```
