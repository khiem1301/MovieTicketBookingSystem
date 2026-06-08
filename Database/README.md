# Database — MovieTicketDB

Hướng dẫn tạo và cập nhật cơ sở dữ liệu cho nhóm phát triển.

> Cấu hình kết nối app: `src/main/resources/database.properties` (xem [`README.md`](../README.md))

---

## Tổng quan

| Hạng mục | Giá trị |
|----------|---------|
| Tên database | `MovieTicketDB` |
| Số bảng | **27** (PascalCase) |
| Script khởi tạo đầy đủ | `create_database.sql` |
| Script cập nhật incremental | `migrations/*.sql` |

---

## A. Lần đầu setup (máy chưa có DB)

1. Bật SQL Server, bật **SQL Server Authentication** (nếu dùng `sa`).
2. Mở **SSMS** hoặc **Azure Data Studio**.
3. Mở file `Database/create_database.sql`.
4. Chạy toàn bộ file (**Ctrl+A** → **F5**).

Kết quả:

- Tạo database `MovieTicketDB`
- Tạo **27 bảng** + index + seed data (roles, users test, phim, genres, loyalty config, VAT 10%, …)
- **Không cần** chạy thêm file trong `migrations/` nếu vừa chạy `create_database.sql` mới nhất

Đảm bảo `db.name=MovieTicketDB` trong `database.properties`.

### Tài khoản seed (mật khẩu `Password@123`)

| Role | Email |
|------|-------|
| ADMIN | admin@movieticket.vn |
| MANAGER | manager@movieticket.vn |
| STAFF | staff@movieticket.vn |

---

## B. Đã có DB cũ — chạy migration sau `git pull`

Khi teammate pull code mới có thay đổi schema, chạy các file migration **theo thứ tự** trong `Database/migrations/`.

### Danh sách migration hiện có

| File | Mô tả | Bắt buộc khi |
|------|--------|--------------|
| `add_system_config_log.sql` | Thêm bảng `SystemConfigLog` — lịch sử chỉnh sửa loyalty trên `/admin/config` | Dùng tính năng lịch sử tích điểm |

### Cách chạy (SSMS)

1. Mở SSMS → kết nối SQL Server.
2. Mở file migration (VD: `Database/migrations/add_system_config_log.sql`).
3. **F5** để execute.
4. Script dùng `IF OBJECT_ID ... IS NULL` — chạy lại an toàn, không tạo trùng bảng.

### Kiểm tra sau migration

```sql
USE MovieTicketDB;
SELECT name FROM sys.tables ORDER BY name;
-- Phải thấy SystemConfigLog (tổng 27 bảng)
```

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
- Trước `git pull`: `scripts\backup-database-properties.bat` → pull → `scripts\restore-database-properties.bat`.
- Chạy lại `create_database.sql` trên DB đang có data sẽ **xóa toàn bộ** bảng và seed lại — chỉ dùng khi reset môi trường dev.
- Khi thêm migration mới: tạo file trong `migrations/`, cập nhật bảng danh sách trong file này và trong `README.md`.

---

*Cập nhật 09/06/2026.*
