---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Art Direction

## Overview

Chỉ đạo nghệ thuật — Low Poly Stylized Diorama.

## Details

- **Style:** Low Poly Stylized Diorama.
- **Góc nhìn:** Limited Orbit (Xoay 90 độ, Tilt-shift effect — post-MVP).

## Visual Swap Tech

- Sử dụng **Shared Mesh** nhưng hoán đổi **Materials/Props** dựa trên Metric.
- Hệ thống **Environmental Shaders** để giả lập gió, cỏ rì rào (Terra Nil vibe).
- **MultiMeshInstance3D** để giả lập chim chóc (Magic) hoặc Drones (Science).

## Reference Board

Pureref board 3 tiers (~20 reference images, lưu trong `docs/art/`):

| Tier | Focus | References |
|------|-------|------------|
| Geometry | Low-poly blocky buildings | Townscaper, Islanders |
| Mood/VFX | Ecological transitions, diorama camera | Terra Nil, Kingdoms and Castles |
| UI/Color | Cold industrial (Science), warm magical (Magic) | Frostpunk, Ori and the Blind Forest |

Không cần custom concept art ở prototype stage.

## Shader Budget

Target: **Godot 4.x Forward+ renderer**, budget **4 custom shaders max** cho MVP:

1. **Terrain grass-wind sway** (vertex displacement)
2. **Building material swap** (Science/Magic variant via uniform toggle)
3. **Sky/atmosphere color shift** (Wave omen + day/night)
4. **Water/pollution tint**

Performance target: 60fps trên integrated AMD Radeon (Steam Deck tier). Dùng `MultiMeshInstance3D` cho particle-like elements thay vì GPU particles để giữ compatibility đơn giản.
