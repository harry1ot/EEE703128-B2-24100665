# J04 · Ghi chú triển khai

## RTL đang dùng

Top của dự án là `tt_um_eee703128_24100665`. RTL giảng viên gửi ở `src/project.v`
và bản mô phỏng/flow ở `rtl/project.sv` giống hệt nhau. `config.json` và workflow
RTL-to-GDSII chọn top này.

Core `j04_display_core` trong `04_IMPLEMENTATION/rtl/` là bản phân tích riêng với
giao diện khác. Các script đi cùng core không phải flow chính và số liệu của core
không được dùng để giải thích kết quả GDS hiện tại.

## Hành vi chính

- Mỗi cạnh lên đồng bộ của `uio_in[3]` nhận một byte từ `ui_in`.
- Byte thứ nhất lưu digit 3:2; byte thứ hai cập nhật đủ digit 3:0.
- Bộ chia quét đổi digit theo `SCAN_DIV`; bộ đếm PWM 3 bit chạy độc lập.
- Bảy đoạn và digit-select active-low; `uio_oe=8'b11110000`.
- Zero đầu được blank; hàng đơn vị vẫn hiển thị zero. BCD ngoài 0–9 blank.

## Kiểm tra và kết quả

Mô phỏng top chính:

```sh
iverilog -g2012 -s tb -o /tmp/j04-sim.vvp rtl/project.sv tb/tb.sv
vvp /tmp/j04-sim.vvp
```

Testbench tự kiểm các hành vi chính, nhưng dùng clock rút gọn và không đo trực tiếp
duty PWM hay refresh mặc định. Run RTL-to-GDSII `RUN_2026-10-20_07-49-51` và các
giới hạn của nó được ghi tại `06_GDSII/physical_report.md`.

Để xem giao diện, đặc tả, từng ca kiểm và giới hạn, bắt đầu từ `README.md`,
`02_SPECIFICATION/` và `05_VERIFICATION/`.
