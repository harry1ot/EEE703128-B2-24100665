# Đặc tả tham khảo — bộ điều khiển bốn LED 7 đoạn

Đây là một đặc tả mẫu để học RTL tuần tự, bộ đếm, FSM nhỏ, bộ giải mã và mô phỏng. Các tần số là giả định cho thiết kế tham khảo; nếu đề chính thức hoặc bo mạch dùng giao diện khác, cần sửa đặc tả và RTL đồng bộ.

## 1. Mục tiêu và phạm vi

Mạch hiển thị một số thập phân bốn chữ số trên bốn LED 7 đoạn bằng phương pháp quét đa hợp. Để tiết kiệm chân dữ liệu, mỗi lần nạp mạch nhận hai chữ số BCD đóng gói trong một byte; hai lần nạp tạo thành một khung bốn chữ số. Mạch quét lần lượt từng LED, giải mã BCD thành bảy đoạn và dùng PWM ba bit để đặt độ sáng. Đây là thiết kế RTL số; mạch ngoài cần cung cấp LED, điện trở hạn dòng và tầng đệm phù hợp.

## 2. Giao diện và ánh xạ chân

Reset `rst_n` tích cực mức thấp. Bảy đoạn có thứ tự bit `{a,b,c,d,e,f,g}` và tích cực mức thấp; digit select cũng tích cực mức thấp. Quy ước này giả định cách nối kiểu common-anode. Không có decimal point.

| Cổng | Chiều | Ý nghĩa |
|---|---|---|
| `clk` | vào | Clock hệ thống, giả định 1 MHz |
| `rst_n` | vào | Reset bất đồng bộ, active-low |
| `ena` | vào | Khi 0, dừng bộ đếm/nạp và tắt toàn bộ digit |
| `ui_in[7:4]` | vào | Chữ số BCD bên trái trong cặp đang nạp |
| `ui_in[3:0]` | vào | Chữ số BCD bên phải trong cặp đang nạp |
| `uio_in[3]` | vào | `load_strobe`; nạp tại cạnh lên được lấy mẫu theo `clk` |
| `uio_in[2:0]` | vào | Mức sáng PWM từ 0 đến 7 |
| `uio_in[7:4]` | không dùng | Các chân vật lý tương ứng được cấu hình làm đầu ra |
| `uo_out[6:0]` | ra | `{a,b,c,d,e,f,g}`, active-low |
| `uo_out[7]` | ra | Không dùng, luôn bằng 0 |
| `uio_out[4]` | ra | Chọn digit 0 (chữ số ngoài cùng bên phải), active-low |
| `uio_out[5]` | ra | Chọn digit 1, active-low |
| `uio_out[6]` | ra | Chọn digit 2, active-low |
| `uio_out[7]` | ra | Chọn digit 3 (chữ số ngoài cùng bên trái), active-low |
| `uio_oe[7:4]` | ra | 1, cấu hình bốn chân `uio[7:4]` làm đầu ra |
| `uio_oe[3:0]` | ra | 0, cấu hình bốn chân `uio[3:0]` làm đầu vào |

`uio_in` và `uio_out` là hai hướng của cùng các chân vật lý `uio`. Ánh xạ trên tránh xung đột: `uio[3:0]` chỉ là đầu vào, `uio[7:4]` chỉ là đầu ra. Tổng cộng dùng 23 đường tín hiệu logic: 8 `ui`, 4 `uio` vào, 7 `uo` ra và 4 `uio` ra, nằm trong ngân sách 24 chân của giao diện mẫu.

## 3. Quy tắc nạp dữ liệu

Một lần nạp là cạnh lên của `uio_in[3]` được lấy mẫu tại cạnh lên `clk`. Giữ strobe ở mức 1 không tạo thêm lần nạp; cần kéo xuống 0 rồi mới tạo cạnh lên kế tiếp.

1. Cạnh lên thứ nhất: chốt `ui_in[7:4]` vào chữ số 3 và `ui_in[3:0]` vào chữ số 2 trong thanh ghi chờ.
2. Cạnh lên thứ hai: chốt byte hiện tại vào chữ số 1 và chữ số 0, đồng thời cập nhật nguyên tử cả bốn chữ số đang hiển thị.
3. Sau lần nạp thứ hai, FSM quay lại chờ cặp đầu tiên của khung tiếp theo.
4. Reset xóa khung hiển thị về `0000` và hủy cặp đang chờ. Nếu chỉ nhận được cặp đầu tiên, màn hình giữ nguyên khung hoàn chỉnh trước đó.

Ví dụ: nạp `8'h12`, kéo strobe xuống thấp, rồi nạp `8'h34` sẽ hiển thị `1234`. BCD hợp lệ nằm trong khoảng 0–9. Nibble 10–15 làm tắt cả bảy đoạn của chữ số đó.

## 4. Kiến trúc RTL

```text
ui_in[7:0] + load_strobe
          │
          ▼
  edge detector + FSM 2 trạng thái
  (chờ cặp trái / chờ cặp phải)
          │
          ▼
  staging registers + 4-digit registers
          │
          ├─────────────► mux 4:1 ─► BCD-to-7-segment decoder ─► uo_out
          │
clk ─► scan divider ─► 2-bit digit index ─► digit select ─────► uio_out[7:4]
          │
clk ──────┴──────────► 3-bit PWM counter ◄── brightness[2:0]
```

- **Nạp/FSM:** `expect_second_pair=0` chờ cặp chữ số bên trái; sau một strobe lên, FSM chờ cặp bên phải. Cặp thứ hai cập nhật cả bốn thanh ghi chữ số cùng lúc để không hiển thị nửa khung mới và nửa khung cũ.
- **Quét:** bộ chia tạo một lần chuyển digit mỗi `SCAN_DIV` chu kỳ clock. `scan_index` chạy vòng `0,1,2,3`; mỗi chữ số được chọn ở tần số xấp xỉ `DIGIT_HZ`.
- **Giải mã:** mux chọn BCD ứng với digit hiện tại; decoder tạo mã active-low cho các đoạn a–g. Giá trị không phải BCD hiển thị trống.
- **PWM:** bộ đếm 3 bit chạy từ 0 đến 7. Digit được bật khi `pwm_counter < brightness`; mức 0 tắt, mức 7 cho duty 7/8. Độ sáng cũng chịu duty quét 1/4.
- **Reset/enable:** reset active-low bất đồng bộ; `ena=0` dừng nạp và bộ đếm, đồng thời đưa các digit về trạng thái tắt.

Với mặc định `CLK_HZ=1,000,000` và `DIGIT_HZ=100`, `SCAN_DIV=CLK_HZ/(4×DIGIT_HZ)=2500`. Tần số chuyển digit là 400 lần/giây và mỗi digit được làm mới 100 lần/giây. Duty quét mỗi digit là 1/4; PWM ở mức 7 làm duty xấp xỉ `1/4 × 7/8 = 21.875%` cho từng đoạn đang sáng.

## 5. Ca kiểm thử đề xuất

Testbench hiện có kiểm tra các trường hợp:

| Ca | Kỳ vọng |
|---|---|
| Reset | Digit tắt, hướng `uio_oe` đúng |
| Chỉ nạp cặp đầu `12` | Màn hình vẫn là `0000`, không cập nhật nửa khung |
| Nạp tiếp cặp `34` | Quét lần lượt giá trị `1`, `2`, `3`, `4` trên đúng digit |
| BCD `A` hoặc `B` | Chữ số tương ứng để trống |
| Giữ strobe mức 1 | Chỉ ghi nhận một lần nạp cho mỗi cạnh lên |
| Brightness = 0 | Không digit nào được chọn |
| Brightness = 7 | Digit được chọn trong 7/8 chu kỳ PWM |

Khi mở waveform, nên quan sát `load_strobe`, `expect_second_pair`, các thanh ghi digit, `scan_index`, `pwm_counter`, `uo_out[6:0]` và `uio_out[7:4]`. Tham số clock trong testbench được giảm để mô phỏng nhanh; tần số phần cứng được xác định bởi tham số RTL và clock thực tế.

## 6. Cấu hình LibreLane

Workflow `.github/workflows/rtl2gds.yml` gọi `librelane config.json`. Cấu hình này:

- Chọn `rtl/project.sv` và top module `tt_um_eee703128_24100665` (phải trùng `DESIGN_NAME` với tên module RTL).
- Chọn `PDK=sky130A` và thư viện cell chuẩn `sky130_fd_sc_hd`.
- Ràng buộc clock `clk` với chu kỳ 1000 ns, tương ứng clock RTL giả định 1 MHz.
- Khởi tạo floorplan tuyệt đối với `DIE_AREA=[0,0,100,100]` (100 × 100 µm). Đây là kích thước khởi đầu để flow thử chạy, không phải kết quả đã chứng minh là đủ chỗ. Nếu floorplan hoặc routing báo không đủ diện tích, cần điều chỉnh die sau khi xem log và báo cáo.

## 7. Giới hạn và giả định

- Đây là giao thức nạp đồng bộ đơn giản, không có `ready`, `busy`, timeout hay bộ lọc dội phím. Nguồn dữ liệu phải tạo strobe sạch, đồng bộ với `clk`.
- Giữa hai lần nạp có thể có khoảng cách bất kỳ; nếu reset xảy ra, cặp đang chờ bị hủy.
- `DIGIT_HZ` là tần số làm mới của từng digit. Clock phải lớn hơn hoặc bằng `4 × DIGIT_HZ`; phép chia nguyên làm tròn xuống số chu kỳ quét và có thể tạo sai số nhỏ ở tần số thực.
- PWM ba bit chỉ có tám mức và mức lớn nhất là 7/8, không phải 100%.
- RTL không điều khiển dòng LED, không chứa mạch đệm/chống ghosting vật lý, không xử lý decimal point và không hỗ trợ nhiều hơn bốn chữ số.
- Mô phỏng xác nhận logic theo các ca đã viết; nó không tự chứng minh mọi trường hợp. Kết quả tổng hợp/DRC/LVS cũng không phải bằng chứng chip đã được chế tạo, sign-off hoặc sẵn sàng sản xuất.
