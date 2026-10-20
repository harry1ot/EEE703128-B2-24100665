# J04 · Sơ đồ hệ thống

```text
 Bộ điều khiển / nguồn BCD
       │ ui_in[7:0], uio_in[3] strobe, uio_in[2:0] brightness
       ▼
 ┌────────────────────────────────────────────┐
 │ tt_um_eee703128_24100665                    │
 │ nhận hai byte → thanh ghi digit → quét     │
 │ → giải mã BCD → PWM chọn digit              │
 └────────────────────────────────────────────┘
       │ uo_out[6:0] segment       │ uio_out[7:4] digit select
       └───────────────────────────┴──────────► LED 7 đoạn x4
```

`clk`, `rst_n` và `ena` điều khiển trạng thái nội bộ. RTL chỉ phát mức logic; tải
LED thực tế cần mạch điện phù hợp. Sơ đồ và mô tả này áp dụng cho top được chọn
bởi `config.json`, không áp dụng cho core phụ trong `04_IMPLEMENTATION/`.
