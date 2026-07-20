# Staff UI Checklist — Kiểm thử & Demo

> **Dự án:** ÉPCINE — Movie Ticket Booking System  
> **Role:** `STAFF` (nhân viên quầy vé offline / POS)  
> **Tài khoản seed:** `staff@movieticket.vn` / `Password@123`  
> **Tham chiếu code:** `CounterBookingServlet`, `CounterHistoryServlet`, `counter-*.jsp`, `counter-booking.js`  
> **Mục đích:** Tick từng item khi kiểm UI, validate field, chạy kịch bản demo / workflow

**Cách dùng:** `[ ]` → chưa check · `[x]` → pass · ghi chú lỗi cạnh item nếu fail.

---

## Mục lục

1. [Phạm vi & luồng tổng](#1-phạm-vi--luồng-tổng)
2. [Checklist phân quyền & điều hướng](#2-checklist-phân-quyền--điều-hướng)
3. [Checklist UI theo màn hình](#3-checklist-ui-theo-màn-hình)
4. [Checklist chung — Validate field / input](#4-checklist-chung--validate-field--input)
5. [Checklist chung — Kịch bản demo](#5-checklist-chung--kịch-bản-demo)
6. [Checklist chung — Workflow end-to-end](#6-checklist-chung--workflow-end-to-end)
7. [Checklist chung — Edge case / lỗi](#7-checklist-chung--edge-case--lỗi)
8. [Ma trận nhanh trước buổi demo](#8-ma-trận-nhanh-trước-buổi-demo)

---

## 1. Phạm vi & luồng tổng

| # | Màn hình | URL | View |
|---|----------|-----|------|
| 1 | Quầy bán vé (POS) | `/staff/counter` | `counter-booking.jsp` |
| 2 | Thanh toán | `/staff/counter?step=payment&bookingId=` | `counter-payment.jsp` |
| 3 | In vé | `/staff/counter?step=print&bookingId=` | `counter-print.jsp` |
| 4 | Lịch sử offline | `/staff/history` | `counter-history.jsp` |

```
Login STAFF → /home
    → Header "Quầy vé" /staff/counter
        → Chọn phim → suất → ghế (± tra cứu TV)
        → POST tạo booking OFFLINE (PENDING/UNPAID)
        → Thanh toán CASH hoặc VietQR
        → In vé + markPrinted
    → /staff/history (lọc / xem / in lại)
```

**Không có trong code Staff:** check-in/scan vé, bán bắp nước, hủy/hoàn tiền đơn đã PAID, đối soát ca.

---

## 2. Checklist phân quyền & điều hướng

### 2.1 Access control

- [ ] Login bằng STAFF → vào được `/staff/counter` và `/staff/history`
- [ ] Chưa login mở `/staff/counter` → redirect login
- [ ] Role CUSTOMER mở `/staff/*` → 403
- [ ] Role MANAGER mở `/staff/*` → 403
- [ ] Role ADMIN mở `/staff/*` → 403
- [ ] STAFF mở `/admin/*` → 403
- [ ] STAFF mở `/manager/*` → 403
- [ ] STAFF mở `/booking-history`, `/checkout`, `/payment` → bị chặn (CUSTOMER only)
- [ ] STAFF vẫn vào được public: `/`, `/home`, `/movies`, `/showtimes`
- [ ] STAFF vào được `/profile`

### 2.2 Header / menu STAFF

- [ ] Dropdown tài khoản có **Tài khoản** → `/profile`
- [ ] Có mục **Quầy vé** → `/staff/counter`
- [ ] Có **Đăng xuất**
- [ ] Không hiện menu Admin / Manager / lịch sử đặt vé online của Customer

### 2.3 Điều hướng trong POS

- [ ] POS: Logo → `/home`; nút **Lịch sử** → `/staff/history`
- [ ] History: **← Quầy bán vé** → `/staff/counter`
- [ ] Payment: **Tạo đơn mới** → `/staff/counter`
- [ ] Print: **✚ Tạo đơn mới** → `/staff/counter`

---

## 3. Checklist UI theo màn hình

### 3.1 Quầy bán vé — `/staff/counter`

#### Header

- [ ] Title **Quầy Bán Vé**
- [ ] Logo ÉpCine (fallback text nếu ảnh lỗi)
- [ ] Hiển thị **Nhân viên: {fullName}** đúng session
- [ ] Badge **OFFLINE**
- [ ] Nút **Lịch sử**

#### Panel trái — Phim & suất

- [ ] Ô search placeholder `Tìm kiếm phim...`
- [ ] Gõ tên → lọc realtime danh sách phim
- [ ] Tab **Đang chiếu** / **Sắp chiếu** chuyển đúng nhóm
- [ ] Item phim: poster (hoặc placeholder chữ cái), title, `{duration} phút`
- [ ] Badge age rating (nếu có)
- [ ] Badge ★ averageRating (nếu > 0)
- [ ] Empty movies: *“Chưa có phim nào… Quản lý cần thêm phim…”*
- [ ] Chọn phim → hiện khối **Chọn suất chiếu**
- [ ] Date tabs + time grid load đúng
- [ ] Loading text *“Đang tải suất chiếu…”*
- [ ] Suất không có → placeholder phù hợp

#### Panel giữa — Sơ đồ ghế

- [ ] Thanh **MÀN CHIẾU**
- [ ] Chưa chọn suất → placeholder *“Chọn phim và suất chiếu để xem sơ đồ ghế”*
- [ ] Legend: Thường / VIP / Cặp đôi / Đang chọn / Đã bán
- [ ] Ghế sold: disabled / không chọn được
- [ ] Ghế đang chọn highlight đúng
- [ ] Phân biệt màu/kiểu STANDARD / VIP / COUPLE

#### Panel phải — Tóm tắt

- [ ] Header **Tóm tắt đặt vé** + badge OFFLINE
- [ ] Chưa chọn: *“Chưa chọn phim”* / *“Chưa có ghế nào”*
- [ ] Chọn xong: hiện phim + suất + danh sách ghế + giá
- [ ] **Tổng tiền** format VND (`#.### ₫`)
- [ ] Section **Tra cứu thành viên (tuỳ chọn)**: SĐT + nút **Tìm**
- [ ] Section KH: họ tên + SĐT (placeholder ghi tùy chọn)
- [ ] Countdown giữ ghế ẩn khi chưa chọn; hiện `01:00` khi đang giữ (đang set 1 phút để test)
- [ ] Cảnh báo member locked (ẩn mặc định)
- [ ] Nút **Tiến hành thanh toán →** disabled khi chưa đủ điều kiện
- [ ] Alert lỗi server (`errorMessage`) hiện đúng khi fail

---

### 3.2 Thanh toán — `step=payment`

#### Layout chung

- [ ] Title **Thanh Toán**; tên NV; badge OFFLINE
- [ ] Alert lỗi (nếu có) kiểu `pos-alert--error`

#### Cột trái — Chi tiết đơn

- [ ] Tag **OFFLINE WALK-IN**
- [ ] **Mã đơn** đúng `bookingCode`
- [ ] Poster / fallback; tên phim; `dd/MM/yyyy HH:mm`; phòng
- [ ] KH: tên + SĐT
- [ ] Từng dòng: `Vé {seatType} — Ghế {seatCode}` + giá
- [ ] Dòng **Tổng cộng** = `finalAmount`
- [ ] Tab **💵 Tiền mặt** / **📱 Chuyển khoản** (active đúng)

#### Cột phải — CASH

- [ ] Label **Tổng cần thanh toán** + số tiền
- [ ] **Tiền nhận** / **Tiền thừa** cập nhật theo numpad
- [ ] Quick: **Vừa đủ**, +50K, +100K, +200K, +500K
- [ ] Numpad: 1–9, 000, 0, ⌫
- [ ] Nút **✓ Xác nhận thanh toán thành công**
- [ ] Link **← Quay lại** | **Tạo đơn mới**

#### Cột phải — VietQR

- [ ] Chưa config: hướng dẫn copy `vietqr.properties.example`
- [ ] Đã config, chưa tạo QR: nút **📲 Tạo mã QR chuyển khoản**
- [ ] Đã tạo QR: ảnh QR + Ngân hàng / STK / Chủ TK / Nội dung CK / Số tiền
- [ ] SePay ON: box chờ + nút **Xác nhận thủ công (nếu SePay chậm)**
- [ ] SePay OFF: nút **✓ Tiền đã vào — tiếp tục in vé**

---

### 3.3 In vé — `step=print`

#### Preview (trái)

- [ ] Title section **Xem trước vé**
- [ ] Mỗi vé: ÉPCINE PREMIUM, mã vé, phim, NGÀY / GIỜ / PHÒNG, GHẾ, tên KH
- [ ] QR render (qrcodejs) đúng `ticket.qrCode`
- [ ] **ADMIT ONE**
- [ ] Fallback khi không có tickets: dùng `bookingCode` + số ghế
- [ ] Note giấy nhiệt 80mm

#### Cài đặt in (phải)

- [ ] **Máy in: Kết nối** (UI status)
- [ ] Số bản in − / + trong khoảng 1–10
- [ ] Radio: Giấy nhiệt (80mm) / Thẻ lưu niệm
- [ ] Checkbox **In kèm biên lai thanh toán** (mặc định checked)
- [ ] **🖨 In vé** mở dialog print
- [ ] **✓ Xác nhận đã in xong**
- [ ] Sau mark OK: nút đổi thành *“✓ Đã lưu trạng thái in”*
- [ ] Card thành công: mã đơn, KH, số vé, badge **ĐÃ THANH TOÁN**, tổng tiền
- [ ] **✚ Tạo đơn mới**

> **Lưu ý demo:** Số bản in / loại giấy / biên lai là UI cosmetic — `window.print()` không nhân bản theo số copies.

---

### 3.4 Lịch sử — `/staff/history`

#### Header & filter

- [ ] Title **Lịch sử đặt vé tại quầy**
- [ ] Nút **← Quầy bán vé**; tên NV; badge OFFLINE
- [ ] Filter: **Từ ngày**, **Đến ngày** (type=date)
- [ ] Select trạng thái: Tất cả / Đã xác nhận / Chờ thanh toán / Đã hủy
- [ ] Search placeholder `Tên, SĐT hoặc mã đơn...`
- [ ] Nút **Lọc** / **Xóa lọc**
- [ ] Quick: **Hôm nay** / **Tuần này** / **Tháng này**
- [ ] Stats: `Tổng: N đơn`; badge **Đang lọc** khi có filter

#### Bảng

- [ ] Empty: *“Không có đơn đặt vé nào phù hợp.”*
- [ ] Cột: Mã đơn | Thời gian đặt | Khách hàng | Phim/Suất | Phòng | Ghế | Tổng tiền | Trạng thái | Nhân viên | Thao tác
- [ ] KH có `userId` → badge **★ TV**
- [ ] Badge booking: Đã xác nhận / Chờ TT / Đã hủy
- [ ] Subline payment: Đã thanh toán / Chưa TT
- [ ] **Xem** → `/staff/history?bookingId=`
- [ ] **In vé** chỉ hiện khi `CONFIRMED` + `PAID`
- [ ] Phân trang 15/page (Trước / số trang / Sau) khi `totalPages > 1`
- [ ] Gõ search client-side ẩn/hiện row theo cột KH trên trang hiện tại

---

## 4. Checklist chung — Validate field / input

Dùng khi demo phải **điền form** hoặc **tương tác control**. Tick theo từng trường hợp.

### 4.1 POS — Chọn phim / suất / ghế

| # | Trường hợp | Thao tác | Kết quả mong đợi | Pass |
|---|------------|----------|------------------|------|
| V01 | Chưa chọn ghế | Bấm **Tiến hành thanh toán** | Nút disabled, không submit | [ ] |
| V02 | Chưa chọn suất | Cố tiến hành | Nút disabled | [ ] |
| V03 | Chọn > 8 ghế | Click ghế thứ 9 | Alert tối đa 8 ghế; không thêm | [ ] |
| V04 | Ghế đã bán | Click ghế sold | Không chọn được | [ ] |
| V05 | Suất CANCELLED | Click giờ suất hủy | Alert không thể đặt | [ ] |
| V06 | Search rỗng / có text | Xóa / gõ lại | List hiện đủ / lọc đúng | [ ] |
| V07 | Tab Đang chiếu ↔ Sắp chiếu | Đổi tab | List đổi đúng status | [ ] |
| V08 | Hold hết 10 phút | Đợi / mock hết giờ | Clear ghế + alert giữ ghế hết | [ ] |
| V09 | Conflict ghế | 2 phiên cùng ghế | Alert ghế bị chọn; map reload | [ ] |

### 4.2 POS — Tra cứu thành viên & KH

| # | Trường hợp | Thao tác | Kết quả mong đợi | Pass |
|---|------------|----------|------------------|------|
| V10 | SĐT không tồn tại | Lookup SĐT fake | Thông báo không tìm thấy / không gắn member | [ ] |
| V11 | SĐT hợp lệ (ACTIVE) | Lookup | Card TV: tên, điểm, status; `memberId` gắn | [ ] |
| V12 | TV LOCKED | Lookup | Cảnh báo khóa; nút thanh toán disabled | [ ] |
| V13 | TV INACTIVE | Lookup | Giống V12 | [ ] |
| V14 | Enter trên ô SĐT | Enter | Gọi lookup (không submit form) | [ ] |
| V15 | Tên KH trống | Submit | Lưu **Khách vãng lai** | [ ] |
| V16 | Có tên + SĐT | Submit | Payment hiện đúng tên/SĐT | [ ] |
| V17 | Chỉ SĐT, không tên | Submit | Tên mặc định Khách vãng lai; SĐT vẫn gửi | [ ] |

### 4.3 Thanh toán — Tiền mặt

| # | Trường hợp | Thao tác | Kết quả mong đợi | Pass |
|---|------------|----------|------------------|------|
| V18 | Tiền nhận = 0 | Xác nhận | Alert *“Tiền nhận chưa đủ…”* | [ ] |
| V19 | Tiền nhận < tổng | Nhập thiếu rồi xác nhận | Alert chưa đủ; không POST | [ ] |
| V20 | Tiền nhận = tổng | **Vừa đủ** rồi xác nhận | Thành công → màn in | [ ] |
| V21 | Tiền nhận > tổng | +50K/+100K… | Tiền thừa hiện đúng; xác nhận OK | [ ] |
| V22 | Numpad ⌫ / 000 | Gõ rồi xóa | Display cập nhật đúng | [ ] |
| V23 | Đơn đã PAID | Mở lại payment / confirm lần 2 | Lỗi *“Đã được xử lý rồi”* hoặc tương đương | [ ] |
| V24 | Server cash < finalAmount | Bypass client (nếu test API) | `errorMessage` số tiền chưa đủ | [ ] |

### 4.4 Thanh toán — VietQR

| # | Trường hợp | Thao tác | Kết quả mong đợi | Pass |
|---|------------|----------|------------------|------|
| V25 | Chưa cấu hình VietQR | Tab Chuyển khoản | Hiện hướng dẫn config | [ ] |
| V26 | Đã config | Bấm tạo QR | Sinh QR + thông tin NH đúng amount | [ ] |
| V27 | Confirm khi chưa init QR | (edge) | Lỗi / không cho confirm | [ ] |
| V28 | SePay poll paid | Chuyển đúng nội dung+số tiền | Tự redirect sang print | [ ] |
| V29 | SePay timeout ~3 phút | Không chuyển khoản | Message dùng xác nhận thủ công | [ ] |
| V30 | Xác nhận thủ công sau khi tiền vào | Bấm confirm | Sang print | [ ] |

### 4.5 In vé

| # | Trường hợp | Thao tác | Kết quả mong đợi | Pass |
|---|------------|----------|------------------|------|
| V31 | Copies < 1 / > 10 | Bấm − / + liên tục | Clamp 1–10 | [ ] |
| V32 | In vé | **🖨 In vé** | Dialog print; chỉ preview vé | [ ] |
| V33 | Mark printed OK | **Xác nhận đã in xong** | Nút *Đã lưu trạng thái in*; DB `is_printed` | [ ] |
| V34 | Mark printed lỗi mạng | (disconnect) | Alert thử lại; nút enable lại | [ ] |
| V35 | Session hết hạn khi mark | (401) | Alert đăng nhập lại | [ ] |

### 4.6 Lịch sử — Filter

| # | Trường hợp | Thao tác | Kết quả mong đợi | Pass |
|---|------------|----------|------------------|------|
| V36 | Không filter | Mở history | List OFFLINE; tổng count đúng | [ ] |
| V37 | dateFrom > dateTo | Chọn khoảng ngược | Không crash; list rỗng hoặc behavior ổn định | [ ] |
| V38 | Status CONFIRMED | Lọc | Chỉ đơn đã xác nhận | [ ] |
| V39 | Status PENDING | Lọc | Chỉ chờ TT | [ ] |
| V40 | Status CANCELLED | Lọc | Chỉ đã hủy | [ ] |
| V41 | Search mã đơn | Gõ booking code | Đúng đơn | [ ] |
| V42 | Search SĐT / tên | Gõ | Đúng đơn (server) | [ ] |
| V43 | Xóa lọc | Click | Reset URL/filter về mặc định | [ ] |
| V44 | Quick Hôm nay / Tuần / Tháng | Click | dateFrom/dateTo đúng khoảng | [ ] |
| V45 | Client filter khi gõ search | Gõ trên trang đã load | Ẩn row không khớp cột KH | [ ] |
| V46 | bookingId không tồn tại | `?bookingId=999999` | *“Không tìm thấy đơn đặt vé.”* | [ ] |
| V47 | Phân trang | > 15 đơn | Chuyển trang giữ filter | [ ] |

---

## 5. Checklist chung — Kịch bản demo

Chuẩn bị data trước demo: ≥1 phim đang chiếu, ≥1 suất OPEN hôm nay, ghế trống, (tuỳ chọn) 1 user ACTIVE có SĐT, VietQR/SePay nếu demo CK.

### D01 — Happy path tiền mặt (walk-in)

**Mục tiêu:** Show full POS trong 2–3 phút.

- [ ] Login STAFF → Quầy vé
- [ ] Search / chọn phim đang chiếu
- [ ] Chọn ngày + suất OPEN
- [ ] Chọn 2 ghế (STANDARD + VIP nếu có)
- [ ] Bỏ trống tên → tiến hành (Khách vãng lai)
- [ ] Tab Tiền mặt → Vừa đủ → Xác nhận
- [ ] Xem preview vé + QR → In vé (optional) → Xác nhận đã in
- [ ] Tạo đơn mới → History thấy đơn CONFIRMED / PAID

### D02 — Happy path có thành viên + loyalty

- [ ] Lookup SĐT TV ACTIVE
- [ ] Card TV hiện điểm / tên
- [ ] Đặt 1–2 ghế → thanh toán CASH
- [ ] (Nếu có) điểm loyalty tăng sau PAID
- [ ] (Nếu có email) mail xác nhận gửi async
- [ ] History: badge **★ TV** trên đơn

### D03 — Demo VietQR (+ SePay nếu bật)

- [ ] Tạo đơn → tab Chuyển khoản → Tạo QR
- [ ] Chỉ QR / nội dung CK / số tiền cho khách “quét”
- [ ] SePay ON: chờ auto confirm **hoặc** bấm xác nhận thủ công
- [ ] SePay OFF: bấm **Tiền đã vào**
- [ ] Vào màn in thành công

### D04 — Demo lịch sử & in lại

- [ ] Mở History → Quick **Hôm nay**
- [ ] Lọc CONFIRMED → thấy đơn vừa bán
- [ ] **Xem** chi tiết
- [ ] **In vé** lại đơn PAID
- [ ] Thử search theo mã đơn vừa tạo

### D05 — Demo negative (gây ấn tượng validate)

- [ ] Cố chọn > 8 ghế → alert
- [ ] Tiền mặt thiếu → alert
- [ ] Lookup TV LOCKED (nếu có data) → không cho thanh toán
- [ ] Role khác vào `/staff/counter` → 403

### D06 — Demo quyền & branding

- [ ] Header STAFF chỉ thấy Quầy vé
- [ ] Badge OFFLINE xuyên suốt POS / payment / print / history
- [ ] Tên nhân viên đúng trên mọi màn

---

## 6. Checklist chung — Workflow end-to-end

### W1 — Offline booking đầy đủ (CASH)

```
Login → Counter → Movie → Showtime → Seats → (optional member)
→ Proceed → Payment CASH ≥ total → Print → markPrinted → New order
→ History verify
```

- [ ] Booking `booking_source = OFFLINE`
- [ ] Trước pay: `PENDING` / `UNPAID`
- [ ] Sau pay: `CONFIRMED` / `PAID` + có tickets
- [ ] Sau markPrinted: `is_printed = 1`

### W2 — Offline booking VietQR

```
… → Payment VIETQR → initVietQR → (SePay | manual confirm) → Print
```

- [ ] Có pending VietQR trước confirm
- [ ] Confirm xong có tickets + sang print

### W3 — Giữ ghế & hết giờ

```
Chọn ghế → thấy countdown → (hết hạn hoặc conflict) → chọn lại → book OK
```

- [ ] Hold ~10 phút hoạt động
- [ ] Hết hạn / conflict xử lý đúng UX

### W4 — Đơn PENDING còn lại

```
Tạo booking → vào payment → không pay → về History lọc PENDING
```

- [ ] Đơn hiện Chờ TT / Chưa TT
- [ ] Không có nút **In vé**
- [ ] (Optional) mở lại `step=payment` để hoàn tất

### W5 — In lại từ History

```
History → đơn PAID → In vé → markPrinted lại (idempotent / OK)
```

- [ ] Preview đúng dữ liệu đơn cũ
- [ ] Không tạo booking mới

### W6 — Song song 2 phiên Staff (nếu demo conflict)

```
Staff A chọn ghế X → Staff B chọn ghế X → một bên fail / alert
```

- [ ] Không double-book cùng ghế cùng suất

---

## 7. Checklist chung — Edge case / lỗi

- [ ] DB không có phim → empty state POS
- [ ] Phim không có suất → picker trống / message
- [ ] Poster URL hỏng → placeholder, không vỡ layout
- [ ] Thanh toán lần 2 cùng booking → bị từ chối
- [ ] Mất session giữa payment/print → redirect login / alert 401
- [ ] History `bookingId` sai → error message rõ
- [ ] Lỗi tải list history → `errorMessage` trên trang
- [ ] Age rating: Staff **không** bị chặn tự động (kiểm tra CCCD thủ công ngoài hệ thống) — ghi chú demo nếu được hỏi

---

## 8. Ma trận nhanh trước buổi demo

| Ưu tiên | Item | Ai demo | Pass |
|---------|------|---------|------|
| P0 | Login STAFF + vào Quầy vé | | [ ] |
| P0 | Chọn phim → suất → ghế → CASH → in | | [ ] |
| P0 | History hôm nay thấy đơn vừa bán | | [ ] |
| P1 | Lookup thành viên + badge ★ TV | | [ ] |
| P1 | VietQR tạo mã + confirm | | [ ] |
| P1 | Validate: thiếu tiền / max 8 ghế | | [ ] |
| P2 | SePay auto / timeout message | | [ ] |
| P2 | TV LOCKED không cho đặt | | [ ] |
| P2 | 403 khi role khác vào `/staff` | | [ ] |
| P3 | markPrinted + in lại từ history | | [ ] |
| P3 | Phân trang / filter status | | [ ] |

---

## Ghi chú khi tick fail

| Field | Ghi |
|-------|-----|
| Mã case | VD: V18, D01, W2 |
| Màn hình / URL | |
| Steps tái hiện | |
| Expected vs Actual | |
| Screenshot / log | |
| Severity | Blocker / Major / Minor |

---

*File này phục vụ kiểm UI + demo role **STAFF**. Khi làm tương tự cho ADMIN / MANAGER / CUSTOMER, tạo file `Admin_UI_Checklist.md` (v.v.) theo cùng cấu trúc: UI theo màn → Validate field → Kịch bản demo → Workflow E2E.*
