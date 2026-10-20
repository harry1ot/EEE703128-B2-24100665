# J04 · Giao diện TinyTapeout

Top RTL: `tt_um_eee703128_24100665` (`rtl/project.sv`). Reset `rst_n` active-low;
segment và digit-select active-low. Không có decimal point.

| Tín hiệu | Chiều | Mô tả |
|---|---|---|
| `ui_in[7:4]` | vào | Nibble BCD cao của byte đang nạp |
| `ui_in[3:0]` | vào | Nibble BCD thấp của byte đang nạp |
| `uio_in[3]` | vào | Strobe; mạch nhận cạnh lên đồng bộ theo `clk` |
| `uio_in[2:0]` | vào | Mức sáng PWM, 0–7 |
| `uio_in[7:4]` | không dùng làm input | Các chân vật lý này được cấu hình làm output |
| `uo_out[6:0]` | ra | `{a,b,c,d,e,f,g}`, active-low |
| `uo_out[7]` | ra | Không dùng, buộc 0 |
| `uio_out[4]` | ra | Chọn digit 0 / hàng đơn vị, active-low |
| `uio_out[5]` | ra | Chọn digit 1, active-low |
| `uio_out[6]` | ra | Chọn digit 2, active-low |
| `uio_out[7]` | ra | Chọn digit 3, active-low |
| `uio_oe[7:4]` | ra | `1`: bốn chân `uio[7:4]` là output |
| `uio_oe[3:0]` | ra | `0`: bốn chân `uio[3:0]` là input |
| `clk` | vào | Clock hệ thống |
| `rst_n` | vào | Reset bất đồng bộ active-low |
| `ena` | vào | Cho phép nạp và đếm; thấp thì tắt digit |

## Quy ước nạp

Hai cạnh lên của `uio_in[3]` tạo một khung. Byte thứ nhất chứa digit 3:2; byte thứ
hai chứa digit 1:0 và cập nhật cả khung. Ví dụ byte `12`, sau đó `34`, hiển thị
`1234`. Strobe phải có mức thấp ít nhất một mẫu clock giữa hai lần nạp.

`uio_in`/`uio_out` là hướng vào/ra của cùng nhóm chân vật lý. RTL đặt `uio_oe` thành
`8'b11110000`, do đó nửa thấp là input và nửa cao là output.
