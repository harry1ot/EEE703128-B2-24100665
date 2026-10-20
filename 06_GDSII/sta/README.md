# Static Timing Analysis

Nguồn: các log signoff post-P&R dưới
[`55-openroad-stapostpnr/`](../../GDS/runs/RUN_2026-10-20_07-49-51/55-openroad-stapostpnr/)
và metrics tổng hợp trong [`final/metrics.json`](../../GDS/runs/RUN_2026-10-20_07-49-51/final/metrics.json).

Clock khai báo trong cấu hình là 1000 ns (1 MHz). Run **không có SDC riêng**:
LibreLane ghi nhận `PNR_SDC_FILE` và `SIGNOFF_SDC_FILE` không được đặt, nên dùng generic
fallback SDC. SDC kết quả đặt clock uncertainty 0.25 ns và input/output delay 200 ns. Vì vậy
các slack dưới đây chỉ có ý nghĩa theo các giả định đó.

| Chỉ số sau P&R | Kết quả |
|---|---:|
| Setup worst slack thấp nhất trong các góc | 594.2517 ns (`max_ss_100C_1v60`) |
| Hold worst slack thấp nhất trong các góc | 0.1070 ns (`min_ff_n40C_1v95`) |
| Setup TNS / WNS | 0 / 0 ns, mọi góc được báo cáo |
| Hold TNS / WNS | 0 / 0 ns, mọi góc được báo |
| Setup / hold violations | 0 / 0, theo checker của flow |

`WNS=0` ở metrics LibreLane là worst **negative** slack (độ vi phạm), không phải slack dương
còn lại; dùng `setup__ws` và `hold__ws` ở trên để đọc worst slack.

Không suy ra tần số tối đa silicon trực tiếp từ slack này: SDC đang dùng giả định I/O tổng quát,
và chưa có yêu cầu timing hệ thống được xác nhận độc lập.

