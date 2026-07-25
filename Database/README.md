# Database — MovieTicketDB

Hướng dẫn tạo và cập nhật cơ sở dữ liệu cho nhóm phát triển.

> Cấu hình kết nối app: `src/main/resources/database.properties` (xem [`README.md`](../README.md))

---

## Tổng quan

| Hạng mục | Giá trị |
|----------|---------|
| Tên database | `MovieTicketDB` |
| Số bảng | **28** (PascalCase) |
| Script duy nhất | [`create_database.sql`](create_database.sql) — schema đầy đủ + seed (đã gộp mọi migration) |
| `migrations/` | **Legacy** — chỉ khi DB cũ không reset được; xem [`migrations/README.md`](migrations/README.md) |

---

## A. Lần đầu setup (máy chưa có DB) — làm đúng như thế này

1. Bật SQL Server, bật **SQL Server Authentication** (nếu dùng `sa`).
2. Mở **SSMS** hoặc **Azure Data Studio**.
3. Mở file `Database/create_database.sql`.
4. Chạy **toàn bộ file** (**Ctrl+A** → **F5**).

**Không** cần chạy thêm file nào trong `migrations/`.

Kết quả:

- Tạo database `MovieTicketDB`
- Tạo **28 bảng** + index + seed data (users, phim, genres, loyalty, VAT, voucher, đơn báo cáo, …)

Đảm bảo `db.name=MovieTicketDB` trong `database.properties`.

### Dữ liệu test báo cáo Admin (`SEED-STATS-*`)

| Khoảng | Kỳ vọng |
|--------|---------|
| Tháng 6/2026 (dashboard) | 4 đơn, 9 vé, doanh thu **1.166.000đ** |
| Top phim tháng 6 | 1. Avengers (5 vé) · 2. Mission (2 vé) · 3. Housemaid (2 vé) |
| Đơn `SEED-STATS-007` | PENDING — **không** tính vào thống kê |

> Dữ liệu nằm trong `create_database.sql` — chạy lại toàn bộ file để có seed mới.

### Seed load-test suất chiếu (tuỳ chọn)

File [`seed_showtime_load_test.sql`](seed_showtime_load_test.sql) — thêm ~12 phim + lịch dày quanh **[-7 .. +7] ngày** (≈225 suất) để test `/manager/showtimes`.

- Chạy trên DB đã có (`create_database.sql` trước).
- Idempotent: chạy lại chỉ thay data `slug LIKE 'seed-load-%'`.
- Không xoá seed báo cáo `SEED-STATS-*`.
- Ngày đã qua = `FINISHED`; đang chiếu = `SHOWING`; sắp tới = `SCHEDULED`; hủy tay = `CANCELLED`.

### Tài khoản seed (mật khẩu `Password@123`)

| Role | Email |
|------|-------|
| ADMIN | admin@movieticket.vn |
| MANAGER | manager@movieticket.vn |
| STAFF | staff@movieticket.vn |
| CUSTOMER (≥18) | customer.adult@email.com |
| CUSTOMER (teen) | customer.teen@email.com |

---

## B. Đã có DB cũ — pull code mới

**Khuyến nghị (dev):** chạy lại `create_database.sql` để sync schema + seed  
→ **xóa toàn bộ data cũ** và tạo lại từ đầu.

**Giữ data:** chỉ khi không thể reset — xem [`migrations/README.md`](migrations/README.md) và chạy đúng file còn thiếu. Schema chuẩn luôn nằm trong `create_database.sql`.

### Schema đã gộp vào `create_database.sql` (không cần chạy riêng)

| Thay đổi | Mô tả |
|----------|-------|
| `Genres.is_active` / `description` | Thể loại active + mô tả |
| `Movies.status` gồm `EARLY_SHOWING` | Suất chiếu sớm |
| `SystemConfigLog` | Lịch sử chỉnh sửa loyalty |
| `UserStatusLog` | Audit khóa/mở khóa user |
| `PasswordResetTokens.purpose` | PASSWORD_RESET / PROFILE_SECURITY (REGISTER_VERIFY legacy) |
| `PendingRegistrations` | Đăng ký chờ xác thực email — chưa ghi `Users` |
| `Promotions.image_url` | Ảnh voucher |
| `SeatTypes.seat_span` | Ghế 1 ô / 2 ô (COUPLE, SWEETBOX = 2) |
| `Tickets.is_printed` | Vé đã in (quầy) |
| `Payments.cash_received` / `change_amount` | Tiền mặt quầy |
| `CK_Payments_Method` gồm `VIETQR` | Thanh toán VietQR |
| `Bookings.points_redeemed` | Điểm đã đổi trên đơn (FR-43) |
| Seed `SEED-STATS-*` | Đơn mẫu báo cáo admin |

---

## C. Nhóm bảng (29 bảng)

| Nhóm | Bảng |
|------|------|
| Auth | `Roles`, `Users`, `PendingRegistrations`, `PasswordResetTokens`, `UserStatusLog` |
| Config | `SystemConfig`, `SystemConfigLog`, `VatRules` |
| Cinema | `CinemaInfo`, `CinemaRooms`, `SeatTypes`, `Seats` |
| Movie | `Movies`, `Genres`, `MovieGenres`, `MovieReviews` |
| Showtime | `Showtimes`, `PricingRules` |
| Booking | `SeatHolds`, `Bookings`, `BookingSeats` |
| Payment | `Payments` |
| Promotion | `Promotions`, `BookingPromotions` |
| Ticket | `Tickets` |
| Loyalty | `LoyaltyPointsLog` |
| Operations | `ShowtimeIncidents` |
| Chatbot | `ChatbotConversations`, `ChatbotMessages` |

---

## D. Lưu ý cho nhóm

- **Không** commit `database.properties` lên Git.
- Chạy lại `create_database.sql` trên DB đang có data sẽ **xóa toàn bộ** bảng và seed lại — chỉ dùng khi reset môi trường dev.
- Khi thêm cột/bảng mới: **cập nhật trực tiếp** `create_database.sql` (nguồn chuẩn). Chỉ thêm file trong `migrations/` nếu nhóm còn máy không reset được DB cũ.

---

*Cập nhật 11/07/2026 — một script duy nhất cho lần clone đầu.*
