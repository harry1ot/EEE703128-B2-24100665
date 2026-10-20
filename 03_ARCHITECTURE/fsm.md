# J04 · Trạng thái và trình tự

RTL không khai báo FSM enum. Việc nạp khung có hai pha, được lưu bằng
`expect_second_pair`:

| Cờ | Sự kiện | Kết quả |
|---|---|---|
| `0` | Cạnh lên strobe khi `ena=1` | Lưu cặp digit 3:2; đặt cờ thành 1 |
| `1` | Cạnh lên strobe kế tiếp | Chốt đủ digit 3:0; xóa cờ |

`load_strobe_d` giúp chỉ nhận cạnh lên, không nhận liên tục khi strobe bị giữ cao.
Cần có mẫu thấp giữa hai lần nạp. Reset bất đồng bộ xóa trình tự đang dở.

Phần quét không phải FSM nạp: `scan_counter` chia clock; khi hết `SCAN_DIV`, nó
được xóa và `scan_index` tăng modulo 4. Bộ đếm PWM tăng độc lập modulo 8.
