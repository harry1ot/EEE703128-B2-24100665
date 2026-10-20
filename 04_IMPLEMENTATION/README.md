# 04 · Implementation

Thư mục này chứa `j04_display_core.sv`, một core phân tích riêng. Top TinyTapeout mà
dự án kiểm thử và đưa qua RTL-to-GDSII nằm ở `rtl/project.sv`; hai module khác
interface và không thể thay thế trực tiếp cho nhau.

## Script trong thư mục

Các script `01_run_sim.sh`, `02_run_synth.sh`, `03_run_sta.tcl` và config
`config_librelane.json` phục vụ core phân tích. Kết quả cũ của core không phải bằng
chứng cho top TinyTapeout và không được trộn với số liệu trong `06_GDSII/`.

Để chạy mô phỏng top chính, từ thư mục gốc:

```sh
iverilog -g2012 -s tb -o /tmp/j04-sim.vvp rtl/project.sv tb/tb.sv
vvp /tmp/j04-sim.vvp
```

Flow RTL-to-GDSII của top dùng `.github/workflows/rtl2gds.yml` và `config.json`.
Run đã lưu được mô tả trong `06_GDSII/physical_report.md`.
