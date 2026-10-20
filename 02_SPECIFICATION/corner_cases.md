# J04 · Ca biên và lý do kỹ thuật (Corner Cases)

Tài liệu này **đọc testbench thật** (`05_VERIFICATION/testbench/j04_display_core_tb.sv`, 44 dòng)
và mô hình chuẩn thật (`05_VERIFICATION/golden_model/reference_model.py`) rồi đối chiếu với
Charter mục 8. Mục đích không phải liệt kê ca, mà nói **vì sao** mỗi ca tồn tại và **ca nào
còn thiếu**.

---

## 0. Cảnh báo về ý nghĩa của chữ "PASS"

`BRIEF J04` ghi *Mô phỏng RTL: **PASS***. Phải hiểu chính xác chữ này. Đọc testbench:

```systemverilog
    repeat(1024) @(posedge clk);
    ...
    $display("J04 RTL testbench completed");
    $finish;
```

Testbench **không có một `assert`, một `$fatal`, hay một phép so sánh nào**. Nó chỉ lái kích
thích rồi in `"J04 RTL testbench completed"`. Log mô phỏng xác nhận:

```
J04 RTL testbench completed
j04_display_core_tb.sv:42: $finish called at 40985 (1s)
```

> ❗ **Kết luận:** "PASS" ở lớp L2 của J04 chỉ chứng minh **RTL biên dịch và chạy 4096 chu kỳ
> không treo, không sinh `X` gây `$fatal`**. Nó **không** chứng minh giá trị `seg` đúng, thứ
> tự quét đúng, hay duty PWM đúng. Mô hình chuẩn Python PASS 7/7 nhưng **chưa bao giờ được
> nối vào RTL** — không có scoreboard. Đây là khoảng trống kiểm chứng lớn nhất của đề này và
> phải nói rõ khi bảo vệ.

Con số biết nói: `$finish` ở thời điểm `40985`. Chu kỳ clock là 10 (`always #5 clk=~clk`),
`repeat(3)` + 4×`repeat(1024)` = 4099 cạnh lên ⟹ `3 + 4096 = 4099` cạnh, cạnh cuối ở
`t = 5 + 4098×10 = 40985`. ✅ Khớp chính xác — testbench đã chạy đúng **4 khung quét đầy đủ**
(4096 chu kỳ = 4 × 1024).

---

## 1. Ca bắt buộc của Charter mục 8 — có trong testbench không?

| # | Ca Charter yêu cầu | Testbench có kích thích? | Có **kiểm** kết quả? | Lý do kỹ thuật của ca |
|:-:|---|:-:|:-:|---|
| 1 | Bốn chữ số khác nhau | ✅ `bcd_digits = 16'h1234`, 1024 clk | ❌ | Bốn giá trị khác nhau là cách duy nhất phát hiện **lỗi ánh xạ khe → chữ số** (ví dụ đảo `d0`/`d3`). Nếu bốn chữ số giống nhau, mọi hoán vị đều "đúng". |
| 2 | Số có 0 ở đầu (kiểm chế độ tắt) | ✅ `16'h0042` + `blank_leading_zero=1` | ❌ | Kích hoạt **cả ba** so sánh `d3==0`, `d2==0`, `d1==0` với kết quả khác nhau: khe 3 và 2 tắt, khe 1 hiện `4`. Đây là ca duy nhất phân biệt được logic ưu tiên đúng/sai. |
| 3 | Đổi độ sáng | ✅ `brightness` 8'hFF → 8'h40 | ❌ | Đổi duty từ 255/256 sang 64/256 kiểm **bộ so sánh `Q < brightness`**. Đặc biệt kiểm rằng đổi `brightness` giữa chừng không làm lệch pha quét. |
| 4 | Kiểm chu kỳ quét trên waveform | ✅ chạy đủ 4 khung | ❌ *(không có `$dumpvars`)* | Đây là ca **bắt buộc quan sát bằng mắt**. Nhưng testbench **không gọi `$dumpfile`/`$dumpvars`** nên **không sinh file VCD** — ca này hiện **chưa có bằng chứng**. |

**Phán xử mục 1:** 4/4 ca có kích thích, **0/4 ca có kiểm tự động**, **1/4 ca (số 4) không thu
được artifact**. Trạng thái đúng của `test_matrix.csv` TC-001 nên là "kích thích đã chạy,
chưa tự kiểm" chứ không phải PASS trần.

---

## 2. Ca có trong mô hình chuẩn Python nhưng **chưa** nối vào RTL

`reference_model.py` PASS 7/7 (`python_reference_run.log`). Bảy ca đó đang kiểm **đặc tả**,
không kiểm **RTL**:

| Hàm test | Kiểm điều gì | Có ca RTL tương ứng? |
|---|---|:-:|
| `test_four_digits` | thứ tự khe 0→3 ứng với `d0→d3` | kích thích có, kiểm không |
| `test_0042` | ưu tiên tắt số 0 đầu | kích thích có, kiểm không |
| `test_0000` | hàng đơn vị **không** bị tắt | ✅ có kích thích (`16'h0000`), kiểm không |
| `test_9999` | không chữ số nào bị tắt khi `d3 != 0` | ❌ **không có** kích thích RTL |
| `test_brightness` | `pwm(0,0)=false`, `pwm(255,255)=false` | ❌ `brightness = 0` **chưa bao giờ** được lái |
| `test_scan` | `10 MHz / 1024 > 60 Hz` | ❌ chỉ là phép tính trên giấy |
| `test_phase` | phân rã `phase` thành `[9:8]` và `[7:0]` | ✅ ngầm |

> 🔎 **Phát hiện đáng chú ý:** `test_brightness` khẳng định `not pwm(0,0)` — tức
> `brightness = 0` phải tắt. Nhưng testbench RTL chỉ dùng `8'hFF` và `8'h40`; **giá trị 0 chưa
> bao giờ chạm tới RTL**. Đây là ca biên quan trọng nhất của nhánh `display_active` mà lại
> đang trống.

---

## 3. Ca tự xây dựng bổ sung (yêu cầu Charter mục 8: ≥ 2, có ca biên)

| ID | Ca | Là ca biên? | Vì sao cần | Cách kiểm |
|---|---|:-:|---|---|
| **CA-T1** | `brightness = 8'h00` với `enable = 1` | ✅ | Ca biên dưới của PWM. Kiểm nhánh `display_active = enable && (brightness != 0)` — nhánh duy nhất **không** đi qua bộ so sánh. Nếu ai đó sửa `display_active` thành `enable` thuần, mọi ca khác vẫn PASS, chỉ ca này bắt được. | Giữ 1024 clk, khẳng định `seg == 0` và `display_active == 0` ở **mọi** chu kỳ |
| **CA-T2** | Đổi `bcd_digits` **giữa** một khe quét (ví dụ ở `phase[7:0] == 128`) | | Phơi bày hiện tượng **tearing**: vì `seg` là tổ hợp thuần, nửa sau của khe hiện chữ số mới còn nửa đầu hiện chữ số cũ. Trên LED thật cho ra ảnh chồng mờ. Đây là hệ quả trực tiếp của việc **không có thanh ghi nạp chữ số** (xem cảnh báo ở `functional_spec.md`). | Ghi lại `seg` từng chu kỳ trong khe, khẳng định có **đúng một** lần đổi giá trị không do PWM |
| **CA-T3** | `bcd_digits = 16'h9999`, `blank_leading_zero = 1` | ✅ (biên trên) | Ca đối ngẫu của `16'h0000`: **không** chữ số nào bị tắt. Cùng với `0000` nó kẹp hai đầu của logic ưu tiên tắt. `reference_model.py::test_9999` đã có, RTL thì chưa. | 1024 clk, khẳng định cả 4 khe đều ra mã `0x7B` |
| **CA-T4** | `bcd_digits` chứa nibble `4'hA..4'hF` (ví dụ `16'h1A2B`) | ✅ | Đầu vào **ngoài miền BCD**. Đặc tả nói `decode7` trả `0`. Cần chốt bằng ca thật để sau này không ai "cải tiến" thành hiện chữ A–F rồi phá `INV-7`. | Khẳng định khe của nibble lạ có `seg == 0` |
| **CA-T5** | `enable` hạ rồi nâng ở giữa khung | | Kiểm `INV-10`: `phase` phải về 0 ⟹ khung mới **bắt đầu lại từ `d0`**, không tiếp tục từ chữ số đang dở. Bắt lỗi kinh điển "quên nhánh `else if (!enable)`". | Khẳng định `digit_sel == 00` ở chu kỳ ngay sau khi `enable` lên lại |
| **CA-T6** | Đếm số chu kỳ `seg != 0` trong một khe, so với `brightness` | | Đây là **phép đo duty thật**, tức là ca duy nhất thực sự chứng minh PWM đúng. Charter mục 2 câu 2 hỏi đúng điều này. | Đếm trong khe `S = 0`; kết quả phải bằng đúng `brightness` khi chữ số không bị tắt |

## 4. Phân loại ca theo tiêu chí kỹ thuật riêng của J04

Đề này có **ba trục độc lập**. Một bộ ca tốt phải phủ tích của ba trục, không phải liệt kê
ngẫu nhiên.

```
   Truc 1: KHE QUET S      0 ── 1 ── 2 ── 3          (4 gia tri, tuan hoan)
   Truc 2: TAT SO 0 DAU    tat ── khong tat          (2 nhanh, co uu tien noi tiep)
   Truc 3: PHA PWM Q       Q < b ── Q >= b           (2 vung trong moi khe)
```

| Lớp ca | Trục nào bị ép | Ca đại diện đang có | Ca còn thiếu |
|---|---|---|---|
| **L-SCAN** — phủ đủ 4 khe | 1 | `16'h1234` (4 chữ số khác nhau) | — |
| **L-BLANK-0** — không nhánh tắt nào kích hoạt | 2 | `16'h1234`, `blank=0` | `16'h9999`, `blank=1` (CA-T3) |
| **L-BLANK-1** — tắt một phần | 2 | `16'h0042` (tắt 2/4) | tắt đúng 1/4 (ví dụ `16'h0123`) |
| **L-BLANK-2** — tắt tối đa | 2 | `16'h0000` (tắt 3/4) | — |
| **L-PWM-HI** — duty gần đầy | 3 | `brightness = 8'hFF` | — |
| **L-PWM-MID** — duty vừa | 3 | `brightness = 8'h40` | — |
| **L-PWM-OFF** — duty 0 | 3 | — | **CA-T1** ❗ |
| **L-XDOMAIN** — đầu vào ngoài miền | — | — | **CA-T4** |
| **L-CTRL** — điều khiển `enable` | — | — | **CA-T5** |

Bộ ca hiện tại phủ **6/9 lớp**. Ba lớp trống đều là ca biên hoặc ca điều khiển.

## 5. Ca **KHÔNG** áp dụng cho đề này

| Ca thường gặp ở đề khác | Vì sao không áp dụng cho J04 | Bằng chứng |
|---|---|---|
| Ca **tràn số học** (overflow/carry-out) | J04 không làm phép toán nào. Bộ đếm `phase` tràn `1023→0` là **hành vi mong muốn**, không phải lỗi tràn. | RTL không có toán tử `+` nào ngoài `phase + 10'd1` |
| Ca **bắt tay (handshake) / backpressure** | Không có `ready`/`ack`. Khối lái LED **vô điều kiện**; tầng ngoài không được phép chặn. | Bảng cổng trong `interface.md` — không có tín hiệu bắt tay |
| Ca **vượt miền clock (CDC)** | Chỉ một clock `clk`, không có clock thứ hai. | Netlist: chỉ một net `clk` nối vào 10 `dfrtp_1` |
| Ca **trạng thái FSM bất hợp lệ** | Không có FSM mã hoá tường minh; "trạng thái" là bộ đếm nhị phân 10 bit **phủ kín** `0..1023`, không có tổ hợp bất hợp lệ nào. | Xem `fsm.md` |
| Ca **số âm / bù 2** | Mọi giá trị đều **không dấu**: BCD, pha, độ sáng. | RTL khai báo `logic`, không `logic signed` |
| Ca **đọc/ghi bộ nhớ** | `Number of memories: 0` | `06_GDSII/synthesis/synth_stat.txt` |

## 6. Ca phải **bổ sung** khi chuyển sang gate-level và post-layout

| Mức | Ca mới cần có | Vì sao chỉ xuất hiện ở mức này |
|---|---|---|
| **Gate-level (L4)** | Chạy lại toàn bộ 6 ca ở §3 trên `06_GDSII/synthesis/netlist.v` | Kiểm rằng Yosys/ABC không đổi hành vi khi gộp `decode7` với logic tắt. Đặc biệt nguy hiểm vì hai khối này **đã bị gộp**: netlist chỉ còn 86 cell cho toàn bộ đường `seg`. |
| **Gate-level (L4)** | Ca `X`-propagation: thả `bcd_digits = 16'hxxxx` trước khi tầng ngoài nạp dữ liệu | RTL hành vi che `X` qua `case`; netlist gate-level thì không. Đây là chỗ RTL-PASS / gate-FAIL kinh điển. |
| **Gate-level (L4)** | Ca reset bất đồng bộ: hạ `rst_n` **không** canh cạnh clock | Kiểm `recovery/removal` thật. STA đã báo đường `rst_n → _216_` slack 9,23 ns nhưng đó là **tĩnh**, chưa có mô phỏng động. |
| **Post-layout (L5)** | Lặp lại với SDF back-annotate | Đường `bcd_digits[12] → seg[3]` hiện dài 2,70 ns **tổ hợp thuần từ chân vào tới chân ra** (`sta/timing_report_max.txt`). Sau routing, RC dây sẽ kéo dài. Nếu tầng ngoài chốt `seg` bằng một thanh ghi, đây là đường phải kiểm lại. |
| **Post-layout (L5)** | Ca **glitch** trên `seg` khi `phase[7:0]` vượt ngưỡng `brightness` | Bộ so sánh 8 bit đổi trạng thái ở đúng một chu kỳ; trên silicon nó tạo xung nhiễu ns trên cả 7 đoạn. Mô phỏng zero-delay **không bao giờ** thấy. LED không nhìn thấy glitch ns, nhưng nếu tầng ngoài dùng `seg` để lái mạch chốt thì thấy. |
| **Mọi mức** | Ca đo **công suất theo `f_clk`** | Công suất đo được (5,52e-05 W) gắn chặt với giả định `f_clk`. Xem `implementation-notes_J04.md` §8. |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
