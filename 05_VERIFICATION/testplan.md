# J04 · Kế hoạch kiểm chứng

## Các lớp kiểm chứng hiện có

| Lớp | Mục tiêu | Đầu vào chính | Trạng thái |
|---|---|---|---|
| Python | Kiểm tra mô hình tham khảo độc lập | `golden_model/reference_model.py` | Có kết quả lưu; không tự đối chiếu RTL |
| RTL | Tự kiểm top TinyTapeout | `tb/tb.sv` + `rtl/project.sv` | PASS trong run lưu |
| Tổng hợp | Kiểm tra khả năng tổng hợp/top và tài nguyên | Artifact Yosys trong `GDS/runs/` | Đã chạy |
| Gate-level / SDF | Kiểm tra netlist hoặc timing sau layout | Chưa có test/result | Chưa chạy |

## Phạm vi testbench RTL

Testbench kiểm reset và hướng `uio_oe`, đảm bảo byte đầu chưa cập nhật màn hình,
nạp/hiển thị `1234`, blank zero đầu với `0005`, giữ digit đơn vị cho `0000`, BCD
không hợp lệ, strobe giữ cao và brightness bằng 0. Testbench ghi `tb.vcd`.

Tham số trong testbench là `CLK_HZ=40`, `DIGIT_HZ=1` để giảm thời gian chạy. Vì vậy
testbench không đo refresh mặc định 100 Hz/digit hoặc duty PWM bằng bộ đếm chu kỳ.
Các ca chưa kiểm được ghi trong `02_SPECIFICATION/corner_cases.md`.

## Điều kiện PASS

Lớp RTL chỉ PASS khi testbench in `PASS` và không ghi mismatch/failure. Kết quả
không mở rộng thành chứng minh hình thức hay kiểm thử toàn miền đầu vào.
