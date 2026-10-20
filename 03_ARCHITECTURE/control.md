# J04 · Điều khiển

Trong top TinyTapeout, quá trình nạp được điều khiển bởi `load_strobe_d` và cờ
`expect_second_pair`:

1. Khi cờ bằng 0, cạnh lên strobe lưu hai nibble cao/trái vào thanh ghi pending và
   chuyển sang chờ byte thứ hai.
2. Cạnh lên kế tiếp cập nhật đồng thời bốn thanh ghi digit rồi xóa cờ.
3. Reset xóa cờ, strobe trễ và dữ liệu pending.

Đây là điều khiển hai pha bằng một cờ, không phải FSM enum riêng. `ena` cho phép
nạp và chạy các bộ đếm. Khi `ena=0`, các bộ đếm giữ giá trị, segment bị blank và
cả bốn digit-select ở trạng thái tắt. Bộ đếm PWM và bộ chia quét dùng chung clock
nhưng là hai bộ đếm độc lập.
