# J04 · Bối cảnh ứng dụng



| | |
|---|---|
| Mã đề | **J04** |
| Tên đề | Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp |
| Nhóm đề | J · Đề khó — nhiều khối, có bắt tay hoặc đường ống |
| Độ khó | Khó |
| Loại mạch | **Tuần tự** |
| Quy mô ước lượng (Charter) | ~400–560 cell · 1×1 tile |
| Nguồn gốc | Project Charter — J04, mục 1 |

---

## 1. Mục tiêu và bối cảnh ứng dụng

Trích nguyên văn Charter mục 1:

> Phân tích khối số “Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp” ở mức khối. Bối cảnh ứng dụng: Khối hiển thị bốn chữ số trên đồng hồ đo, dùng chung đường dữ liệu để tiết kiệm chân.

## 2. Vị trí khối J04 trong hệ thống

```
   ┌──────────────┐      ┌──────────────────────────────┐      ┌──────────────┐
   │  Nguồn tín   │─────▶│      ►►► KHỐI J04 ◄◄◄        │─────▶│  Tầng tiêu   │
   │  hiệu / dữ   │      │  Bộ điều khiển bốn LED 7 đoạn │      │  thụ kết quả │
   │  liệu vào    │      │  Loại mạch: Tuần tự          │      │              │
   └──────────────┘      └──────────────────────────────┘      └──────────────┘
```

> Sơ đồ chi tiết có chú thích: `03_ARCHITECTURE/system_diagram.md`.

## 3. Phân loại analog / digital / mixed

| Khối | Phân loại | Ghi chú |
|---|---|---|
| Cảm biến / nguồn tín hiệu vật lý (nếu có) | Analog | Đại lượng liên tục |
| Chuyển đổi ADC/DAC (nếu có) | Mixed-signal | Ranh giới analog–số |
| **J04 — Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp** | **Digital, tuần tự** | Có ô nhớ, hoạt động theo cạnh clock |
| Tầng xử lý phía sau | Digital | Tiêu thụ kết quả của J04 |

Bằng chứng cho dòng phân loại của J04: tổng hợp thật cho **10 flip-flop**
(`06_GDSII/synthesis/synth_stat.txt`).

---

**Truy vết:** yêu cầu sinh từ tài liệu này được đánh số `REQ-J04-0xx` trong
`01_REQUIREMENT/requirements.md`, và truy vết đến bằng chứng trong `07_TRACEABILITY/RTM.csv`.

*Phiên bản: v1.0 · Ngày: 2026-09-24*
