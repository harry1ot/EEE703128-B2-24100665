# J04 · Máy trạng thái (FSM)

---

## 1. Kết luận: J04 **không có FSM mã hoá tường minh** — nhưng **có** máy trạng thái

Phải phân biệt hai điều khác nhau mà sinh viên hay gộp:

| Khái niệm | J04 có? | Bằng chứng |
|---|:-:|---|
| **Mạch tuần tự có trạng thái** | ✅ Có | 10 `dfrtp_1`; công suất nhóm Sequential = **78,0 %** |
| **FSM mã hoá tường minh** (`typedef enum`, `case (state)`, `next_state`) | ❌ Không | RTL không có từ khoá `enum`, không có biến `state`, không có `case` trên trạng thái |
| **Máy trạng thái theo nghĩa toán học** | ✅ Có | Bộ đếm 1024 trạng thái, hàm chuyển là `+1` |

Bằng chứng công cụ: Yosys chạy `fsm` pass trong `synth.ys` (dòng `fsm` giữa hai `opt`).
`yosys.log` **không** báo phát hiện hay trích xuất FSM nào. Với một thiết kế có
`typedef enum` + `case(state)`, pass này thường in `Extracting FSM ...`.

## 2. Vậy trạng thái của J04 là gì

```
  Khong gian trang thai = { phase | phase ∈ [0, 1023] }   ⟹ 1024 trang thai

  Ham chuyen:
      δ(phase, rst_n=0)              = 0
      δ(phase, rst_n=1, enable=0)    = 0
      δ(phase, rst_n=1, enable=1)    = (phase + 1) mod 1024

  Ham ra (Moore mot phan, Mealy mot phan — xem §4):
      digit_sel      = phase[9:8]
      seg            = f(phase, bcd_digits, brightness, blank_leading_zero, enable)
      display_active = g(enable, brightness)
```

Vẽ đủ 1024 trạng thái là vô nghĩa. Cách đúng là vẽ **trạng thái gộp theo khe quét** —
đây chính là "FSM" mà người thiết kế nghĩ trong đầu:

```
                   rst_n=0  hoac  enable=0
       ┌──────────────────────────────────────────────┐
       │                                              │
       ▼                                              │
  ╔═════════╗  256 clk  ╔═════════╗  256 clk  ╔═════════╗  256 clk  ╔═════════╗
  ║ KHE 0   ║──────────▶║ KHE 1   ║──────────▶║ KHE 2   ║──────────▶║ KHE 3   ║
  ║ S = 00  ║           ║ S = 01  ║           ║ S = 10  ║           ║ S = 11  ║
  ║ hien d0 ║           ║ hien d1 ║           ║ hien d2 ║           ║ hien d3 ║
  ╚═════════╝           ╚═════════╝           ╚═════════╝           ╚═════════╝
       ▲                                                                  │
       └──────────────────────── 256 clk ─────────────────────────────────┘

  Trong MOI khe, Q = phase[7:0] chay tron 0 → 255:
       Q ∈ [0, brightness-1]   ⟹ seg = seg_raw   (LED sang)
       Q ∈ [brightness, 255]   ⟹ seg = 0         (LED tat)
```

## 3. Bảng chuyển trạng thái (mức khe)

| Trạng thái hiện tại | `rst_n` | `enable` | `Q` (`phase[7:0]`) | Trạng thái kế | Ghi chú |
|---|:-:|:-:|---|---|---|
| bất kỳ | 0 | × | × | **KHE 0**, `Q = 0` | Reset bất đồng bộ |
| bất kỳ | 1 | 0 | × | **KHE 0**, `Q = 0` | Dừng đồng bộ, không giữ vị trí |
| KHE 0 | 1 | 1 | `< 255` | KHE 0, `Q+1` | Còn trong khe |
| KHE 0 | 1 | 1 | `= 255` | **KHE 1**, `Q = 0` | Tràn `Q` ⟹ sang khe kế |
| KHE 1 | 1 | 1 | `< 255` | KHE 1, `Q+1` | |
| KHE 1 | 1 | 1 | `= 255` | **KHE 2**, `Q = 0` | |
| KHE 2 | 1 | 1 | `< 255` | KHE 2, `Q+1` | |
| KHE 2 | 1 | 1 | `= 255` | **KHE 3**, `Q = 0` | |
| KHE 3 | 1 | 1 | `< 255` | KHE 3, `Q+1` | |
| KHE 3 | 1 | 1 | `= 255` | **KHE 0**, `Q = 0` | Kết thúc một khung |

## 4. Mealy hay Moore — và bằng chứng

Câu trả lời đúng của J04 là **lai (hybrid)**, và điều đó nhìn thấy được từ RTL:

| Đầu ra | Phụ thuộc trạng thái? | Phụ thuộc đầu vào **trực tiếp**? | Phân loại | Dòng RTL |
|---|:-:|:-:|---|---|
| `digit_sel[1:0]` | ✅ chỉ trạng thái | ❌ | **Moore thuần** | `assign digit_sel = phase[9:8];` (dòng 17) |
| `display_active` | ❌ | ✅ chỉ đầu vào | **không phải đầu ra của FSM** — logic tổ hợp độc lập | dòng 18 |
| `seg[6:0]` | ✅ (`phase`) | ✅ (`bcd_digits`, `brightness`, `blank_leading_zero`, `enable`) | **Mealy** | `always_comb` dòng 67–80 |

**Bằng chứng Mealy cho `seg`:** đường tới hạn thật trong STA là
`bcd_digits[12] (input) → seg[3] (output)` — một đường **tổ hợp thuần từ chân vào tới chân
ra**, không qua flip-flop nào. Nếu `seg` là Moore, đường này không tồn tại; STA sẽ chỉ thấy
`reg → out`. Đây là cách **dùng báo cáo STA để chứng minh loại FSM**.

**Hệ quả thực tế của tính Mealy:** `seg` thừa hưởng mọi glitch của `bcd_digits`. Trên LED là
vô hại (mắt tích phân), nhưng nếu tầng ngoài chốt `seg` bằng thanh ghi thì phải canh cạnh.

## 5. Mã hoá trạng thái

| Thuộc tính | Giá trị | Nhận xét |
|---|---|---|
| Kiểu mã hoá | **Nhị phân (binary)**, ngầm định bởi phép `+1` | Không phải one-hot, không phải Gray |
| Số bit | 10 | `2^10 = 1024` = đúng số trạng thái |
| Số trạng thái **hợp lệ** | 1024 | |
| Số tổ hợp bit **bất hợp lệ** | **0** | Không gian mã **phủ kín** |
| Trạng thái reset | `10'd0` (KHE 0, `Q = 0`) | |

> 🔎 Đây là lý do J04 **không cần** xử lý trạng thái bất hợp lệ: mọi giá trị 10 bit đều là một
> trạng thái hợp lệ, và hàm chuyển `+1 mod 1024` đưa mọi trạng thái trở về chu trình chính.
> So sánh: một FSM 5 trạng thái mã hoá 3 bit có **3 tổ hợp chết** và **bắt buộc** phải có
> nhánh `default` để tự phục hồi.

## 6. Xử lý trạng thái bất hợp lệ — phân tích đúng cho J04

| Loại sự cố | J04 chịu được không? | Cơ chế |
|---|:-:|---|
| Bit `phase` bị lật do nhiễu (SEU) | ✅ tự phục hồi | Trạng thái mới vẫn hợp lệ; tiếp tục đếm. Triệu chứng: **một khung** hiển thị sai thứ tự, rồi tự đúng lại. Không kẹt vĩnh viễn |
| `phase` khởi động bất định (chưa reset) | ✅ tự phục hồi | Như trên |
| Kẹt ở trạng thái chết | ⬛ không thể xảy ra | Đồ thị chuyển là **một chu trình duy nhất** phủ hết 1024 trạng thái |
| Mất đồng bộ giữa PWM và khe | ⬛ không thể xảy ra | Chỉ có **một** bộ đếm; xem `control.md` §4 |

**Cái J04 *không* chịu được:** nếu `phase` lật, chữ số **có thể hiện sai vị trí** trong một
khung (ví dụ `d2` hiện trên anode của `d1`) vì tầng ngoài giải mã `digit_sel` một cách mù
quáng. Không có mã kiểm tra nào phát hiện điều này. Muốn chống thì phải đổi `phase[9:8]` sang
mã Gray hoặc thêm bit chẵn lẻ — **ngoài phạm vi** đề này.

## 7. Khi nào J04 **sẽ** cần một FSM tường minh

| Nếu thêm yêu cầu | FSM xuất hiện ở đâu | Số trạng thái |
|---|---|---:|
| **Nạp `ui_in[7:0]` hai nhịp** (Charter mục 4 đang đòi) | FSM đầu vào: `CHO → NAP_THAP → NAP_CAO → CHO` | 3 |
| Dead-time giữa hai khe | FSM con trong mỗi khe: `TAT_TRUOC → SANG → TAT_SAU` | 3 |
| Hiệu ứng nhấp nháy / cuộn chữ | FSM chế độ hiển thị | 3–5 |
| Bắt tay với tầng ngoài (`valid`/`ack`) khi nạp số | FSM bắt tay 4 pha | 4 |

Hiện RTL chưa có yêu cầu nào trong số đó ⟹ **không có FSM là lựa chọn đúng**, gọn hơn và
ít lỗi hơn.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
