# J04 · Sơ đồ khối bên trong (Block Diagram)

Sơ đồ dưới vẽ theo **đúng** `04_IMPLEMENTATION/rtl/j04_display_core.sv`, không phải theo
kiến trúc "sách giáo khoa".

---

## 1. Sơ đồ ASCII bên trong khối

```
                                  ┌──────────────────────────────────────────────┐
  rst_n ──────────────────────────┤                                              │
  clk   ──────────────────────────┤   B1 · BO DEM PHA (always_ff)                │
  enable ─────────────────────────┤   phase <= 0        neu !rst_n hoac !enable   │
                                  │   phase <= phase+1  nguoc lai                 │
                                  │   10 flip-flop · dfrtp_1 ×10                  │
                                  └────────┬──────────────────────┬──────────────┘
                                           │ phase[9:8] = S       │ phase[7:0] = Q
                                           │ (2 FF)               │ (8 FF)
                     ┌─────────────────────┤                      │
                     │                     │                      │
                     ▼                     ▼                      │
              digit_sel[1:0]      ┌─────────────────┐              │
              (day thuan,         │  B2 · CHON CHU  │              │
               0 logic)           │  SO + TAT SO 0  │              │
                                  │  DAU            │              │
  bcd_digits[15:0] ──┬───────────▶│                 │              │
                     │            │  d3==0 ?        │              │
                     │            │  d3==0 & d2==0 ?│              │
  blank_leading_zero ┼───────────▶│  ...&d1==0 ?    │              │
                     │            │  → mux 4:1      │              │
                     │            └────────┬────────┘              │
                     │                     │ selected_bcd[3:0]     │
                     │                     ▼                       │
                     │            ┌─────────────────┐              │
                     │            │  B3 · DECODE7   │              │
                     │            │  bang tra 10    │              │
                     │            │  muc + mac dinh │              │
                     │            │  0000000        │              │
                     │            └────────┬────────┘              │
                     │                     │ seg_raw[6:0]          │
                     │                     │                       │
                     │                     │        ┌──────────────▼──────────┐
  brightness[7:0] ───┼──────────┬─────────▶│        │ B4 · SO SANH PWM        │
                     │          │          │        │   Q < brightness        │
  enable ────────────┼──────┐   │          │        │   (so sanh khong dau 8b)│
                     │      │   │          │        └──────────────┬──────────┘
                     │      ▼   ▼          │                       │ pwm_on
                     │  ┌─────────────┐    │                       │
                     │  │ B5 · ACTIVE │    │                       │
                     │  │ enable AND  │    │                       │
                     │  │ (b != 0)    │    │                       │
                     │  └──────┬──────┘    │                       │
                     │         │           │                       │
                     │         ├───────────┼───────────────────────┤
                     │         │           ▼                       ▼
                     │         │    ┌──────────────────────────────────┐
                     │         │    │  B6 · CONG CHAN (AND 7 duong)    │
                     │         │    │  seg = seg_raw & active & pwm_on │
                     │         │    └──────────────┬───────────────────┘
                     │         │                   │
                     │         ▼                   ▼
                     │   display_active         seg[6:0]
```

## 2. Bảng ánh xạ cấu trúc RTL → phần cứng sinh ra

| Khối | Dòng RTL | Cấu trúc RTL | Phần cứng thật (từ `netlist.v`) | Cell | Diện tích (µm²) |
|---|---|---|---|---:|---:|
| **B1** bộ đếm pha | 82–89 | `always_ff` + `phase + 10'd1` | 10 × `dfrtp_1` + chuỗi tăng 1 (26 cell tổ hợp) | 10 FF + 26 | 250,2400 + 150,1440 |
| **B2** chọn + tắt số 0 | 32–49 | `function selected_with_blank` | 3 × `nor4_1` (ba phép `==0`) + logic ưu tiên + mux 4:1 | *(gộp vào B3/B6)* | *(xem ghi chú)* |
| **B3** giải mã 7 đoạn | 51–65 | `function decode7`, `case` 10 mục | mảng cổng AND-OR hai tầng | *(gộp)* | *(xem ghi chú)* |
| **B4** so sánh PWM | 76 | `phase[7:0] < brightness` | so sánh 8 bit (chuỗi mượn) | *(gộp)* | *(xem ghi chú)* |
| **B5** `display_active` | 18 | `enable && (brightness != 0)` | 2 × `nor4_1` + 1 × `a21boi_0` | 3 | 20,0192 |
| **B6** cổng chặn | 76–79 | `if … else seg = 0` | gộp vào tầng cuối của B3 | *(gộp)* | *(xem ghi chú)* |
| **Dây** `digit_sel` | 17 | `assign digit_sel = phase[9:8]` | **0 cell** — đổi tên net | 0 | 0,0000 |

> **Ghi chú quan trọng về "gộp".** Yosys + ABC **không** giữ ranh giới B2/B3/B4/B6. Phân tích
> nón logic (cone) trên `netlist.v` cho kết quả **chính xác** sau đây, và ba nhóm này cộng lại
> đúng bằng tổng của cả thiết kế:
>
> | Nhóm | Số cell | Diện tích (µm²) | % diện tích |
> |---|---:|---:|---:|
> | Nón logic lái `seg[6:0]` — **B2 + B3 + B4 + B5 + B6 đã gộp** | **86** | **521,7504** | 56,6 % |
> | Nón logic trạng thái kế của `phase` — B1 tổ hợp | **26** | **150,1440** | 16,3 % |
> | 10 × `dfrtp_1` — B1 tuần tự | **10** | **250,2400** | 27,1 % |
> | **Tổng** | **122** | **922,1344** | 100 % |
>
> Cộng khớp tuyệt đối với `synth_stat.txt` (122 cell · 922,1344 µm²). Nhóm `display_active`
> (3 cell, 20,0192 µm²) **nằm trong** nhóm `seg` vì nó là đầu vào của cổng chặn.

### Bằng chứng gián tiếp về chi phí của "tắt số 0 đầu"

Netlist có **đúng 5** `nor4_1`. Đếm theo cấu trúc RTL:
- 3 cái cho ba phép `d3==0`, `d2==0`, `d1==0` (mỗi phép là NOR 4 bit),
- 2 cái cho `brightness != 8'h00` (8 bit = 2 × NOR4, rồi hợp lại bằng `a21boi_0`).

3 + 2 = 5 ✅ khớp chính xác. Vậy **riêng ba bộ dò 0 tốn `3 × 6,256 = 18,768 µm²` (2,0 % diện
tích khối)**. Phần logic ưu tiên/mux đi kèm đã bị gộp vào mux chữ số nên **không tách được
chính xác nếu không chạy tổng hợp lần hai** với `blank_leading_zero` bị buộc bằng 0 —
xem `implementation-notes_J04.md` §7 câu 3.

## 3. Khối con nào nằm trên đường tới hạn

Đọc `06_GDSII/sta/summary.txt` và `timing_report_max.txt`:

| Hạng | Startpoint → Endpoint | Slack (ns) | Arrival (ns) | Nhóm | Khối con liên quan |
|---:|---|---:|---:|---|---|
| 1 | `rst_n` → `_216_/RESET_B` | 9,23 | 1,00 | asynchronous (recovery) | **không phải logic** — chỉ là đường reset, arrival = đúng 1,00 ns input delay giả định |
| 2 | `bcd_digits[12]` → `seg[3]` | **6,30** | **2,70** | clk (in→out) | **B2 → B3 → B6** ⬅ **đường dữ liệu tới hạn thật** |
| 3 | `bcd_digits[12]` → `seg[6]` | 6,30 | 2,70 | clk | như trên |
| 8 | `brightness[4]` → `display_active` | 7,68 | — | clk | B5 |
| 9 | `_216_` (`phase[0]`) → `_225_` (`digit_sel[1]`) | **8,40** | **1,48** | clk (reg→reg) | **B1** |

> ❗ **Phải đọc đúng.** `02_SPECIFICATION/timing.md` và `physical_report.md` (sinh tự động) ghi
> "đường tới hạn: `rst_n → _216_`, arrival 1 ns". Đó là **recovery check của reset bất đồng
> bộ**, arrival bằng đúng `set_input_delay 1.0`, **không chứa một cổng logic nào**. Nó là số
> có thật nhưng **không** nói gì về tốc độ của thiết kế.
>
> Đường tới hạn **có ý nghĩa kỹ thuật** là hạng 2: `bcd_digits[12] → seg[3]`, 2,70 ns.

### Trích đường tới hạn thật (rút gọn từ `timing_report_max.txt`)

```
bcd_digits[12] (in)                      1.00 ns   ← input delay gia dinh
  _138_/A  nor4_1   → _093_              1.57      ← d3 == 0  (BO DO SO 0!)
  _160_/A2 a21oi_1  → _021_              1.71      ← logic uu tien tat
  _164_/A2 o2111a_1 → _025_              1.97      ← mux chon chu so
  _204_/B  or3b_1   → _062_              2.33      ← decode7
  _205_/B  and2_0   → _063_              2.49      ← decode7 / chan
  _207_/A1 o21ai_0  → _065_              2.64
  _208_/A2 a21oi_1  → seg[3]             2.70      ← data arrival time
  required = 10.00 − 1.00 (output delay) = 9.00 → slack 6.30 (MET)
```

**Đọc ra điều gì:** cổng đầu tiên trên đường tới hạn là `nor4_1` thực hiện `d3 == 0`. Nghĩa
là **chính tính năng "tắt số 0 vô nghĩa ở đầu" là cái nối dài đường tới hạn của `seg`**, chứ
không phải bộ giải mã 7 đoạn. Lý do bản chất: `d3` phải được so với 0 **trước** khi biết chữ
số nào được chọn, và kết quả so sánh đó chi phối **cả bốn** khe (bất biến INV-9), nên nó nằm
ở **đầu** chuỗi phụ thuộc chứ không song song với nó.

`bcd_digits[12]` là bit thấp nhất của `d3` — đúng là một đầu vào của `nor4_1` đó. ✅ Nhất quán.

## 4. Đối chiếu số flip-flop với cấu trúc RTL

| Tín hiệu RTL | Số FF dự kiến | Tên net trong netlist | Số `dfrtp_1` thật |
|---|---:|---|---:|
| `phase[7:0]` | 8 | `phase[0..7]` | 8 |
| `phase[9:8]` | 2 | `digit_sel[0]`, `digit_sel[1]` | 2 |
| `selected_bcd`, `seg_raw`, `seg` | 0 (tổ hợp) | — | 0 |
| `display_active` | 0 (tổ hợp) | — | 0 |
| **Tổng** | **10** | | **10** ✅ |

> 🔎 Yosys **đổi tên** `phase[9:8]` thành `digit_sel[1:0]` vì `assign digit_sel = phase[9:8]`
> là phép nối dây thuần; công cụ giữ tên cổng ra và bỏ tên nội bộ. Đây là lý do
> `synth_stat.txt` không có net nào tên `phase[8]` hay `phase[9]`. Sinh viên hay tưởng "mất
> 2 FF" — thực ra chúng bị đổi tên.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
