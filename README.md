# J04 — Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp

## Thông tin dự án

| | |
|---|---|
| **Mã đề** | J04 |
| **Môn học** | EEE703128 — Nhập môn Thiết kế Vi mạch Tích hợp |
| **Sinh viên** | Phạm Minh Hoàng |
| **MSSV** | 24100665 |
| **Ngôn ngữ** | Verilog/SystemVerilog |
| **Nhóm / độ khó** | J · Đề khó — nhiều khối, có bắt tay hoặc đường ống |
| **Loại mạch** | Tuần tự |
| **Top module TinyTapeout** | `tt_um_eee703128_24100665` |
| **Top module phân tích** | `j04_display_core` trong `04_IMPLEMENTATION/rtl/` |
| **Clock mặc định** | 1 MHz |
| **Tần số làm mới mỗi digit** | 100 Hz |
| **Quy mô tham khảo theo Charter** | ~400–560 cell · 1×1 tile |

## Tổng quan

Khối hiển thị bốn chữ số trên đồng hồ đo bằng phương pháp quét đa hợp, dùng chung đường dữ liệu để tiết kiệm chân. Bản TinyTapeout nhận hai cặp chữ số BCD qua `ui_in[7:0]`: cạnh lên `uio_in[3]` nạp một byte, cặp đầu là hai chữ số bên trái và cặp thứ hai là hai chữ số bên phải. Khung hiển thị chỉ cập nhật sau khi nhận đủ hai byte.

Thiết kế giải mã BCD sang bảy đoạn active-low, quét lần lượt bốn digit và điều chỉnh độ sáng bằng PWM ba bit. Các số 0 vô nghĩa ở đầu được tự động tắt; chữ số hàng đơn vị luôn hiển thị, kể cả khi giá trị là `0000`. BCD ngoài khoảng 0–9 hiển thị trống.

## Ánh xạ chân TinyTapeout

| Chân | Tín hiệu / chức năng |
|---|---|
| `ui_in[7:4]` | Chữ số BCD trái của cặp đang nạp |
| `ui_in[3:0]` | Chữ số BCD phải của cặp đang nạp |
| `uio_in[3]` | Strobe nạp; lấy cạnh lên đồng bộ với `clk` |
| `uio_in[2:0]` | Mức sáng PWM; 0=tắt, 7=7/8 duty |
| `uo_out[6:0]` | `{a,b,c,d,e,f,g}`, active-low |
| `uio_out[7:4]` | Chọn digit 3..0, active-low |
| `uio_oe[7:4]` / `uio_oe[3:0]` | `1111` đầu ra / `0000` đầu vào |
| `rst_n` | Reset active-low |
| `ena` | Enable; khi `0`, dừng hoạt động và tắt digit |

`uio[3:0]` chỉ dùng làm đầu vào và `uio[7:4]` chỉ dùng làm đầu ra, tránh gán một chân vừa nhận dữ liệu vừa phát tín hiệu chọn LED. Sơ đồ khối, giao thức nạp, phép tính tần số và giả định được trình bày trong [docs/info.md](docs/info.md).

## Kiến trúc và tài liệu

Kiến trúc gồm bộ phát hiện cạnh nạp và FSM hai trạng thái, hai thanh ghi staging, bốn thanh ghi chữ số, bộ chia clock quét, mux chọn digit, bộ giải mã BCD và bộ đếm PWM.

| Bạn muốn | Tài liệu |
|---|---|
| Nắm nhanh bản chất và cách thực hiện | [implementation-notes_J04.md](implementation-notes_J04.md) hoặc [bản HTML](implementation-notes_J04.html) |
| Xem yêu cầu, đặc tả và kiến trúc | `01_REQUIREMENT/`, `02_SPECIFICATION/`, `03_ARCHITECTURE/` |
| Xem RTL, ràng buộc và scripts | `04_IMPLEMENTATION/` |
| Xem mô hình chuẩn và kiểm chứng | `05_VERIFICATION/` |
| Xem RTM, bằng chứng và giới hạn | `07_TRACEABILITY/` |

### Cây thư mục hồ sơ

```text
J04/
├── README.md
├── implementation-notes_J04.md / implementation-notes_J04.html
├── 01_REQUIREMENT/     application · requirements · scope · acceptance_criteria
├── 02_SPECIFICATION/   functional_spec · interface · timing · corner_cases · parameters
├── 03_ARCHITECTURE/    system_diagram · block_diagram · datapath · control · fsm
│                       timing_diagram · tradeoff
├── 04_IMPLEMENTATION/  rtl/ · constraints/ · scripts/ · README
├── 05_VERIFICATION/    golden_model/ · testbench/ · assertions/ · waveforms/
│                       testplan · test_matrix.csv · verification_report
├── 06_GDSII/           synthesis/ · sta/ · power/ · physical_report
└── 07_TRACEABILITY/    RTM.csv · evidence_index · limitations
```

## Kiểm thử mô phỏng

Chạy testbench TinyTapeout từ thư mục gốc:

```sh
iverilog -g2012 -o sim.vvp rtl/project.sv tb/tb.sv
vvp sim.vvp
```

Testbench kiểm tra reset, khung không cập nhật sau byte đầu, nạp và quét `1234`, blank số 0 đầu với `0005`, trường hợp biên `0000`, BCD không hợp lệ, strobe bị giữ mức cao và độ sáng bằng 0. Tham số clock trong testbench được giảm để mô phỏng nhanh; thiết kế mặc định dùng clock 1 MHz và refresh 100 Hz mỗi digit.

Chạy mô hình chuẩn và các script của hồ sơ phân tích:

```sh
python3 05_VERIFICATION/golden_model/reference_model.py
bash 04_IMPLEMENTATION/scripts/01_run_sim.sh
bash 04_IMPLEMENTATION/scripts/02_run_synth.sh
sta -no_splash -exit 04_IMPLEMENTATION/scripts/03_run_sta.tcl
bash 04_IMPLEMENTATION/scripts/04_run_librelane.sh  # cần PDK sky130A
```

## Kết quả hồ sơ phân tích

Hồ sơ v1.0 ghi nhận mô hình chuẩn Python và mô phỏng Icarus Verilog PASS; synthesis, STA và ước lượng công suất đã chạy; P&R chưa chạy do cần PDK sky130A. Các số liệu bên dưới thuộc khối phân tích `j04_display_core` và môi trường/cấu hình được ghi trong hồ sơ đó; không xem chúng là kết quả synthesis của top module TinyTapeout trong `rtl/project.sv`.

| Chỉ số trong hồ sơ `j04_display_core` | Giá trị | Công cụ / nguồn |
|---|---:|---|
| Số cell | 122 | Yosys 0.33 |
| Flip-flop | 10 | Yosys 0.33 |
| Diện tích | 922,1344 µm² | Yosys 0.33 |
| Đường tới hạn | `bcd_digits[12]` → `seg[3]` | OpenSTA 3.1.0 |
| Độ trễ | 2,7 ns | OpenSTA 3.1.0 |
| Công suất ước lượng | 5.52e-05 W | Báo cáo trong hồ sơ |

Các kết quả timing, diện tích và công suất phụ thuộc vào thư viện, góc PVT, giả định timing và cấu hình công cụ. P&R, DRC, LVS và GDSII chưa được xác nhận; không suy diễn các kết quả này thành sign-off hay khả năng chế tạo.

## RTL-to-GDSII

`config.json` là cấu hình LibreLane dùng workflow `.github/workflows/rtl2gds.yml`. Cấu hình chọn `rtl/project.sv`, top `tt_um_eee703128_24100665`, PDK `sky130A`, thư viện `sky130_fd_sc_hd`, clock `clk` với chu kỳ 1000 ns (1 MHz) và die ban đầu 100 × 100 µm.

Die size là giả định floorplan, chưa được chứng minh là đủ. Chỉ ghi số liệu area, cell, utilization, timing, power và trạng thái DRC/LVS sau khi đọc kết quả của chính lần chạy thực tế. Flow thành công không đồng nghĩa thiết kế đã sign-off, tape-out, chế tạo hoặc kiểm tra trên silicon.

## Giới hạn

Đây là thiết kế học tập ở mức RTL, không bao gồm driver LED, điện trở hạn dòng hay kiểm thử phần cứng. Giao thức không có `ready/busy`, bộ lọc dội phím hoặc decimal point. Thiết kế không chèn khoảng tắt riêng giữa các digit nên cần kiểm tra nguy cơ ghosting trên mạch thực.

---

*Nguồn chuẩn: Project Charter J04, mục 1–10. Hồ sơ phân tích: v1.0 · 2026-09-24.*
