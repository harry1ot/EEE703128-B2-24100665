# J04 · Giản đồ trình tự

## Nạp một khung

```text
clk edge          ↑       ↑       ↑       ↑       ↑
uio_in[3]         0───────1───────0───────1───────0
ui_in             -- byte 12 --          -- byte 34 --
expect_second_pair 0───────1──────────────0
display frame     ─────── khung cũ ──────┴─── 1234 ─
```

Giản đồ chỉ thể hiện thứ tự các sự kiện. Byte đầu lưu cặp digit 3:2; byte thứ hai
cập nhật toàn bộ khung. Strobe cần được lấy mẫu thấp giữa hai cạnh lên.

## Quét mặc định

Với `SCAN_DIV=2500`, `scan_index` đổi sau mỗi 2500 chu kỳ `clk` khi `ena=1`:

```text
scan_index    0 (digit0)   1 (digit1)   2 (digit2)   3 (digit3)   0 ...
slot length      2500         2500         2500         2500       clk
```

Đây là phép suy ra từ RTL; testbench dùng tham số clock rút gọn. Không xem giản đồ
này là waveform đo refresh mặc định hoặc timing gate-level.
