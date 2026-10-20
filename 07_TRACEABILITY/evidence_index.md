# Chỉ mục bằng chứng

Các đường dẫn dưới đây trỏ tới artifact của một lần chạy cụ thể; run ID là
`RUN_2026-10-20_07-49-51`. Không thay đổi đường dẫn để trỏ sang run khác nếu chưa rà soát lại
các kết luận trong báo cáo.

| ID | Artifact | Chứng minh / dùng để kiểm tra | Không chứng minh |
|---|---|---|---|
| E-01 | [`GDS/simulation.log`](../GDS/simulation.log) | Testbench TinyTapeout in PASS với các ca đã viết | Mọi trạng thái đầu vào hoặc thiết kế trên board |
| E-02 | [`GDS/tb.vcd`](../GDS/tb.vcd) | Dạng sóng của lần mô phỏng testbench | Tần số mặc định phần cứng; testbench dùng tham số giảm |
| E-03 | [`06-yosys-synthesis/yosys-synthesis.log`](../GDS/runs/RUN_2026-10-20_07-49-51/06-yosys-synthesis/yosys-synthesis.log) | Thống kê Yosys trước P&R, gồm 43 flip-flop | Tổng số instance sau physical design |
| E-04 | [`final/metrics.json`](../GDS/runs/RUN_2026-10-20_07-49-51/final/metrics.json) | Metrics area/utilization/timing/power/DRC/LVS của run | Độ chính xác vật lý ngoài giả định flow |
| E-05 | [`flow.log`](../GDS/runs/RUN_2026-10-20_07-49-51/flow.log) | Flow steps, cảnh báo, generic fallback SDC và kết thúc thành công | Sign-off của nhà máy |
| E-06 | [`final/gds/tt_um_eee703128_24100665.gds`](../GDS/runs/RUN_2026-10-20_07-49-51/final/gds/tt_um_eee703128_24100665.gds) | Layout database streamout cuối | Chức năng đúng hoặc đã chế tạo |
| E-07 | [`final/render/tt_um_eee703128_24100665.png`](../GDS/runs/RUN_2026-10-20_07-49-51/final/render/tt_um_eee703128_24100665.png) | Hình render bố trí/routing | Báo cáo DRC/LVS, timing hoặc khả năng chế tạo |
| E-08 | [`64-magic-drc/magic-drc.log`](../GDS/runs/RUN_2026-10-20_07-49-51/64-magic-drc/magic-drc.log) và [`65-klayout-drc/klayout-drc.log`](../GDS/runs/RUN_2026-10-20_07-49-51/65-klayout-drc/klayout-drc.log) | Kết quả hai checker DRC trong run | Kiểm chứng chức năng |
| E-09 | [`70-netgen-lvs/netgen-lvs.log`](../GDS/runs/RUN_2026-10-20_07-49-51/70-netgen-lvs/netgen-lvs.log) | So khớp netlist extracted với schematic theo cấu hình flow | Sign-off độc lập; log có dòng thống kê 4 disconnected pins |
| E-10 | [`config.json`](../config.json) | Top, nguồn RTL, PDK, clock và die khai báo | Constraint timing được xác nhận; config không chỉ định SDC riêng |
| E-11 | [`tb/tb.sv`](../tb/tb.sv) | Nguồn testbench và các kiểm tra PASS/FAIL | Độ bao phủ toàn bộ không gian trạng thái |

