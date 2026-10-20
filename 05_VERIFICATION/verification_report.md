# J04 · Báo cáo kiểm chứng

## RTL simulation

| Thuộc tính | Giá trị |
|---|---|
| Top | `tt_um_eee703128_24100665` |
| RTL | `rtl/project.sv` |
| Testbench | `tb/tb.sv` |
| Công cụ | Icarus Verilog; log/version trong `GDS/` |
| Điều kiện clock test | `CLK_HZ=40`, `DIGIT_HZ=1` |
| Kết quả | PASS cho các assertion/checks có trong testbench |

Testbench kiểm reset, giao thức nạp khung hai byte, kết quả quét/giải mã một số
digit, blank zero đầu, `0000`, BCD ngoài miền, strobe giữ cao và brightness 0.
Waveform `tb.vcd` được tạo trong run. Testbench không đo duty PWM hay refresh ở
cấu hình mặc định; xem `test_matrix.csv` để biết phạm vi từng ca.

## Tổng hợp và physical

Run `RUN_2026-10-20_07-49-51` áp dụng cho cùng top TinyTapeout. Yosys ghi 176 cell,
43 flip-flop và diện tích tổng hợp 2337.2416 µm². Flow tạo final GDS; kết quả DRC,
LVS, STA và power được tổng hợp trong `06_GDSII/physical_report.md`.

## Giới hạn

Không có gate-level simulation hoặc post-layout simulation có SDF. SDC physical
dùng generic fallback do chưa khai báo SDC sign-off riêng. Các kết quả không phải
sign-off và không chứng minh hoạt động trên board hoặc silicon.
