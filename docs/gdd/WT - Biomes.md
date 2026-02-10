---
up: "[GDD - Wildtide](GDD - Wildtide.md)"
created:
  - 2026-02-11 00:10
aliases: []
updated: 2026-02-11 00:10
type: note
status: in-progress
tags:
  - project/gamedev
  - gdd
---

# WT - Biomes

## Overview

Hệ thống Biome — các vùng sinh thái khác nhau trên bản đồ hex, mỗi biome ảnh hưởng đến gameplay, AI behavior, và visual aesthetic. Trong bối cảnh post-apocalyptic của Wildtide, biomes không chỉ là cosmetic mà còn là yếu tố chiến lược quan trọng: chúng quyết định tài nguyên có sẵn, tốc độ xây dựng, và cách AI city-builder ra quyết định đặt buildings.

## Details

### Các loại Biome MVP

Giữ scope nhỏ gọn cho solo dev — 5 biomes cơ bản, mỗi biome có identity rõ ràng:

#### 🌾 Đồng Bằng (Plains)
- Biome mặc định, chiếm phần lớn bản đồ.
- Cân bằng — không bonus/penalty đặc biệt.
- Dễ xây dựng nhất, AI sẽ ưu tiên khi không có alignment rõ ràng.
- Visual: Cỏ thấp, đất bằng phẳng, tone màu vàng-xanh nhạt.

#### 🌲 Rừng (Forest)
- Giàu tài nguyên gỗ và Mana.
- **+Harmony bonus** — khu vực tự nhiên còn nguyên vẹn.
- Xây dựng chậm hơn (phải phát quang trước khi đặt building).
- Phù hợp **Magic alignment** — The Veil faction thích xây dựng ở đây.
- Visual: Cây low-poly rậm rạp, tone xanh đậm, particle lá rơi.

#### ⛰️ Đá/Núi (Rocky/Highland)
- Giàu khoáng sản và Gold.
- **+Defense bonus tự nhiên** (+20%) — địa hình cao, dễ phòng thủ.
- Giới hạn loại building có thể đặt (không thể đặt farm/garden).
- Phù hợp **Science alignment** — The Lens faction ưu tiên mining operations.
- Visual: Đá xám-nâu, ít vegetation, terrain cao hơn các hex xung quanh.

#### 🐊 Đầm Lầy (Swamp)
- Thường xuất hiện gần Rifts — bị ô nhiễm tự nhiên.
- **+Pollution base** — hex bắt đầu với Pollution cao hơn.
- Chứa **rare resources** không tìm thấy ở biome khác.
- Nguy hiểm nhưng rewarding — risk/reward tradeoff rõ ràng.
- Visual: Nước đục, cây chết, tone xanh rêu-tím, fog effect nhẹ.

#### 🏚️ Phế Tích (Ruins)
- Vùng có di tích Ancient — tàn tích của nền văn minh cũ.
- Chứa **loot/tech fragments** — có thể salvage để unlock tech.
- **+Anxiety** — dân cư lo lắng khi xây gần phế tích.
- Liên kết chặt với hệ thống [WT - Ancient Ruins](WT - Ancient Ruins.md).
- Visual: Cấu trúc đổ nát, rêu phong, tone xám-vàng cũ kỹ.

### Biome ảnh hưởng đến Gameplay

**Construction Speed Modifier:**
- Mỗi biome có hệ số tốc độ xây dựng riêng (0.5x → 1.0x).
- Kết hợp với History Scars (-20%) nếu hex đã bị damage trước đó.
- AI tính toán effective build time khi quyết định vị trí.

**Resource Yield Modifier:**
- Gold yield và Mana yield khác nhau per biome.
- Ảnh hưởng trực tiếp đến economy loop của thành phố.
- AI cân nhắc resource needs hiện tại khi chọn biome để expand.

**Metric Influence:**
- Mỗi biome push certain metrics theo hướng cụ thể.
- VD: Xây nhiều trên Forest → tổng Harmony tăng; xây trên Swamp → Pollution tăng.
- Tạo tension giữa "cần tài nguyên" vs "giữ metrics healthy".

**AI Building Preference:**
- AI ưu tiên biome phù hợp với alignment hiện tại (Science vs Magic).
- Science-leaning AI → prefer Rocky/Highland cho mining.
- Magic-leaning AI → prefer Forest cho Mana generation.
- Neutral AI → prefer Plains cho efficiency.

**Wave Pathing:**
- Một số biome slow down hoặc redirect Wave enemies từ Rifts.
- Forest: Slow enemies 20% (terrain phức tạp).
- Rocky: Natural chokepoints — enemies phải đi vòng hoặc chậm lại.
- Swamp: Không slow enemies (chúng quen môi trường gần Rift).
- Tạo chiến lược phòng thủ dựa trên biome placement.

**Defense Bonuses:**
- Rocky terrain = natural chokepoints, +20% defense cho buildings trên đó.
- Swamp = -10% defense (địa hình bất lợi cho phòng thủ).
- Player/AI có thể exploit biome layout để tối ưu defense line.

### Biome và Hex Grid

**Data Structure:**
- Mỗi hex tile có 1 biome type (stored trong hex data struct).
- Biome type là enum: `PLAINS`, `FOREST`, `ROCKY`, `SWAMP`, `RUINS`.
- Hex data bao gồm: `biome_type`, `construction_modifier`, `resource_modifiers`, `defense_modifier`.

**Procedural Generation Rules:**
- Swamp clusters gần Rifts (trong radius 3-4 hexes từ mỗi Rift).
- Ruins scattered ngẫu nhiên nhưng không adjacent nhau (minimum 5 hex distance).
- Forest tạo thành clusters lớn (Perlin noise-based).
- Rocky/Highland tạo thành dải hoặc cụm (simulate mountain ranges).
- Plains fill phần còn lại.

**Static vs Dynamic:**
- Biome **không thay đổi** trong game (static) — giữ complexity thấp cho MVP.
- Tuy nhiên, Pollution metric có thể **"degrade" biome visuals** (cây héo, nước đổi màu) mà không thay đổi gameplay stats.
- **Post-MVP:** Biome transformation system (Forest → Swamp nếu Pollution quá cao, Plains → Forest nếu Harmony cao).

### Visual per Biome

**Material Palette:**
- Mỗi biome có material palette riêng.
- Swap via shader uniform — tận dụng Building material swap shader đã có trong [WT - Art Direction](WT - Art Direction.md).
- Giữ Low Poly Stylized Diorama aesthetic nhất quán.

**Vegetation Density:**
- Plains: Cỏ thấp, sparse.
- Forest: Cây + bụi rậm, dense.
- Rocky: Gần như không có vegetation.
- Swamp: Cây chết + rêu, medium density.
- Ruins: Rêu + dây leo trên cấu trúc, sparse-medium.

**Performance Notes:**
- Target 60fps trên Steam Deck tier hardware.
- Vegetation dùng GPU instancing (cùng mesh, khác transform).
- LOD system: Hex xa camera giảm vegetation detail.
- Ambient sounds khác nhau per biome — **post-MVP** (focus visual trước).

## Data / Metrics

### Biome Stats Table

| Biome | Construction Speed | Gold Yield | Mana Yield | Defense | Metric Push | Alignment Affinity |
|-------|-------------------|------------|------------|---------|-------------|-------------------|
| Đồng Bằng | 1.0x | 1.0x | 1.0x | 0 | Neutral | Neutral |
| Rừng | 0.7x | 0.5x | 1.5x | 0 | +Harmony | Magic |
| Đá/Núi | 0.8x | 1.5x | 0.5x | +20% | -Harmony | Science |
| Đầm Lầy | 0.5x | 0.8x | 1.2x | -10% | +Pollution | Neutral |
| Phế Tích | 0.6x | 1.0x | 1.0x | 0 | +Anxiety | Neutral |

### Map Composition Estimate

| Biome | % of Map | ~Hex Count (250 total) |
|-------|----------|----------------------|
| Đồng Bằng | 40% | ~100 |
| Rừng | 25% | ~62 |
| Đá/Núi | 15% | ~38 |
| Đầm Lầy | 10% | ~25 |
| Phế Tích | 10% | ~25 |

> [!note] Tỷ lệ này là baseline — procedural generation sẽ có variance ±5% per biome mỗi lần generate map mới.

## Open Questions

- [ ] Biome có nên ảnh hưởng đến faction quest availability không? (VD: The Lens chỉ propose mining quests trên Rocky biome, The Veil chỉ propose ritual quests trên Forest)
- [ ] Có cần biome transition zones không? (hex ở ranh giới 2 biomes blend visual — đẹp hơn nhưng tốn thêm shader work)
- [ ] Wave enemies có nên có biome affinity không? (VD: swamp enemies mạnh hơn trên Swamp tiles, yếu hơn trên Rocky)
- [ ] Procedural generation seed có nên cho player chọn/reroll không? (tăng replayability nhưng thêm UI work)
- [ ] Biome có ảnh hưởng đến Solidarity metric không? (VD: dân cư trên cùng biome type có Solidarity bonus?)

## References

- [WT - Hexagonal Terrain](WT - Hexagonal Terrain.md) — Hex grid system, terrain data structure
- [WT - Metric System](WT - Metric System.md) — 4 State Metrics và cách biomes interact
- [WT - Core Vision & Lore](WT - Core Vision & Lore.md) — Lore context cho từng biome trong world post-apocalyptic
- [WT - Art Direction](WT - Art Direction.md) — Visual style guidelines, material swap shader
- [WT - Ancient Ruins](WT - Ancient Ruins.md) — Chi tiết về di tích trong Ruins biome
