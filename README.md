# J04 — Bộ điều khiển bốn LED 7 đoạn

## Nguồn RTL

Thiết kế nộp là top TinyTapeout `tt_um_eee703128_24100665`. Bản RTL giảng viên gửi
được giữ tại `src/project.v`; `rtl/project.sv` là bản dùng cho mô phỏng và LibreLane.
Hai file hiện giống hệt nhau. Không cần chép hay viết lại RTL để đồng bộ.

`04_IMPLEMENTATION/rtl/j04_display_core.sv` là một core phân tích riêng từ bản trước,
khác giao diện và không được dùng bởi cấu hình TinyTapeout, testbench `tb/tb.sv` hay
run RTL-to-GDSII được báo cáo. Các tài liệu yêu cầu, đặc tả và kiến trúc trong hồ sơ
này mô tả top TinyTapeout; không lấy kết quả của core riêng để thay thế.

## Chức năng

Mạch nhận hai byte BCD qua `ui_in[7:0]`. Cạnh lên đồng bộ của `uio_in[3]` thứ nhất
lưu hai chữ số bên trái; cạnh lên thứ hai chốt đủ bốn chữ số để hiển thị. Mạch quét
bốn digit, giải mã BCD sang bảy đoạn active-low và nhận mức sáng PWM ba bit tại
`uio_in[2:0]`. Số 0 ở đầu được làm trống; digit hàng đơn vị vẫn hiện số 0. BCD không
hợp lệ làm trống digit tương ứng.

## Chạy mô phỏng

```sh
iverilog -g2012 -s tb -o /tmp/j04-sim.vvp rtl/project.sv tb/tb.sv
vvp /tmp/j04-sim.vvp
```

Testbench tự kiểm tra reset, giao thức nạp hai byte, quét/giải mã, số 0 đầu, `0000`,
BCD không hợp lệ, strobe giữ mức cao và brightness bằng 0. Tần số trong testbench
được giảm để chạy nhanh; phép tính mặc định của RTL dùng `CLK_HZ=1 MHz` và
`DIGIT_HZ=100 Hz`.

## Hồ sơ

| Thư mục | Nội dung |
|---|---|
| `01_REQUIREMENT/` | Yêu cầu và phạm vi theo Charter |
| `02_SPECIFICATION/` | Giao diện, hành vi và timing của top TinyTapeout |
| `03_ARCHITECTURE/` | Sơ đồ và mô tả khối theo RTL được nộp |
| `04_IMPLEMENTATION/` | RTL core phân tích riêng và các script của core |
| `05_VERIFICATION/` | Mô hình tham khảo, testbench và kết quả |
| `06_GDSII/` | Báo cáo tổng hợp, timing, power và physical |
| `07_TRACEABILITY/` | RTM, bằng chứng và giới hạn |
| `08_ORIGINAL_SOURCE/` | Bản lưu core phân tích cũ, không phải top TinyTapeout |
| `GDS/runs/` | Artifact thô từ run RTL-to-GDSII |

## Kết quả RTL-to-GDSII

Run `RUN_2026-10-20_07-49-51` hoàn tất cho top TinyTapeout, sinh final GDS; báo cáo
ghi nhận 176 cell tổng hợp, 43 flip-flop, 0 lỗi DRC trong các checker đã chạy và
LVS `Circuits match uniquely`. Flow dùng generic fallback SDC; lint có 448 warnings.
Chi tiết và giới hạn nằm trong `06_GDSII/physical_report.md`. Đây không phải tuyên bố
sign-off, tape-out hay kiểm chứng trên silicon.

*Nguồn chuẩn: Project Charter J04 và RTL giảng viên cung cấp.*
