# J04 · Sơ đồ hệ thống (System Diagram)

---

## 1. Bối cảnh ứng dụng — đồng hồ đo bốn chữ số

Charter mục 1: *"Khối hiển thị bốn chữ số trên đồng hồ đo, dùng chung đường dữ liệu để tiết
kiệm chân."* Sơ đồ dưới là hệ thống đầy đủ; **khung đậm** là phần J04 chịu trách nhiệm.

```
          MIEN ANALOG                  |            MIEN SO (digital)
 ─────────────────────────────────────┼──────────────────────────────────────────────
                                       |
  ┌──────────┐   ┌──────────┐   ┌──────┴───┐   ┌──────────────┐
  │ Cam bien │──▶│ Khuech   │──▶│   ADC    │──▶│ Xu ly do luong│
  │          │   │ dai      │   │          │   │ (trung binh,  │
  └──────────┘   └──────────┘   └──────────┘   │  hieu chinh)  │
                                               └───────┬───────┘
                                                       │ gia tri nhi phan
                                                       ▼
                                               ┌───────────────┐
                                               │ BIN → BCD     │   ← NGOAI J04
                                               │ (double-dabble)│     (xem de B04)
                                               └───────┬───────┘
                                                       │ bcd_digits[15:0]
                                                       │ brightness[7:0]
                                                       │ blank_leading_zero
                                                       │ enable
   ╔═══════════════════════════════════════════════════▼═══════════════════════════╗
   ║                    J04 · j04_display_core   (TRONG PHAM VI)                    ║
   ║                                                                                ║
   ║   ┌────────────┐   ┌──────────────┐   ┌──────────┐   ┌────────────────┐       ║
   ║   │ bo dem     │──▶│ chon chu so  │──▶│ decode7  │──▶│ chan PWM       │──▶ seg║
   ║   │ phase[9:0] │   │ + tat so 0   │   │ BCD→7seg │   │ Q < brightness │  [6:0]║
   ║   └─────┬──────┘   └──────────────┘   └──────────┘   └────────────────┘       ║
   ║         │ phase[9:8]                                                           ║
   ║         └──────────────────────────────────────────────────────▶ digit_sel[1:0]║
   ║                                                        enable ──▶ display_active║
   ╚═══════════════════════╤═══════════════════╤════════════════════╤══════════════╝
                           │ seg[6:0]          │ digit_sel[1:0]     │ display_active
                           ▼                   ▼                    ▼
                  ┌─────────────────┐  ┌────────────────┐   (den bao / chan OE)
                  │ 7 dien tro han  │  │ giai ma 2→4    │   ← NGOAI J04
                  │ dong (~330 Ω)   │  │ + 4 transistor │
                  └────────┬────────┘  │ lai anode      │
                           │           └───────┬────────┘
                           │  a b c d e f g    │  A0 A1 A2 A3
                           ▼                   ▼
                   ┌───────────────────────────────────┐
                   │   4 × LED 7 doan dung chung        │   ← NGOAI J04 (analog/dien)
                   │   duong doan, rieng duong anode    │
                   │        ┌─┐ ┌─┐ ┌─┐ ┌─┐            │
                   │        │8│ │8│ │8│ │8│            │
                   │        └─┘ └─┘ └─┘ └─┘            │
                   │         d3  d2  d1  d0             │
                   └───────────────────────────────────┘
```

## 2. Ranh giới khối — cái gì thuộc J04, cái gì không

| Chức năng | Trong J04? | Bằng chứng / ghi chú |
|---|:-:|---|
| Sinh chu kỳ quét tuần hoàn | ✅ | `phase[9:8]` trong RTL |
| Giải mã BCD → 7 đoạn | ✅ | hàm `decode7` |
| Tắt số 0 vô nghĩa ở đầu | ✅ | hàm `selected_with_blank` |
| Điều chế độ sáng PWM | ✅ | `phase[7:0] < brightness` |
| Báo "đang hiển thị" | ✅ | `display_active` |
| **Chuyển nhị phân → BCD** | ❌ | J04 nhận BCD **đã sẵn sàng**. Đây là đề B04 riêng |
| **Giải mã `digit_sel` 2 bit → 4 đường anode** | ❌ | RTL chỉ ra 2 bit nhị phân. Tầng ngoài phải có bộ giải mã 2→4 |
| **Lái dòng LED** (transistor, điện trở hạn dòng) | ❌ | Charter mục 3 liệt "điều khiển dòng" vào **ngoài phạm vi** |
| **Mức tích cực của LED** (common anode / common cathode) | ❌ | RTL phát mức **tích cực cao**. Nếu LED common-anode, tầng ngoài phải đảo |
| **Nhiều hơn 4 chữ số, ma trận LED** | ❌ | Charter mục 3 — ngoài phạm vi |
| **Đồng bộ hoá `enable`, `bcd_digits` vào miền `clk`** | ❌ | Nghĩa vụ tầng ngoài, xem `interface.md` §4 |

### Nghĩa vụ hợp đồng của tầng ngoài

1. **Giữ `bcd_digits` ổn định ít nhất một khung (1024 chu kỳ).** Vì `seg` là tổ hợp thuần
   (độ trễ 0 chu kỳ), đổi dữ liệu giữa khe gây xé hình. Xem `corner_cases.md` CA-T2.
2. **Cung cấp `clk` trong dải cho phép.** Xem §4 dưới đây và `implementation-notes_J04.md` §8.
3. **Giải mã `digit_sel` và lái anode đúng thứ tự** `00→d0, 01→d1, 10→d2, 11→d3`.
4. **Chen thời gian chết (dead time) nếu transistor anode chậm.** J04 đổi `digit_sel` và `seg`
   ở **cùng một cạnh clock**; nếu transistor cũ tắt chậm hơn transistor mới bật, sẽ có hiện
   tượng "bóng ma" (ghosting) giữa hai chữ số kề nhau. J04 **không** tạo dead time.

## 3. Phân loại analog / digital / mixed

| Phần | Phân loại | Lý do |
|---|---|---|
| `j04_display_core` (J04) | **Digital thuần, tuần tự đồng bộ** | Chỉ mức logic 0/1, một clock, 10 flip-flop (`synth_stat.txt`) |
| Bộ giải mã anode + transistor | Digital điều khiển, **tải điện** | Ngoài phạm vi |
| LED 7 đoạn + điện trở hạn dòng | **Analog / điện** | Dòng thuận, sụt áp — ngoài phạm vi |
| Hệ thống đồng hồ đo tổng thể | **Mixed-signal** | Có ADC ở đầu vào |

## 4. Dải clock hợp lệ — suy từ chính thiết kế

| Ràng buộc | Công thức | Giá trị |
|---|---|---|
| **Cận dưới** — mắt không thấy nháy (~60 Hz/LED) | `f_clk ≥ 60 × 1024` | **≥ 61 440 Hz (61,44 kHz)** |
| Cận dưới thoải mái (~100 Hz/LED) | `f_clk ≥ 100 × 1024` | ≥ 102,4 kHz |
| Cận trên **chức năng** | do STA quyết định | ⬜ chưa có số sau routing |
| Cận trên **công suất hợp lý** (~1 kHz/LED là quá đủ) | `f_clk ≈ 1000 × 1024` | ≈ 1,024 MHz |

Chi tiết phép tính và đối chiếu với các giả định trong hồ sơ: `implementation-notes_J04.md` §8.

## 5. Sơ đồ vòng đời RTL → GDSII — trạng thái **thật**

Lấy đúng từ `BRIEF J04.md` và `06_GDSII/physical_report.md`. Không suy diễn.

```
  ┌───────────────┐
  │ 1. Dac ta     │ ✅ 01_REQUIREMENT/ + 02_SPECIFICATION/
  └───────┬───────┘
  ┌───────▼───────┐
  │ 2. RTL        │ ✅ j04_display_core.sv (90 dong)
  └───────┬───────┘
  ┌───────▼───────┐
  │ 3. Mo phong   │ ⚠️ CHAY XONG, KHONG TU KIEM
  │    hanh vi    │    "J04 RTL testbench completed", $finish @ 40985
  │               │    → 4096 chu ky = 4 khung quet, nhung 0 assertion
  └───────┬───────┘    (xem corner_cases.md §0)
  ┌───────▼───────┐
  │ 4. Tong hop   │ ✅ PASS · Yosys 0.33
  │    (Yosys)    │    122 cell · 10 FF · 922,1344 um2
  └───────┬───────┘
  ┌───────▼───────┐
  │ 5. STA        │ ✅ PASS (real_clock) · OpenSTA 3.1.0
  │               │    WNS 0,00 · TNS 0,00 · slack xau nhat 6,30 ns (duong du lieu)
  └───────┬───────┘
  ┌───────▼───────┐
  │ 6. Power      │ ✅ uoc luong · 5,52e-05 W (tuan tu 78,0 % / to hop 22,0 %)
  └───────┬───────┘
  ┌───────▼───────┐
  │ 7. Floorplan  │ ⬜ chua chay — can LibreLane + PDK sky130A
  └───────┬───────┘
  ┌───────▼───────┐
  │ 8. Placement  │ ⬜ chua chay
  └───────┬───────┘
  ┌───────▼───────┐
  │ 9. CTS        │ ⬜ chua chay — moi so thoi gian hien tai gia dinh clock LY TUONG
  └───────┬───────┘
  ┌───────▼───────┐
  │10. Routing    │ ⬜ chua chay — chua co ky sinh RC
  └───────┬───────┘
  ┌───────▼───────┐
  │11. DRC / LVS  │ ⬜ chua chay
  └───────┬───────┘
  ┌───────▼───────┐
  │12. GDSII      │ ⬜ chua chay
  └───────┬───────┘
  ┌───────▼───────┐
  │13. Tape-out   │ ⬛ KHONG AP DUNG — Charter muc 3 liet vao ngoai pham vi
  └───────────────┘
```

**Cần gì để mở khoá bước 7–12:** một bộ cài LibreLane đã xác minh với PDK `sky130A`
(Charter mục 3 — phần *Mở rộng*, **tự nguyện**, không phải điều kiện đạt).

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
