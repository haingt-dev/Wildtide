---
up: "[[GDD - Wildtide]]"
created: [2026-02-01 01:02]
aliases: []
updated: 2026-02-09 18:57
type: note
status: in-progress
tags: [gdd, project/gamedev]
---

# WT - Design Pillars

## Overview

Bốn trụ cột thiết kế không thể thương lượng của Wildtide.

## The Pillars

### 1. Quyền Lực Gián Tiếp (Indirect Sovereignty)

Người chơi không đặt từng viên gạch. Mọi tác động đều qua Sắc lệnh (Edicts), Thuế (Tax) và Phê duyệt (Quest Approval).

**Mô hình 3 cấp độ agency:**
1. **Edicts** (macro): Đặt chính sách toàn thành phố (thuế suất, ưu tiên nghiên cứu). Tối đa 2-3 edicts active cùng lúc.
2. **Quest Approval** (meso): Chấp thuận/từ chối đề xuất của phe phái. ~3 pending quests mỗi cycle.
3. **Emergency Powers** (micro): CHỈ trong Wave phase, player có thể trực tiếp đặt 1-2 barricades hoặc healing zones. Đây là "pressure valve" cho direct control mà không phá vỡ indirect pillar.

> **Luật bất di bất dịch:** Ngoài Wave phase, player KHÔNG BAO GIỜ trực tiếp đặt buildings.

### 2. Sự Phát Triển Phát Sinh (Emergent Growth)

Thành phố là một hệ sinh thái. AI tự xây dựng dựa trên các chỉ số Metric.

### 3. Sa Bàn Sống Động (Living Diorama)

Đồ họa Low Poly nhưng cực kỳ trù phú, chi tiết (chim chóc, mây khói, Shader chuyển động).

**MVP Scope — 3 visual layers:**
1. **Layer 1 — Static:** Low-poly buildings với Science/Magic material swap. *(Bắt buộc)*
2. **Layer 2 — Ambient:** Grass wind shader + sky color shift. *(Bắt buộc — defines the vibe)*
3. **Layer 3 — Flavor:** MultiMesh birds/drones, smoke particles. *(Nice-to-have, thêm cuối cùng)*

**Cắt khỏi MVP:** Dynamic water, weather system, tilt-shift post-process.

### 4. Áp Lực Định Kỳ (The Wave)

Những đợt "Unit Test" khốc liệt cho hệ thống quản trị của người chơi.
