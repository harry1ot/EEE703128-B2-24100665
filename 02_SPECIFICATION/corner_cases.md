# J04 · Trường hợp biên

Các ca dưới đây được đối chiếu với testbench tự kiểm `tb/tb.sv`.

| Trường hợp | Hành vi trong RTL | Đã kiểm trong testbench |
|---|---|---|
| Reset đang tác động | Digit-select tắt; thanh ghi và bộ đếm reset | Có |
| Mới nhận byte thứ nhất | Lưu cặp digit 3:2; khung hiện tại giữ nguyên | Có |
| Nhận đủ byte thứ hai | Chốt một khung bốn digit | Có, `1234` |
| Số có các zero đầu | Digit zero có trọng số cao bị làm trống | Có, `0005` |
| Giá trị `0000` | Ba digit cao trống; hàng đơn vị vẫn hiện 0 | Có |
| Nibble BCD 10–15 | Decoder trả mã trống | Có, kích thích `A` và `B` |
| Strobe giữ cao | Chỉ cạnh lên đầu tiên được nhận | Có |
| Brightness bằng 0 | Tắt tất cả digit-select | Có |
| `ena=0` | Dừng nạp/đếm, tắt digit-select và blank segment | Chưa có kiểm tra riêng |
| Thay brightness khi đang quét | Comparator đổi trực tiếp theo input | Chưa đo duty bằng scoreboard |

Testbench cũng ghi `tb.vcd`. Tuy nhiên, nó dùng `CLK_HZ=40` và `DIGIT_HZ=1` để
giảm thời gian mô phỏng; waveform đó không phải phép đo refresh ở cấu hình 1 MHz.
`PASS` chỉ xác nhận những điều kiện được kiểm tra trong testbench, không thay cho
kiểm chứng mọi đầu vào hoặc phép đo PWM đầy đủ.
