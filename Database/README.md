# Database — MovieTicketDB

Hướng dẫn tạo và cập nhật cơ sở dữ liệu cho nhóm phát triển.

> Cấu hình kết nối app: `src/main/resources/database.properties` (xem [`README.md`](../README.md))

---

## Tổng quan

| Hạng mục | Giá trị |
|----------|---------|
| Tên database | `MovieTicketDB` |
| Số bảng | **27** (PascalCase) |
| Script duy nhất | `create_database.sql` — schema đầy đủ + seed data |

> **Không còn file migration riêng lẻ.** Mọi thay đổi schema đều đã được gộp vào `create_database.sql`.

---

## A. Lần đầu setup (máy chưa có DB)

1. Bật SQL Server, bật **SQL Server Authentication** (nếu dùng `sa`).
2. Mở **SSMS** hoặc **Azure Data Studio**.
3. Mở file `Database/create_database.sql`.
4. Chạy toàn bộ file (**Ctrl+A** → **F5**).

Kết quả:

- Tạo database `MovieTicketDB`
- Tạo **27 bảng** + index + seed data (roles, users test, phim, genres, loyalty config, VAT 10%, …)

Đảm bảo `db.name=MovieTicketDB` trong `database.properties`.

### Tài khoản seed (mật khẩu `Password@123`)

| Role | Email |
|------|-------|
| ADMIN | admin@movieticket.vn |
| MANAGER | manager@movieticket.vn |
| STAFF | staff@movieticket.vn |

---

## B. Đã có DB cũ — pull code mới

Khi pull code có thay đổi schema, chạy lại `create_database.sql` để sync (**chú ý: sẽ xóa toàn bộ data cũ và seed lại**).

Nếu muốn giữ data: tự viết `ALTER TABLE` tương ứng theo diff so với commit trước.

### Schema đã thay đổi so với commit ban đầu

| Thay đổi | Mô tả |
|----------|-------|
| `Genres.is_active BIT NOT NULL DEFAULT 1` | Trạng thái active/inactive của thể loại |
| `Genres.description NVARCHAR(500) NULL` | Mô tả thể loại |
| `Movies.status` — thêm giá trị `EARLY_SHOWING` | Suất chiếu sớm (Early Showing) |
| Bảng `SystemConfigLog` | Lịch sử chỉnh sửa cấu hình loyalty |

---

## C. Nhóm bảng (27 bảng)

| Nhóm | Bảng |
|------|------|
| Auth | `Roles`, `Users`, `PasswordResetTokens` |
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
- Khi thêm cột/bảng mới: cập nhật trực tiếp vào `create_database.sql` và ghi vào bảng "Schema đã thay đổi" ở mục B.

---

*Cập nhật 14/06/2026.*
