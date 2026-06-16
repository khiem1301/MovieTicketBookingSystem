# Module Staff — Tài liệu chi tiết

> **Dự án:** ÉPCINE — Movie Ticket Booking System  
> **Phạm vi:** Toàn bộ source code liên quan đến nhân viên quầy (STAFF) — bán vé offline tại rạp  
> **Tổng quan dự án:** [`SOURCE_CODE_OVERVIEW.md`](SOURCE_CODE_OVERVIEW.md)  
> **Spec nghiệp vụ:** [`project_summary_final.md`](project_summary_final.md)  
> **Database & migration:** [`Database/README.md`](Database/README.md)  
> **Module liên quan:** [`MANAGER_MODULE_DETAIL.md`](MANAGER_MODULE_DETAIL.md) (quản lý phòng, ghế, suất chiếu)

---

## 1. Tổng quan module Staff

Module Staff phục vụ người dùng có role **STAFF** — nhân viên bán vé trực tiếp tại quầy (walk-in / offline). Toàn bộ giao diện theo dạng POS (Point of Sale) 3 cột: danh sách phim → suất chiếu → sơ đồ ghế → tóm tắt → thanh toán → in vé.

### 1.1 Tính năng đã triển khai

| Tính năng | FR | Trạng thái | Ghi chú |
|-----------|----|------------|---------|
| Giao diện POS 3 cột (phim / suất / ghế + tóm tắt) | FR-35 | ✅ | Layout responsive, dark theme |
| Tìm kiếm & lọc phim theo tab (Đang chiếu / Sắp chiếu) | FR-35 | ✅ | Filter JS real-time |
| Chọn suất chiếu theo ngày (date tabs) | FR-35 | ✅ | Load AJAX, hiển thị trạng thái OPEN/CLOSED |
| Sơ đồ ghế tương tác (chọn nhiều ghế) | FR-35 | ✅ | Load AJAX, phân biệt VIP/REGULAR/COUPLE, ghế đã bán xám |
| Nhập thông tin khách (tên, số điện thoại) | FR-38 | ✅ | Walk-in — khách vãng lai hoặc thành viên |
| Tra cứu thành viên theo SĐT | FR-42 | ✅ | AJAX lookup → hiện card thông tin: avatar, trạng thái, email, điểm tích lũy, ngày tham gia |
| Tạo đơn đặt vé offline (`OFFLINE` source) | FR-35 | ✅ | `BookingDAO.createOfflineBooking` — `booking_source='OFFLINE'` |
| Xem chi tiết đơn trước khi thanh toán | FR-36 | ✅ | Trang payment hiển thị đầy đủ: phim, suất, ghế, tổng tiền |
| Thanh toán tiền mặt (numpad + tiền thừa) | FR-36 | ✅ | Numpad bấm số, tính tiền thừa tự động |
| Thanh toán chuyển khoản VietQR | FR-36 | ✅ | Sinh QR động qua `VietQRUtil`, hiển thị mã QR + thông tin ngân hàng |
| Xác nhận thanh toán → cập nhật DB | FR-36 | ✅ | `confirmPaymentWithDetails` — atomic transaction |
| Phát hành vé điện tử (QR code) | FR-18 | ✅ | `generateTicketsInTransaction` — ghi bảng `Tickets` |
| Trang in vé (danh sách vé + QR) | FR-37 | ✅ | Giao diện in, nút "Xác nhận đã in xong" |
| Đánh dấu vé đã in (`is_printed = 1`) | FR-37 | ✅ | AJAX POST `markPrinted` → cột `Tickets.is_printed` |
| Gửi email xác nhận vé cho thành viên | FR-19 | ✅ | Async thread — `EmailUtil.sendBookingConfirmation` |
| Tích điểm loyalty sau thanh toán | FR-42 | ✅ | `addLoyaltyPoints` — `LoyaltyPointsLog` + `Users.loyalty_points` |

### 1.2 Tính năng chưa triển khai

| Tính năng | FR | Ghi chú |
|-----------|----|---------|
| Đối soát VietQR tự động (webhook) | FR-36 | Hiện xác nhận thủ công sau khi nhận chuyển khoản |
| In nhiều vé theo batch (nhiều booking) | FR-37 | Hiện chỉ in 1 booking mỗi lần |
| Hủy đơn sau khi đã thanh toán | — | Chỉ hủy PENDING; PAID chưa có luồng hoàn tiền |
| Lịch sử đơn offline theo ca làm việc | — | Chưa có màn hình quản lý ca |

---

## 2. Danh sách file source liên quan Staff

### 2.1 Controller

```
src/main/java/controller/staff/
└── CounterBookingServlet.java   # /staff/counter — xử lý toàn bộ luồng POS
```

**Các `action` được xử lý bởi `CounterBookingServlet`:**

| action (GET) | Mô tả |
|---|---|
| _(mặc định)_ | Render trang POS chính — danh sách phim |
| `showtimes` | JSON — suất chiếu theo `movieId` |
| `seats` | JSON — sơ đồ ghế theo `showtimeId` |
| `lookup` | JSON — tra cứu thành viên theo `phone` |
| `step=payment` | Render trang chi tiết thanh toán |
| `step=print` | Render trang in vé |

| action (POST) | Mô tả |
|---|---|
| `book` | Tạo booking offline → redirect sang trang payment |
| `payment` | Xác nhận thanh toán → gọi `confirmPaymentWithDetails` |
| `markPrinted` | Đánh dấu vé đã in (AJAX, trả JSON) |

### 2.2 DAL

```
src/main/java/dal/
├── BookingDAO.java       # Toàn bộ logic booking offline + payment + ticket
├── ShowtimeDAO.java      # Lấy suất chiếu theo movieId (dùng cho POS)
└── UserDAO.java          # findByPhone — tra cứu thành viên
```

**Các method liên quan trong `BookingDAO`:**

| Method | Mô tả |
|--------|--------|
| `createOfflineBooking()` | Tạo Booking + BookingSeats trong 1 transaction |
| `getDetailById()` | Lấy đầy đủ thông tin đơn (phim, ghế, khách, vé) |
| `confirmPaymentWithDetails()` | Cập nhật trạng thái → tạo Payment → tạo Ticket → tích điểm |
| `markAllPrinted()` | Cập nhật `is_printed = 1` cho tất cả vé của booking |
| `generateTicketsInTransaction()` | Sinh `ticket_code` + `qr_code`, ghi bảng `Tickets` (private) |
| `addLoyaltyPoints()` | Cộng điểm `Users.loyalty_points` + ghi `LoyaltyPointsLog` (private) |

### 2.3 DTO

```
src/main/java/model/dto/
└── BookingDetailDTO.java   # DTO tổng hợp thông tin đơn + ghế + vé
```

**Inner classes của `BookingDetailDTO`:**

- `SeatItem` — mã ghế, loại ghế, giá
- `TicketItem` — `ticketCode`, `qrCode`, `seatCode`

### 2.4 View (JSP)

```
src/main/webapp/WEB-INF/views/staff/
├── counter-booking.jsp   # Trang POS chính (chọn phim → suất → ghế → tóm tắt)
├── counter-payment.jsp   # Trang thanh toán (numpad tiền mặt + VietQR)
└── counter-print.jsp     # Trang in vé (danh sách vé + QR code)
```

### 2.5 CSS & JS

```
src/main/webapp/css/
└── counter-pos.css          # Style toàn bộ POS (layout 3 cột, numpad, member card, VietQR panel)

src/main/webapp/js/
└── counter-booking.js       # Logic chọn phim/suất/ghế, tra cứu thành viên (AJAX)
```

### 2.6 Utility liên quan

```
src/main/java/utils/
├── VietQRUtil.java          # Sinh URL ảnh QR chuyển khoản (VietQR API)
├── VietQRConfig.java        # Đọc cấu hình từ vietqr.properties
└── EmailUtil.java           # Gửi email xác nhận vé (SMTP async)
```

### 2.7 Cấu hình

```
src/main/resources/
├── vietqr.properties            # Thông tin ngân hàng nhận chuyển khoản (gitignored — chứa thông tin thật)
└── vietqr.properties.example    # Template — điền thông tin ngân hàng của rạp
```

---

## 3. Luồng nghiệp vụ

### 3.1 Luồng bán vé tại quầy

```
[STAFF đăng nhập]
      │
      ▼
[POS — /staff/counter]
      │
      ├─ Chọn phim (tab Đang chiếu / Sắp chiếu)
      │
      ├─ Chọn suất chiếu theo ngày
      │
      ├─ Chọn ghế trên sơ đồ phòng
      │
      ├─ (Tùy chọn) Tra cứu thành viên theo SĐT
      │     └─ Tìm thấy → điền tên/SĐT tự động + liên kết userId
      │     └─ Không tìm thấy → nhập tay → khách vãng lai (userId = NULL)
      │
      ├─ Nhấn "Tiến hành thanh toán" → POST book
      │     └─ BookingDAO.createOfflineBooking() → Bookings (PENDING/UNPAID) + BookingSeats
      │
      ▼
[Trang thanh toán — step=payment]
      │
      ├─ Chọn phương thức: 💵 Tiền mặt | 📱 Chuyển khoản VietQR
      │
      ├─ Tiền mặt: nhập số tiền nhận → tính tiền thừa
      ├─ VietQR: hiển thị QR động + thông tin ngân hàng
      │
      ├─ Nhấn "Xác nhận thanh toán" → POST payment
      │     └─ confirmPaymentWithDetails():
      │           1. UPDATE Bookings → CONFIRMED/PAID
      │           2. INSERT Payments (CASH hoặc VIETQR)
      │           3. generateTicketsInTransaction() → INSERT Tickets (ticket_code, qr_code)
      │           4. addLoyaltyPoints() → UPDATE Users + INSERT LoyaltyPointsLog
      │           5. (Async) gửi email xác nhận nếu khách có tài khoản
      │
      ▼
[Trang in vé — step=print]
      │
      ├─ Hiển thị danh sách vé + QR code
      ├─ Nút "In vé" → window.print()
      └─ Nút "Xác nhận đã in xong" → AJAX POST markPrinted
            └─ markAllPrinted() → UPDATE Tickets SET is_printed = 1
```

### 3.2 Tra cứu thành viên (FR-42)

```
Nhân viên nhập SĐT → AJAX GET /staff/counter?action=lookup&phone=...
      │
      ├─ Tìm thấy user → trả JSON:
      │     { found: true, fullName, email, phone, userId,
      │       loyaltyPoints, status, joinedDate }
      │     → Hiện member card (avatar, badge THÀNH VIÊN, trạng thái, điểm vàng)
      │     → Auto-fill form tên/SĐT, set hidden userId
      │
      └─ Không tìm thấy → trả { found: false }
            → Hiện card "Không tìm thấy" — khách vãng lai
            → Auto-fill SĐT vào form
```

---

## 4. Database — thay đổi Sprint 2

Migration: [`Database/migrations/sprint2_counter_pos.sql`](Database/migrations/sprint2_counter_pos.sql)

| Bảng | Thay đổi | Lý do |
|------|----------|-------|
| `Genres` | Thêm cột `description NVARCHAR(500) NULL` | Mô tả thể loại |
| `Genres` | Thêm cột `is_active BIT NOT NULL DEFAULT 1` | Lọc thể loại active |
| `Tickets` | Thêm cột `is_printed BIT NOT NULL DEFAULT 0` | FR-37 — đánh dấu vé đã in |
| `Payments` | Thêm cột `cash_received DECIMAL(12,2) NULL` | FR-36 — lưu tiền khách đưa |
| `Payments` | Thêm cột `change_amount DECIMAL(12,2) NULL` | FR-36 — lưu tiền thừa trả lại |
| `Payments` | Cập nhật `CK_Payments_Method` → `('VNPAY','MOMO','CASH','VIETQR')` | Bỏ CARD, thêm VIETQR |

> **Lưu ý:** File migration idempotent — có thể chạy lại nhiều lần mà không bị lỗi (`IF NOT EXISTS`).

---

## 5. Cấu hình VietQR

Để hiển thị mã QR chuyển khoản, tạo file `src/main/resources/vietqr.properties` (copy từ `.example`):

```properties
vietqr.bank.bin=970422          # BIN ngân hàng (VD: 970422 = MB Bank)
vietqr.bank.name=MB Bank        # Tên ngân hàng hiển thị
vietqr.account.number=xxxxxxxxx # Số tài khoản nhận tiền
vietqr.account.name=TEN CHU TK  # Tên chủ tài khoản (IN HOA)
vietqr.template=compact2        # Template QR (compact2 / qr_only / print)
```

> File `vietqr.properties` đã thêm vào `.gitignore` — **không commit thông tin ngân hàng thật lên repo**.

---

## 6. Tài khoản test

| Email | Role | Ghi chú |
|-------|------|---------|
| `staff@epcine.com` | STAFF | Tài khoản nhân viên quầy |
| Mật khẩu | `Password@123` | |

---

## 7. Điểm kỹ thuật đáng chú ý

| Vấn đề | Giải pháp |
|--------|-----------|
| `OUTPUT INSERTED.id` (SQL Server) | Dùng `ps.executeQuery()` thay vì `getGeneratedKeys()` |
| Tích điểm không được để lỗi làm hỏng payment | Tất cả trong 1 transaction; `LoyaltyPointsLog` columns: `points_delta`, `transaction_type='EARN'` |
| Email gửi chậm không block response | Gửi email trong `Thread` async, không join |
| `markPrinted` trả 500 trước bị Tomcat chặn | Luôn trả `HTTP 200`, lỗi đặt trong JSON body `{ success: false, error: "..." }` |
| SVG ticket icon render quá to | Thêm `width="16" height="16"` trực tiếp vào thẻ `<svg>` trong `home.jsp` |
