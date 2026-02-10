---
up: "[GDD - Wildtide](GDD - Wildtide.md)"
created: [2026-02-10 23:22]
aliases: []
updated: 2026-02-10 23:22
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Hexagonal Terrain

## Overview

Quyết định sử dụng lưới Hexagon làm nền tảng cho sa bàn (terrain grid) của Wildtide. Hex grid phù hợp với aesthetic "Living Diorama" và hỗ trợ tốt cho AI city-building, wave pathing, cùng layout 3 Rifts tự nhiên.

## Details

### Tại sao Hexagon thay vì Square Grid

- **6 hướng kề nhau** (vs 4 hoặc 8 của square) → movement và adjacency tự nhiên hơn. AI placement không cần xử lý diagonal edge cases.
- **Không có diagonal ambiguity** — mọi neighbor đều equidistant. Khoảng cách giữa center của 2 hex kề nhau luôn bằng nhau, giúp pathfinding và metric calculation đơn giản hơn.
- **Phù hợp với aesthetic "Living Diorama"** — hexagon tạo cảm giác organic, giống bàn cờ tabletop hơn là digital grid cứng nhắc. Low Poly Stylized Diorama + hex = vibe board game cao cấp.
- **Tương thích tốt với 3 Rifts layout** — tam giác đe dọa map tự nhiên trên hex grid. 3 Rifts đặt ở 3 cạnh/góc hex map tạo thành triangle of threats cân đối, không bị bias hướng như square grid.
- **Đã được validate bởi nhiều strategy/city-builder games** — Civilization, Humankind, Terraforming Mars, Dorfromantik. Player quen thuộc với hex grid trong context strategy.

### Hex Grid Specs

- **Flat-top hexagons** — phù hợp hơn với camera orbit limited 90° (camera nhìn từ trên xuống hơi nghiêng, flat-top cho visual alignment tốt hơn).
- **Coordinate system:** Cube coordinates internally (q, r, s với q + r + s = 0) cho pathfinding và distance calculation. Offset coordinates cho display/UI.
- **Kích thước hex:** Cần tuning qua playtesting, bắt đầu với ~2 unit Godot width. Đủ lớn để chứa 1 building model + padding visual.
- **Map size MVP:** ~200–300 hexes. Đủ cho:
  - City center cluster (~60–80 hexes)
  - 3 Rift zones (~15–20 hexes mỗi zone)
  - Wilderness buffer giữa city và Rifts (~100–150 hexes)
  - Expansion room cho late-game Era progression

### Tích hợp với hệ thống hiện tại

- **AI placement:** Mỗi hex là 1 buildable slot → AI chọn hex dựa trên Metric weights và adjacency bonuses. Ví dụ: đặt Market hex kề Residential hex → +Commerce metric. Utility AI scoring tự nhiên trên hex grid vì mọi neighbor đều equidistant.
- **Wave pathing:** Hex grid cho phép A* pathfinding sạch sẽ từ Rifts vào city center. 6-directional movement không có diagonal shortcut → wave spread đều và predictable hơn. Dễ visualize threat radius.
- **History Scars:** Mỗi hex có thể mang scar state riêng (ví dụ: -20% construction speed sau khi bị Wave tàn phá). Scar data lưu per-hex trong save file (`world.json`).
- **Science/Magic visual swap:** Mỗi hex tile có thể swap material/shader theo alignment hiện tại. Science hex = chrome, clean lines. Magic hex = crystal, organic growth. Transition animation khi alignment thay đổi.

### Godot Implementation Notes

- Sử dụng custom `HexGrid` Resource class (`.tres`) để quản lý grid data — hex states, building references, scar data, alignment.
- Mỗi hex tile là 1 `Node3D` với `MeshInstance3D`. Dùng `MultiMeshInstance3D` cho terrain base mesh nếu cần optimize (target 60fps trên integrated AMD Radeon / Steam Deck tier).
- Hex coordinate system: `Vector3i(q, r, s)` internally. Helper functions: `hex_distance()`, `hex_neighbors()`, `hex_ring()`, `hex_to_world()`, `world_to_hex()`.
- **GridMap node của Godot KHÔNG dùng được cho hex** → cần custom solution hoàn toàn. GridMap chỉ hỗ trợ square/rectangular grid.
- Raycasting để pick hex: Camera ray → plane intersection → `world_to_hex()` conversion.

## Data / Metrics

### So sánh Hex vs Square Grid

| Tiêu chí | Hex Grid | Square Grid |
|---|---|---|
| Neighbors | 6 (equidistant) | 4 (cardinal) hoặc 8 (+ diagonal, không equidistant) |
| Diagonal ambiguity | Không có | Có (√2 vs 1 distance) |
| Aesthetic fit (Diorama) | Cao — organic, tabletop feel | Trung bình — digital, rigid |
| 3 Rifts triangle layout | Tự nhiên | Cần workaround |
| Pathfinding complexity | Đơn giản hơn (uniform distance) | Phức tạp hơn nếu dùng 8-dir |
| Godot built-in support | Không (custom solution) | Có (GridMap) |
| Player familiarity | Cao (Civ, Humankind) | Cao (SimCity, Cities Skylines) |

### Map Size Estimates

| Config | Hex Count | Estimated Draw Calls (MultiMesh) | Notes |
|---|---|---|---|
| Small (prototype) | ~100 | 1–2 | Đủ test core loop |
| MVP | ~200–300 | 2–4 | Target cho vertical slice |
| Full game | ~500–800 | 5–10 | Nếu cần map lớn hơn post-MVP |

## Open Questions

- [ ] Exact hex size (Godot units) cần playtesting — bắt đầu 2.0, tune theo camera zoom range và building model scale.
- [ ] Có cần hex elevation (multi-level terrain) cho MVP không? Flat terrain đơn giản hơn nhiều. Elevation có thể là post-MVP feature.
- [ ] Hex border rendering style: subtle grid lines, terrain color blend, hay chỉ hiện khi hover/select?
- [ ] Hex rotation: Map có cần rotate được không hay fixed orientation?
- [ ] Performance benchmark cần chạy sớm: 300 hex tiles + MultiMesh + ambient shaders trên Steam Deck tier hardware.

## References

- [Red Blob Games — Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/) — Comprehensive guide về hex grid math, coordinates, algorithms. **Must-read.**
- [Red Blob Games — Implementation of Hex Grids](https://www.redblobgames.com/grids/hexagons/implementation.html) — Code examples cho cube coordinates.
- [WT - Core Loop](WT - Core Loop.md) — Hex grid là foundation cho mọi phase trong core loop.
- [WT - Technical Stack](WT - Technical Stack.md) — Godot 4.4 + GDScript implementation details.
- [WT - The Wave](WT - The Wave.md) — Wave pathing sử dụng hex grid A*.
- [WT - Metric System](WT - Metric System.md) — Adjacency bonuses tính trên hex neighbors.
- [WT - Art Direction](WT - Art Direction.md) — "Living Diorama" aesthetic quyết định hex visual style.
- [WT - Design Pillars](WT - Design Pillars.md) — "Ngắm nhìn" pillar → hex grid phải đẹp khi zoom in.
