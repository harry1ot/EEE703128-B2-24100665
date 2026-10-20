# J04 · Tham số và cấu hình

## Tham số RTL

| Tham số | Mặc định | Tác dụng |
|---|---:|---|
| `CLK_HZ` | 1,000,000 | Clock dùng để tính bộ chia quét |
| `DIGIT_HZ` | 100 | Tần số làm mới mục tiêu cho mỗi digit |
| `SCAN_DIV` | 2500 | `CLK_HZ/(DIGIT_HZ×4)`, tối thiểu 1 |

Các tham số nằm trong top `tt_um_eee703128_24100665`. Dữ liệu BCD, brightness và
strobe là tín hiệu runtime, không phải tham số elaboration.

## Cấu hình flow

`config.json` chọn `rtl/project.sv`, top `tt_um_eee703128_24100665`, PDK `sky130A`
và die khởi tạo 100×100 µm. `info.yaml` tham chiếu `src/project.v` cho gói TinyTapeout.
Hai RTL source hiện giống hệt nhau.

Run đã lưu tổng hợp được 176 cell, 43 flip-flop và diện tích tổng hợp 2337.2416 µm².
Physical metrics ghi 1312 instances, gồm filler/tap/buffer; đây không phải số cell
logic RTL. Điều kiện và giới hạn được ghi trong `06_GDSII/physical_report.md`.
