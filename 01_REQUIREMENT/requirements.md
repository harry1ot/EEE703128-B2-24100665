# J04 · Bảng yêu cầu (Requirements)



Mọi yêu cầu đều **suy trực tiếp từ Project Charter — J04**. Cột *Nguồn* chỉ rõ mục nào
của Charter sinh ra yêu cầu đó. Không có yêu cầu nào do người soạn tự thêm.

Mức: **M** = bắt buộc · **S** = nên có · **O** = tuỳ chọn.

---

## 1. Yêu cầu chức năng và cấu trúc

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-J04-001 | M | Khối thực hiện đúng chức năng mô tả trong Charter mục 1: *Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp*. | mục 1 |
| REQ-J04-002 | M | Giao diện đúng ánh xạ chân Charter mục 4 (xem `02_SPECIFICATION/interface.md`). | mục 4 |
| REQ-J04-003 | M | Loại mạch phải đúng phân loại Charter: **Tuần tự** — có ô nhớ, đồng bộ theo clock. | mục 10 |
| REQ-J04-004 | M | Quy mô nằm trong khoảng hợp lý cho ô 1×1 tile (Charter ước lượng ~400–560 cell · 1×1 tile). | metadata |

## 2. Yêu cầu kiểm chứng

| ID | Mức | Nội dung yêu cầu | Nguồn |
|---|---|---|---|
| REQ-J04-010 | M | Chạy đủ các ca kiểm thử bắt buộc của Charter mục 8 (xem §4). | mục 8 |
| REQ-J04-011 | M | Bổ sung **ít nhất hai ca tự xây dựng**, trong đó có **ca biên**. | mục 8 |
| REQ-J04-012 | M | Mỗi khẳng định phải đi kèm **bằng chứng** và **điều kiện tạo ra bằng chứng**. | mục 6 |
| REQ-J04-013 | S | Thu một **artifact số có chú thích** và nêu điều kiện tạo ra nó. | mục 3, 5 |

## 3. Yêu cầu phân tích riêng (đặc thù của J04)

> Charter mục 9 — bắt buộc trả lời bằng số liệu của chính mình:
>
> Tần số quét phải đủ cao để mắt không thấy nháy nhưng đủ thấp để không phí công suất. Tính tần số quét thực tế của thiết kế mình từ xung nhịp và bộ chia, đối chiếu với ngưỡng ~60 Hz mỗi LED, và đưa phép tính vào báo cáo.
> Bắt buộc trả lời bằng số liệu của chính mình. Mỗi đề một câu khác nhau.

| ID | Mức | Nội dung |
|---|---|---|
| REQ-J04-020 | M | Trả lời câu phân tích riêng ở trên bằng dữ liệu do chính mình sinh ra. |
| REQ-J04-021 | M | Trả lời các câu hỏi kỹ thuật Charter mục 2 (xem §5) bằng bằng chứng. |

## 4. Ca kiểm thử bắt buộc (Charter mục 8)

- Bốn chữ số khác nhau · số có 0 ở đầu (kiểm chế độ tắt) · đổi độ sáng · kiểm chu kỳ quét trên waveform
- Bổ sung ít nhất hai ca tự xây dựng, trong đó có ca biên.

Danh sách thực thi và kết quả: `05_VERIFICATION/test_matrix.csv`.

## 5. Câu hỏi kỹ thuật của Charter (mục 2)

1. **Chu kỳ quét phải nhanh bao nhiêu để mắt không thấy nháy — và đo được trên waveform không?**
2. **PWM chỉnh độ sáng lồng vào chu kỳ quét như thế nào — hai bộ đếm hay một?**
3. **Chế độ tắt số 0 vô nghĩa ở đầu tốn bao nhiêu logic?**

> Sinh viên được phép thay bằng câu hỏi của mình, miễn là cụ thể và trả lời được bằng bằng
> chứng — không viết "tìm hiểu về…". *(Charter mục 2)*

Câu trả lời kèm bằng chứng: `05_VERIFICATION/verification_report.md` và `06_GDSII/physical_report.md`.

## 6. Yêu cầu bàn giao (Charter mục 5)

- Hồ sơ phân tích đủ tám thành phần, có số phiên bản và ngày sửa.
- Bảng giao diện: tên tín hiệu, chiều, độ rộng, mức tích cực, giả định.
- Một artifact số có chú thích và nêu điều kiện tạo ra nó.
- Kết luận nêu rõ đã chứng minh được gì và chưa chứng minh được gì.

## 7. Mốc thực hiện (Charter mục 7)

- M1 · T7. Chốt đề và viết charter: ứng dụng, mục tiêu, 2–3 câu hỏi kỹ thuật.
- M2 · T8–9. Bảng hành vi suy từ đặc tả; đọc RTL và waveform; lập danh sách ca kiểm thử.
- M3 · T11–12. Sơ đồ khối hỗ trợ; thu artifact số, chú thích và đối chiếu bảng hành vi.
- M4 · T13–14. Hoàn thiện bảng giao diện, RTM-lite, sơ đồ vòng đời; rà từng khẳng định.
- M5 · T15. Nộp hồ sơ và trình bày; trả lời câu phân tích riêng bằng số của chính mình.

## 8. Rủi ro chính (Charter mục 10)

> Chỗ hay tắc: Hai bộ đếm (quét và PWM) chạy không đồng bộ với nhau → độ sáng nhấp nháy không đều.
> Dấu hiệu làm đúng: 4×4 (chữ số) + 2 (chọn LED) + 8 (PWM) + 8 (chia quét) ≈ 34–38 ô nhớ.
> Điều kiện giao đề: Chỉ giao khi đã CI xanh trước tuần 11.

---

*Phiên bản: v1.0 · Ngày: 2026-09-24 · Nguồn chuẩn: `Project_Charter_80_De.docx`, mục J04.*
