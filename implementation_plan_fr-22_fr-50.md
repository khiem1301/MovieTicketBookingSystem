# Implementation Plan — FR-50 + FR-22 (Customer)

> **Trạng thái:** ✅ Hoàn thành (16/06/2026)  
> **Phạm vi:** Customer module + DAL/utils dùng chung + seed SQL — **không** sửa `controller.manager` hay UI admin promotion.

---

## FR-50 — Dynamic Price Display

### Đã có (trước plan)
- [`PricingCalculator`](src/main/java/utils/PricingCalculator.java) + [`PricingRuleDAO.getActiveRules()`](src/main/java/dal/PricingRuleDAO.java)
- Áp dụng trên `/showtimes`, `/checkout`, `BookingDAO.createOnlineBooking`

### Bổ sung
| Hạng mục | File |
|----------|------|
| Seed 2 pricing rules demo | [`Database/create_database.sql`](Database/create_database.sql) |
| Chip suất: giá hiệu quả + gạch giá gốc | [`showtimes-selector.jsp`](src/main/webapp/WEB-INF/views/customer/components/showtimes-selector.jsp) |
| Header checkout: badge giá động | [`checkout-header.jsp`](src/main/webapp/WEB-INF/views/customer/components/checkout-header.jsp) |
| Summary checkout: ghi chú giá động | [`booking-summary.jsp`](src/main/webapp/WEB-INF/views/customer/components/booking-summary.jsp) |
| CSS `.st-price-original`, `.ck-price-badge` | [`customer-showtimes.css`](src/main/webapp/css/customer-showtimes.css), [`customer-checkout.css`](src/main/webapp/css/customer-checkout.css) |

**Seed pricing rules:**
- `Phụ thu cuối tuần` — T7/CN +10.000đ
- `Phụ thu khung tối` — 21:00–23:00 +10%

> DB đã tạo trước đó: chạy thủ công block INSERT `PricingRules` trong `create_database.sql`.

---

## FR-22 — Apply Discount Code

### Luồng
1. Customer có đơn PENDING → `/payment?bookingId=`
2. Nhập mã → POST `action=applyPromo`
3. Validate + tính giảm → `BookingPromotions` + cập nhật `Bookings.discount_amount`, `final_amount`
4. Gỡ mã → POST `action=removePromo` (hoàn `used_count`)
5. Hủy đơn → `cancelOnlinePendingBooking` xóa junction + hoàn lượt

### Công thức
```
discount_amount = giảm trên total_amount (chưa VAT)
final_amount = (total_amount - discount_amount) × (1 + vat_rate_snapshot / 100)
```

### File mới / sửa
| File | Vai trò |
|------|---------|
| [`PromotionCalculator.java`](src/main/java/utils/PromotionCalculator.java) | Tính discount + VAT + final |
| [`BookingPromotionDAO.java`](src/main/java/dal/BookingPromotionDAO.java) | CRUD junction |
| [`PromotionDAO`](src/main/java/dal/PromotionDAO.java) | `incrementUsedCountIfAvailable`, `decrementUsedCount` |
| [`BookingDAO`](src/main/java/dal/BookingDAO.java) | `applyPromotionToBooking`, `removePromotionFromBooking`; cancel hoàn voucher |
| [`BookingDetailDTO`](src/main/java/model/dto/BookingDetailDTO.java) | `discountAmount`, `vatAmount`, `appliedPromoCode` |
| [`PaymentServlet`](src/main/java/controller/customer/PaymentServlet.java) | `applyPromo` / `removePromo` |
| [`payment.jsp`](src/main/webapp/WEB-INF/views/customer/payment.jsp) | UI voucher + breakdown |
| [`customer-payment.js`](src/main/webapp/js/customer-payment.js) | Uppercase mã client-side |

### Seed voucher test
| Mã | Loại | Điều kiện |
|----|------|-----------|
| `WEEKEND10` | -10%, max 50k | Đơn ≥ 100.000đ |
| `FLAT20K` | -20.000đ | Đơn ≥ 150.000đ |

Quản lý voucher: `/admin/promotions` (FR-21, Manager truy cập được).

---

## Manual test

**FR-50:** So sánh chip suất T7/CN vs ngày thường; checkout header hiện badge khi `effectivePrice ≠ basePrice`.

**FR-22:**
1. Tạo đơn → `/payment` → `WEEKEND10` (đơn ≥ 100k) → breakdown có dòng giảm giá
2. Mã sai / dưới min → thông báo lỗi
3. Gỡ mã → tiền về ban đầu, `used_count` giảm
4. Hủy đơn có mã → `used_count` hoàn lại

**Tài khoản:** `customer.adult@email.com` / `Password@123`
