# J04 · Phân tích đánh đổi (Trade-off)

Mọi số liệu trong tài liệu này lấy từ `06_GDSII/synthesis/synth_stat.txt`,
`06_GDSII/sta/`, `06_GDSII/power/power_report.txt`, phân tích nón logic trên
`06_GDSII/synthesis/netlist.v`, và diện tích cell trong
`sky130_fd_sc_hd__tt_025C_1v80.lib`. Chỗ nào chưa có số thì ghi `⬜ chưa chạy`.

---

## 1. Số liệu nền của kiến trúc đã chọn

| Chỉ số | Giá trị thật |
|---|---:|
| Tổng cell | **122** |
| Flip-flop | **10** |
| Diện tích | **922,1344 µm²** |
| Slack đường dữ liệu xấu nhất | **6,30 ns** (`bcd_digits[12] → seg[3]`) |
| Arrival đường đó | **2,70 ns** (gồm 1,00 ns input delay giả định) |
| Slack reg→reg | 8,40 ns (`phase[0] → digit_sel[1]`, arrival 1,48 ns) |
| WNS / TNS | 0,00 / 0,00 |
| Công suất | **5,52e-05 W** (tuần tự 78,0 % · tổ hợp 22,0 %) |
| Charter ước lượng quy mô | ~400–560 cell |

> 🔎 **Điều đáng chú ý đầu tiên:** thiết kế dùng **122 cell**, chỉ bằng **~30 %** cận dưới
> ước lượng của Charter (400 cell). Nguyên nhân đã phân tích ở `functional_spec.md`: RTL
> thiếu thanh ghi nạp chữ số (−16 FF) và gộp hai bộ đếm thành một (−6 FF). Con số nhỏ này
> **không** phải dấu hiệu "làm hay", mà là dấu hiệu **thiếu chức năng so với Charter**.

## 2. So sánh kiến trúc quét với ba kiến trúc thay thế

| Tiêu chí | **(A) Quét đa hợp — ĐÃ CHỌN** | (B) Bốn bộ giải mã song song | (C) Quét + thanh ghi nạp 2 nhịp | (D) Nối tiếp ra thanh ghi dịch ngoài |
|---|---|---|---|---|
| Chân ra cần | **7 + 2 = 9** | 4 × 7 = **28** | 7 + 2 = 9 | **3** (data/clk/latch) |
| Số bộ giải mã 7 đoạn | 1 | **4** | 1 | 1 |
| Flip-flop | **10** (đo thật) | 0 (nếu tổ hợp thuần) | ≈ 10 + 16 + 2 ≈ **28** | ≈ 10 + 8 (SR) ≈ 18 |
| Diện tích | **922,1344 µm²** (đo thật) | ước ≈ 4 × 522 + 0 ≈ **2 100 µm²** *(ước từ nón `seg` 521,75 µm²)* | ước ≈ 922 + 16×25,024 ≈ **1 322 µm²** | ⬜ chưa ước được |
| Độ sáng mỗi LED | **1/4** (chỉ sáng 25 % thời gian) | **1/1** (sáng liên tục) | 1/4 | 1/4 |
| Cần dead-time / driver nhanh | ✅ có | ❌ không | ✅ có | ✅ có |
| Xé hình khi đổi dữ liệu | ✅ **có** (nhược điểm hiện tại) | ❌ không | ❌ **không** (có thanh ghi) | ❌ không |
| Đúng Charter mục 4 | ❌ **CHƯA** | ❌ (28 chân ra vượt ngân sách) | ✅ gần đúng nhất | ❌ (không đúng ánh xạ đề) |
| Khi nào nên dùng | Khi chân là tài nguyên khan hiếm — **đúng bối cảnh Tiny Tapeout 24 chân** | Khi số chữ số ít và chân dư dả; khi cần độ sáng tối đa | Khi cần đúng Charter và chống xé hình | Khi LED ở xa, nối bằng cáp ít dây |

### Tại sao (A) là lựa chọn đúng trong bối cảnh này

Bối cảnh Charter mục 1 nói rõ: *"dùng chung đường dữ liệu để **tiết kiệm chân**"*. Với
Tiny Tapeout, một ô có **đúng 24 chân**. Phương án (B) cần 28 chân **chỉ riêng cho đầu ra** —
**không khả thi về mặt vật lý**, không phải "kém hơn". Đây là kiểu ràng buộc mà không phân
tích diện tích nào thay thế được.

### Cái giá của (A) mà phải nói thẳng

**Độ sáng giảm 4 lần.** Mỗi LED chỉ nhận dòng trong 1/4 thời gian. Trên phần cứng thật,
người ta bù bằng cách tăng dòng đỉnh 4 lần (LED chịu được dòng xung cao hơn dòng liên tục).
Việc đó thuộc **thiết kế điện, ngoài phạm vi** (Charter mục 3 loại "điều khiển dòng").
Nhân thêm với duty PWM `brightness/256`, độ sáng cảm nhận thực tế là
`(1/4) × (brightness/256)` — với `brightness = 64` chỉ còn **6,25 %** mức tối đa.

## 3. Đánh đổi nội bộ #1 — một bộ đếm 10 bit thay vì hai bộ đếm 8 bit

| | Một bộ đếm 10 bit (**đã chọn**) | Hai bộ đếm riêng |
|---|---|---|
| Flip-flop | **10** (đo thật trong netlist) | ≥ 16 |
| Diện tích FF | 10 × 25,024 = **250,240 µm²** | ≥ 16 × 25,024 = 400,384 µm² |
| Chênh lệch | — | **+150,144 µm² (+16,3 %** diện tích khối) |
| Đồng pha PWM ↔ khe | ✅ **bảo đảm bằng xây dựng** | ❌ phải tự đồng bộ bằng tay |
| Rủi ro Charter mục 10 | **triệt tiêu** | **hiện hữu** |
| Linh hoạt | ❌ Độ phân giải PWM và số chữ số **khoá cứng** vào nhau | ✅ chỉnh độc lập |

> Đây là **đánh đổi hay nhất của thiết kế này**: tiết kiệm 6 flip-flop **và đồng thời** khử
> hẳn một lớp lỗi. Hiếm khi có phương án vừa nhỏ hơn vừa an toàn hơn. Cái mất là tính linh
> hoạt: muốn PWM 10 bit thì `phase` phải 12 bit, tần số khung tụt 4 lần.

## 4. Đánh đổi nội bộ #2 — không đăng ký `bcd_digits`

| | Không đăng ký (**hiện tại**) | Có thanh ghi 16 bit |
|---|---|---|
| Flip-flop | 10 | ≈ 26 |
| Diện tích thêm | 0 | **+400,384 µm²** = **+43,4 %** *(phép nhân từ thư viện; chưa tính logic `load`)* |
| Đường tới hạn `seg` | `bcd_digits → seg`, **in→out tổ hợp 2,70 ns** | `reg → seg`, ngắn hơn và **thuộc miền clock** |
| Xé hình | ✅ có | ❌ không |
| Charter mục 4 (nạp 2 nhịp) | ❌ **CHƯA THOẢ** | ✅ nền tảng để làm |
| Nghĩa vụ tầng ngoài | Phải giữ dữ liệu ổn định 1024 chu kỳ | Chỉ cần ổn định 1 chu kỳ quanh `load` |

**Phán xử:** đây là đánh đổi **sai hướng** so với Charter. Nó tiết kiệm 43 % diện tích của
một khối vốn đã nhỏ hơn dự kiến 3 lần, để đổi lấy một khuyết tật chức năng (xé hình) và một
khoản nợ so với Charter mục 4. Nhưng **không được tự sửa** (SPEC §0.2) — cần giảng viên duyệt.

## 5. Đánh đổi nội bộ #3 — chi phí của "tắt số 0 vô nghĩa ở đầu"

| Chỉ số | Giá trị | Nguồn |
|---|---:|---|
| Cell dò 0 (3 × `nor4_1`) | 3 cell · **18,768 µm²** · **2,0 %** diện tích | Đếm `nor4_1` trong `synth_stat.txt` (5 cái: 3 cho blank, 2 cho `brightness != 0`) |
| Cell logic ưu tiên + mux | **không tách được** | Đã gộp vào mux chữ số bởi ABC |
| Chi phí thời gian | `nor4_1` là **cổng đầu tiên** trên đường tới hạn, tốn **0,57 ns / 1,70 ns** logic = **33,5 %** | `sta/timing_report_max.txt` |

> ❗ **Kết luận quan trọng:** tính năng này **rẻ về diện tích** (2 %) nhưng **đắt về thời
> gian** (33,5 % đường tới hạn). Lý do bản chất: `d3 == 0` phải biết **trước** khi chọn được
> chữ số, và kết quả đó chi phối cả ba khe trên (bất biến INV-9) nên `nor4_1` có fanout 6.
> Nó nằm ở **đầu** chuỗi phụ thuộc, không song song với nó.
>
> **Để có con số chính xác** cho câu hỏi Charter mục 2 số 3, cần chạy tổng hợp **lần hai** với
> `blank_leading_zero` buộc bằng `1'b0` rồi lấy hiệu diện tích. `⬜ chưa chạy` — xem
> `implementation-notes_J04.md` §7.

## 6. Đánh đổi công suất ↔ tần số quét

Công suất động tỉ lệ tuyến tính với `f_clk` (`P_dyn ≈ α·C·V²·f`). Bảng dưới **ngoại suy
tuyến tính** từ một điểm đo thật, và được ghi rõ là ngoại suy.

| `f_clk` | Tần số khung (`f_clk/1024`) | So với ngưỡng 60 Hz | Công suất động (ngoại suy) |
|---:|---:|---:|---|
| **100 MHz** (giả định SDC) | 97 656,25 Hz | ×1 627,6 | **5,52e-05 W** ← **điểm đo thật** |
| 10 MHz (giả định `test_scan`) | 9 765,63 Hz | ×162,8 | ≈ 5,5e-06 W |
| 1,024 MHz | 1 000,00 Hz | ×16,7 | ≈ 5,7e-07 W |
| **102,4 kHz** | 100,00 Hz | ×1,67 | ≈ 5,7e-08 W |
| **61,44 kHz** | **60,00 Hz** | **×1,00** ← biên | ≈ 3,4e-08 W |

Rò (leakage) **không** đổi theo tần số: **3,53e-10 W** (`power_report.txt`). Ở 61,44 kHz nó
trở thành ~1 % tổng công suất thay vì ~0,0006 % như ở 100 MHz.

> ⚠️ Chỉ **hàng 100 MHz là số đo**. Các hàng khác là phép nhân tuyến tính, hợp lệ ở bậc nhất
> nhưng chưa tính tới việc slew chậm hơn ở tần số thấp. Muốn số thật phải chạy lại OpenSTA
> với `create_clock` khác — `⬜ chưa chạy`.

**Kết luận:** chạy J04 ở 100 MHz là **lãng phí 1 628 lần** so với nhu cầu. Điểm vận hành hợp
lý là **100 kHz – 1 MHz**. Đây là câu trả lời định lượng cho nửa sau của Charter mục 9
("đủ thấp để không phí công suất").

## 7. Những đánh đổi **KHÔNG được phép** trong đề này

| Đánh đổi bị cấm | Căn cứ | Vì sao ghi ở đây |
|---|---|---|
| Tăng lên nhiều hơn **bốn** chữ số | Charter mục 3 — ngoài phạm vi | Có người sẽ đề xuất "mở rộng cho 6 chữ số dễ mà" |
| Đổi sang **ma trận LED** | Charter mục 3 — ngoài phạm vi | |
| Thêm mạch **điều khiển dòng** (chopper, current sink) | Charter mục 3 — ngoài phạm vi | Đây là cách "đúng" để bù độ sáng 1/4, nhưng bị cấm |
| **Tự tối ưu netlist bằng tay** | Charter mục 3 (áp dụng cho mọi đề) | Netlist phải là sản phẩm của Yosys, không sửa tay |
| **Tự làm physical design, sign-off, tape-out** | Charter mục 3 | Bước 7–13 của vòng đời phải ghi `⬜` / `⬛` |
| **Tự sửa RTL** cho khớp Charter mục 4 | SPEC §0.2 của học phần | Phải báo cáo chênh lệch, chờ giảng viên duyệt |

## 8. Bảng tổng kết đánh đổi

| Quyết định | Được gì (số thật) | Mất gì | Phán xử |
|---|---|---|---|
| Quét đa hợp thay vì song song | 9 chân thay vì 28 | Độ sáng còn 1/4 | ✅ **Bắt buộc** trong bối cảnh 24 chân |
| Một bộ đếm 10 bit | −150,144 µm², khử rủi ro Charter mục 10 | PWM và số chữ số khoá cứng | ✅ **Tốt** |
| PWM lồng trong khe quét | Không cần logic đồng bộ nào | Duty tối đa 255/256 | ✅ **Tốt** |
| Không đăng ký `bcd_digits` | −400,384 µm² | Xé hình; đường in→out 2,70 ns; nợ Charter mục 4 | ⚠️ **Nghi vấn** — cần duyệt |
| `digit_sel` 2 bit nhị phân | −2 chân so với one-hot 4 bit | Tầng ngoài phải giải mã; nợ Charter mục 4 | ⚠️ **Nghi vấn** |
| `brightness` 8 bit thay vì 3 bit | Độ phân giải 256 mức | +5 chân; nợ Charter mục 4 | ⚠️ **Nghi vấn** |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
