# J04 · Tiêu chí đạt

Trạng thái được đánh giá theo bằng chứng hiện có; PASS của mô phỏng chỉ áp dụng cho
các điều kiện mà testbench kiểm tra.

| # | Tiêu chí | Bằng chứng | Trạng thái |
|---|---|---|---|
| AC-1 | Giao diện thống nhất với top TinyTapeout | `02_SPECIFICATION/interface.md`, `rtl/project.sv` | Đạt |
| AC-2 | Có test tự kiểm cho các hành vi chính | `tb/tb.sv`, `GDS/simulation.log` | Đạt |
| AC-3 | Kết quả gắn với run và điều kiện tạo | `07_TRACEABILITY/RTM.csv`, `06_GDSII/physical_report.md` | Đạt |
| AC-4 | Nêu rõ giới hạn, không gọi kết quả là sign-off | `07_TRACEABILITY/limitations.md` | Đạt |
| AC-5 | Top tổng hợp được với thư viện sky130 | `GDS/runs/RUN_2026-10-20_07-49-51/` | Đạt |
| AC-6 | Sinh final GDS trong run được lưu | `06_GDSII/physical_report.md` | Đạt |
| AC-7 | DRC/LVS của run được báo cáo | `06_GDSII/physical_report.md` | Đạt, trong phạm vi checker đã chạy |
| AC-8 | Đo refresh rate mặc định trực tiếp trên waveform | `tb/tb.sv` dùng tham số rút gọn; không đo mặc định | Chưa chứng minh trực tiếp |
| AC-9 | Gate-level hoặc post-layout SDF simulation | Không có kết quả lưu | Chưa chạy |

Các tiêu chí này không khẳng định mọi trạng thái đầu vào đã được kiểm thử. Xem
`05_VERIFICATION/test_matrix.csv` và `07_TRACEABILITY/limitations.md`.
