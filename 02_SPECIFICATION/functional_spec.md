# J04 · Đặc tả chức năng (Functional Specification)

> ## ⚠️ CẢNH BÁO ĐỐI CHIẾU CHARTER — TRẠNG THÁI: **CHƯA THOẢ**
>
> RTL trong hồ sơ (`04_IMPLEMENTATION/rtl/j04_display_core.sv`) **không khớp** ánh xạ chân
> mà Charter mục 4 yêu cầu, và **không khớp** dấu hiệu quy mô của Charter mục 10.
> Bảng đối chiếu dưới đây lập từ mã nguồn thật và từ `06_GDSII/synthesis/synth_stat.txt`.
>
> | Charter yêu cầu | RTL thật có | Phán xử |
> |---|---|---|
> | `ui_in[7:0]` = **hai chữ số, nạp 2 lần** | `bcd_digits[15:0]` — **bốn chữ số song song, nạp một lần** | ❌ Thiếu cơ chế nạp hai nhịp |
> | `uio_in[2:0]` = độ sáng (**3 bit**) | `brightness[7:0]` (**8 bit**) | ❌ Sai độ rộng (rộng hơn 5 bit) |
> | `uo_out[6:0]` = đoạn | `seg[6:0]` | ✅ Khớp |
> | `uio_out[3:0]` = chọn LED (**4 bit**, hiểu là one-hot) | `digit_sel[1:0]` (**2 bit nhị phân**) | ❌ Sai mã hoá và độ rộng |
> | Mục 10 — dấu hiệu làm đúng: **≈34–38 ô nhớ** | **10 flip-flop** (`synth_stat.txt`) | ❌ Thiếu ~24–28 FF |
> | Ngân sách chân: 22/24 | RTL cần **38 bit** (28 vào + 10 ra) — `02_SPECIFICATION/interface.md` §3 | ❌ Vượt 14 bit |
>
> **Nguyên nhân gốc của chênh lệch FF:** Charter tính 4×4 bit thanh ghi chữ số + 2 bit chọn
> LED + 8 bit PWM + 8 bit chia quét ≈ 34–38 FF. RTL thật **không đăng ký chữ số** —
> `bcd_digits` đi thẳng vào logic tổ hợp — nên biến mất 16 FF; đồng thời RTL **gộp** bộ chia
> quét và bộ đếm PWM thành **một bộ đếm 10 bit duy nhất** nên chỉ còn 10 FF thay vì 8+8+2=18.
> Netlist xác nhận: `phase[7:0]` ×8 + `digit_sel[1:0]` ×2 = **đúng 10** `dfrtp_1`.
>
> **Đánh giá:** việc gộp hai bộ đếm là một quyết định kiến trúc **tốt** (xem `control.md` §4),
> nhưng việc thiếu thanh ghi nạp chữ số và thiếu cơ chế nạp hai nhịp là **thiếu so với Charter
> mục 4**. Theo §0.2 của SPEC, **không tự sửa RTL**; cần giảng viên duyệt hướng xử lý.
>
> Phần còn lại của tài liệu này đặc tả **hành vi mà RTL thật đang có**, để mọi phân tích phía
> sau bám đúng mã nguồn. Chỗ nào Charter đòi mà RTL chưa có thì ghi rõ `⬜ CHƯA THOẢ`.

---

## 1. Chức năng ở mức hệ thống

J04 là **bộ điều khiển quét đa hợp (time-multiplexed scan)** cho bốn LED 7 đoạn dùng chung
một đường dữ liệu 7 bit. Tại mỗi thời điểm **đúng một** chữ số được lái ra `seg[6:0]`, và
`digit_sel[1:0]` cho tầng ngoài biết chữ số đó thuộc vị trí nào. Mắt người tích hợp bốn ảnh
nhấp nháy đó thành một số bốn chữ số liên tục — đây là cơ chế vật lý mà khối dựa vào.

Khối làm **ba việc chồng lên nhau trên cùng một bộ đếm**:

1. **Quét (scan)** — chọn tuần tự chữ số 0 → 1 → 2 → 3 → 0 …
2. **Giải mã** — BCD 4 bit → 7 đoạn.
3. **Điều chế độ rộng xung (PWM)** — chặn `seg` trong một phần của mỗi khe quét để giảm độ sáng.

## 2. Bảng hành vi của từng đầu ra

Ký hiệu: `P = phase[9:0]` (bộ đếm nội bộ), `S = P[9:8]` (chỉ số chữ số), `Q = P[7:0]` (pha PWM),
`d3..d0 = bcd_digits[15:12], [11:8], [7:4], [3:0]`.

### 2.1 `digit_sel[1:0]`

| Điều kiện | Giá trị |
|---|---|
| mọi lúc | `digit_sel = P[9:8]` — **thuần tổ hợp từ thanh ghi**, không có logic xen giữa |

`digit_sel` mã hoá **nhị phân** (00,01,10,11), **không** one-hot. `⬜ CHƯA THOẢ` Charter mục 4
(đòi 4 bit). Tầng ngoài phải tự giải mã 2→4 nếu cần lái anode/cathode.

### 2.2 `display_active`

```
display_active = enable AND (brightness != 8'h00)
```

Thuần tổ hợp, **không qua thanh ghi**. Là tín hiệu "khối đang thực sự hiển thị", dùng cho cả
việc chặn `seg`. Lưu ý: `brightness == 0` được đặc tả là **tắt hoàn toàn**, không phải "duty 0/256".

### 2.3 `selected_bcd` (nội bộ) — chọn chữ số + tắt số 0 vô nghĩa

Khi `blank_leading_zero = 0`:

| `S` | `selected_bcd` |
|:-:|---|
| 0 | `d0` |
| 1 | `d1` |
| 2 | `d2` |
| 3 | `d3` |

Khi `blank_leading_zero = 1` (mã hoá "tắt" bằng giá trị canh gác `4'hF`):

| `S` | Điều kiện tắt | `selected_bcd` |
|:-:|---|---|
| 3 | `d3 == 0` | `4'hF` ngược lại `d3` |
| 2 | `d3 == 0 ∧ d2 == 0` | `4'hF` ngược lại `d2` |
| 1 | `d3 == 0 ∧ d2 == 0 ∧ d1 == 0` | `4'hF` ngược lại `d1` |
| 0 | **không bao giờ tắt** | `d0` |

> Chữ số hàng đơn vị **luôn hiện**, kể cả khi bằng 0. Đây là quy ước đúng của hiển thị số:
> giá trị 0 phải đọc được là `"   0"` chứ không phải màn hình trống. Mô hình chuẩn
> `reference_model.py::test_0000` kiểm đúng tính chất này.

### 2.4 `seg[6:0]`

```
seg_raw = 7'b0000000                      nếu selected_bcd == 4'hF
        = decode7(selected_bcd)            ngược lại

seg     = seg_raw                          nếu display_active ∧ (Q < brightness)
        = 7'b0000000                       ngược lại
```

Bảng `decode7` đọc trực tiếp từ RTL (bit `[6]` là đoạn a … bit `[0]` là đoạn g, mức tích cực **cao**):

| BCD | `seg[6:0]` nhị phân | hex | BCD | `seg[6:0]` nhị phân | hex |
|:-:|---|---:|:-:|---|---:|
| 0 | `1111110` | `0x7E` | 5 | `1011011` | `0x5B` |
| 1 | `0110000` | `0x30` | 6 | `1011111` | `0x5F` |
| 2 | `1101101` | `0x6D` | 7 | `1110000` | `0x70` |
| 3 | `1111001` | `0x79` | 8 | `1111111` | `0x7F` |
| 4 | `0110011` | `0x33` | 9 | `1111011` | `0x7B` |
| A–F (10–15) | `0000000` | `0x00` | | (dùng làm mã "tắt") | |

## 3. Hành vi tuần tự — bộ đếm `phase`

| Điều kiện (ưu tiên từ trên xuống) | `phase` chu kỳ sau |
|---|---|
| `rst_n == 0` (bất đồng bộ) | `10'd0` |
| `enable == 0` | `10'd0` |
| ngược lại | `phase + 1` (tràn tự nhiên `1023 → 0`) |

**Trạng thái sau reset:** `phase = 0` ⟹ `digit_sel = 00`, `Q = 0`.
Vì `Q = 0 < brightness` với mọi `brightness ≥ 1`, chu kỳ đầu tiên sau reset **đã** lái đúng
chữ số `d0`. Không có chu kỳ "rác".

**Độ trễ từ đầu vào tới đầu ra:**

| Đường | Độ trễ (chu kỳ) |
|---|:-:|
| `bcd_digits` → `seg` | **0** (thuần tổ hợp) |
| `brightness` → `seg` | **0** |
| `blank_leading_zero` → `seg` | **0** |
| `enable` → `display_active` | **0** |
| `enable` → `digit_sel` | **1** (qua `phase`) |
| `bcd_digits` → chữ số đó **hiện ra mắt người** | tới **1024** chu kỳ (chờ khe quét của nó) |

> Dòng cuối là điểm quan trọng: **độ trễ logic bằng 0 nhưng độ trễ cảm nhận được bằng một khung
> quét.** Đổi `bcd_digits` giữa chừng làm chữ số đang sáng đổi ngay lập tức → hiện tượng "xé
> hình" (tearing). Xem `corner_cases.md` §3 CA-T2.

## 4. Chu kỳ quét và PWM — quan hệ số học

Với `f_clk` là tần số clock:

| Đại lượng | Công thức | Suy từ |
|---|---|---|
| Số clock cho một khe chữ số | `2^8 = 256` | `Q = phase[7:0]` |
| Số clock cho một khung 4 chữ số | `2^10 = 1024` | `phase` 10 bit |
| Tần số làm tươi mỗi LED | `f_refresh = f_clk / 1024` | mỗi LED sáng 1 lần/khung |
| Tần số PWM | `f_pwm = f_clk / 256` | một chu kỳ PWM mỗi khe |
| Duty cycle | `brightness / 256` | so sánh `Q < brightness` |

**Miền duty thực tế: `0` (khi `brightness = 0`, qua `display_active`) và `1/256 … 255/256`.
Không bao giờ đạt 100 %.** `brightness = 255` cho duty 255/256 ≈ 99,61 %.

## 5. Tính chất bất biến (invariants) — dùng làm assertion

| ID | Phát biểu | Kiểm bằng |
|---|---|---|
| **INV-1** | `digit_sel == phase[9:8]` tại mọi thời điểm | assertion tổ hợp; hoặc so `digit_sel` với bộ đếm tham chiếu của testbench |
| **INV-2** | Sau khi `rst_n` lên 1 và `enable == 1`, `phase` tăng đúng 1 mỗi cạnh lên `clk`, không bỏ giá trị nào trong `0..1023` | đếm 1024 cạnh, kiểm `phase` đi qua đủ 1024 giá trị khác nhau |
| **INV-3** | `digit_sel` giữ nguyên đúng **256** chu kỳ liên tiếp rồi mới đổi | đo độ dài khe trên waveform |
| **INV-4** | `display_active == 0` ⟹ `seg == 7'b0000000` | assertion tổ hợp |
| **INV-5** | `brightness == 0` ⟹ `seg == 7'b0000000` với mọi `phase` | quét đủ 1024 pha |
| **INV-6** | Trong một khe quét, số chu kỳ có `seg != 0` bằng đúng `brightness` khi `display_active == 1` và `selected_bcd != 4'hF` | đếm trên waveform, so với `brightness` |
| **INV-7** | `blank_leading_zero == 0` ⟹ `seg` luôn là một trong 10 mã hợp lệ của `decode7` (hoặc `0` do PWM), không bao giờ là mã lạ | so bảng |
| **INV-8** | `blank_leading_zero == 1 ∧ d0 == 0 ∧ d1 == d2 == d3 == 0` ⟹ khe `S = 0` vẫn hiện mã của số 0 (`0x7E`) | ca `bcd_digits = 16'h0000` |
| **INV-9** | Tắt số 0 đầu là **đơn điệu**: nếu chữ số ở vị trí `i` bị tắt thì mọi chữ số ở vị trí `> i` cũng bị tắt | duyệt 4 khe của một khung |
| **INV-10** | `enable == 0` ⟹ `phase == 0` ở chu kỳ kế tiếp ⟹ `digit_sel == 00` | assertion tuần tự |

## 6. Điều kiện biên và hành vi không xác định

| Tình huống | Hành vi đặc tả | Ghi chú |
|---|---|---|
| `bcd_digits` chứa nibble > 9 (A–F) | `decode7` trả `7'b0000000` — chữ số **tắt** | Hợp lệ nhưng **không phân biệt được** với "bị PWM chặn" hay "bị blank". Nhập nhằng có chủ ý, xem §7 |
| `brightness == 0` | Toàn bộ hiển thị tắt qua `display_active` | Không phải duty 0/256 |
| `brightness == 255` | Duty 255/256, **không** phải 100 % | Nguồn gốc: so sánh `<` chứ không `<=` |
| `enable` hạ giữa khe quét | `phase` về 0 **ngay cạnh clock kế tiếp** ⟹ khe đang chạy bị cắt cụt | Khe của `d0` sau đó bắt đầu lại từ đầu; không mất đồng bộ PWM |
| `rst_n` hạ bất đồng bộ | `phase = 0` tức thì, không chờ clock | Là `always_ff @(posedge clk or negedge rst_n)` |
| `bcd_digits` đổi giữa khe | `seg` đổi **ngay** (0 chu kỳ) | Tearing — xem `corner_cases.md` CA-T2 |
| `blank_leading_zero` đổi giữa khe | `seg` đổi ngay | Có thể tạo nháy một khe |
| `clk` chưa chạy | `seg` vẫn hợp lệ theo `bcd_digits` và `phase` hiện tại | Mạch ra là tổ hợp, không cần clock |

## 7. Ràng buộc cấu trúc bắt buộc

Tên đề chốt **"phương pháp quét đa hợp"**. Điều đó buộc RTL phải:

1. **Chỉ lái một chữ số tại một thời điểm.** ✅ Thoả — chỉ có một `seg[6:0]` và một `digit_sel`.
2. **Có bộ đếm quét tuần hoàn.** ✅ Thoả — `phase[9:8]`.
3. **Không được nhân bản bốn bộ giải mã 7 đoạn.** ✅ Thoả — chỉ một hàm `decode7`, netlist
   cho thấy vùng logic `seg` chỉ 86 cell (xem `datapath.md` §4); bốn bộ giải mã song song sẽ
   tốn khoảng gấp ba lần.
4. **PWM phải nằm *trong* khe quét, không cắt ngang khe.** ✅ Thoả một cách mạnh: `Q` là
   **phần thấp của chính bộ đếm quét**, nên chu kỳ PWM và khe quét đồng bộ tuyệt đối theo
   xây dựng. Đây là cách triệt tiêu rủi ro Charter mục 10 nêu.

Ràng buộc **chưa thoả**:

5. **Nạp hai nhịp cho `ui_in[7:0]`** — `⬜ CHƯA THOẢ`, RTL không có thanh ghi nạp nào.
6. **`digit_sel` 4 bit** — `⬜ CHƯA THOẢ`, RTL dùng 2 bit nhị phân.
7. **`brightness` 3 bit** — `⬜ CHƯA THOẢ`, RTL dùng 8 bit.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
