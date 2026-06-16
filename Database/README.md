# Database — MovieTicketDB

Hướng dẫn tạo và cập nhật cơ sở dữ liệu cho nhóm phát triển.

> Cấu hình kết nối app: `src/main/resources/database.properties` (xem [`README.md`](../README.md))

---

## Tổng quan

| Hạng mục | Giá trị |
|----------|---------|
| Tên database | `MovieTicketDB` |
| Số bảng | **28** (PascalCase) |
| Script chính | `create_database.sql` — schema đầy đủ + seed data |
| Migration bổ sung | `migrations/` — cho DB đã tạo trước khi schema gộp vào `create_database.sql` |

---

## A. Lần đầu setup (máy chưa có DB)

1. Bật SQL Server, bật **SQL Server Authentication** (nếu dùng `sa`).
2. Mở **SSMS** hoặc **Azure Data Studio**.
3. Mở file `Database/create_database.sql`.
4. Chạy toàn bộ file (**Ctrl+A** → **F5**).

Kết quả:

- Tạo database `MovieTicketDB`
- Tạo **28 bảng** + index + seed data (roles, users test, phim, genres, loyalty config, VAT 10%, **đơn đặt vé mẫu cho báo cáo**)

Đảm bảo `db.name=MovieTicketDB` trong `database.properties`.

### Dữ liệu test báo cáo Admin (`SEED-STATS-*`)

| Khoảng | Kỳ vọng |
|--------|---------|
| Tháng 6/2026 (dashboard) | 4 đơn, 9 vé, doanh thu **1.166.000đ** |
| Top phim tháng 6 | 1. Avengers (5 vé) · 2. Mission (2 vé) · 3. Housemaid (2 vé) |
| Đơn `SEED-STATS-007` | PENDING — **không** tính vào thống kê |

> Dữ liệu nằm trong `create_database.sql` — chạy lại toàn bộ file để có seed mới.

### Tài khoản seed (mật khẩu `Password@123`)

| Role | Email |
|------|-------|
| ADMIN | admin@movieticket.vn |
| MANAGER | manager@movieticket.vn |
| STAFF | staff@movieticket.vn |

---

## B. Đã có DB cũ — pull code mới

Khi pull code có thay đổi schema, chạy lại `create_database.sql` để sync (**chú ý: sẽ xóa toàn bộ data cũ và seed lại**).

Nếu muốn giữ data: chạy script trong `Database/migrations/` tương ứng (xem bảng dưới).

### Migration scripts (`Database/migrations/`)

| File | Mục đích |
|------|----------|
| `add_user_status_log.sql` | Thêm bảng `UserStatusLog` — audit khóa tài khoản |
| `add_vietqr_payment_method.sql` | Thêm `VIETQR` vào `CK_Payments_Method` |

> `SystemConfigLog` chỉ có trong `create_database.sql` (không có file migration riêng).

### Schema đã thay đổi so với commit ban đầu

| Thay đổi | Mô tả |
|----------|-------|
| `Genres.is_active BIT NOT NULL DEFAULT 1` | Trạng thái active/inactive của thể loại |
| `Genres.description NVARCHAR(500) NULL` | Mô tả thể loại |
| `Movies.status` — thêm giá trị `EARLY_SHOWING` | Suất chiếu sớm (Early Showing) |
| Bảng `SystemConfigLog` | Lịch sử chỉnh sửa cấu hình loyalty |
| Bảng `UserStatusLog` | Lịch sử khóa/mở khóa user (lý do, email_sent) |
| Seed `SEED-STATS-*` | Đơn PAID mẫu cho báo cáo admin tháng 6/2026 |

---

## C. Nhóm bảng (28 bảng)

| Nhóm | Bảng |
|------|------|
| Auth | `Roles`, `Users`, `PasswordResetTokens`, `UserStatusLog` |
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
- Khi thêm cột/bảng mới: cập nhật `create_database.sql`, thêm migration trong `migrations/` (nếu cần upgrade DB cũ), và ghi vào bảng "Schema đã thay đổi" ở mục B.

---

*Cập nhật 09/06/2026.*
