# Ước lượng công suất

Nguồn số liệu: [`final/metrics.json`](../../GDS/runs/RUN_2026-10-20_07-49-51/final/metrics.json),
run `RUN_2026-10-20_07-49-51`, top `tt_um_eee703128_24100665`.

| Corner / thành phần | Internal | Switching | Leakage | Tổng |
|---|---:|---:|---:|---:|
| `max_ff_n40C_1v95` | 7.3017 µW | 2.9348 µW | 0.00666 µW | **10.2432 µW** |
| `nom_tt_025C_1v80` | 6.3463 µW | 2.3946 µW | 0.00399 µW | **8.7448 µW** |

Nguồn: post-P&R STA log cho từng corner trong
[`55-openroad-stapostpnr/`](../../GDS/runs/RUN_2026-10-20_07-49-51/55-openroad-stapostpnr/)
(`max_ff_n40C_1v95/sta.log` và `nom_tt_025C_1v80/sta.log`). Không trộn số giữa các corner.

Đây là ước lượng trong flow, không phải phép đo chip. Hãy diễn giải cùng corner, clock và giả
định hoạt động của công cụ; không dùng số này làm công suất tiêu thụ trên board hay silicon.
