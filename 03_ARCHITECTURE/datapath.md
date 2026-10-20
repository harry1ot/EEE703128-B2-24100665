# J04 · Đường dữ liệu (Datapath)

---

## 1. J04 có **hai** đường dữ liệu tách biệt, giao nhau đúng một chỗ

Khác với mạch số học, dữ liệu của J04 không chảy một chiều. Có hai dòng:

```
  DONG A · DU LIEU HIEN THI (to hop thuan, 0 chu ky)
     bcd_digits[15:0] ──▶ chon ──▶ decode7 ──▶ ┐
                                                ├─ AND ──▶ seg[6:0]
  DONG B · DU LIEU THOI GIAN (tuan hoan, tu thanh ghi)             ▲
     phase[9:0] ─┬─ [9:8] ──▶ chon chu so ──────────────────────────┘
                 │        └──▶ digit_sel[1:0]
                 └─ [7:0] ──▶ so sanh < brightness ────────────────▶┘
```

Điểm giao duy nhất là cổng AND cuối (`B6`). Mọi đặc tính thời gian của J04 đều bắt nguồn từ
việc **dòng A hoàn toàn tổ hợp** còn **dòng B hoàn toàn tuần tự**.

## 2. Bảng các đường dữ liệu

| Đường | Độ rộng | Từ | Đến | Bản chất |
|---|---:|---|---|---|
| `bcd_digits[15:0]` | 16 | cổng vào | 3 bộ dò `==0`, mux 4:1 | Dữ liệu hiển thị, **không đăng ký** |
| `blank_leading_zero` | 1 | cổng vào | logic ưu tiên tắt | Điều khiển chế độ (xem `control.md`) |
| `brightness[7:0]` | 8 | cổng vào | so sánh PWM + dò `!=0` | Dữ liệu điều chế |
| `enable` | 1 | cổng vào | `phase` reset đồng bộ + `display_active` | Điều khiển |
| `phase[9:0]` | 10 | thanh ghi (10 FF) | tách làm hai nhánh | **Nguồn duy nhất của thời gian trong khối** |
| `phase[9:8]` = `S` | 2 | thanh ghi | `digit_sel` (dây) + chọn chữ số | Chỉ số khe quét |
| `phase[7:0]` = `Q` | 8 | thanh ghi | so sánh `Q < brightness` | Pha PWM |
| `selected_bcd[3:0]` | 4 | mux + logic tắt | `decode7` | Chữ số đang hiện (`4'hF` = tắt) |
| `seg_raw[6:0]` | 7 | `decode7` | cổng chặn | Mẫu đoạn chưa qua PWM |
| `seg[6:0]` | 7 | cổng chặn | cổng ra | Mẫu đoạn cuối |
| `digit_sel[1:0]` | 2 | `phase[9:8]` | cổng ra | **0 cell logic** — dây thuần |
| `display_active` | 1 | `enable ∧ (brightness≠0)` | cổng ra + cổng chặn | Cờ trạng thái + điều khiển nội bộ |

## 3. Đồ thị phụ thuộc và độ sâu logic

### 3.1 Nhánh `seg[6:0]` — nhánh sâu nhất

```
 muc 0   bcd_digits[15:12]=d3   brightness[7:0]   phase[7:0]=Q   phase[9:8]=S
             │                        │                │              │
 muc 1   [d3==0]  (nor4_1)            │       ┌────────┴──────┐       │
             │                        │       │ so sanh 8 bit │       │
 muc 2   [d3==0 & d2==0]              │       │  Q < b        │       │
             │                        │       │ (chuoi muon   │       │
 muc 3   [...& d1==0]                 │       │  ~4-5 muc)    │       │
             │                        │       └───────┬───────┘       │
 muc 4   logic uu tien tat ◀───────────────────────────────────────────┘
             │  (blank_leading_zero)
 muc 5   mux 4:1 chon chu so ──▶ selected_bcd[3:0]
             │
 muc 6-7 decode7 (AND-OR 2 tang)  ──▶ seg_raw[6:0]
             │
 muc 8   AND voi (display_active & pwm_on) ──▶ seg[6:0]
```

### 3.2 Nhánh `phase` — nhánh nông nhất

```
 muc 0   phase[0]
 muc 1..9  chuoi tang 1 (increment): phase[i+1] lat khi AND cua phase[0..i]
 muc 9   phase[9] → digit_sel[1]
```

### 3.3 Bảng độ sâu

| Đầu ra | Nguồn sâu nhất | Độ sâu logic (mức cổng, ước từ RTL) | Đo được từ STA |
|---|---|---|---|
| `digit_sel[1:0]` | `phase[9:8]` | **0** (dây thuần) | không có đường in→out |
| `display_active` | `brightness[7:0]`, `enable` | ~2 (`nor4` ×2 → `a21boi`) | `brightness[4] → display_active`, slack 7,68 |
| `phase[i]` (reg→reg) | `phase[0]` | ~5 (chuỗi tăng 1, 10 bit) | `_216_ → _225_`, arrival **1,48 ns**, 4 cổng trên đường |
| `seg[6:0]` | `bcd_digits[12]` (bit của `d3`) | **~8** ⬅ **sâu nhất** | `bcd_digits[12] → seg[3]`, arrival **2,70 ns**, **7 cổng** |

## 4. Dự đoán đường tới hạn từ RTL — rồi đối chiếu STA

### Dự đoán trước khi xem STA

Từ cấu trúc RTL, có hai ứng cử viên:

| Ứng cử viên | Lập luận | Dự đoán |
|---|---|---|
| **(a)** Chuỗi so sánh 8 bit `Q < brightness` | So sánh không dấu 8 bit là một chuỗi mượn nối tiếp 8 tầng — giống hệt chuỗi carry. Trực giác "số học thì chậm" | Nhiều người chọn cái này |
| **(b)** `d3 == 0` → ưu tiên tắt → mux → `decode7` → chặn | Bốn tầng **nối tiếp không thể song song hoá**, vì mỗi tầng cần kết quả tầng trước | Dự đoán của tài liệu này |

**Dự đoán:** (b), vì (a) chỉ dài 8 mức *nhưng chạy song song* với (b) và **hợp lưu ở tầng
cuối cùng**; trong khi (b) là 4 khối nối tiếp mà mỗi khối tự nó đã vài mức.

### Đối chiếu với STA thật

`06_GDSII/sta/summary.txt`, dòng thứ hai (đường dữ liệu xấu nhất):

```
bcd_digits[12] (input)      seg[3] (output)       6.30
```

✅ **Dự đoán (b) đúng.** Và trích đường chi tiết còn cho biết nhiều hơn dự đoán:

| Vị trí trên đường | Cell | Delay cộng dồn (ns) | Thuộc khối |
|---|---|---:|---|
| `bcd_digits[12]` vào | — | 1,00 *(input delay giả định)* | — |
| `_138_` | `nor4_1` | 1,57 | **B2** — phép `d3 == 0` |
| `_160_` | `a21oi_1` | 1,71 | B2 — ưu tiên tắt |
| `_164_` | `o2111a_1` | 1,97 | B2 — mux chọn chữ số |
| `_204_` | `or3b_1` | 2,33 | B3 — `decode7` |
| `_205_` | `and2_0` | 2,49 | B3 |
| `_207_` | `o21ai_0` | 2,64 | B3/B6 |
| `_208_` | `a21oi_1` | **2,70** | B6 — cổng chặn, ra `seg[3]` |

**Logic thuần = 2,70 − 1,00 = 1,70 ns** trên 7 cổng.

### Ba điều STA nói mà dự đoán từ RTL **không** nói được

1. **Bộ so sánh PWM không hề xuất hiện trên 7 đường xấu nhất.** Tra `summary.txt`: bảy đường
   tệ nhất nhóm `clk` đều xuất phát từ `bcd_digits[12]`, đường liên quan `brightness` tốt hơn
   (`brightness[4] → display_active`, slack 7,68). Ứng cử viên (a) bị loại **bằng số liệu**.
   Lý do: ABC ánh xạ phép so sánh 8 bit thành cây thay vì chuỗi tuyến tính, còn chuỗi
   `d3==0 → tắt → mux → decode` thì **không thể** làm phẳng vì nó là phụ thuộc dữ liệu thật.

2. **`nor4_1` tốn 0,57 ns** — gần **một phần ba** toàn bộ logic của đường. Cổng 4 đầu vào có
   fanout 6 (`Fanout 6` trong báo cáo) nên slew tới 0,65 ns. Đây là chi phí thật của việc bắt
   **một** tín hiệu (`d3==0`) chi phối **cả ba** khe trên.

3. **Đường reg→reg của bộ đếm chỉ 1,48 ns**, tức bộ đếm 10 bit **không phải** nút thắt —
   trái với trực giác "bộ đếm dài thì chậm". Chuỗi tăng 1 chỉ cần 4 cổng vì ABC dùng
   `and3b_1`/`nand4_1` gom nhiều bit một lúc.

### Giải thích chỗ lệch giữa "đường tới hạn báo cáo" và "đường tới hạn thật"

`timing_report_max.txt` xếp `rst_n → _216_` lên đầu với slack 9,23 ns. Đó là **recovery check**
của reset bất đồng bộ, thuộc `Path Group: asynchronous`, và arrival của nó bằng **đúng**
`set_input_delay 1.0` — không đi qua một cổng nào (`rst_n` nối thẳng vào chân `RESET_B` của
10 flip-flop, `Fanout 10`). Công cụ xếp nó trước chỉ vì thứ tự nhóm, **không phải** vì nó chậm nhất.

> **Bài học đọc báo cáo:** luôn lọc theo `Path Group`. Số dùng để nói về tốc độ thiết kế là
> đường tệ nhất trong nhóm `clk`, ở đây là **6,30 ns slack / 2,70 ns arrival**.

## 5. Vì sao `bcd_digits` **không** có thanh ghi — và điều đó tốn gì

| Câu hỏi | Trả lời | Bằng chứng |
|---|---|---|
| RTL có đăng ký `bcd_digits` không? | Không | `always_ff` chỉ chứa `phase` |
| Hệ quả 1 — thời gian | Đường `bcd_digits → seg` là **in→out tổ hợp**, 2,70 ns; thiết kế **phụ thuộc vào `set_output_delay` của tầng ngoài** | `sta/summary.txt` dòng 2 |
| Hệ quả 2 — chức năng | Xé hình khi đổi dữ liệu giữa khe | `corner_cases.md` CA-T2 |
| Hệ quả 3 — Charter | Thiếu 16 FF so với dấu hiệu mục 10 | `functional_spec.md` cảnh báo |
| Nếu thêm thanh ghi 16 bit thì sao? | +16 `dfrtp_1` = **+400,384 µm²** (16 × 25,024), tức **+43,4 %** diện tích khối hiện tại (922,1344 µm²); đổi lại: cắt đường in→out, khử xé hình, và đúng Charter | Diện tích `dfrtp_1` đọc từ `sky130_fd_sc_hd__tt_025C_1v80.lib` |

> Con số +400,384 µm² là **phép nhân từ diện tích cell thật trong thư viện**, không phải chạy
> tổng hợp lại. Diện tích thật sẽ **cao hơn** một chút vì cần thêm logic `load`. Muốn số chính
> xác phải chạy Yosys lần hai — `⬜ chưa chạy`.

## 6. Phân bổ diện tích theo đường dữ liệu (số thật)

| Nhóm | Cell | Diện tích (µm²) | % |
|---|---:|---:|---:|
| Nón logic `seg` (dòng A + tầng chặn) | 86 | 521,7504 | 56,6 % |
| Nón logic trạng thái kế `phase` (dòng B tổ hợp) | 26 | 150,1440 | 16,3 % |
| 10 × `dfrtp_1` (dòng B tuần tự) | 10 | 250,2400 | 27,1 % |
| **Tổng** | **122** | **922,1344** | **100 %** |

Nguồn: phân tích nón logic trên `06_GDSII/synthesis/netlist.v`, diện tích từng cell lấy từ
`sky130_fd_sc_hd__tt_025C_1v80.lib`; tổng khớp chính xác `synth_stat.txt`.

**Đọc ra:** hơn một nửa diện tích nằm ở **logic hiển thị tổ hợp**, chỉ 27 % là flip-flop.
Điều này trái với công suất đo được (tuần tự **78,0 %**, tổ hợp 22,0 % — `power/power_report.txt`).
Không mâu thuẫn: flip-flop lật **mỗi chu kỳ** (bộ đếm luôn chạy) nên tiêu thụ nhiều, còn logic
hiển thị chỉ đổi khi `digit_sel` hoặc ngưỡng PWM đổi — tức vài lần trong 256 chu kỳ.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
