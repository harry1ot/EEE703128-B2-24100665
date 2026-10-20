# 06 · Kết quả tổng hợp và RTL-to-GDSII

## Run được ghi nhận

- **Run ID:** `RUN_2026-10-20_07-49-51`
- **Top:** `tt_um_eee703128_24100665`
- **RTL:** `rtl/project.sv`
- **Cấu hình:** `config.json`
- **PDK / thư viện:** `sky130A` / `sky130_fd_sc_hd`
- **Die:** 100 × 100 µm
- **Trạng thái:** LibreLane hoàn tất, GDS được tạo; xem giới hạn về lint và SDC trong
  [`physical_report.md`](physical_report.md) và [`../07_TRACEABILITY/limitations.md`](../07_TRACEABILITY/limitations.md).

File kết quả thô được giữ nguyên trong thư mục [`../GDS/runs/RUN_2026-10-20_07-49-51/`](../GDS/runs/RUN_2026-10-20_07-49-51/);
không sao chép các netlist, thư viện, SDF hay GDS lớn lần thứ hai.

| Nhóm | Tóm tắt | Nguồn thô |
|---|---|---|
| Synthesis | Cell count, flip-flop và diện tích trước floorplan | [`synthesis/README.md`](synthesis/README.md) |
| STA | Setup/hold theo các góc PVT và giả định SDC | [`sta/README.md`](sta/README.md) |
| Power | Công suất ước lượng của flow | [`power/README.md`](power/README.md) |
| P&R / DRC / LVS / GDS | Kết quả vật lý và hình render | [`physical_report.md`](physical_report.md) |

> Đây là kết quả của top TinyTapeout trong run nêu trên. Không trộn số liệu này với các phép
> phân tích riêng của `j04_display_core`.
