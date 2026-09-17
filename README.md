# EEE703128 — Bài kiểm tra số 2: <Tên Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp / J04>

## 📌 Thông tin dự án

- **Tên đề tài:** `Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp`
- **Mã đề tài:** `J04`
- **Sinh viên thực hiện:** `Phạm Minh Hoàng`
- **Mã số sinh viên (MSSV):** `24100665`
- **Ngôn ngữ thiết kế:** Verilog HDL
- **Top Module:** `tt_um_eee703128_24100665`
- **Tần số xung nhịp:** `1000` Hz

---

## 📝 Mô tả thiết kế

### 1. Bài toán & Chức năng
<Mô tả ngắn gọn 3–5 câu về bài toán: Mạch nhận tín hiệu đầu vào gì, xử lý chức năng gì, xuất tín hiệu đầu ra như thế nào. Mạch là mạch tổ hợp hay mạch tuần tự?>

### 2. Nguyên lý hoạt động
<Giải thích cấu trúc phần cứng và kiến trúc mạch:
- Mạch gồm các khối logic/thanh ghi nào?
- Đề tổ hợp: Bảng chân lý hoặc biểu thức logic chính.
- Đề tuần tự: Sơ đồ trạng thái (FSM), danh sách các trạng thái và điều kiện chuyển trạng thái.>

---

## 🔌 Ánh xạ chân (Pinout Mapping)

| Tên cổng (Module) | Chân vật lý | Tín hiệu kết nối | Loại | Ý nghĩa / Chức năng |
|---|---|---|---|---|
| `clk` | Clock | Clock System | In | Xung nhịp hệ thống |
| `rst_n` | Reset | Reset System | In | Tín hiệu Reset (tích cực mức thấp `0`) |
| `ena` | Enable | Power / Enable | In | Tín hiệu cho phép hoạt động |
| `ui_in[7:0]` | `ui[7:0]` | `<Tín hiệu đầu vào>` | In | Tín hiệu vào chính |
| `uo_out[7:0]` | `uo[7:0]` | `<Tín hiệu đầu ra>` | Out | Tín hiệu ra chính |
| `uio_in[7:0]` | `uio[7:0]` | `<Tín hiệu I/O vào>` | In | Tín hiệu I/O linh hoạt (Input) |
| `uio_out[7:0]` | `uio[7:0]` | `<Tín hiệu I/O ra>` | Out | Tín hiệu I/O linh hoạt (Output) |
| `uio_oe[7:0]` | `uio[7:0]` | `<Cho phép ra I/O>` | Out | Tín hiệu điều khiển hướng buffer (1: Out, 0: In) |

---

## 📂 Cấu trúc thư mục dự án

```text
.
├── README.md                    # Tài liệu hướng dẫn & tổng quan dự án
├── info.yaml                    # Thông tin cấu hình thiết kế cho chuỗi công cụ (Flow)
├── HUONG_DAN_CHAY_FLOW.md       # Hướng dẫn chi tiết chạy RTL-to-GDSII
├── KIEM_TRA_TRUOC_KHI_COMMIT.py # Script kiểm tra lỗi phổ biến trước khi push/commit
├── docs/
│   └── info.md                  # Báo cáo chi tiết về thiết kế (theo tiêu chí chấm điểm)
├── src/
│   └── project.v                # Mã nguồn Verilog HDL chính
└── test/
    └── tb.v                     # Testbench kiểm thử chức năng
```

---

## 🚀 Hướng dẫn phát triển & Kiểm thử

### 1. Mô phỏng kiểm thử (Simulation)
Chạy kiểm thử testbench cục bộ bằng `iverilog` hoặc các công cụ mô phỏng Verilog tương đương:
```bash
# Biên dịch và chạy mô phỏng
iverilog -g2012 -o tb.vvp src/project.v test/tb.v
vvp tb.vvp

# Mở dạng sóng (nếu có xuất file vcd)
gtkwave tb.vcd
```

### 2. Tổng hợp & Tạo GDSII tự động (CI/CD)
Khi đẩy code lên repository GitHub, GitHub Actions sẽ tự động kích hoạt chuỗi công cụ RTL-to-GDSII để tổng hợp, định vị, đi dây và xuất file kết quả (GDSII, ảnh layout, báo cáo STA, DRC, LVS).

---

## 📊 Tóm tắt kết quả (RTL-to-GDSII Results)

*Cập nhật các số liệu chính từ artifact báo cáo sau khi chạy xong GitHub Actions:*

- **Diện tích thiết kế (Area):** `<...>` $\mu m^2$
- **Tổng số Cell (Cell Count):** `<...>` cells
- **Hệ số sử dụng (Utilization):** `<...>` %
- **Worst Negative Slack (Setup STA):** `<...>` ns
- **Công suất tiêu thụ (Power):** `<...>` mW
- **Trạng thái DRC / LVS:** `<Sạch 0 lỗi / Clean>`

---

## ⚠️ Giới hạn của thiết kế

- `<Nêu các trường hợp/điều kiện thiết kế chưa đáp ứng hoặc các giả định được áp dụng.>`
- `<Các tần số hoạt động giới hạn hoặc kích thước dữ liệu đầu vào.>`

---

## 📜 Giấy phép (License)

Dự án này được phát hành dưới giấy phép...
