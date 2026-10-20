# J04 · Giản đồ thời gian (Timing Diagram)

> ⚠️ **Mọi waveform dưới đây là mô phỏng *hành vi* (zero-delay).** Trong mô phỏng hành vi,
> mọi tín hiệu tổ hợp đổi **tức thì** tại cạnh clock. Chúng **không** minh hoạ độ trễ lan
> truyền thật (ví dụ 2,70 ns của đường `bcd_digits[12] → seg[3]` mà STA đo được). Muốn thấy
> độ trễ thật phải mô phỏng gate-level có SDF — `⬜ chưa chạy` (xem `test_matrix.csv` L5-SDF).
>
> Giá trị trong các bảng dưới đây được **suy ra từ ngữ nghĩa RTL**, không phải đọc từ VCD:
> testbench hiện **không gọi `$dumpfile`/`$dumpvars`** nên hồ sơ **chưa có file VCD**.
> Đây là một khoảng trống bằng chứng đã ghi ở `corner_cases.md` §1 ca số 4.

---

## 1. Giao dịch điển hình — reset → khung quét đầu tiên

Kích thích lấy đúng từ testbench: `brightness = 8'hFF`, `bcd_digits = 16'h1234`,
`blank_leading_zero = 0`, `enable` lên cùng `rst_n` sau 3 cạnh lên.

```
 Chu ky:        0    1    2    3    4    5   ...  255  256  257 ... 511  512 ... 767  768 ...1023 1024
                ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐       ┌─┐  ┌─┐  ┌─┐     ┌─┐  ┌─┐     ┌─┐  ┌─┐     ┌─┐  ┌─┐
 clk          ──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └── ... ─┘ └──┘ └──┘ └─ ...┘ └──┘ └─ ...┘ └──┘ └─ ...┘ └──┘ └──
                          ┌──────────────────────────────────────────────────────────────────────────────
 rst_n        ────────────┘        (nha o canh #3)
                          ┌──────────────────────────────────────────────────────────────────────────────
 enable       ────────────┘
                     ┌────────────────────────────────────────────────────────────────────────────────────
 display_active ─────┘  (to hop: len ngay khi enable & brightness != 0)

 phase[9:0]   0    0    0    0    1    2   ...  255  256  257 ... 511  512 ... 767  768 ...1023   0
                                  ^-- bat dau dem
 phase[9:8]=S  00   00   00   00   00   00  ...  00   01   01  ... 01   10  ... 10   11  ... 11   00
 phase[7:0]=Q  00   00   00   00   01   02  ...  FF   00   01  ... FF   00  ... FF   00  ... FF   00

 digit_sel     00   00   00   00   00   00  ...  00   01   01  ... 01   10  ... 10   11  ... 11   00
 chu so hien   d0   d0   d0   d0   d0   d0  ...  d0   d1   d1  ... d1   d2  ... d2   d3  ... d3   d0
               =4   =4   =4   =4   =4   =4       =4   =3   =3      =3   =2      =2   =1      =1   =4

 seg[6:0]     0x00 0x00 0x00 0x33 0x33 0x33 ... 0x00 0x79 0x79 ...0x00 0x6D ...0x00 0x30 ...0x00 0x33
              (tat vi          └──── 4 ────┘       ^   └── 3 ──┘     ^   └ 2 ┘     ^   └ 1 ┘     ^
               chua enable)                        │                 │             │             │
                                          Q=255 >= brightness=255 ⟹ TAT dung 1 chu ky cuoi moi khe
```

### Đọc ra các bất biến

| Quan sát trên giản đồ | Bất biến được chứng minh |
|---|---|
| `digit_sel` giữ nguyên 256 chu kỳ rồi mới đổi | **INV-3** |
| `digit_sel` đổi đúng lúc `Q` đi từ `FF → 00` | `control.md` §4 — PWM và khe đồng pha tuyệt đối |
| Thứ tự chữ số hiện ra là `4, 3, 2, 1` (tức `d0…d3`) | `reference_model.py::test_four_digits` |
| Chu kỳ `Q = 255` có `seg = 0` dù `brightness = 255` | **duty = 255/256, không phải 100 %** |
| Chu kỳ #3 (ngay sau khi nhả reset) đã lái đúng `0x33` | Không có chu kỳ rác sau reset |

### Bảng mã đoạn trong khung này

| Khe `S` | Chữ số | Giá trị | `seg[6:0]` | hex |
|:-:|---|:-:|---|---:|
| 00 | `d0` | 4 | `0110011` | `0x33` |
| 01 | `d1` | 3 | `1111001` | `0x79` |
| 10 | `d2` | 2 | `1101101` | `0x6D` |
| 11 | `d3` | 1 | `0110000` | `0x30` |

## 2. Phóng to một khe — cơ chế PWM (`brightness = 8'h40 = 64`)

Đây là kích thích thứ ba của testbench (`brightness = 8'h40` ở chu kỳ 2051+).

```
 Trong khe S (256 chu ky), danh so Q = 0..255:

 Q:        0    1    2  ...  62   63   64   65  ...  254  255 │  0    1  ...
           ┌─┐  ┌─┐  ┌─┐     ┌─┐  ┌─┐  ┌─┐  ┌─┐      ┌─┐  ┌─┐ │ ┌─┐  ┌─┐
 clk     ──┘ └──┘ └──┘ └─ ...┘ └──┘ └──┘ └──┘ └─ ... ┘ └──┘ └─┼─┘ └──┘ └── ...
                                                              │
 Q<64 ?   ─────────── DUNG ───────────┐                       │ ──── DUNG ...
                                      └─────── SAI ───────────┤
                                                              │
 seg    ──┬────── 0x33 (chu so 4) ────┬──── 0x00 (tat) ───────┼── 0x33 ...
          │                           │                       │
          └── 64 chu ky SANG ─────────┴── 192 chu ky TAT ──────┘
                                                              ^
                                                     digit_sel doi tai day

 Duty = 64/256 = 25,0 %
```

| `brightness` | Số chu kỳ sáng / khe | Duty | Ghi chú |
|---:|---:|---:|---|
| `8'h00` = 0 | **0** | 0 % | Qua `display_active`, không qua bộ so sánh |
| `8'h01` = 1 | 1 | 0,39 % | Duty nhỏ nhất **khác 0** |
| `8'h40` = 64 | 64 | 25,0 % | Ca testbench |
| `8'hFF` = 255 | 255 | 99,61 % | **Không** phải 100 % |

## 3. Ca "tắt số 0 vô nghĩa ở đầu" — `bcd_digits = 16'h0042`, `blank_leading_zero = 1`

Kích thích thứ hai của testbench (chu kỳ 1027…2050).

```
 Khe:            S=00           S=01           S=10           S=11        │  S=00
                 (256 clk)      (256 clk)      (256 clk)      (256 clk)   │
                                                                          │
 chu so thu:     d0 = 2         d1 = 4         d2 = 0         d3 = 0      │  d0 = 2
 dieu kien tat:  KHONG BAO GIO  d3=0&d2=0&d1=0 d3=0&d2=0      d3=0        │
                                = 0&0&(4!=0)   = 0&0          = 0         │
                                ⟹ KHONG tat    ⟹ TAT          ⟹ TAT       │
 selected_bcd:   4'h2           4'h4           4'hF           4'hF        │  4'h2
                                                                          │
 seg (khi Q<b): ─ 0x6D ────────┬─ 0x33 ───────┬─ 0x00 ───────┬─ 0x00 ────┼─ 0x6D ─
                               │              │              │            │
 Mat nguoi thay:      "     4      2"   →  hien thi la  "  42"            │
                       ^^^^ hai khe trai toi den
```

✅ Khớp `reference_model.py::test_0042` → `[2, 4, None, None]`.

Ca biên đối ngẫu, `bcd_digits = 16'h0000` (kích thích thứ tư của testbench):

```
 Khe:            S=00           S=01           S=10           S=11
 chu so:         d0 = 0         d1 = 0         d2 = 0         d3 = 0
 dieu kien tat:  KHONG BAO GIO  0&0&0 ⟹ TAT    0&0 ⟹ TAT      0 ⟹ TAT
 seg (Q<b):      0x7E           0x00           0x00           0x00
 Mat nguoi thay:        "   0"    ← DUNG: gia tri 0 phai doc duoc
```

✅ Khớp `reference_model.py::test_0000`.

## 4. Ca điều khiển — `enable` hạ giữa khung (ca CA-T5, **chưa có** trong testbench)

```
 Chu ky:      n-1   n    n+1   n+2   n+3
                ┌─┐  ┌─┐  ┌─┐  ┌─┐  ┌─┐
 clk         ───┘ └──┘ └──┘ └──┘ └──┘ └──
             ─────────┐
 enable                └─────────────────    (ha giua khe S=10, Q=130)
                       │
 phase        648  648 │  0    0    0       ← ve 0 tai CANH CLOCK KE (dong bo)
 digit_sel     10   10 │ 00   00   00
             ──────────┐
 display_active        └─────────────────    ← ha NGAY (to hop, 0 chu ky)
 seg          0x6D  0x00  0x00  0x00  0x00   ← tat ngay cung enable
```

> `phase = 648` = `10_1000_1000₂` ⟹ `S = 10`, `Q = 136`. Điểm cần chú ý: `display_active`
> (và do đó `seg`) tắt **trước một chu kỳ** so với khi `phase` về 0. Đó là hai đường khác
> nhau: một tổ hợp, một tuần tự. Trên waveform gate-level có SDF, khoảng lệch này còn cộng
> thêm độ trễ lan truyền.

## 5. Giản đồ lan truyền tổ hợp — đường tới hạn thật (số từ STA)

Đây là phần **không** thấy được trên waveform hành vi. Số lấy từ
`06_GDSII/sta/timing_report_max.txt`, đường `bcd_digits[12] → seg[3]`.

```
  t (ns):  0.0      1.0      1.57     1.71  1.97   2.33  2.49  2.64  2.70          9.00
           │        │        │        │     │      │     │     │     │              │
 bcd_digits[12] ────╳════════════════════════════════════════════════════════════════
                    │ (input delay gia dinh 1,00 ns)
                    │
  _093_ (d3==0)     └──[nor4_1 0,57]──╳═══════════════════════════════════════════════
                                      │
  _021_ (uu tien)                     └[a21oi 0,14]─╳══════════════════════════════════
  _025_ (mux)                                       └[o2111a 0,26]─╳═══════════════════
  _062_ (decode)                                                   └[or3b 0,35]─╳══════
  _063_                                                                         └[and2 0,16]─╳
  _065_                                                                                  └[o21ai 0,14]─╳
  seg[3]                                                                                          └[a21oi 0,06]─╳══
                                                                                                        2,70 ns
                                                                    ├──── VUNG GLITCH ────┤
                                                                    1,00 → 2,70 ns: seg[3] co the
                                                                    lat nhieu lan truoc khi on dinh

  required time = 10,00 − 1,00 (output delay) = 9,00 ns   ⟹  slack = 6,30 ns (MET)
```

**Vùng glitch:** trong khoảng `1,00 → 2,70 ns` sau khi `bcd_digits` đổi, `seg[3]` chưa ổn
định và có thể lật nhiều lần (bảy cổng, các nhánh tới không cùng lúc). Với LED điều đó vô
hại. Với một thanh ghi ở tầng ngoài thì **bắt buộc** phải lấy mẫu sau 2,70 ns cộng lề.

### Ca "tốt nhất" để so sánh

| Đường | Arrival (ns) | Số cổng | Nhận xét |
|---|---:|---:|---|
| `bcd_digits[12] → seg[3]` | **2,70** | 7 | Xấu nhất — đi qua bộ dò `d3==0` |
| `brightness[4] → display_active` | *(slack 7,68 ⟹ arrival ≈ 1,32)* | ~2 | Nông |
| `phase[0] → digit_sel[1]` (reg→reg) | **1,48** | 4 | Bộ đếm — **không** phải nút thắt |
| `rst_n → _216_/RESET_B` | 1,00 | **0** | Chỉ là dây reset; arrival = đúng input delay |

## 6. Thời điểm và độ trễ quan sát được ở mức hệ thống

| Sự kiện | Độ trễ (chu kỳ) | Độ trễ (giả định `f_clk = 10 MHz`, từ `reference_model.py::test_scan`) |
|---|---:|---|
| `bcd_digits` đổi → `seg` đổi | 0 | < 1 chu kỳ (tổ hợp) |
| `bcd_digits` đổi → chữ số đó thực sự hiện | 0 … 1024 | 0 … **102,4 µs** |
| Một khung quét đầy đủ | 1024 | **102,4 µs** ⟹ **9 765,6 Hz** mỗi LED |
| Một chu kỳ PWM | 256 | 25,6 µs ⟹ 39 062,5 Hz |
| `rst_n` nhả → `digit_sel` hợp lệ | 1 | 0,1 µs |

Xem phép tính đầy đủ và đối chiếu ngưỡng 60 Hz ở `implementation-notes_J04.md` §8.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
