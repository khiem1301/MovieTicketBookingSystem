# Kế hoạch triển khai FR-11 — Xem Lịch chiếu cho Khách hàng (View Showtimes)

Tài liệu này mô tả chi tiết phương án thiết kế mô-đun và triển khai tính năng **FR-11 — Xem Lịch Chiếu (View Showtimes)** cho Khách hàng, bao gồm việc tính toán giá vé hiệu quả động (Dynamic Pricing) dựa trên các quy tắc `PricingRules` đang hoạt động.

Đồng thời, kế hoạch này thiết kế giao diện theo cấu trúc mô-đun phân tách rõ rệt để lập trình viên khác có thể dễ dàng chèn thêm phần mô tả chi tiết phim ở phía trên màn hình mà không ảnh hưởng tới code hiển thị suất chiếu của bạn.

---

## Thiết kế Mô-đun & Hướng mở rộng cho đồng nghiệp

Để giao diện có tính mở rộng cao và giảm thiểu xung đột mã nguồn (merge conflict), màn hình chi tiết phim và lịch chiếu sẽ được phân tách thành **1 trang chính điều hướng (wrapper)** và **2 thành phần con (components)**:

```
[WEB-INF/views/customer/showtimes.jsp]  <-- Trang chính (chứa bố cục & nạp các phần con)
        │
        ├─► [components/movie-info-placeholder.jsp] <-- PHẦN TRÊN: Mô tả chi tiết phim (Đồng nghiệp làm)
        │
        └─► [components/showtimes-selector.jsp]    <-- PHẦN DƯỚI: Chọn ngày & Suất chiếu theo phòng (Bạn làm)
```

- **Lợi ích:** Đồng nghiệp chỉ cần mở file `movie-info-placeholder.jsp` để sửa đổi mã nguồn, thêm trailer, tóm tắt phim, danh sách diễn viên,... Phần code hiển thị suất chiếu của bạn trong `showtimes-selector.jsp` sẽ hoàn toàn độc lập.
- **Dữ liệu chia sẻ:** Servlet sẽ nạp sẵn đối tượng `Movie` (gán vào request attribute `movie`). Đồng nghiệp có thể truy xuất trực tiếp các trường như `${movie.title}`, `${movie.description}`, `${movie.director}`,... ngay trong file của họ.

---

## Proposed Changes

Các thay đổi cụ thể cần thực hiện trong dự án:

### 1. Database Access & Model Layer (DAL)

#### [NEW] [PricingRule.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/model/entity/PricingRule.java)
Tạo thực thể biểu diễn bảng `PricingRules` trong DB:
- Các trường: `id`, `ruleName`, `conditionType`, `dayOfWeek`, `timeFrom`, `timeTo`, `dateFrom`, `dateTo`, `adjustmentType`, `adjustmentValue`, `priority`, `status`.
- Các getter và setter tương ứng.

#### [MODIFY] [Showtime.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/model/entity/Showtime.java)
- Thêm trường transient: `private BigDecimal effectivePrice;` cùng getter/setter. Trường này dùng để lưu giá sau khi đã tính toán qua các quy tắc tăng/giảm giá tại thời điểm chạy (runtime).

#### [NEW] [PricingRuleDAO.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/dal/PricingRuleDAO.java)
- Phương thức `public List<PricingRule> getActiveRules()`: Tải toàn bộ các quy tắc định giá đang hoạt động (`status = 'ACTIVE'`), sắp xếp theo thứ tự ưu tiên giảm dần.

#### [MODIFY] [ShowtimeDAO.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/dal/ShowtimeDAO.java)
- Thêm phương thức `public List<Showtime> getUpcomingShowtimesByMovieId(String movieId)`: Lấy các suất chiếu của phim từ thời điểm hiện tại trở đi (`start_time >= GETDATE()`) và trạng thái khác `CANCELLED`.

---

### 2. Business Logic Layer

#### [NEW] [PricingCalculator.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/utils/PricingCalculator.java)
Lớp tiện ích thực hiện áp dụng các quy tắc giảm giá động:
- Duyệt qua danh sách `PricingRules` hoạt động.
- Kiểm tra suất chiếu có thoả mãn điều kiện không:
  - `DAY_OF_WEEK`: Ngày trong tuần (Thứ 2 - Chủ Nhật tương ứng 1-7) nằm trong chuỗi `day_of_week` (VD: "6,7").
  - `TIME_RANGE`: Giờ bắt đầu nằm trong khoảng `time_from` và `time_to`.
  - `DATE_RANGE` / `SPECIFIC_DATE`: Ngày chiếu nằm trong khoảng/đúng ngày cấu hình.
- Tính toán giá hiệu quả theo công thức:
  `price = base_price * (1 + sum_percentage / 100) + sum_fixed`

---

### 3. Controller Layer

#### [NEW] [ShowtimesServlet.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/controller/ShowtimesServlet.java)
Tạo servlet công khai xử lý đường dẫn `/showtimes`.
- Nhận tham số `movieId`.
- Lấy thông tin phim từ `MovieDAO` để làm thông tin chi tiết phim (phần trên).
- Tạo danh sách 7 ngày tiếp theo (bắt đầu từ Hôm nay) gửi xuống JSP làm các tab chọn ngày.
- Lấy danh sách suất chiếu sắp tới của phim.
- Chạy `PricingCalculator` trên từng suất chiếu để tính `effectivePrice`.
- Nhóm các suất chiếu này theo cấu trúc: `Map<String, Map<String, List<Showtime>>>` (Ngày chiếu `"yyyy-MM-dd"` -> Tên phòng chiếu -> Danh sách suất chiếu tương ứng).
- Đẩy dữ liệu này xuống dưới dạng các attribute: `movie`, `dateKeys`, `dateLabels`, `showtimeMap`.
- Forward tới `/WEB-INF/views/customer/showtimes.jsp`.

---

### 4. View Layer (JSP)

#### [NEW] [showtimes.jsp](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/webapp/WEB-INF/views/customer/showtimes.jsp)
- Chứa cấu trúc HTML khung của trang.
- Nạp header và footer hệ thống.
- Sử dụng `<jsp:include>` để tách riêng phần trên và phần dưới:
  ```jsp
  <div class="movie-detail-wrapper">
      <%-- PHẦN 1: THÔNG TIN PHIM (Do đồng nghiệp phát triển) --%>
      <jsp:include page="components/movie-info-placeholder.jsp" />
      
      <%-- PHẦN 2: LỊCH CHIẾU VÀ PHÒNG CHIẾU (Bạn phát triển) --%>
      <jsp:include page="components/showtimes-selector.jsp" />
  </div>
  ```

#### [NEW] [movie-info-placeholder.jsp](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/webapp/WEB-INF/views/customer/components/movie-info-placeholder.jsp)
- File chứa layout placeholder cho thông tin phim (poster, tên phim, tóm tắt, đạo diễn, thời lượng).
- Đồng nghiệp của bạn sau này chỉ cần chỉnh sửa file này để thiết kế lại phần thông tin phim mà không cần đụng đến code của bạn.

#### [NEW] [showtimes-selector.jsp](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/webapp/WEB-INF/views/customer/components/showtimes-selector.jsp)
- Hiển thị thanh tab gồm 7 ngày (Hôm nay, Ngày mai, Thứ X...).
- Khi click chọn 1 ngày: hiển thị danh sách các phòng chiếu hoạt động có suất chiếu của ngày đó.
- Dưới mỗi phòng, hiển thị các chip suất chiếu: Giờ bắt đầu và Giá vé hiệu quả sau khi áp PricingRules (Ví dụ: `19:30 | 85.000 đ`).
- Mỗi chip suất chiếu sẽ là link dẫn tới trang đặt ghế: `/checkout?showtimeId=...` (hoặc luồng chọn ghế tương ứng).
- Sử dụng Vanilla Javascript đơn giản để chuyển đổi giữa các tab ngày mà không cần tải lại trang (Zero reload, tạo cảm giác mượt mà cho người dùng).

---

## Verification Plan

### Manual Verification
1. **Kiểm tra hiển thị theo phòng:**
   - Đảm bảo các suất chiếu của cùng một ngày, cùng một phòng được nhóm chính xác dưới tiêu đề phòng chiếu đó (ví dụ: "Phòng chiếu 1", "Phòng chiếu 2").
2. **Kiểm tra áp dụng quy tắc định giá động (PricingRules):**
   - Giả sử suất chiếu có giá gốc là `80.000 đ`.
   - Tạo quy tắc định giá: Phụ thu cuối tuần `+10.000 đ` (loại FIXED_AMOUNT, áp dụng T7/CN).
   - Kiểm tra lịch chiếu:
     - Ngày thường (Thứ 2 - Thứ 6): Hiển thị giá `80.000 đ`.
     - Cuối tuần (Thứ 7 / Chủ nhật): Hiển thị giá `90.000 đ`.
3. **Kiểm tra tính tương thích khi tích hợp:**
   - Thay đổi thử nội dung file `movie-info-placeholder.jsp` xem giao diện phần trên có cập nhật đúng mà phần lịch chiếu bên dưới không bị lỗi hay ảnh hưởng gì không.
