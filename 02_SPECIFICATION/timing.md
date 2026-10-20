# J04 · Timing

Các con số dưới đây mô tả RTL top TinyTapeout, không phải core `j04_display_core`.

## Timing chức năng

| Hạng mục | Giá trị / hành vi |
|---|---|
| Clock RTL mặc định | `CLK_HZ=1 MHz`, tham số trong module |
| Refresh mục tiêu | `DIGIT_HZ=100 Hz` cho mỗi digit |
| Bộ chia | `SCAN_DIV=CLK_HZ/(4×DIGIT_HZ)=2500` |
| Khe digit | Một lần chuyển digit mỗi 2500 chu kỳ được enable |
| Reset | Bất đồng bộ, active-low |
| Nạp dữ liệu | Strobe được lấy mẫu đồng bộ; phát hiện cạnh lên |

Ở cấu hình mặc định, mỗi digit có tần số refresh 100 Hz. Nếu `ena` thấp, bộ đếm
dừng nên thời gian thực giữa các lần chuyển digit phụ thuộc thời lượng enable thấp.
Tham số nên được chọn sao cho `DIGIT_HZ` khác 0 và bộ chia nguyên có giá trị phù
hợp với clock của hệ thống.

## STA của run RTL-to-GDSII

Run `RUN_2026-10-20_07-49-51` dùng generic fallback SDC của flow vì cấu hình chưa
chỉ định SDC sign-off riêng. Chi tiết clock, I/O delay và uncertainty nằm tại
`06_GDSII/sta/README.md`. Không dùng các giả định fallback này để tuyên bố timing
đã được duyệt cho hệ thống đích.

Không có kết quả gate-level hoặc post-layout SDF simulation trong hồ sơ.
