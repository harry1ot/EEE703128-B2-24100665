# J04 · Phần điều khiển (Control)

J04 là mạch **tuần tự**, nên mục này mô tả khối điều khiển **thật** trong RTL, không phải
giải thích "vì sao không có".

---

## 1. Toàn bộ điều khiển của J04 nằm trong **một** thanh ghi 10 bit

```systemverilog
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          phase <= 10'd0;
        else if (!enable)    phase <= 10'd0;
        else                 phase <= phase + 10'd1;
    end
```

Đó là **toàn bộ** phần tuần tự của thiết kế — 8 dòng, 10 flip-flop. Mọi thứ khác là tổ hợp.

`phase` giữ **ba vai trò điều khiển cùng lúc**:

| Trường | Vai trò điều khiển | Tác động tới datapath |
|---|---|---|
| `phase[9:8]` | **Con trỏ khe quét** | Chọn 1 trong 4 nibble của `bcd_digits`; phát ra `digit_sel` |
| `phase[7:0]` | **Pha PWM** | So với `brightness` để bật/tắt `seg` |
| `phase` toàn bộ | **Bộ chia tần** | Chia `f_clk` cho 1024 để ra tần số khung |

## 2. Bảng tín hiệu điều khiển và tác dụng

| Tín hiệu | Nguồn | Loại | Tác dụng chính xác | Có đăng ký? |
|---|---|---|---|:-:|
| `rst_n` | ngoài | reset **bất đồng bộ**, tích cực thấp | Ép `phase = 0` tức thì, không chờ clock | — |
| `enable` | ngoài | điều khiển **đồng bộ** | (1) Hạ ⟹ `phase = 0` ở cạnh clock kế; (2) tham gia `display_active` **tức thì** (tổ hợp) | ❌ |
| `brightness[7:0]` | ngoài | tham số điều chế | (1) Ngưỡng của so sánh PWM; (2) `= 0` ⟹ tắt hẳn qua `display_active` | ❌ |
| `blank_leading_zero` | ngoài | chọn **chế độ** | Chuyển hàm chọn chữ số giữa hai nhánh: thẳng hoặc có ưu tiên tắt | ❌ |
| `display_active` | nội bộ → ra | cờ + điều khiển nội bộ | Chặn cả 7 đường `seg`; đồng thời báo ra ngoài | ❌ |
| `phase[9:8]` | nội bộ → ra | con trỏ | Chọn khe; phát `digit_sel` | ✅ (2 FF) |
| `phase[7:0]` | nội bộ | pha | Vế trái của `Q < brightness` | ✅ (8 FF) |

> ⚠️ **Bốn trên bảy tín hiệu điều khiển không được đăng ký.** `enable`, `brightness`,
> `blank_leading_zero` đi thẳng vào logic tổ hợp và tác động lên `seg` trong **0 chu kỳ**.
> Đây là lựa chọn có chủ ý (ít FF) nhưng buộc tầng ngoài phải giữ chúng ổn định — xem §5.

## 3. Thứ tự ưu tiên trong khối điều khiển

```
  rst_n = 0  ─────────────────────────────▶ phase = 0      (uu tien cao nhat, bat dong bo)
       │ rst_n = 1
       ▼
  enable = 0 ─────────────────────────────▶ phase = 0      (dong bo, cho canh clock)
       │ enable = 1
       ▼
  mac dinh   ─────────────────────────────▶ phase = phase+1
```

Không có trạng thái nào khác. Không có nhánh `else` bỏ trống ⟹ **không sinh latch**.
Netlist xác nhận: 0 cell `dlatch`/`dlxtp` trong `synth_stat.txt`.

## 4. Quan hệ giữa điều khiển và datapath — điểm thiết kế quan trọng nhất của J04

Charter mục 10 nêu rủi ro: *"Hai bộ đếm (quét và PWM) chạy không đồng bộ với nhau → độ sáng
nhấp nháy không đều."*

**RTL này triệt tiêu rủi ro đó bằng xây dựng, không bằng cẩn thận.** Cơ chế:

```
  PHUONG AN 1 (rui ro) — HAI bo dem doc lap:
     ┌──────────────┐               ┌──────────────┐
     │ dem quet 8b  │──▶ digit_sel  │ dem PWM 8b   │──▶ nguong
     └──────────────┘               └──────────────┘
     → 16 FF; hai chu ky 256 va 256 nhung KHONG cung pha;
       neu chu ky quet khong chia het chu ky PWM → moi khe nhan
       mot phan khac nhau cua chu ky PWM → do sang 4 LED KHAC NHAU.

  PHUONG AN 2 (RTL nay) — MOT bo dem 10 bit, lay bit:
     ┌────────────────────────────────┐
     │      phase[9:0]                │
     │  [9:8] = khe     [7:0] = pha   │
     └────────────────────────────────┘
     → 10 FF; khe chi doi khi pha PWM VUA TRAN (Q: 255→0).
       ⟹ moi khe chua DUNG MOT chu ky PWM tron ven, dong pha tuyet doi.
```

**Bằng chứng số học:** khe đổi khi `phase[9:8]` đổi, tức khi `phase` đi từ `...11111111` sang
`...00000000` — đúng lúc `Q` tràn. Vậy trong mỗi khe, `Q` chạy trọn vẹn `0 → 255`, và số chu
kỳ sáng bằng đúng `brightness` với **mọi** khe. Bốn LED nhận duty giống hệt nhau.

**Bằng chứng netlist:** đúng **10** `dfrtp_1`, không phải 16. Nếu RTL dùng hai bộ đếm riêng,
`synth_stat.txt` phải ghi ≥ 16 FF. Đây là cách **đọc netlist để xác minh quyết định kiến trúc**.

Chi phí: 10 FF thay vì 16 ⟹ tiết kiệm `6 × 25,024 = 150,144 µm²` (16,3 % diện tích khối).
Ràng buộc kèm theo: **độ phân giải PWM và số chữ số bị khoá cứng vào nhau** — 8 bit PWM + 2
bit khe = 10 bit. Muốn PWM 10 bit thì `phase` phải 12 bit và tần số khung giảm 4 lần.

## 5. Nghĩa vụ hợp đồng của tầng ngoài (vì phần điều khiển cố ý tối giản)

| # | Nghĩa vụ | Vì sao | Hậu quả nếu vi phạm |
|:-:|---|---|---|
| 1 | Giữ `bcd_digits` ổn định trọn một khung (1024 chu kỳ) | `seg` tổ hợp, độ trễ 0 | Xé hình giữa khe |
| 2 | Chỉ đổi `brightness` ở ranh giới khung | Đổi giữa khe làm khe đó có duty lai giữa hai giá trị | Một khung nhấp nháy |
| 3 | Đồng bộ hoá `enable` vào miền `clk` trước khi đưa vào | `enable` vào thẳng `always_ff` và cả logic tổ hợp | Metastability trên `phase` |
| 4 | Giữ `rst_n` thấp đủ dài (≥ 1 chu kỳ clock) | Reset bất đồng bộ nhưng **nhả** phải thoả recovery | Trạng thái `phase` bất định |
| 5 | Giải mã `digit_sel[1:0]` → 4 đường anode | J04 không phát one-hot | Không lái được LED |
| 6 | Tự chèn dead-time giữa hai khe nếu transistor chậm | J04 đổi `digit_sel` và `seg` cùng cạnh, không có khoảng trống | "Bóng ma" (ghosting) giữa chữ số kề nhau |
| 7 | Đảo mức nếu LED là common-anode | J04 phát tích cực **cao** | Hiển thị ảnh âm bản |

## 6. Những gì J04 **không** làm mặc dù thường được kỳ vọng

| Không có | Vì sao đúng khi không có | Nếu cần thì thêm ở đâu |
|---|---|---|
| Tín hiệu bắt tay (`ready`/`valid`) | Hiển thị là luồng **liên tục vô hạn**, không có khái niệm "giao dịch xong" | Không bao giờ cần |
| Thanh ghi nạp hai nhịp | Charter mục 4 **có** đòi, RTL **chưa** có → `⬜ CHƯA THOẢ` | Một thanh ghi 16 bit + FSM 2 trạng thái ở đầu vào |
| Dead-time giữa các khe | Tiết kiệm logic; giả định driver đủ nhanh | So sánh thêm `Q > 250` để chặn cuối khe |
| Chống rung / lọc đầu vào | Không có đầu vào cơ khí | Đề F06 |
| Đồng bộ CDC | Chỉ một clock | Đề J11 |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
