---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Quest System

## Overview

Hệ thống phê duyệt Quest — cơ chế chính để người chơi tác động gián tiếp lên thành phố.

## Phe Phái

**4 phe phái** (sweet spot cho solo dev — đủ tension, manageable scope):

1. **The Lens** (Science)
2. **The Veil** (Magic)
3. **The Coin** (Commerce)
4. **The Wall** (Military)

Mỗi phe submit 1 quest/cycle → player thấy ~4 proposals để approve/reject mỗi Influence phase.

## Quest Flow

### Ví Dụ: The Lens Xin Phép Xây "Lò Phản Ứng Hạt nhân"

- **Ưu:** Tăng mạnh Science, cấp điện diện rộng.
- **Nhược:** Tăng Pollution và Anxiety cho dân cư xung quanh.
- **Duration:** 3 cycles.

## Quest Failure

**MVP: Quests không thể fail mid-execution.** Một khi approved, luôn complete sau N cycles.

- Failure logic (abort states, partial refunds, faction morale hits) quá phức tạp cho MVP.
- **Quest duration** là lever cân bằng: approve quest dài = tie up faction resources. Opportunity cost IS penalty.
- **Post-MVP:** Thêm failure conditions triggered bởi Wave damage (nếu building đang xây bị phá hủy).

## Player-Initiated Quests

**MVP: Approve/reject only.** Player-initiated quests cần cả UI flow (quest builder, resource picker) — quá costly cho prototype.

**Compromise — Sovereign Quest:**
- 1 slot "Sovereign Quest" mở khóa mỗi Era.
- Menu cố định 3-4 pre-designed upgrade quests (ví dụ: "Build City Wall Lv2", "Expand Market District").
- Player chọn một. Cho agency mà không cần quest editor.
