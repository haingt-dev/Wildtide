---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Core Loop

## Overview

Vòng lặp gameplay cốt lõi của Wildtide.

## The Loop

1. **Quan sát (Observe) — 3 phút:** Ngắm nhìn AI tự quy hoạch, xây dựng và sinh hoạt. Tích lũy tài nguyên (Mana/Gold).
2. **Tác động (Influence) — 3 phút:** Ban hành chính sách, điều chỉnh Metric, phê duyệt Quest cho các phe phái.
3. **Chống chọi (The Wave) — 1 phút:** Hệ thống tự vận hành để phòng thủ trước thảm họa dựa trên chuẩn bị trước đó. Player có Emergency Powers (đặt 1-2 barricades/healing zones).
4. **Tái thiết & Tiến hóa (Evolve) — 1 phút:** Thu thập tài nguyên sau Wave, mở khóa Era mới, thay đổi bộ mặt thành phố.

## Timing

- **~8 phút thực/cycle** ở 1x speed.
- **~7 cycles/giờ chơi.**
- **16 cycles tới endgame → ~2 giờ campaign.**
- Game speed: 1x, 2x, 3x.

## Observe Phase

Không cho phép hard skip. Observe phase LÀ identity của game (ngắm diorama). Ở 3x speed, 3 phút nén còn ~1 phút. Phase tự chuyển sang Influence khi resource threshold đạt HOẶC hết thời gian.

## Technical Notes

- Implement `CycleTimer` resource với configurable durations per phase.
- Debug metric logger (CSV export) từ ngày đầu để tune values khi playtesting.
