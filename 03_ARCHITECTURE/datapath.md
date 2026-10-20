# J04 · Đường dữ liệu

Byte thứ nhất được tách thành `ui_in[7:4]` (digit 3) và `ui_in[3:0]` (digit 2),
rồi giữ ở thanh ghi pending. Byte thứ hai cập nhật digit 1:0 và chuyển cặp đang
chờ sang bốn thanh ghi hiển thị.

`scan_index` chọn một trong bốn nibble. Decoder tạo mã `{a,b,c,d,e,f,g}` active-low
cho BCD 0–9; nibble 10–15 tạo mã blank. Trước giải mã, logic blanking tắt digit 3,
2 hoặc 1 khi các chữ số có trọng số cao hơn đều bằng 0. Digit 0 không bị blank do
giá trị 0.

Bộ đếm PWM ba bit chạy modulo 8. So sánh `pwm_counter >= uio_in[2:0]` sẽ tắt toàn
bộ digit-select; segment bus không bị điều chế PWM. Với brightness 7, digit được
chọn trong 7/8 chu kỳ PWM.
