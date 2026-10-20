# J04 · Phạm vi

## Trong phạm vi

- Mô tả yêu cầu, giao diện và hành vi của top TinyTapeout trong `rtl/project.sv`.
- Kiểm thử mô phỏng bằng `tb/tb.sv` và mô hình tham khảo Python.
- Tổng hợp, STA, power và RTL-to-GDSII theo các artifact còn lưu trong `GDS/`.
- Truy vết kết luận tới bằng chứng và điều kiện tạo bằng chứng.

| Thành phần hồ sơ | Vị trí |
|---|---|
| Bối cảnh ứng dụng | `01_REQUIREMENT/application.md` |
| Giao diện và đặc tả | `02_SPECIFICATION/` |
| Kiến trúc | `03_ARCHITECTURE/` |
| Bằng chứng số và physical | `05_VERIFICATION/`, `06_GDSII/` |
| RTM và giới hạn | `07_TRACEABILITY/` |

## Ngoài phạm vi

Thiết kế board/driver LED, điều khiển dòng, decimal point, nhiều hơn bốn digit,
kiểm tra trên silicon và ASIC sign-off. GDS/DRC/LVS trong hồ sơ là kết quả của run
cụ thể, không chứng minh chế tạo hay khả năng hoạt động trên phần cứng.

## Nguồn liên quan

`04_IMPLEMENTATION/rtl/j04_display_core.sv` và các script cùng thư mục là core phân
tích riêng, không thuộc top TinyTapeout và không làm đầu vào cho báo cáo GDS hiện tại.
