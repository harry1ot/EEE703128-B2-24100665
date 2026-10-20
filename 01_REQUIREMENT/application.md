# J04 · Bối cảnh ứng dụng

| Mục | Nội dung |
|---|---|
| Mã đề | J04 |
| Chức năng | Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp |
| Loại mạch | Digital, tuần tự |
| Top module | `tt_um_eee703128_24100665` |

Khối hiển thị bốn chữ số trên thiết bị như đồng hồ đo. Các đường segment được dùng
chung; tại mỗi thời điểm chỉ một digit được chọn. Bên ngoài RTL cần có LED, điện trở
hạn dòng và tầng đệm phù hợp. Mạch RTL không trực tiếp điều khiển dòng LED.

Số liệu triển khai trong gói này thuộc top TinyTapeout nói trên. Run tổng hợp ghi
176 cell và 43 flip-flop. Ước lượng 400–560 cell trong Charter là giá trị tham khảo
ban đầu, không phải số đo hay tiêu chí thay thế kết quả flow.

**Truy vết:** `01_REQUIREMENT/requirements.md`; giao diện chi tiết:
`02_SPECIFICATION/interface.md`.
