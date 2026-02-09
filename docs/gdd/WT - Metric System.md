---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Metric System

## Overview

Hệ thống chỉ số (The Matrix) điều khiển toàn bộ AI behavior và visual vibe của thành phố.

## Cực Alignment

- **Science (S) vs. Magic (M):**

		Alignment = (S-M) / (S+M)

- Range: -1.0 (pure Magic) → +1.0 (pure Science).
- Sử dụng **linear interpolation** cho visual/behavioral effects.
- _Tác động:_ Quyết định kiến trúc (Mechanical vs. Eldritch) và loại Ambient (Drones vs. Birds).

## Chỉ Số Trạng Thái (State Metrics)

| Metric         | Thấp                                | Cao                                             |
| -------------- | ----------------------------------- | ----------------------------------------------- |
| **Pollution**  | Thiên nhiên trù phú, xanh mát.      | Xuất hiện quái đột biến, bầu trời độc hại.      |
| **Anxiety**    | AI thong dong, làm việc hiệu quả.   | AI hỗn loạn, di chuyển nhanh, dễ bạo động.      |
| **Solidarity** | AI cá nhân hóa, phát triển rời rạc. | AI hỗ trợ nhau, xây dựng các cầu nối, liên kết. |
| **Harmony**    | Công nghiệp hóa mạnh mẽ.            | Sinh vật và con người hòa hợp (Eco-city).       |

## Metric Interaction Matrix

Ma trận trọng số 4×4 — áp dụng per-cycle: `delta = weight × source_metric_normalized`.

| Source ↓ / Target → | Pollution | Anxiety | Solidarity | Harmony |
|---|---|---|---|---|
| **Pollution** | — | +0.3 | 0 | -0.5 |
| **Anxiety** | 0 | — | -0.3 | -0.2 |
| **Solidarity** | 0 | -0.2 | — | +0.3 |
| **Harmony** | -0.4 | -0.1 | +0.2 | — |

- Lưu trữ trong một `.tres` Resource file duy nhất để dễ tweaking.
- **Game modes via weight presets:**
  - **Normal:** Bảng trên.
  - **Hell:** Tất cả trọng số âm × 2.
  - **Zen:** Tất cả trọng số âm × 0.5.
  - Implement bằng alternative `.tres` files.

## Technical Notes

- `MetricDebugPanel` (in-game overlay, debug build only) hiển thị tất cả metric values real-time.
- Log metric snapshots mỗi cycle ra CSV. Balance qua data, không qua lý thuyết.
