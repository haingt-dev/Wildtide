---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - The Wave

## Overview

Cơ chế áp lực định kỳ — "Vibe Shield Hero". Đây là Unit Test cho toàn bộ hệ thống quản trị.

## Details

- **Điềm báo:** Bầu trời đổi màu, đồng hồ cát đếm ngược.
- **Tác động:** Quái vật tràn ra từ 3 Rifts.
- **Hậu quả:** Phá hủy công trình, tạo ra "Vết sẹo lịch sử". Người chơi thu thập "Rift Shards" để nâng cấp công nghệ/phép thuật tối thượng.

## Wave Scaling

Linear scaling với step function per Era:

| Era | Cycles | Wave Power | Enemy Types |
|-----|--------|------------|-------------|
| Era 1 | 1-5 | `base × 1.0` | Rift Crawlers (basic) |
| Era 2 | 6-10 | `base × 1.8` | + Rift Stalkers (ranged) |
| Era 3 | 11-15 | `base × 3.0` | + Rift Titan (mini-boss, 1/wave) |
| Final | 16 | `base × 5.0` | All types + Rift Core (boss) |

- `base` = tunable constant trong `.tres` Resource. Bắt đầu với `base = 10` (10 enemies wave 1).
- Thắng Final Wave = endgame.

## Summon the Tide (Early Wave Trigger)

Player có thể chủ động trigger Wave sớm qua "Summon the Tide" trong Sovereign menu:
- **Chi phí:** 50% Mana/Gold reserves hiện tại.
- **Sức mạnh:** 80% Wave power bình thường (dễ hơn chút).
- **Phần thưởng:** 60% Rift Shard rewards bình thường (diminishing returns chống exploit).
- **Cooldown:** Tối đa 1 lần/cycle.

## Vết Sẹo Lịch Sử (History Scars)

**Cả visual lẫn gameplay impact:**
- **Visual:** Tiles bị sẹo có permanent cracked/scorched texture overlay (simple UV blend, không cần shader riêng).
- **Gameplay:** Tiles bị sẹo có **-20% construction speed** penalty. Vẫn xây được, chỉ chậm hơn. Tạo organic city planning — player route growth quanh sẹo cũ.
- **Post-MVP:** Sẹo có thể heal qua late-game "Restoration" quest.
