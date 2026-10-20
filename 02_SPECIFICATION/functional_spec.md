# J04 · Đặc tả chức năng

Đặc tả này mô tả top `tt_um_eee703128_24100665` trong `rtl/project.sv`, cũng là RTL
được chọn bởi `config.json`. Không áp dụng các cổng `bcd_digits` của core phân tích
`j04_display_core`.

## Nạp khung hiển thị

`uio_in[3]` được lấy mẫu tại cạnh lên `clk`; mạch phát hiện cạnh lên bằng
`load_strobe_d`. Khi `ena=1`, cạnh lên đầu tiên chốt `ui_in[7:4]` vào digit 3 và
`ui_in[3:0]` vào digit 2. Cạnh lên kế tiếp chốt dữ liệu đang chờ cùng byte hiện tại
vào bốn digit, theo thứ tự trái sang phải. Cần đưa strobe xuống thấp giữa hai cạnh
lên. Chỉ có cặp đầu tiên thì khung đang hiển thị không đổi.

Reset active-low bất đồng bộ xóa dữ liệu digit và trạng thái nạp. Các thanh ghi số
được khởi tạo bằng 0. Khi `ena=0`, không nạp dữ liệu, bộ đếm quét và PWM dừng; các
digit bị tắt.

## Hiển thị

`scan_index` lần lượt chọn digit 0, 1, 2, 3. Digit 0 là hàng đơn vị và được giữ lại
kể cả khi bằng 0. Các digit cao hơn được làm trống nếu mọi digit có trọng số cao hơn
đều bằng 0. BCD 10–15 làm trống digit đó. Segment được xuất theo thứ tự
`{a,b,c,d,e,f,g}`, active-low.

PWM dùng bộ đếm modulo 8. Digit được chọn khi `pwm_counter < uio_in[2:0]`, với
brightness từ 0 đến 7; mức 7 tương ứng 7/8 chu kỳ PWM, không phải 100%. PWM chỉ tắt
digit-select; mã segment vẫn do digit đang quét quyết định.

## Tần số quét mặc định

Với `CLK_HZ=1,000,000` và `DIGIT_HZ=100`, `SCAN_DIV=2500`. Chỉ số digit đổi mỗi
2500 clock được bật, tức 400 khe digit mỗi giây và 100 lần làm mới cho mỗi digit.
Phép tính giả định clock thật là 1 MHz và `ena` luôn cao.
