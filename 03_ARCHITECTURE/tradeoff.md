# J04 · Đánh đổi và số liệu

| Lựa chọn | Tác động |
|---|---|
| Chia sẻ bus segment và quét 4 digit | Giảm số đường dữ liệu segment, đổi lại mỗi digit chỉ được chọn một phần thời gian |
| Hai byte cho một khung | Dùng ít chân input; khung hiển thị chỉ cập nhật khi nhận đủ hai byte |
| PWM 3 bit | Có 8 mức mã; mức tối đa 7/8, không phải full-on |
| Làm trống zero đầu trong RTL | Tránh hiển thị zero không cần thiết; hàng đơn vị vẫn hiện zero |
| Bộ đếm quét và PWM riêng | Dễ hiểu và kiểm soát độc lập; dùng thêm trạng thái so với bộ đếm gộp |

Run `RUN_2026-10-20_07-49-51` tổng hợp top TinyTapeout thành 176 cell, 43
flip-flop, diện tích tổng hợp 2337.2416 µm². Final physical metrics có 1312
instances, trong đó có filler/tap/buffer. Không so sánh số instance physical với
số cell logic như thể chúng cùng đại lượng.

Timing/power dùng điều kiện flow của run, gồm generic fallback SDC. DRC/LVS và GDS
được báo cáo tại `06_GDSII/physical_report.md`; đây không phải kết quả sign-off.
