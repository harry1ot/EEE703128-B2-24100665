# J04 · Giao diện (Interface)

---

## 1. Ánh xạ chân theo Charter (mục 4)

> Theo danh mục đề: ui_in[7:0]=hai chữ số (nạp 2 lần) · uio_in[2:0]=độ sáng · uo_out[6:0]=đoạn · uio_out[3:0]=chọn LED
> Ngân sách chân: 11 bit vào + 11 bit ra = 22 trên 24 chân.
> Lỗi ánh xạ cần sửa trước khi thiết kế: chân uio[0, 1, 2] bị gán vừa làm đầu vào vừa làm đầu ra. Tổng bit vẫn trong 24 chân nên chỉ cần đánh số lại.
> Một ô Tiny Tapeout có đúng 24 chân: ui_in 8 chỉ vào, uo_out 8 chỉ ra, uio 8 chọn chiều từng chân. uio_in và uio_out là cùng một bộ chân vật lý.

## 2. Bảng giao diện đã CHỐT — module `j04_display_core`

Bảng dưới đây **đọc trực tiếp từ RTL** (`04_IMPLEMENTATION/rtl/`), không phải chép tay,
nên luôn nhất quán với mã nguồn.

| Tín hiệu | Chiều | Độ rộng (bit) | Vai trò | Mức tích cực / giả định |
|---|---|---:|---|---|
| `clk` | input | 1 | clock | |
| `rst_n` | input | 1 | reset (đồng bộ hoá trạng thái) | |
| `enable` | input | 1 | điều khiển | |
| `blank_leading_zero` | input | 1 | dữ liệu vào | |
| `brightness[7:0]` | input | 8 | dữ liệu vào | |
| `bcd_digits[15:0]` | input | 16 | dữ liệu vào | |
| `seg[6:0]` | output | 7 | kết quả ra | |
| `digit_sel[1:0]` | output | 2 | kết quả ra | |
| `display_active` | output | 1 | kết quả ra | |

**Tổng hợp:** 6 cổng vào (28 bit) · 3 cổng ra (10 bit).

**Clock:** `clk`

**Reset:** `rst_n`

## 3. Ngân sách chân Tiny Tapeout

| Hạng mục | Số bit |
|---|---:|
| Tổng bit vào | **28** |
| Tổng bit ra | **10** |
| **Tổng cộng** | **38** |
| Ô Tiny Tapeout có | **24** |
| **Chênh lệch** | **+14 (VƯỢT)** |

> Nhắc lại cấu trúc chân Tiny Tapeout: một ô có đúng 24 chân — `ui_in` 8 chỉ vào,
> `uo_out` 8 chỉ ra, `uio` 8 chọn chiều từng chân; **`uio_in` và `uio_out` là cùng một bộ
> chân vật lý**.

> 🟡 **ĐIỂM MỞ.** Thiết kế cần nhiều hơn 24 bit. Charter mục 4 yêu cầu **hỏi giảng viên
> trước khi chọn cách xử lý**. Gói này chốt lõi logic và **cố ý không** tự bịa ra lớp vỏ
> vật lý. Ba hướng thường dùng: (1) nạp/phát nhiều nhịp — thêm ô nhớ; (2) thu hẹp độ rộng
> một toán hạng; (3) bỏ bớt tín hiệu ra. Mỗi hướng đều đánh đổi khác nhau — xem
> `03_ARCHITECTURE/tradeoff.md`.

## 4. Điều kiện hợp lệ của đầu vào

| Điều kiện | Ai bảo đảm |
|---|---|
| Các cổng vào không chứa `X`/`Z` khi lấy mẫu | Tầng ngoài |
| Tín hiệu vào đồng bộ với `clk` hoặc đã qua bộ đồng bộ | Tầng ngoài |
| Chuỗi reset được giữ đủ dài trước khi bắt đầu hoạt động | Tầng ngoài |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Truy vết: REQ-J04-002, AC-1.*
