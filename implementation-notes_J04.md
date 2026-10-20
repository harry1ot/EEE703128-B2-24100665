# J04 — Bộ điều khiển bốn LED 7 đoạn theo phương pháp quét đa hợp · Ghi chú thực hiện

---

## 1. Bài toán này thực chất là gì

Bề ngoài đây là bài "hiện số lên LED". Thực chất nó là bài **đổi tài nguyên không gian lấy
tài nguyên thời gian**. Bốn LED 7 đoạn nếu lái song song cần 28 đường tín hiệu; một ô Tiny
Tapeout chỉ có **24 chân cho tất cả mọi thứ**, kể cả đầu vào. Phương án song song không phải
"tốn hơn" — nó **bất khả thi về vật lý**.

Quét đa hợp giải bài toán bằng cách chấp nhận rằng **mắt người là một bộ lọc thông thấp**.
Nếu lần lượt bật từng LED đủ nhanh, võng mạc tích phân bốn ảnh rời rạc thành một ảnh liên
tục. Ta đã "mượn" khả năng tích phân của mắt để tiết kiệm 19 chân.

Nhưng việc mượn đó đi kèm **hoá đơn**: mỗi LED chỉ sáng 1/4 thời gian nên tối đi bốn lần;
và nếu quét chậm quá ngưỡng, ảo giác sụp đổ và người dùng thấy nhấp nháy. Vì vậy J04 không
phải bài toán logic — nó là bài toán **chọn điểm vận hành** giữa một ràng buộc sinh lý
(≈60 Hz) và một ràng buộc kỹ thuật (công suất động tỉ lệ với tần số). Charter mục 9 hỏi đúng
câu đó, và câu trả lời phải là **một con số của chính mình**.

Lớp thứ ba của bài toán là **ghép ba chức năng lên cùng một trục thời gian**: quét, PWM, và
tắt số 0 vô nghĩa. Ba chức năng ấy có thể làm rời rạc — và đó là chỗ đa số thiết kế đi sai.

## 2. Bản chất kỹ thuật — cơ chế hoạt động

Cơ chế cốt lõi của J04 nằm ở **một dòng khai báo**: `logic [9:0] phase;`.

Không phải "một bộ đếm quét 2 bit và một bộ đếm PWM 8 bit". Là **một** bộ đếm 10 bit, rồi
**cắt** nó ra:

```
      phase[9]  phase[8] │ phase[7] ... phase[0]
      └────┬─────────────┘ └────────┬──────────┘
        S = khe quet          Q = pha PWM
```

Điều này tạo ra một bất biến **không thể phá vỡ bằng lỗi lập trình**: `S` chỉ đổi khi `Q`
tràn từ 255 về 0. Nói cách khác, **mỗi khe quét chứa đúng một chu kỳ PWM trọn vẹn**, và điều
đó đúng theo **cấu trúc bit**, không phải theo sự cẩn thận của người viết mã.

Đây chính là rủi ro mà Charter mục 10 cảnh báo: *"Hai bộ đếm chạy không đồng bộ với nhau →
độ sáng nhấp nháy không đều."* Với hai bộ đếm riêng, nếu chu kỳ quét không chia hết cho chu
kỳ PWM, khe 0 có thể nhận đoạn `Q = 0…255` còn khe 1 nhận `Q = 137…255, 0…136` — bốn LED
nhận bốn duty khác nhau và "thở" chậm theo nhịp phách (beat frequency). Bug này **rất khó
thấy trên waveform ngắn** vì nó chỉ lộ sau hàng nghìn chu kỳ.

Cơ chế thứ hai đáng nói là **chuỗi phụ thuộc của tính năng tắt số 0 đầu**. Ba điều kiện:

```
  tat_khe3 = (d3 == 0)
  tat_khe2 = (d3 == 0) ∧ (d2 == 0)
  tat_khe1 = (d3 == 0) ∧ (d2 == 0) ∧ (d1 == 0)
```

Chúng **lồng nhau**. Kết quả `d3 == 0` phải sẵn sàng **trước** khi biết chữ số nào được chọn,
và nó chi phối **cả ba** khe trên. Vì vậy cổng tính `d3 == 0` không thể chạy song song với
đường chọn chữ số — nó nằm **nối tiếp phía trước**. STA xác nhận chính xác điều này: cổng đầu
tiên trên đường tới hạn là `_138_/A (nor4_1)` với fanout 6, tốn **0,57 ns trên tổng 1,70 ns
logic** — tức **33,5 %** đường tới hạn cho một phép so sánh với 0.

Đây mới là nút thắt thật của J04. **Không phải** bộ giải mã 7 đoạn (bảng tra 10 mục, phẳng),
**không phải** bộ so sánh PWM 8 bit (ABC ánh xạ thành cây, và nó chạy **song song** với đường
chọn chữ số rồi mới hợp lưu ở cổng AND cuối), và **không phải** bộ đếm 10 bit (reg→reg chỉ
1,48 ns).

## 3. Đọc mã nguồn: RTL làm gì, từng dòng quan trọng

### 3.1 Dòng tạo ra toàn bộ thời gian của khối (dòng 82–89)

```systemverilog
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)          phase <= 10'd0;
        else if (!enable)    phase <= 10'd0;
        else                 phase <= phase + 10'd1;
    end
```

Ba điểm phải nhận ra. **Một:** reset là **bất đồng bộ** (`negedge rst_n` trong danh sách nhạy)
— nên STA sinh `recovery/removal check`, và đó là lý do báo cáo có nhóm `Path Group:
asynchronous`. **Hai:** `enable = 0` không "tạm dừng" mà **về 0** — thiết kế chọn khởi động
lại khung thay vì tiếp tục, tránh tình trạng một LED bị kẹt sáng. **Ba:** không có nhánh
`else` nào bỏ trống ⟹ không sinh latch; netlist xác nhận 0 cell `dlatch`.

### 3.2 Dòng biến bộ đếm thành con trỏ khe quét (dòng 17)

```systemverilog
    assign digit_sel = phase[9:8];
```

Một dòng, **0 cell logic**. Yosys thậm chí đổi tên hai flip-flop cao thành `digit_sel[0]` và
`digit_sel[1]`, nên `synth_stat.txt` không còn net nào tên `phase[8]`/`phase[9]`. Sinh viên
hay hoảng "mất 2 FF" — chúng chỉ bị đổi tên.

### 3.3 Chuỗi ưu tiên tắt số 0 (dòng 42–47)

```systemverilog
            else case(i)
                2'd3: selected_with_blank = (d3==0) ? 4'hF : d3;
                2'd2: selected_with_blank = (d3==0 && d2==0) ? 4'hF : d2;
                2'd1: selected_with_blank = (d3==0 && d2==0 && d1==0) ? 4'hF : d1;
                default: selected_with_blank = d0;
            endcase
```

`default` bắt `i == 2'd0` và **không có điều kiện tắt** — chữ số hàng đơn vị **luôn hiện**.
Đây là đặc tả đúng: giá trị 0 phải đọc được là `"   0"` chứ không phải màn hình trống.
`reference_model.py::test_0000` kiểm chính xác tính chất này.

Giá trị canh gác `4'hF` là một **thủ thuật mã hoá** đáng học: thay vì thêm một tín hiệu
`blank_valid` riêng, nó mượn một mã nằm ngoài miền BCD. Chi phí bằng 0 vì `decode7` vốn đã
trả `7'b0000000` cho mọi mã ≥ 10 (nhánh `default` dòng 63).

### 3.4 PWM và cổng chặn (dòng 76–79)

```systemverilog
        if (display_active && (phase[7:0] < brightness))
            seg = seg_raw;
        else
            seg = 7'b0000000;
```

Phép so sánh **`<` chứ không `<=`** quyết định miền duty là `0 … 255/256`, **không bao giờ
đạt 100 %**. Với `brightness = 255`, chu kỳ `Q = 255` vẫn tắt. Đây là đánh đổi cổ điển của
PWM dựa trên so sánh, và `reference_model.py::test_brightness` khẳng định đúng nó:
`assert not pwm(255,255)`.

### 3.5 Một dòng phơi bày khuyết tật kiến trúc (dòng 18)

```systemverilog
    assign display_active = enable && (brightness != 8'h00);
```

`brightness == 0` được xử lý **ngoài** bộ so sánh PWM, qua một đường riêng. Nếu chỉ dựa vào
`Q < brightness` thì `brightness = 0` cũng cho duty 0 — vậy vì sao cần dòng này? Vì
`display_active` còn là **tín hiệu ra**: tầng ngoài dùng nó để tắt driver LED và tiết kiệm
điện. Nhưng nó là **tổ hợp thuần, không đăng ký** ⟹ glitch trên `brightness` truyền thẳng ra
chân. Với LED vô hại; với logic tầng ngoài thì không.

## 4. Vì sao chọn kiến trúc này

| Quyết định | Lý do | Có đúng không |
|---|---|---|
| Quét đa hợp | 24 chân là ràng buộc cứng; phương án song song cần 28 chân **chỉ cho đầu ra** | ✅ bắt buộc |
| Một bộ đếm 10 bit | Đồng pha PWK↔khe **bằng xây dựng**; −6 FF = −150,144 µm² | ✅ xuất sắc |
| `digit_sel` 2 bit nhị phân | Tiết kiệm 2 chân so với one-hot | ⚠️ trái Charter mục 4 |
| `bcd_digits` không đăng ký | −400,384 µm² (−43,4 %) | ⚠️ gây xé hình, trái Charter mục 4 |
| Mã canh gác `4'hF` cho "tắt" | Dùng lại nhánh `default` của `decode7`, chi phí 0 | ✅ tinh tế |

Chi tiết và ba kiến trúc thay thế: `03_ARCHITECTURE/tradeoff.md`.

## 5. Cách thực hiện — lộ trình 8 bước từ đặc tả tới GDSII

| Bước | Việc | Trạng thái J04 | Bằng chứng |
|:-:|---|---|---|
| 1 | Đọc Charter, lập bảng yêu cầu có truy vết | ✅ | `01_REQUIREMENT/requirements.md` |
| 2 | Viết đặc tả hành vi + bất biến (INV-1…10) **trước khi** đọc RTL | ✅ | `02_SPECIFICATION/functional_spec.md` |
| 3 | Viết mô hình chuẩn độc lập (Python) và cho nó PASS | ✅ 7/7 | `python_reference_run.log` |
| 4 | Viết RTL; đối chiếu ánh xạ chân với Charter mục 4 | ⚠️ **lệch** | cảnh báo đầu `functional_spec.md` |
| 5 | Viết testbench **tự kiểm** nối mô hình chuẩn vào RTL | ❌ **chưa có scoreboard** | `corner_cases.md` §0 |
| 6 | Tổng hợp (Yosys) và **đọc netlist** để xác minh kiến trúc | ✅ | 122 cell · 10 FF · 922,1344 µm² |
| 7 | STA và **lọc theo `Path Group`** để tìm đường tới hạn thật | ✅ | `sta/summary.txt` dòng 2 |
| 8 | Place & route, DRC/LVS, GDS | ⬜ chưa chạy | `system_diagram.md` §5 |

Điểm gãy của J04 là **bước 5**. Mô hình chuẩn đã có và đã PASS, RTL đã có, nhưng hai thứ đó
chưa bao giờ gặp nhau.

## 6. Số liệu thật đã đo được và cách đọc chúng

| Chỉ số | Giá trị | **Chứng minh** gì | **Không** chứng minh gì |
|---|---:|---|---|
| 122 cell | | RTL tổng hợp được ra standard cell sky130 | Không nói hành vi đúng |
| 10 flip-flop | | Có đúng một bộ đếm 10 bit, **không** phải hai bộ đếm | Không nói bộ đếm đếm đúng |
| 922,1344 µm² | | Quy mô khả thi cho 1×1 tile | Chưa có số sau P&R (routing sẽ làm phình) |
| Slack 6,30 ns / arrival 2,70 ns | | Ở giả định `T = 10 ns`, đường `bcd_digits[12] → seg[3]` **còn dư** 6,30 ns | **Không** phải "chạy được ở 100 MHz" — clock lý tưởng, chưa có RC |
| WNS 0,00 / TNS 0,00 | | Không có đường nào vi phạm dưới giả định hiện tại | Không nói gì về các góc PVT khác |
| 5,52e-05 W | | Ước lượng ở `f_clk` ứng với `T = 10 ns` | **Tỉ lệ tuyến tính với `f_clk`** — con số này vô nghĩa nếu không nói kèm tần số |
| Tuần tự 78,0 % / tổ hợp 22,0 % | | Bộ đếm lật **mỗi chu kỳ** nên chiếm đa số công suất | Trái với tỉ lệ diện tích (FF chỉ 27,1 %) — không mâu thuẫn, xem `datapath.md` §6 |
| Mô phỏng RTL "PASS" | | Chạy 4096 chu kỳ = **4 khung quét**, không treo | ❌ **Không** chứng minh `seg` đúng — testbench 0 assertion |
| Python reference PASS 7/7 | | **Đặc tả** tự nhất quán | ❌ Không chứng minh RTL khớp đặc tả |

> Cách kiểm chéo đáng tin nhất trong hồ sơ này: `$finish` ở `t = 40985`. Với `always #5 clk`
> và `3 + 4×1024 = 4099` cạnh lên, cạnh cuối ở `5 + 4098×10 = 40985`. ✅ Khớp tuyệt đối ⟹
> testbench thực sự chạy đủ 4 khung.

## 7. Trả lời các câu hỏi kỹ thuật của Charter (mục 2)

**Câu 1 — Chu kỳ quét phải nhanh bao nhiêu để mắt không thấy nháy, và đo được trên waveform
không?**

Ngưỡng thường dùng là **60 Hz mỗi LED**. Vì `phase` 10 bit, một khung = **1024 chu kỳ clock**,
nên `f_clk ≥ 60 × 1024 = 61 440 Hz`. **Đo được trên waveform về nguyên tắc** — chỉ cần đếm
số chu kỳ giữa hai lần `digit_sel` trở về `00`. Nhưng **hồ sơ hiện chưa có bằng chứng** vì
testbench không gọi `$dumpfile`/`$dumpvars` ⟹ không sinh VCD. Cần bổ sung 2 dòng vào testbench
rồi chạy lại. Bằng chứng gián tiếp hiện có: `$finish @ 40985` chứng minh đã chạy đúng 4 khung.

**Câu 2 — PWM chỉnh độ sáng lồng vào chu kỳ quét như thế nào: hai bộ đếm hay một?**

**Một.** Bằng chứng ở ba mức: (a) RTL chỉ khai báo `logic [9:0] phase` và không có biến đếm
nào khác; (b) netlist có **đúng 10** `dfrtp_1` — hai bộ đếm riêng phải ≥ 16; (c) `digit_sel`
được ánh xạ **trực tiếp** lên hai flip-flop cao của chính bộ đếm đó. Hệ quả: `S` chỉ đổi khi
`Q` tràn ⟹ mỗi khe chứa đúng một chu kỳ PWM ⟹ bốn LED có duty giống hệt nhau. Chi phí tiết
kiệm: `6 × 25,024 = 150,144 µm²` (16,3 % diện tích khối).

**Câu 3 — Chế độ tắt số 0 vô nghĩa ở đầu tốn bao nhiêu logic?**

Tách được **một phần** bằng số thật: netlist có 5 `nor4_1`, trong đó **3** dùng cho `d3==0`,
`d2==0`, `d1==0` (2 cái còn lại dùng cho `brightness != 0`, vì 8 bit = 2 × NOR4 + 1 hợp).
Vậy riêng ba bộ dò 0 = `3 × 6,256 = 18,768 µm²` = **2,0 %** diện tích khối. Phần logic ưu tiên
và mux đã bị ABC **gộp** vào mux chọn chữ số nên **không tách được chính xác**.

Chi phí **thời gian** thì đo trực tiếp được và lớn hơn nhiều: `nor4_1` là cổng đầu tiên trên
đường tới hạn, tốn **0,57 ns** trên tổng **1,70 ns** logic ⟹ **33,5 %** đường tới hạn.

⬜ **Để có con số diện tích chính xác:** chạy Yosys lần hai trên một bản RTL có
`blank_leading_zero` buộc `1'b0`, rồi lấy hiệu `Chip area`. Chưa chạy.

## 8. Trả lời câu phân tích riêng (Charter mục 9)

> *"Tính tần số quét thực tế của thiết kế mình từ xung nhịp và bộ chia, đối chiếu với ngưỡng
> ~60 Hz mỗi LED, và đưa phép tính vào báo cáo."*

**Bộ chia của thiết kế này, đọc từ RTL:** `phase` rộng 10 bit; `digit_sel = phase[9:8]` ⟹ hệ
số chia tới tần số khung là `2^10 = 1024`. Mỗi LED sáng **một lần** mỗi khung, nên tần số làm
tươi mỗi LED **bằng** tần số khung:

```
    f_refresh = f_clk / 1024        (Hz moi LED)
    f_pwm     = f_clk / 256         (Hz)
    duty      = brightness / 256    (0 … 255/256)
```

**Đối chiếu với ba giá trị `f_clk` có mặt trong hồ sơ:**

| Nguồn của `f_clk` | `f_clk` | `f_refresh` | So với 60 Hz | Kết luận |
|---|---:|---:|---:|---|
| `design.sdc` (`create_clock -period 10.0`) | 100 MHz | **97 656,25 Hz** | **×1 627,6** | Thừa xa, lãng phí công suất |
| `reference_model.py::test_scan` (`10_000_000/1024 > 60`) | 10 MHz | **9 765,63 Hz** | **×162,8** | Vẫn thừa ~163 lần |
| Điểm vận hành đề xuất | **102,4 kHz** | **100,00 Hz** | ×1,67 | Đủ lề an toàn, rất tiết kiệm |
| **Cận dưới tuyệt đối** | **61,44 kHz** | **60,00 Hz** | ×1,00 | Biên — không nên vận hành ở đây |

**Phép tính cận dưới:** `f_clk,min = 60 Hz × 1024 = 61 440 Hz = 61,44 kHz`.

**Nửa sau của câu hỏi — "đủ thấp để không phí công suất":** công suất động tỉ lệ tuyến tính
với `f_clk`. Điểm đo thật duy nhất là **5,52e-05 W tại `f_clk` ứng với `T = 10 ns`**. Ngoại
suy tuyến tính (ghi rõ là **ngoại suy**, không phải đo): ở 102,4 kHz công suất động rơi về
khoảng **5,7e-08 W**, tức **giảm ~977 lần**. Rò không đổi ở **3,53e-10 W**.

**Kết luận định lượng:** giả định 100 MHz trong `design.sdc` cho tần số quét **thừa 1 628
lần** so với nhu cầu sinh lý. Điểm vận hành hợp lý cho một đồng hồ đo là **100 kHz – 1 MHz**,
cho `f_refresh` 100 Hz – 1 kHz. ⚠️ Nhắc lại: `T = 10 ns` trong SDC là **giả định phân tích
khởi điểm**, không phải yêu cầu hệ thống (`02_SPECIFICATION/timing.md` §3).

## 9. Những chỗ sinh viên hay sai và cách phát hiện

| # | Sai lầm | Hậu quả | **Phát hiện bằng bằng chứng nào** |
|:-:|---|---|---|
| 1 | Dùng **hai** bộ đếm riêng cho quét và PWM | Bốn LED có độ sáng khác nhau, "thở" theo nhịp phách | Đếm `dfrtp_1` trong `synth_stat.txt`: **> 10 là dấu hiệu**. Trên waveform: đo số chu kỳ `seg != 0` ở từng khe, bốn giá trị phải bằng nhau |
| 2 | Coi "mô phỏng PASS" là "RTL đúng" | Giao nộp một thiết kế chưa bao giờ được kiểm | Mở testbench, đếm số `assert`/`$fatal`. J04 hiện có **0** |
| 3 | Đọc `timing_report_max.txt` dòng đầu và tuyên bố đường tới hạn là `rst_n → _216_` | Kết luận sai hoàn toàn về nút thắt | Xem cột `Path Group`. Dòng đầu là `asynchronous` (recovery), arrival = đúng 1,00 ns = input delay, **0 cổng logic**. Đường thật là dòng 2 của `summary.txt` |
| 4 | Nói "chạy được ở 100 MHz vì slack dương" | Phát biểu vượt mức | `timing.md` §3: clock **lý tưởng**, chưa CTS, chưa RC, một góc PVT. Chỉ được nói "dưới giả định T = 10 ns, còn dư 6,30 ns" |
| 5 | Tưởng `brightness = 255` cho duty 100 % | Sai 1/256 ở biên | RTL dùng `<` không `<=`. `reference_model.py`: `assert not pwm(255,255)` |
| 6 | Quên rằng chữ số hàng đơn vị **không** được tắt | Hiện `0` thành màn hình trống | `test_0000` trong mô hình chuẩn; nhánh `default` dòng 46 của RTL |
| 7 | Tưởng "mất 2 flip-flop" vì netlist không có `phase[8]`,`phase[9]` | Kết luận sai là công cụ tối ưu mất bit | Grep `.Q(` trong `netlist.v`: có `digit_sel[0]`, `digit_sel[1]` — Yosys **đổi tên**, tổng vẫn 10 |
| 8 | Đổi `bcd_digits` bất cứ lúc nào | Xé hình giữa khe | `seg` là tổ hợp thuần; STA có đường `bcd_digits[12] → seg[3]` **in→out**. Kiểm bằng ca CA-T2 |
| 9 | Nói "quét đa hợp tiết kiệm diện tích" | Sai bản chất | Nó tiết kiệm **chân**, và **tốn** thời gian (độ sáng 1/4). Diện tích chỉ là hệ quả phụ của việc chỉ cần 1 bộ giải mã |
| 10 | Trả lời Charter mục 9 bằng "quét nhanh hơn 60 Hz là được" | Bỏ mất nửa sau của câu hỏi | Phải có bảng số như §8, gồm cả cận trên theo công suất |

## 10. Câu hỏi mentor nên đặt khi bảo vệ

| # | Câu hỏi | Đáp án mong đợi |
|:-:|---|---|
| 1 | Thiết kế của em có mấy bộ đếm? Chứng minh bằng netlist. | Một. `synth_stat.txt` ghi đúng **10** `dfrtp_1` = `phase[7:0]` + `digit_sel[1:0]`. Hai bộ đếm riêng phải ≥ 16 FF. |
| 2 | Tần số quét của em là bao nhiêu, và em lấy `f_clk` ở đâu? | `f_clk/1024`. `f_clk` **không** phải số của thiết kế — `T = 10 ns` trong SDC chỉ là giả định phân tích. Cận dưới thật: 61,44 kHz cho 60 Hz/LED. |
| 3 | Vì sao khe quét không bị lệch pha so với PWM? | Vì `S = phase[9:8]` và `Q = phase[7:0]` **thuộc cùng một thanh ghi**. `S` chỉ đổi khi `Q` tràn — đúng theo cấu trúc bit, không cần logic đồng bộ nào. |
| 4 | Đường tới hạn của thiết kế nằm ở đâu, và vì sao? | `bcd_digits[12] → seg[3]`, arrival 2,70 ns, slack 6,30 ns. Cổng đầu là `nor4_1` tính `d3 == 0` — vì kết quả đó chi phối cả ba khe trên nên nằm **nối tiếp phía trước** mux chọn chữ số. |
| 5 | Vì sao `rst_n → _216_` đứng đầu báo cáo nhưng không phải đường tới hạn? | Vì nó thuộc `Path Group: asynchronous` (recovery check), arrival = đúng 1,00 ns input delay và **không đi qua cổng nào**. Thứ tự in không phải thứ tự chậm. |
| 6 | "Mô phỏng PASS" của em chứng minh điều gì? | Chỉ chứng minh chạy 4096 chu kỳ (4 khung) không treo. Testbench **không có assertion nào**; mô hình chuẩn Python chưa được nối vào RTL. Đây là khoảng trống lớn nhất. |
| 7 | `brightness = 255` cho duty bao nhiêu? | 255/256 ≈ 99,61 %, **không** phải 100 %, vì so sánh dùng `<`. |
| 8 | Nếu `bcd_digits` là `16'h0000` và bật chế độ tắt, màn hình hiện gì? | `"   0"` — ba chữ số đầu tắt, hàng đơn vị **luôn hiện**. Nhánh `default` của `selected_with_blank` không có điều kiện tắt. |
| 9 | Tính năng tắt số 0 đầu tốn bao nhiêu? | Diện tích: **≥ 18,768 µm²** (3 × `nor4_1`) = 2,0 % — phần còn lại đã bị ABC gộp, cần chạy tổng hợp lần hai để tách. Thời gian: **33,5 %** đường tới hạn. |
| 10 | Thiết kế em có 122 cell, Charter ước ~400–560. Vì sao? | Vì RTL **thiếu** thanh ghi nạp chữ số (−16 FF) và cơ chế nạp hai nhịp mà Charter mục 4 yêu cầu, đồng thời gộp hai bộ đếm (−6 FF). Số nhỏ là dấu hiệu **thiếu chức năng**, không phải làm giỏi. |
| 11 | Nếu một bit của `phase` bị lật do nhiễu thì sao? | Tự phục hồi. Không gian mã 10 bit **phủ kín** 1024 trạng thái nên không có trạng thái chết. Triệu chứng: một khung hiển thị sai thứ tự rồi tự đúng lại. |
| 12 | Muốn PWM 10 bit thì phải đổi gì? | `phase` lên 12 bit ⟹ +2 FF, và tần số khung **giảm 4 lần** ⟹ `f_clk,min` tăng lên 245,76 kHz. Đây là cái giá của việc gộp hai bộ đếm. |

## 11. Giới hạn: đã chứng minh được gì, chưa chứng minh được gì

### Đã chứng minh

- RTL **tổng hợp được** ra 122 standard cell sky130, 922,1344 µm² (`synth_stat.txt`).
- Thiết kế dùng **đúng một** bộ đếm 10 bit — xác minh bằng số flip-flop và tên net trong netlist.
- Dưới giả định `T = 10 ns`, IO delay 1 ns, clock **lý tưởng**, thư viện `tt_025C_1v80`: WNS
  và TNS bằng 0; đường dữ liệu xấu nhất còn dư **6,30 ns**.
- Đường tới hạn dữ liệu đi qua **bộ dò `d3 == 0`**, không phải bộ giải mã hay bộ so sánh PWM.
- Đặc tả (mô hình chuẩn Python) **tự nhất quán**: 7/7 test PASS.
- Testbench chạy đúng **4 khung quét đầy đủ** — xác minh bằng `$finish @ 40985`.

### Chưa chứng minh

| Điều chưa chứng minh | Cần gì để chứng minh |
|---|---|
| **RTL khớp mô hình chuẩn** | Viết scoreboard nối `reference_model.py` vào testbench. **Đây là việc quan trọng nhất còn thiếu.** |
| Chu kỳ quét quan sát được trên waveform | Thêm `$dumpfile`/`$dumpvars` và chạy lại → sinh VCD |
| Duty PWM đúng bằng `brightness` | Ca CA-T6 (đếm chu kỳ sáng trong một khe) |
| Hành vi khi `brightness = 0` | Ca CA-T1 — giá trị này **chưa bao giờ** được lái vào RTL |
| Hành vi với nibble ngoài miền BCD | Ca CA-T4 |
| Netlist tương đương RTL | Mô phỏng gate-level (L4) — `⬜ chưa chạy` |
| Độ trễ lan truyền thật | Mô phỏng post-layout có SDF (L5) — `⬜ chưa chạy` |
| Tần số hoạt động thật | STA **sau routing**, nhiều góc PVT — chưa có RC |
| Diện tích thật | Sau place & route — con số 922,1344 µm² là **sau tổng hợp logic**, chưa có dây |
| Chi phí chính xác của "tắt số 0 đầu" | Chạy Yosys lần hai với `blank_leading_zero = 1'b0` |
| **Đúng Charter mục 4** | ❌ **CHƯA THOẢ** — ba trên bốn ánh xạ chân lệch; cần giảng viên duyệt hướng xử lý (xem cảnh báo đầu `functional_spec.md`) |

---

*Phiên bản: v1.0 · Ngày: 2026-09-24*
