# FR-15 — Booking History (Lịch sử đặt vé)

> **PIC:** Gia Long (`gialong`)  
> **Branch:** `gialong/fr-15-booking-history`  
> **Spec:** `project_summary_final.md` — FR-15  
> **Liên quan:** FR-14/16 (payment), FR-05 (profile link), FR-19 (email vé — chưa có)

Tài liệu tham chiếu hành vi runtime sau khi triển khai.

---

## 1. URL & phân quyền

| URL | Method | Role |
|-----|--------|------|
| `/booking-history` | GET | **CUSTOMER** + đăng nhập |

- Chưa login → redirect `/login?redirect=/booking-history`
- STAFF/MANAGER/ADMIN → `RoleFilter` + `AccessControl` chặn (path thuộc `CUSTOMER_PREFIXES`)
- Chỉ hiển thị booking có `user_id` = user đang đăng nhập (**ONLINE + OFFLINE**)

---

## 2. Query params

| Param | Mặc định | Mô tả |
|-------|----------|-------|
| `status` | `ALL` | `ALL` \| `PENDING` \| `CONFIRMED` \| `CANCELLED` \| `EXPIRED` \| `REFUNDED` |
| `q` | — | Tìm theo `Movies.title` hoặc `Bookings.booking_code` (LIKE, max 100 ký tự) |
| `page` | `1` | Phân trang, **8 đơn/trang**, `ORDER BY booked_at DESC` |

---

## 3. Hành động trên card

| Điều kiện | Badge | CTA |
|-----------|-------|-----|
| `PENDING` + `UNPAID` + chưa hết `expired_at` | CHỜ THANH TOÁN | **Thanh toán ngay** → `/payment?bookingId=` |
| `CONFIRMED` + `PAID` | ĐÃ THANH TOÁN | **Xem vé** → `/payment/success?bookingId=` |
| `CANCELLED` / `EXPIRED` / `REFUNDED` | tương ứng | Chỉ xem (dòng chú thích) |
| `PENDING` hết hạn | — | Ghi chú “Đơn hết thời gian thanh toán” |

---

## 4. File chính

| File | Vai trò |
|------|---------|
| `BookingSummaryDTO.java` | DTO card + helper `isPayable()`, `isViewableTicket()` |
| `BookingDAO.findSummariesByUserId()` / `countByUserId()` | List + filter + search + pagination |
| `BookingHistoryServlet.java` | GET handler |
| `booking-history.jsp` | UI hero, search, 6 chip, grid 2 cột |
| `booking-history.css` | Theme Dark Vader (`bh-` prefix) |

---

## 5. Test checklist

1. CUSTOMER chưa có đơn → empty state + link `/movies`
2. Đơn PENDING còn hạn → chip “Chờ TT”, nút Thanh toán
3. Đơn CONFIRMED + PAID → nút Xem vé
4. Filter `status=CANCELLED` / search `q=BK` → đúng kết quả
5. Còn trang → nút “Xem thêm lịch sử” (`page+1`, giữ `status` + `q`)
6. STAFF truy cập `/booking-history` → bị chặn
7. (Nếu có seed OFFLINE gắn `user_id`) → badge “Tại quầy”

**Tài khoản test:** `customer.adult@email.com` / `Password@123`

---

## 6. Out of scope

- FR-08–10: hủy/hoàn sau thanh toán
- FR-19: email vé
- Trang chi tiết riêng `/booking-history/{id}` — dùng lại payment/success
- Job tự động chuyển `EXPIRED` (UI vẫn hiện PENDING hết `expired_at`)
