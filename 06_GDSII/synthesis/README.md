# Tổng hợp logic

Nguồn: [`yosys-synthesis.log`](../../GDS/runs/RUN_2026-10-20_07-49-51/06-yosys-synthesis/yosys-synthesis.log),
run `RUN_2026-10-20_07-49-51`, thiết kế
`tt_um_eee703128_24100665`, PDK `sky130A`, thư viện `sky130_fd_sc_hd`.

| Chỉ số | Kết quả |
|---|---:|
| Cell sau synthesis | 176 |
| Flip-flop `dfrtp_2` | 43 |
| Diện tích cell synthesis | 2337.2416 µm² |
| Diện tích tuần tự | 1129.8336 µm² (48.34%) |
| Cell chưa ánh xạ | 0 |
| Synthesis check errors | 0 |

Đây là số liệu **sau synthesis, trước P&R**. Không so sánh trực tiếp với tổng số instance sau
P&R: bước physical thêm clock/timing buffers, tap và filler cells.

