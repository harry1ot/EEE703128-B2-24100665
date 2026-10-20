# Giới hạn và cách diễn giải kết quả

## Phạm vi run

- Báo cáo trong `06_GDSII/` dựa trên run `RUN_2026-10-20_07-49-51` và top
  `tt_um_eee703128_24100665` từ `rtl/project.sv`.
- Không áp dụng số liệu này cho top phân tích `j04_display_core` hoặc cho một RTL/config khác.
- GDS, DRC, LVS và STA là kết quả của flow/configuration có trong thư mục [`../GDS/runs/`](../GDS/runs/).

## Các giả định cần giữ khi trích số liệu

1. Cấu hình đặt `clk` period 1000 ns và die 100 × 100 µm, nhưng không khai báo
   `PNR_SDC_FILE` hoặc `SIGNOFF_SDC_FILE`. LibreLane vì vậy dùng generic fallback SDC.
2. SDC sinh ra dùng input/output delay 200 ns, uncertainty 0.25 ns và giả định tải/driver của
   flow. Slack chỉ có ý nghĩa trong các giả định đó; không suy ra trực tiếp tần số tối đa của
   sản phẩm.
3. Công suất là ước lượng từ flow, không phải đo dòng trên silicon. Mức toggle/hoạt động không
   được xác nhận bằng workload thực tế trong báo cáo này.
4. `SCAN_DIV=CLK_HZ/(4×DIGIT_HZ)=2500` cho cấu hình RTL 1 MHz/100 Hz, nên tần số làm mới
   được tính là 100 Hz mỗi digit. Waveform đi kèm được tạo với tham số testbench rút gọn, không
   phải đo tần số hoạt động tại cấu hình mặc định.

## Cảnh báo và điểm cần theo dõi

- Flow hoàn tất và `error.log` rỗng, nhưng log ghi **448 lint warnings**. Không đồng nhất “flow
  complete” với “không cảnh báo”.
- Log Netgen kết luận `Circuits match uniquely` và metrics báo không có unmatched devices/nets;
  tuy nhiên phần thống kê Netgen có dòng `4 disconnected pins`. Giữ lại để đối chiếu khi cần
  rà soát LVS.
- DRC Magic và KLayout đều báo 0 lỗi; điều này không kiểm chứng logic chức năng.
- Setup/hold checker không báo vi phạm trong constraint đã dùng. Điều đó không thay thế yêu
  cầu timing hệ thống, constraint đã duyệt, sign-off hay phân tích nhiều điều kiện ngoài flow.
- Testbench PASS chỉ áp dụng các ca có trong `tb/tb.sv`; không chứng minh mọi chuỗi đầu vào,
  glitch, ghosting, board hoặc silicon.

## Không được kết luận từ các artifact này

- Không tuyên bố thiết kế đã được nhà máy sign-off, tape-out hoặc chế tạo.
- Không tuyên bố đã kiểm tra trên silicon.
- Không coi ảnh render là GDS hoặc báo cáo DRC/LVS.
- Không coi area/cell count tổng instance có filler/tap là số lượng logic cell của RTL.

