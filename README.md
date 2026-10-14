# EEE703128 — Bộ điều khiển bốn LED 7 đoạn (J04)

## Thông tin dự án

- **Sinh viên:** Phạm Minh Hoàng
- **MSSV:** 24100665
- **Ngôn ngữ:** Verilog/SystemVerilog
- **Top module:** `tt_um_eee703128_24100665`
- **Clock giả định:** 1 MHz
- **Tần số làm mới:** 100 Hz cho mỗi digit

## Đặc tả và kiến trúc

Mạch nhận hai cặp chữ số BCD, ghép thành một khung bốn chữ số rồi hiển thị bằng phương pháp quét đa hợp. Cạnh lên `uio_in[3]` nạp một byte `ui_in[7:0]`; cặp đầu là hai chữ số bên trái, cặp thứ hai là hai chữ số bên phải. Mạch cập nhật cả khung sau khi nhận đủ hai byte, giải mã BCD sang bảy đoạn active-low, quét lần lượt bốn digit và điều chỉnh độ sáng với PWM ba bit ở `uio_in[2:0]`.

Kiến trúc gồm bộ phát hiện cạnh nạp và FSM hai trạng thái, hai thanh ghi staging, bốn thanh ghi chữ số, bộ chia clock quét, mux chọn digit, bộ giải mã BCD và bộ đếm PWM. Sơ đồ khối, giao thức nạp, ánh xạ chân, phép tính tần số và giả định được mô tả chi tiết trong [docs/info.md](docs/info.md).

## Ánh xạ chân chính

| Chân | Tín hiệu / chức năng |
|---|---|
| `ui_in[7:4]` | Chữ số BCD trái của cặp đang nạp |
| `ui_in[3:0]` | Chữ số BCD phải của cặp đang nạp |
| `uio_in[3]` | Strobe nạp, lấy cạnh lên đồng bộ với `clk` |
| `uio_in[2:0]` | Mức sáng PWM, 0=tắt, 7=7/8 duty |
| `uo_out[6:0]` | `{a,b,c,d,e,f,g}`, active-low |
| `uio_out[7:4]` | Chọn digit 3..0, active-low |
| `uio_oe[7:4]` / `[3:0]` | `1111` đầu ra / `0000` đầu vào |

`uio[3:0]` chỉ dùng làm đầu vào và `uio[7:4]` chỉ dùng làm đầu ra nên không có chân nào vừa nhận dữ liệu vừa phát tín hiệu chọn LED. `rst_n` active-low; `ena=0` dừng hoạt động và tắt digit.

## Kiểm thử mô phỏng

```sh
iverilog -g2012 -o sim.vvp rtl/*.sv tb/*.sv
vvp sim.vvp
```

Testbench bao gồm reset, kiểm tra khung không cập nhật sau byte đầu, nạp và quét `1234`, BCD không hợp lệ, strobe bị giữ mức cao và độ sáng bằng 0. Tham số clock của testbench được giảm để chạy nhanh; tham số mặc định của thiết kế là 1 MHz.

## RTL-to-GDSII

`config.json` là cấu hình đầu vào của LibreLane, được workflow `.github/workflows/rtl2gds.yml` gọi sau bước mô phỏng. Cấu hình chọn `rtl/project.sv`, top module `tt_um_eee703128_24100665`, PDK `sky130A` với thư viện `sky130_fd_sc_hd`, clock `clk` với chu kỳ 1000 ns (1 MHz), và die ban đầu 100 × 100 µm. Die size là giả định floorplan để flow tham khảo, không phải kích thước đã được chứng minh là đủ; cần xác nhận từ báo cáo placement/routing của lần chạy thực tế.

Workflow chạy RTL-to-GDSII và lưu artifacts. Chỉ điền số liệu area, cell, utilization, timing, power và DRC/LVS vào báo cáo sau khi đọc kết quả của chính lần chạy. Flow thành công không chứng minh thiết kế đã được chế tạo, sign-off hoặc sẵn sàng sản xuất.

## Giới hạn

Đây là ví dụ học tập ở mức RTL, không bao gồm driver LED, điện trở hạn dòng hay kiểm thử phần cứng. Giao thức không có `ready/busy`, bộ lọc dội phím hoặc decimal point; giá trị BCD ngoài 0–9 hiển thị trống. Thiết kế không chèn khoảng tắt riêng giữa các digit nên cần kiểm tra nguy cơ ghosting trên mạch thực.
