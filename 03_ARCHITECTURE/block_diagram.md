# J04 · Sơ đồ khối

```text
ui_in[7:0] ─┐
uio_in[3] ───┴─► cạnh strobe + điều khiển nạp
                      │ byte đầu: staging digit 3:2
                      │ byte sau: chốt digit 3:0
                      ▼
                thanh ghi 4 digit ──► mux scan ──► BCD decoder ──► uo_out[6:0]
clk ─► scan divider ─► scan_index ────────────────► uio_out[7:4]
clk ─► PWM counter ──► brightness comparator ────► digit blanking
rst_n, ena ──────────────────────────────────────► reset / enable
```

Segment output active-low; digit-select active-low. Leading zero suppression is
combinational and leaves the units digit visible.
