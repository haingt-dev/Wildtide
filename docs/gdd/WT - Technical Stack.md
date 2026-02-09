---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Technical Stack

## Overview

Cấu trúc kỹ thuật — Godot 4.4, GDScript.

## Engine & Language

- **Godot 4.4 stable.** Pin version trong `.godot-version` file ở repo root. Không chase pre-release builds.
- **GDScript only.** Lý do:
  - Solo dev = minimize toolchain complexity. Không phụ thuộc .NET SDK trên Linux.
  - GDScript 4.x performance đủ cho city-builder (không phải FPS).
  - Godot C# support trên Linux vẫn còn occasional export issues.
  - Nếu có hotspot (e.g., pathfinding cho 500+ NPCs), dùng GDExtension với C++ như surgical optimization.

## Architecture

- **Logic:** Data-driven với `Resources` (.tres) để lưu trữ Policy, Quest data, và Metric interaction matrix.
- **AI:** Utility AI (Scoring system) để NPC tự đưa ra quyết định dựa trên World Metrics.
- **Performance:** Sử dụng `MultiMeshInstance3D` cho các tiểu tiết số lượng lớn (cỏ, chim, drone) để tối ưu trên Linux/Nobara.

## Save System

**JSON-based save files** dùng Godot `FileAccess` + `JSON` classes:

```
save/
  meta.json        # save name, timestamp, era, cycle count
  world.json       # terrain, building positions, rift states
  metrics.json     # all metric values
  factions.json    # faction states, active quests
```

- Split nhiều files để debug dễ hơn và smaller diffs.
- Không encryption cho MVP (single-player).
- **Autosave** tại đầu mỗi Wave phase.
