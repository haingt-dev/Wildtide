---
up: "[GDD - Wildtide](GDD - Wildtide.md)"
created:
  - 2026-02-11 00:21
aliases: []
updated: 2026-02-11 00:21
type: note
status: in-progress
tags:
  - project/gamedev
  - gdd
---

# WT - Ancient Ruins

## Overview

Di Tích Cổ Đại (Ancient Ruins) — tàn tích của nền văn minh The Ancients rải rác trên bản đồ. Đây là nguồn lore, tài nguyên quý hiếm, và cầu nối giữa quá khứ và hiện tại của thế giới Wildtide.

## Details

### Vai trò trong Gameplay

- Ruins là nguồn **Tech Fragments** (Science) và **Rune Shards** (Magic) — tài nguyên đặc biệt không thể farm từ nguồn khác
- Khai thác Ruins qua faction quests: The Lens gửi expedition để giải mã blueprints, The Veil gửi ritualists để channel rune energy
- Mỗi Ruin hex chỉ khai thác được 1 lần (exhaustible resource) → tạo strategic scarcity
- Khai thác Ruins push Alignment theo hướng faction thực hiện (Science quest → +Science, Magic quest → +Magic)

### Các loại Ruins (MVP — 3 types đủ cho solo dev)

- **Đài Quan Sát (Observatory):** Cấu trúc cao, còn tương đối nguyên vẹn. Yield: Tech Fragments. Bonus: Reveal thông tin về Wave tiếp theo (enemy composition preview). Visual: Tháp đá với lens/kính thiên văn vỡ.
- **Đền Thờ Năng Lượng (Energy Shrine):** Nền móng phát sáng gần Rifts. Yield: Rune Shards. Bonus: Tạm thời buff Mana generation trong radius. Visual: Bệ đá với glyphs phát sáng xanh/tím.
- **Kho Lưu Trữ (Archive Vault):** Hầm ngầm, khó tiếp cận. Yield: Cả Tech Fragments lẫn Rune Shards (ít hơn mỗi loại). Bonus: Unlock 1 Sovereign Quest option đặc biệt. Visual: Cửa hầm bán chìm trong đất, có ký hiệu Ancient.

### Placement Rules

- Ruins nằm trên Phế Tích biome hexes (xem [WT - Biomes](WT - Biomes.md))
- Không bao giờ adjacent trực tiếp với Rift hex (lore: Ancients xây xa Rifts vì biết nguy hiểm)
- Observatory ưu tiên hex cao (nếu có elevation system), hoặc edge of map
- Energy Shrine: 2-4 hex cách Rift (gần nhưng không sát)
- Archive Vault: Trung tâm map hoặc giữa 2 Rifts

### Exploration Mechanic

- Ruins bắt đầu ở trạng thái "Undiscovered" (visual: đống đổ nát mờ, không rõ type)
- Khi AI scouts đến gần (hoặc player dùng Edict "Survey"), Ruin được reveal → hiện type và potential yield
- Khai thác = faction quest (2-3 cycles duration)
- Sau khi khai thác: Ruin chuyển sang "Depleted" state → có thể build trên hex đó nhưng với penalty

### Lore Delivery qua Ruins

- Mỗi Ruin khi reveal hiện 1 dòng flavor text ngắn (tooltip) — gợi ý về The Ancients
- Ví dụ Observatory: *"Họ đã nhìn thấy điều gì qua ống kính này trước khi bầu trời vỡ ra?"*
- Ví dụ Energy Shrine: *"Năng lượng vẫn chảy qua các đường rãnh — như máu trong tĩnh mạch đá."*
- Ví dụ Archive Vault: *"Cánh cửa này được thiết kế để mở từ bên trong."*
- Không cutscene, không dialogue — chỉ environmental text. Phù hợp MVP lore delivery approach.

### Tương tác với các hệ thống khác

- **Metrics:** Khai thác Ruins tăng Anxiety nhẹ (dân sợ đào bới quá khứ) nhưng tăng Solidarity (shared discovery)
- **The Wave:** Ruins gần Rift có thể bị damage bởi Wave → mất potential yield nếu không khai thác kịp. Tạo urgency.
- **Factions:** The Lens và The Veil cạnh tranh khai thác Ruins. The Coin muốn bán artifacts. The Wall muốn dùng Ruins làm defensive positions.

## Data / Metrics

### Ruin Types

| Loại | Yield chính | Yield phụ | Bonus | Exploration Duration | Rarity |
|------|------------|-----------|-------|---------------------|--------|
| Đài Quan Sát | 3 Tech Fragments | — | Wave preview | 2 cycles | Common (~40%) |
| Đền Thờ Năng Lượng | 3 Rune Shards | — | Mana buff (3 hex radius, 2 cycles) | 2 cycles | Common (~40%) |
| Kho Lưu Trữ | 1 Tech Fragment | 1 Rune Shard | Unlock Sovereign Quest | 3 cycles | Rare (~20%) |

### Ruin States

| State | Visual | Interactable | Notes |
|-------|--------|-------------|-------|
| Undiscovered | Đống đổ nát mờ | Không | Cần scout/survey |
| Discovered | Hiện rõ type + glow | Có | Sẵn sàng khai thác |
| Being Explored | Faction workers visible | Không (đang xử lý) | 2-3 cycles |
| Depleted | Nền móng trống | Có (buildable) | -30% construction speed |
| Damaged | Vết nứt + smoke | Không | Wave damage, yield giảm 50% |

## Open Questions

- Có nên cho phép rebuild/restore Ruins (post-MVP feature)?
- Tech Fragments và Rune Shards có nên là currency riêng hay convert sang Gold/Mana?
- Có cần "Ancient Guardian" mini-boss bảo vệ Archive Vaults không?
- Flavor text pool size: bao nhiêu unique texts per Ruin type là đủ cho MVP?
- Ruins có nên respawn sau nhiều cycles (renewable) hay hoàn toàn exhaustible?

## References

- [WT - Core Vision & Lore](WT - Core Vision & Lore.md) — The Ancients lore, Rifts
- [WT - Biomes](WT - Biomes.md) — Phế Tích biome type
- [WT - Hexagonal Terrain](WT - Hexagonal Terrain.md) — Hex grid placement
- [WT - Quest System](WT - Quest System.md) — Faction quest mechanics, Sovereign Quests
- [WT - The Wave](WT - The Wave.md) — Wave damage, Rift Shards
- [WT - Metric System](WT - Metric System.md) — Anxiety, Solidarity metrics
- [WT - Art Direction](WT - Art Direction.md) — Low Poly visual style for ruins
