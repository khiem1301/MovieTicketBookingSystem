# Migrations — legacy (chỉ DB cũ)

**Máy mới / lần đầu clone:** không dùng thư mục này.

Chạy **một file duy nhất**:

```text
Database/create_database.sql
```

(SSMS → Ctrl+A → F5)

Mọi thay đổi schema từng có trong các file dưới đây **đã được gộp** vào `CREATE TABLE` + seed của `create_database.sql`.

| File (legacy) | Đã có trong `create_database.sql` |
|---------------|-----------------------------------|
| `add_user_status_log.sql` | Bảng `UserStatusLog` |
| `add_token_purpose.sql` | `PasswordResetTokens.purpose` |
| `add_promotion_image.sql` | `Promotions.image_url` |
| `add_seat_type_span.sql` | `SeatTypes.seat_span` |
| `add_vietqr_payment_method.sql` | `CK_Payments_Method` gồm `VIETQR` |
| `sprint2_counter_pos.sql` | Genres / Tickets / Payments (counter POS) |

---

## Khi nào vẫn chạy file trong thư mục này?

Chỉ khi:

1. Database **đã có data** quan trọng, **không** muốn chạy lại `create_database.sql` (script đó DROP toàn bộ bảng), và
2. Schema máy bạn còn thiếu cột/bảng so với code mới nhất.

Khi đó chọn đúng file còn thiếu, chạy từng file (idempotent). Sau khi đã sync, lần sau nên coi `create_database.sql` là nguồn chuẩn khi reset môi trường dev.

---

*Cập nhật 11/07/2026 — gộp migration vào script duy nhất.*
