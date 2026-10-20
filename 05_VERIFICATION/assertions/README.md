# J04 · Assertions

`tb/tb.sv` không dùng câu lệnh SystemVerilog `assert`; nó tăng bộ đếm lỗi và in
`FAIL` khi các phép so sánh đầu ra không khớp. Kết thúc bằng `PASS` nghĩa là các
check được viết trong testbench đều qua.

Chưa có bộ assertion độc lập hoặc đối chiếu từng chu kỳ với mô hình chuẩn. Bất biến
đáng bổ sung khi mở rộng kiểm chứng: đầu ra xác định sau reset, digit-select one-hot
active-low trong lúc hoạt động và kết quả decoder khớp bảng BCD.
