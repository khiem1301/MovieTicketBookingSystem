# Module Customer — Tài liệu chi tiết

> **Dự án:** ÉPCINE — Movie Ticket Booking System  
> **Phạm vi:** Source code dành cho khách hàng (CUSTOMER) và luồng đặt vé online  
> **Tổng quan dự án:** [`SOURCE_CODE_OVERVIEW.md`](SOURCE_CODE_OVERVIEW.md)  
> **Spec nghiệp vụ:** [`project_summary_final.md`](project_summary_final.md)  
> **Kế hoạch FR-11:** [`implementation_plan_fr-11.md`](implementation_plan_fr-11.md)  
> **Kế hoạch FR-12:** [`fr-12_seat_selection_2f514b7b.plan.md`](fr-12_seat_selection_2f514b7b.plan.md)  
> **Module liên quan:** [`MANAGER_MODULE_DETAIL.md`](MANAGER_MODULE_DETAIL.md) (phim, suất chiếu, pricing rules)

---

## 1. Tổng quan module Customer

Module Customer phục vụ người dùng có role **CUSTOMER** (và khách chưa đăng nhập cho các màn public). Theo spec (`project_summary_final.md`), nhóm FR Customer gồm FR-06 – FR-20, FR-43, FR-44.

**Trạng thái hiện tại (15/06/2026):** Đã triển khai **FR-11**, **FR-50**, **FR-12** (chọn ghế), **FR-13** (validate), **FR-14** (tạo đơn ONLINE + trang payment stub). Chưa có VNPay/MoMo (FR-16–18), loyalty, reviews.

### 1.1 Tính năng đã triển khai

| Tính năng | FR | Trạng thái | Ghi chú |
|-----------|-----|------------|---------|
| Xem lịch chiếu theo phim | FR-11 | ✅ | URL public `/showtimes?movieId=` |
| Hiển thị giá hiệu quả sau pricing rules | FR-50 | ✅ | `PricingCalculator` + `PricingRuleDAO` |
| Tab chọn 7 ngày (zero reload) | FR-11 | ✅ | `showtimes-selector.js` |
| Nhóm suất theo phòng chiếu | FR-11 | ✅ | Chip link `/checkout?showtimeId=` |
| Chọn ghế trên sơ đồ phòng | FR-12 | ✅ | `/checkout` — CUSTOMER + login |
| Validate ghế trống + tuổi trên checkout | FR-13 | ✅ | Logic `SeatHoldDAO.findBlockingSeatCodes` + `SeatAvailabilityValidator` |
| Tạo đơn đặt vé online (1 POST gộp) | FR-14 | ✅ | POST checkout → `Bookings` PENDING/UNPAID + redirect `/payment` |
| Trang thanh toán stub + countdown | FR-14 | ✅ | `/payment?bookingId=` — chưa VNPay/MoMo |
| Poll cập nhật sơ đồ ghế | — | ✅ | JSON mỗi 2s (`customer-checkout.js`) |
| Placeholder thông tin phim (phần trên) | — | 🟡 | `movie-info-placeholder.jsp` — đồng nghiệp mở rộng |
| Duyệt phim / trang chủ | — | ✅ | Thuộc `common/` (`HomeServlet`, `MovieListServlet`) |

### 1.2 Tính năng chưa triển khai

| Tính năng | FR | URL reserve | Ghi chú |
|-----------|-----|-------------|---------|
| Thanh toán VNPay / MoMo | FR-16–18 | `/payment` POST | Stub disabled; schema `Payments` có, chưa DAO |
| Lịch sử đặt vé | FR-07 | `/booking-history` | |
| Điểm tích lũy (xem / đổi) | FR-43, FR-44 | `/loyalty` | Config loyalty có ở Admin |
| Đánh giá phim | FR-20 | `/reviews/mine` | Schema `MovieReviews` có |
| Email xác nhận vé | FR-19 | — | `EmailUtil` có sẵn |
| Hủy / hoàn vé online | FR-08 – FR-10 | — | |

| Profile khách hàng | — | `/profile` | AccessControl: mọi role đã login |

> `ShowtimesServlet` ở `controller` (public). `CheckoutServlet` ở `controller.customer` (CUSTOMER-only qua `RoleFilter`).

**Tài khoản test (seed):**

| Email | Role | Ghi chú |
|-------|------|---------|
| `customer.adult@email.com` | CUSTOMER | Người lớn — mọi suất T13+ |
| `customer.teen@email.com` | CUSTOMER | 14 tuổi — T13 OK, T16/T18 bị chặn |
| Mật khẩu | `Password@123` | |

---

## 2. Danh sách file source liên quan Customer

### 2.1 Controller

```
src/main/java/controller/
├── ShowtimesServlet.java          # /showtimes — FR-11 (public)
└── customer/
    ├── CheckoutServlet.java       # /checkout — FR-12 / FR-13 / FR-14 (CUSTOMER)
    ├── PaymentServlet.java        # /payment — FR-14 stub (CUSTOMER)
    └── package-info.java
```

**Servlet dùng chung (public, phục vụ customer journey):**

| Servlet | URL | Vai trò trong hành trình khách |
|---------|-----|--------------------------------|
| `HomeServlet` | `/home` | Khám phá phim, CTA "Đặt vé" → `/showtimes` |
| `MovieListServlet` | `/movies` | Danh sách phim + filter |
| `ShowtimesServlet` | `/showtimes` | Chọn ngày & suất → link checkout |
| `CheckoutServlet` | `/checkout` | Chọn ghế, tạo đơn ONLINE, panel tóm tắt |
| `PaymentServlet` | `/payment` | Tóm tắt đơn + countdown (stub FR-16) |

**Endpoint checkout:**

| URL | Method | Mô tả |
|-----|--------|-------|
| `/checkout?showtimeId=` | GET | Trang chọn ghế |
| `/checkout?action=seats&showtimeId=` | GET | JSON availability (poll client) |
| `/checkout` | POST | Validate + `createOnlineBooking` → redirect `/payment` |
| `/payment?bookingId=` | GET | Tóm tắt đơn + countdown 10 phút |
| `/payment` | POST | Stub VNPay/MoMo |

### 2.2 View (`WEB-INF/views/customer/`)

```
src/main/webapp/WEB-INF/views/customer/
├── showtimes.jsp                              # Wrapper lịch chiếu (FR-11)
├── checkout.jsp                               # Wrapper chọn ghế (FR-12)
├── payment.jsp                                # Thanh toán online stub (FR-14)
├── components/
│   ├── movie-info-placeholder.jsp           # PHẦN TRÊN showtimes
│   ├── showtimes-selector.jsp               # PHẦN DƯỚI — lịch chiếu (FR-11)
│   ├── checkout-header.jsp                  # Header checkout — back, meta suất
│   ├── seat-map.jsp                         # Sơ đồ ghế + legend (FR-12)
│   └── booking-summary.jsp                  # Summary + countdown + POST (FR-12/13)
└── .gitkeep
```

**Design reference:**

```
Screen Design/
├── Movie-detail/           # FR-11 — code.html, DESIGN.md, screen.png
├── Seat selection/         # FR-12 — code.html, DESIGN.md, screen.png
└── Ticket booking/         # FR-14 — code.html, DESIGN.md, screen.png
```

### 2.3 CSS & JS

| File | Mục đích |
|------|----------|
| `css/main.css` | Layout chung, header/footer (kế thừa từ mọi trang) |
| `css/customer-showtimes.css` | Lịch chiếu — `.mi-*`, `.st-*` |
| `css/customer-checkout.css` | Chọn ghế — `.ck-*` (glass, VIP gold, selected red `#e50914`) |
| `js/showtimes-selector.js` | Tab ngày (FR-11) |
| `js/customer-checkout.js` | Toggle ghế, summary, poll JSON 2s (FR-12/13) |
| `js/customer-payment.js` | Countdown hết hạn đơn trên payment (FR-14) |
| `js/seat-type-colors.js` | Màu legend loại ghế (dùng chung staff + customer) |

Trang load CSS qua `extraCss` trong JSP → `header.jsp` (`customer-showtimes` / `customer-checkout`).

### 2.4 DAL & Model

| File | Vai trò với Customer |
|------|----------------------|
| `dal/MovieDAO.java` | `getById()` + `loadGenres()` — chi tiết phim trên trang lịch chiếu |
| `dal/ShowtimeDAO.java` | `getUpcomingShowtimesByMovieId()` — suất từ `GETDATE()`, loại `CANCELLED` |
| `dal/PricingRuleDAO.java` | `getActiveRules()` — rule `status = ACTIVE` cho FR-50 |
| `model/entity/Movie.java` | Entity phim (+ list `genres`) |
| `model/entity/Showtime.java` | Entity suất; field transient `effectivePrice` |
| `model/entity/PricingRule.java` | Entity quy tắc giá động |
| `dal/SeatDAO.java` | `getSeatsForShowtime(id)` / `(id, userId)` — availability + hold; giá base×multiplier (staff) |
| `dal/SeatHoldDAO.java` | FR-13: validate blocking, `holdSeats`, expiry, dọn hold hết hạn |
| `utils/SeatAvailabilityValidator.java` | FR-13: tuổi T13/T16/T18 |
| `utils/SeatHoldException.java` | Conflict giữ ghế (race / UK) |
| `utils/PricingCalculator.java` | `effectivePrice` trên checkout (ghi đè `ticketPrice` per seat) |

**Bảng DB liên quan (đã dùng / sẽ dùng):**

| Bảng | Trạng thái DAO | Dùng cho |
|------|----------------|----------|
| `Movies`, `MovieGenres`, `Genres` | ✅ `MovieDAO` | Thông tin phim |
| `Showtimes`, `CinemaRooms` | ✅ `ShowtimeDAO` | Lịch chiếu |
| `PricingRules` | ✅ read-only | Giá động (FR-50) |
| `Seats`, `SeatTypes` | ✅ `SeatDAO` | Sơ đồ ghế checkout + staff counter |
| `SeatHolds` | ✅ `SeatHoldDAO` | Giữ ghế 10 phút (FR-13) |
| `Bookings`, `BookingSeats` | ✅ `BookingDAO` | `createOnlineBooking` (FR-14) + staff OFFLINE |
| `Payments`, `Tickets` | ❌ | Thanh toán & vé điện tử |
| `Promotions`, `BookingPromotions` | ❌ | Mã giảm giá |
| `MovieReviews` | ❌ | Đánh giá phim |
| `LoyaltyPointsLog` | ❌ | Tích / đổi điểm |

### 2.5 Filter & Access Control

| Path | Yêu cầu | Ghi chú |
|------|---------|---------|
| `/showtimes`, `/showtimes/*` | **Public** | `AccessControl.PUBLIC_PREFIXES` |
| `/movies` | **Public** | |
| `/checkout`, `/checkout/*` | **CUSTOMER** + đăng nhập | `CheckoutServlet`, JSON poll |
| `/payment`, `/payment/*` | **CUSTOMER** + đăng nhập | `PaymentServlet` |
| `/profile`, `/profile/*` | Đăng nhập (mọi role) | Servlet chưa có |
| `/booking-history`, `/loyalty`, `/reviews/mine` | **CUSTOMER** + đăng nhập | Servlet chưa có |

---

## 3. Kiến trúc màn hình 2 người (tránh merge conflict)

Màn **chi tiết phim + lịch chiếu** được chia cho **2 developer** làm song song:

```
showtimes.jsp                         ← Wrapper (ít đụng — chỉ layout khung)
    │
    ├─► components/movie-info-placeholder.jsp   ← Developer A: poster, trailer, cast, mô tả
    │
    └─► components/showtimes-selector.jsp         ← Developer B: tab ngày, phòng, chip suất
```

| Quy tắc | Chi tiết |
|---------|----------|
| Dữ liệu chia sẻ | Servlet set `movie` — cả 2 component đọc `${movie.*}` |
| Servlet | Chỉ `ShowtimesServlet` — không cần sửa khi A làm UI phần trên |
| CSS class prefix | `.mi-*` = movie info; `.st-*` = showtimes — tránh đè selector |
| JS | Chỉ `showtimes-selector.js` — không đụng `main.js` |

**Đồng nghiệp (phần trên)** chỉnh `movie-info-placeholder.jsp`.  
**Phần lịch chiếu** nằm trong `showtimes-selector.jsp` + `customer-showtimes.css` (phần `.st-*`).

---

## 4. `ShowtimesServlet` — Luồng xử lý

**File:** `src/main/java/controller/ShowtimesServlet.java`  
**URL:** `GET /showtimes?movieId={uuid}`  
**View:** `/WEB-INF/views/customer/showtimes.jsp`

### 4.1 Sơ đồ luồng

```mermaid
sequenceDiagram
    participant B as Browser
    participant S as ShowtimesServlet
    participant MD as MovieDAO
    participant SD as ShowtimeDAO
    participant PR as PricingRuleDAO
    participant PC as PricingCalculator
    participant J as showtimes.jsp

    B->>S: GET /showtimes?movieId=...
    alt movieId rỗng
        S->>B: 302 → /movies
    else movieId hợp lệ
        S->>MD: getById(movieId)
        MD-->>S: Movie (+ genres)
        alt null hoặc DELETED
            S->>B: forward 404.jsp
        else OK
            S->>SD: getUpcomingShowtimesByMovieId(id)
            S->>PR: getActiveRules()
            S->>PC: applyToShowtimes(list, rules)
            S->>S: build dateKeys (7 ngày) + showtimeMap
            S->>J: forward attributes
            J->>B: HTML (2 jsp:include)
        end
    end
```

### 4.2 Request attributes

| Attribute | Kiểu | Mô tả |
|-----------|------|-------|
| `movie` | `Movie` | Phim đầy đủ + `genres` (List&lt;String&gt;) |
| `dateKeys` | `List<String>` | 7 key `yyyy-MM-dd` từ hôm nay |
| `dateLabels` | `List<String>` | Nhãn tab: "Hôm nay", "Ngày mai", "Thứ …" |
| `showtimeMap` | `Map<String, Map<String, List<Showtime>>>` | Ngày → tên phòng → danh sách suất |
| `genreList` | `List<Genre>` | Cho dropdown thể loại trên `header.jsp` |

### 4.3 Query suất chiếu

`ShowtimeDAO.getUpcomingShowtimesByMovieId()`:

- `start_time >= GETDATE()`
- `status <> 'CANCELLED'` (gồm SCHEDULED, OPEN, SOLD_OUT, FINISHED)
- JOIN `Movies`, `CinemaRooms` — có `roomName` denormalized trên `Showtime`

### 4.4 Nhóm theo ngày & phòng

- Chỉ gán suất vào **7 ngày tab** (suất sau ngày thứ 7 không hiện trên UI — có thể mở rộng sau).
- Trong mỗi ngày: `LinkedHashMap` theo `roomName` — thứ tự phòng theo suất xuất hiện đầu tiên.
- Suất trong phòng giữ thứ tự `ORDER BY start_time` từ SQL.

### 4.5 Điểm vào từ UI hiện có

| Nguồn | Link |
|-------|------|
| `common/home.jsp` | `/showtimes?movieId=${movie.id}` (hero, tab phim) |
| `common/movies.jsp` | Nút "Đặt vé" / "Đặt vé sớm" |

---

## 5. Dynamic Pricing (FR-50)

### 5.1 `PricingRuleDAO`

```java
List<PricingRule> getActiveRules()
// WHERE status = 'ACTIVE' ORDER BY priority DESC, created_at ASC
```

Chỉ **đọc** — CRUD pricing rules cho Manager (FR-49) chưa có UI.

### 5.2 `PricingCalculator`

**Công thức** (theo `project_summary_final.md`):

```
effectivePrice = base_price × (1 + Σ% / 100) + Σfixed
```

- Duyệt **tất cả** rule ACTIVE khớp điều kiện — **cộng dồn** (priority chỉ ảnh hưởng thứ tự load, không chọn 1 rule).
- Kết quả gán vào `Showtime.effectivePrice` (transient, không persist DB).
- Làm tròn `setScale(0, HALF_UP)` — đơn vị VND.

### 5.3 Điều kiện rule (`condition_type`)

| Loại | Kiểm tra |
|------|----------|
| `DAY_OF_WEEK` | `day_of_week` CSV `"6,7"` — Thứ 2=1 … Chủ nhật=7 (Java `DayOfWeek`) |
| `TIME_RANGE` | Giờ bắt đầu suất ∈ [`time_from`, `time_to`] |
| `DATE_RANGE` | Ngày chiếu ∈ [`date_from`, `date_to`] |
| `SPECIFIC_DATE` | Ngày chiếu = `date_from` |

### 5.4 Kiểu điều chỉnh (`adjustment_type`)

| Loại | `adjustment_value` |
|------|-------------------|
| `PERCENTAGE` | Cộng vào Σ% (VD: `10` = +10%, `-5` = −5%) |
| `FIXED_AMOUNT` | Cộng vào Σfixed VND (VD: `10000` = +10.000đ) |

### 5.5 Ví dụ kiểm tra

| base_price | Rule | Kết quả |
|------------|------|---------|
| 80.000đ | T7/CN `FIXED_AMOUNT +10.000` | 90.000đ cuối tuần |
| 80.000đ | Khung 21h–23h `PERCENTAGE +10` | 88.000đ |

> Giá hiển thị trên chip là **giá gốc suất** sau pricing rules. Trên checkout, giá vé = `effectivePrice × seat_multiplier` (theo loại ghế).

---

## 6. `CheckoutServlet` — Chọn ghế & tạo đơn (FR-12 / FR-13 / FR-14)

**File:** `src/main/java/controller/customer/CheckoutServlet.java`  
**URL:** `/checkout`  
**View:** `/WEB-INF/views/customer/checkout.jsp`

### 6.1 Sơ đồ luồng

```mermaid
sequenceDiagram
    participant B as Browser
    participant C as CheckoutServlet
    participant SD as ShowtimeDAO
    participant SeD as SeatDAO
    participant BD as BookingDAO
    participant V as SeatAvailabilityValidator
    participant PC as PricingCalculator
    participant P as PaymentServlet

    B->>C: GET /checkout?showtimeId=
    C->>SD: load showtime + movie
    C->>SeD: getSeatsForShowtime(id, userId)
    C->>PC: apply effectivePrice per seat
    C->>B: checkout.jsp (seat map + summary)

    loop Poll mỗi 2s
        B->>C: GET ?action=seats&showtimeId=
        C->>SeD: getSeatsForShowtime(id, userId)
        C->>B: JSON availability
    end

    B->>C: POST seatIds[]
    C->>V: validateAge(movie, user)
    C->>BD: createOnlineBooking (transaction)
    C->>C: session checkoutDraft
    C->>B: redirect /payment?bookingId=
    B->>P: GET payment summary
```

### 6.2 Guard & trạng thái suất

| Điều kiện | Hành vi |
|-----------|---------|
| Thiếu / sai `showtimeId` | 404 |
| Suất `SOLD_OUT` | Hiển thị sơ đồ read-only, không chọn ghế |
| Chưa login / không phải CUSTOMER | `RoleFilter` → login |

### 6.3 Giá vé trên checkout

```
ticketPrice = effectivePrice × seat_multiplier
```

- `effectivePrice` tính từ `PricingCalculator` (FR-50) trên `Showtime.basePrice`
- `seat_multiplier` lấy từ `SeatTypes` qua JOIN `SeatDAO`

### 6.4 FR-14 — Tạo đơn ONLINE (luồng gộp 1 POST)

| Bước | Logic |
|------|-------|
| Tuổi | `SeatAvailabilityValidator` trên servlet POST (FR-13) |
| Availability | `SeatHoldDAO.findBlockingSeatCodes` trong `BookingDAO.createOnlineBooking` |
| Giá | Server-side: `PricingCalculator` × `SeatTypes.price_multiplier` |
| INSERT | `Bookings` ONLINE, PENDING, UNPAID, `expired_at = NOW + 10 phút`, mã `BK-yyyyMMdd-xxxx` |
| BookingSeats | Snapshot `ticket_price` từng ghế |
| Idempotency | Double-click → trả về cùng `bookingId` nếu đã có PENDING cùng suất |
| Session | `checkoutDraft` — `bookingId`, `showtimeId`, `seatIds`, `expiredAt` |
| Sau POST | Redirect `/payment?bookingId=` (không còn `?hold=ok`) |

**Race condition:** validate lại trong transaction; UK → `SeatHoldException` message thân thiện.

> Luồng gộp **không INSERT SeatHolds** — ghế bị chặn qua `Bookings.booking_status IN ('PENDING','CONFIRMED')` trong `SeatDAO`.

### 6.5 Poll cập nhật sơ đồ (client)

- `customer-checkout.js`: `SEAT_REFRESH_MS = 2000` — gọi JSON `?action=seats`
- Ghế hold bởi **chính user** vẫn hiển thị selectable (`heldByCurrentUser` trên entity `Seat`)
- **Không** dùng SSE/WebSocket — chỉ polling HTTP

### 6.6 View checkout (modular)

```jsp
<c:set var="extraCss" value="customer-checkout"/>
<%@ include file="common/header.jsp" %>
<div class="ck-layout">
    <jsp:include page="components/checkout-header.jsp"/>
    <jsp:include page="components/seat-map.jsp"/>
    <jsp:include page="components/booking-summary.jsp"/>
</div>
<%@ include file="common/footer.jsp" %>
```

| Component | Vai trò |
|-----------|---------|
| `checkout-header.jsp` | Back → showtimes, meta suất, badge tuổi phim |
| `seat-map.jsp` | Màn hình + lưới ghế + legend (available / selected / booked / held) |
| `booking-summary.jsp` | Danh sách ghế, tạm tính (chưa VAT), nút **Tiếp tục thanh toán** |

**Design:** `Screen Design/Seat selection/` — prefix CSS `.ck-*`. Payment: `Screen Design/Ticket booking/`.

---

## 6b. `PaymentServlet` — Thanh toán stub (FR-14 / FR-16)

**File:** `src/main/java/controller/customer/PaymentServlet.java`  
**URL:** `/payment?bookingId=`  
**View:** `/WEB-INF/views/customer/payment.jsp`

| Guard | Hành vi |
|-------|---------|
| Không thuộc user hiện tại | 404 |
| Không phải ONLINE / PENDING | Redirect checkout + error |
| `expired_at` đã qua | Redirect checkout + error |

UI: poster phim, ghế, breakdown VAT, countdown 10 phút, nút VNPay/MoMo disabled (stub FR-16).

---

## 7. View Layer — Chi tiết JSP (showtimes)

### 7.1 `showtimes.jsp` (wrapper)

```jsp
<c:set var="extraCss" value="customer-showtimes"/>
<%@ include file="common/header.jsp" %>
<div class="movie-detail-wrapper">
    <jsp:include page="components/movie-info-placeholder.jsp"/>
    <jsp:include page="components/showtimes-selector.jsp"/>
</div>
<%@ include file="common/footer.jsp" %>
```

### 7.2 `movie-info-placeholder.jsp` (phần trên)

**Hiện có (placeholder):**

- Banner `backdropUrl` / fallback `posterUrl`
- Poster 2:3 + badge rating
- Title, age rating, thời lượng, ngày công chiếu, thể loại
- Đạo diễn, mô tả (hoặc text placeholder)

**Đồng nghiệp có thể thêm** (theo `Screen Design/Movie-detail/`):

- Nút Play trailer (`movie.trailerUrl`)
- Cast horizontal scroll
- Rating IMDb / Rotten Tomatoes (nếu có field)
- Section "You May Also Like"

**Biến JSP sẵn có:** `${movie.title}`, `${movie.description}`, `${movie.director}`, `${movie.posterUrl}`, `${movie.backdropUrl}`, `${movie.genres}`, `${movie.averageRating}`, …

### 7.3 `showtimes-selector.jsp` (phần dưới)

- Tiêu đề "Chọn suất chiếu"
- 7 nút tab ngày (`.st-date-tab`)
- Panel theo ngày (`.st-day-panel`) — ẩn/hiện bằng JS
- Mỗi phòng: tiêu đề + danh sách chip
- Chip: `HH:mm | {giá} đ`
  - Link: `/checkout?showtimeId={id}` (yêu cầu login CUSTOMER)
  - `SOLD_OUT`: chip disabled, trang checkout read-only
- Empty state: "Không có suất chiếu trong ngày này"

---

## 8. CSS — Showtimes & Checkout

### 8.1 `customer-showtimes.css`

| Prefix | Vùng | Tham chiếu design |
|--------|------|-------------------|
| `.mi-*` | Movie info — banner, poster, meta | Movie-detail hero + grid |
| `.st-*` | Showtimes — glass panel, tabs, chips | Date & Time Selectors |

Đặc điểm chính:

- Nền glass: `rgba(18,18,18,0.6)` + `backdrop-filter: blur(24px)`
- Tab ngày active: `#e50914` (Cinematic Red)
- Chip suất: viền trắng mờ, hover sáng hơn
- Responsive: mobile stack poster + căn giữa meta

### 8.2 `customer-checkout.css`

| Prefix | Vùng | Ghi chú |
|--------|------|---------|
| `.ck-*` | Layout 2 cột, seat grid, summary glass | Cinematic Premium — đỏ `#e50914`, VIP gold |

---

## 9. JavaScript

### 9.1 `showtimes-selector.js`

- IIFE, không pollute global
- Click `.st-date-tab` → toggle `.st-date-tab--active` + `.st-day-panel--active`
- Cập nhật `aria-selected`, attribute `hidden` cho a11y
- **Không** gọi API — toàn bộ dữ liệu render server-side lần đầu

### 9.2 `customer-checkout.js`

- Toggle chọn ghế (`.ck-seat--available`), cập nhật summary + tổng tiền
- Poll JSON `?action=seats` mỗi **2 giây** — đồng bộ booked / held
- Countdown hết hạn đơn trên trang payment (`customer-payment.js`)
- Form POST gửi `seatIds[]` + hidden `showtimeId`

---

## 10. Entity bổ sung

### 10.1 `PricingRule`

| Field Java | Cột DB | Ghi chú |
|------------|--------|---------|
| `ruleName` | `rule_name` | |
| `conditionType` | `condition_type` | DAY_OF_WEEK, TIME_RANGE, … |
| `dayOfWeek` | `day_of_week` | CSV, VD `"6,7"` |
| `timeFrom` / `timeTo` | `time_from` / `time_to` | `java.sql.Time` |
| `dateFrom` / `dateTo` | `date_from` / `date_to` | |
| `adjustmentType` | `adjustment_type` | PERCENTAGE, FIXED_AMOUNT |
| `adjustmentValue` | `adjustment_value` | `BigDecimal` |
| `priority` | `priority` | |
| `status` | `status` | ACTIVE / INACTIVE |

### 10.2 `Showtime.effectivePrice`

- Kiểu `BigDecimal`, **không** map từ DB
- Set bởi `PricingCalculator.applyToShowtimes()` trước khi forward JSP
- JSP fallback: `${st.effectivePrice != null ? st.effectivePrice : st.basePrice}`

### 10.3 `Seat` (checkout)

| Field | Ghi chú |
|-------|---------|
| `ticketPrice` | Set runtime = `effectivePrice × multiplier` |
| `heldByCurrentUser` | Transient — ghế đang hold bởi user hiện tại vẫn chọn được |
| `status` | `AVAILABLE`, `BOOKED`, `HELD`, … — từ JOIN `SeatHolds` / `BookingSeats` |

---

## 11. Lộ trình triển khai tiếp theo

```
FR-11 ✅  →  FR-12 ✅  →  FR-13 ✅  →  FR-14 ✅  →  FR-16–18 (payment gateway)
                                              ↓
                                       FR-07 (lịch sử) · FR-19 (email) · FR-43 (loyalty)
```

| Bước | FR | Việc cần làm |
|------|-----|--------------|
| 1 | FR-16–18 | `PaymentDAO`, redirect VNPay/MoMo, callback xác nhận |
| 2 | FR-19 | Email e-ticket qua `EmailUtil` |
| 3 | FR-07 | `BookingHistoryServlet` → `/booking-history` |
| 4 | FR-20 | `MovieReviewDAO` + servlet reviews |
| 5 | FR-43–44 | `LoyaltyServlet` → `/loyalty` |

**Tùy chọn kỹ thuật:** SSE/WebSocket thay poll 2s nếu cần near-realtime (chưa có trong repo).

---

## 12. Kiểm tra thủ công

### 12.1 Truy cập trang showtimes

1. Chạy Tomcat + DB có seed showtimes.
2. Mở `/home` → chọn phim → "Đặt vé" hoặc trực tiếp `/showtimes?movieId=<uuid>`.
3. Thiếu `movieId` → redirect `/movies`.
4. `movieId` sai → `404.jsp`.

### 12.2 Lịch chiếu & phòng

1. Chọn từng tab ngày — không reload trang.
2. Cùng ngày, suất cùng `room_name` nằm dưới một tiêu đề phòng.
3. Ngày không có suất → empty state.

### 12.3 Giá động

1. INSERT `PricingRules` ACTIVE (VD: phụ thu cuối tuần +10.000đ).
2. So sánh chip T2–T6 vs T7/CN cùng `base_price`.

### 12.4 Checkout & tạo đơn (FR-12 / FR-14)

1. Login `customer.adult@email.com` / `Password@123`.
2. `/showtimes?movieId=` → click chip suất → `/checkout?showtimeId=`.
3. Chọn 1–8 ghế — summary cập nhật giá × multiplier.
4. **Tiếp tục thanh toán** → redirect `/payment?bookingId=`, countdown ~10 phút.
5. DB: 1 row `Bookings` (ONLINE, PENDING, UNPAID) + N rows `BookingSeats`.
6. Tab ẩn danh / user khác: ghế vừa đặt unavailable trên checkout (poll 2s).
7. Staff counter đặt cùng ghế trước → customer POST fail.
8. Double-click nút → idempotency, cùng `bookingId`.
9. `customer.teen@email.com` + suất T18 → POST bị chặn (validate tuổi).

### 12.5 Tích hợp 2 người (showtimes UI)

1. Sửa nội dung `movie-info-placeholder.jsp` (thêm HTML tùy ý).
2. Xác nhận `showtimes-selector.jsp` vẫn hoạt động, không vỡ layout.

### 12.6 Sold out

- Suất `status = SOLD_OUT` → chip disabled, không click được.

---

## 13. Hạn chế & ghi chú kỹ thuật

1. **FR-16–18 chưa có** — trang `/payment` là stub; VNPay/MoMo chưa implement.
2. **Poll 2s** — không realtime; race xử lý bằng validate DB + unique constraint.
3. **Pricing rules** — chỉ đọc ACTIVE; Manager chưa có UI CRUD (FR-49).
4. **Không seed `PricingRules`** trong `create_database.sql` — INSERT thủ công để test FR-50.
5. **Suất sau ngày thứ 7** không hiển thị — chỉ 7 tab cố định.
6. **`ShowtimesServlet` ở `controller`** (public); checkout authenticated ở `controller.customer`.
7. **Không CSRF** — form POST checkout cần cân nhắc token khi harden bảo mật.

---

## 14. Liên kết tài liệu

| Tài liệu | Nội dung |
|----------|----------|
| [`SOURCE_CODE_OVERVIEW.md`](SOURCE_CODE_OVERVIEW.md) | Tổng quan toàn repo |
| [`implementation_plan_fr-11.md`](implementation_plan_fr-11.md) | Spec triển khai FR-11 |
| [`MANAGER_MODULE_DETAIL.md`](MANAGER_MODULE_DETAIL.md) | Nguồn dữ liệu phim, suất, phòng |
| [`fr-12_seat_selection_2f514b7b.plan.md`](fr-12_seat_selection_2f514b7b.plan.md) | Spec triển khai FR-12/13 |
| [`Screen Design/Movie-detail/DESIGN.md`](Screen%20Design/Movie-detail/DESIGN.md) | Design lịch chiếu / movie detail |
| [`Screen Design/Seat selection/DESIGN.md`](Screen%20Design/Seat%20selection/DESIGN.md) | Design chọn ghế |
| [`Screen Design/Ticket booking/DESIGN.md`](Screen%20Design/Ticket%20booking/DESIGN.md) | Design trang payment |
| [`project_summary_final.md`](project_summary_final.md) | FR đầy đủ + luồng đặt vé online |

---

*Tài liệu được tổng hợp từ source code thực tế trong repo, cập nhật 15/06/2026.*
