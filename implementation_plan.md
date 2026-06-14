# Kế hoạch triển khai FR-25 — Quản lý Suất chiếu (Showtime Management)

Tài liệu này mô tả chi tiết kế hoạch thiết kế và phát triển tính năng quản lý suất chiếu (CRUD suất chiếu, kiểm tra trùng giờ cùng phòng chiếu) dành cho Manager/Admin trong hệ thống đặt vé phim ÉPCINE.

## User Review Required

> [!IMPORTANT]
> **Các quy tắc nghiệp vụ cốt lõi cần được phê duyệt:**
> 1. **Kiểm tra trùng phòng/giờ:** Suất chiếu mới `[start_time, end_time]` không được trùng lặp với bất kỳ suất chiếu nào khác trong cùng phòng chiếu mà có trạng thái khác `CANCELLED`.
>    - Công thức kiểm tra trùng lặp: `start_time < new_end_time` và `end_time > new_start_time`.
> 2. **Tự động tính thời gian kết thúc:** `end_time` sẽ tự động tính bằng `start_time + movie_duration_minutes`. Trong pha này, chúng ta chưa áp dụng thời gian dọn dẹp (buffer) giữa các suất trừ khi người dùng yêu cầu, nhưng sẽ để xuất trên giao diện.
> 3. **Ràng buộc sửa/xoá khi có vé:** Nếu suất chiếu đã có đơn đặt vé (booking active, khác trạng thái `CANCELLED`), hệ thống sẽ **khoá** không cho thay đổi Phim, Phòng chiếu, và Giờ bắt đầu, đồng thời không cho xoá cứng (hard delete). Người quản lý chỉ có thể thay đổi trạng thái (ví dụ: `CANCELLED` hoặc `SOLD_OUT`) hoặc giá vé cơ bản.
> 4. **Xoá suất chiếu:** Hỗ trợ xoá cứng nếu chưa có booking. Nếu đã có booking, chỉ hỗ trợ chuyển trạng thái thành `CANCELLED` (huỷ suất chiếu).

---

## Proposed Changes

Các thay đổi được chia theo các lớp Layer: Database Access (DAL), Controller (Servlet), View (JSP).

### 1. Database Access Layer (DAL)

#### [MODIFY] [ShowtimeDAO.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/dal/ShowtimeDAO.java)
Thêm các phương thức viết và kiểm tra nghiệp vụ:
- `public List<Showtime> getAllForManager()`: Lấy toàn bộ danh sách suất chiếu, sắp xếp theo thời gian bắt đầu giảm dần.
- `public void create(Showtime s, String createdBy)`: Thêm mới một suất chiếu vào bảng `Showtimes`. Sử dụng `createdBy` để lưu người tạo.
- `public void update(Showtime s)`: Cập nhật thông tin suất chiếu (movie_id, room_id, start_time, end_time, base_price, status).
- `public void delete(String id)`: Xoá suất chiếu khỏi database (chỉ khi không có ràng buộc khoá ngoại).
- `public boolean isOverlapping(String roomId, Timestamp startTime, Timestamp endTime, String excludeId)`: Kiểm tra phòng chiếu có bị trùng lịch trong khoảng thời gian đó không.
- `public int countBookingsByShowtimeId(String showtimeId)`: Đếm số lượng booking active của suất chiếu này (để làm điều kiện chặn sửa/xoá).

---

### 2. Controller Layer

#### [NEW] [ManageShowtimeServlet.java](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/java/controller/manager/ManageShowtimeServlet.java)
Tạo servlet quản lý tại path `/manager/showtimes`.
- **doGet:**
  - Kiểm tra phân quyền (chỉ cho phép `MANAGER` hoặc `ADMIN`).
  - Nếu `action=edit`, lấy thông tin suất chiếu theo ID để hiển thị lên form sửa.
  - Lấy danh sách phim đang hoạt động (`MovieDAO`).
  - Lấy danh sách phòng chiếu đang hoạt động (`CinemaRoomDAO`).
  - Lấy danh sách toàn bộ suất chiếu để hiển thị bảng.
  - Forward đến trang JSP `/WEB-INF/views/manager/showtime-list.jsp`.
- **doPost:**
  - Kiểm tra phân quyền.
  - **Action `create`:**
    - Parse dữ liệu: `movieId`, `roomId`, `startTime` (từ datetime-local), `basePrice`.
    - Kiểm tra hợp lệ: phim/phòng tồn tại, giờ bắt đầu ở tương lai, giá vé > 0.
    - Lấy thời lượng phim để tính `endTime = startTime + duration`.
    - Gọi `isOverlapping` để kiểm tra trùng giờ cùng phòng. Nếu trùng, trả về lỗi.
    - Thực hiện lưu. Redirect kèm `success=created`.
  - **Action `update`:**
    - Parse dữ liệu kèm `id` và `status`.
    - Kiểm tra nếu có booking tồn tại mà người dùng cố tình thay đổi Phim, Phòng hoặc Giờ chiếu → Báo lỗi chặn.
    - Kiểm tra trùng lịch (`isOverlapping`) loại trừ chính ID hiện tại.
    - Thực hiện cập nhật. Redirect kèm `success=updated`.
  - **Action `delete`:**
    - Kiểm tra số lượng booking. Nếu > 0, không cho xoá (báo lỗi).
    - Thực hiện xoá. Redirect kèm `success=deleted`.

---

### 3. View Layer (JSP)

#### [NEW] [showtime-list.jsp](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/webapp/WEB-INF/views/manager/showtime-list.jsp)
Thiết kế giao diện quản lý suất chiếu đẹp mắt và đồng bộ với hệ thống manager:
- Grid 2 cột: Cột trái chứa Form (Thêm/Sửa), Cột phải chứa bảng danh sách suất chiếu.
- Bộ lọc danh sách suất chiếu: Lọc theo Phim, Lọc theo Phòng chiếu, Lọc theo Ngày chiếu, Lọc theo Trạng thái.
- Form fields:
  - Chọn Phim (dropdown).
  - Chọn Phòng chiếu (dropdown).
  - Giờ bắt đầu (input `datetime-local`).
  - Giá vé cơ bản (input `number`, đơn vị VNĐ, VD: 80,000).
  - Trạng thái (dropdown: SCHEDULED, OPEN, SOLD_OUT, CANCELLED, FINISHED - chỉ hiện khi EDIT).
- Hiển thị badge trạng thái với màu sắc đồng bộ:
  - `SCHEDULED`: Muted blue.
  - `OPEN`: Green (sẵn sàng đặt vé).
  - `SOLD_OUT`: Orange.
  - `CANCELLED`: Red (có gạch ngang chữ).
  - `FINISHED`: Gray.
- Xử lý JavaScript phía Client:
  - Khi thay đổi Phim, hiển thị thời lượng phim tương ứng để người dùng ước lượng.

#### [MODIFY] [header.jsp](file:///d:/01.LEARNING%20MATERIALS/FPT%20University/Semester%208/SWP391/MovieTicketBookingSystem/src/main/webapp/WEB-INF/views/common/header.jsp)
- Thêm link điều hướng đến trang quản lý suất chiếu dành cho MANAGER:
  ```jsp
  <a href="${pageContext.request.contextPath}/manager/showtimes">Quản lý suất chiếu</a>
  ```

---

## Verification Plan

### Automated Tests
Dự án sử dụng cơ chế kiểm thử thủ công và dựng server Tomcat chạy thực tế. Để xác thực, ta có thể tạo các hàm kiểm tra nhỏ (Scratch Unit Test) trong `/scratch/TestShowtimeOverlap.java` hoặc kiểm thử trực tiếp trên luồng hoạt động.

### Manual Verification
1. **Kiểm tra tạo suất chiếu trùng giờ:**
   - Tạo suất chiếu 1 tại Phòng 1 từ 19:00 đến 21:00.
   - Thử tạo suất chiếu 2 tại Phòng 1 từ 20:00 đến 22:00 → Hệ thống phải ngăn chặn và hiển thị thông báo lỗi trùng lịch.
   - Thử tạo suất chiếu 3 tại Phòng 2 từ 20:00 đến 22:00 → Hệ thống cho phép lưu bình thường vì khác phòng chiếu.
2. **Kiểm tra sửa suất chiếu đã có booking:**
   - Giả lập một booking cho suất chiếu X.
   - Truy cập trang Edit suất chiếu X. Các trường Chọn phim, Chọn phòng và Giờ chiếu phải bị vô hiệu hoá (`disabled`), chỉ cho phép sửa Giá vé hoặc Trạng thái suất chiếu.
3. **Kiểm tra xoá suất chiếu:**
   - Suất chiếu không có booking: Cho phép xoá thành công khỏi danh sách.
   - Suất chiếu đã có booking: Nút xoá bị ẩn hoặc báo lỗi khi cố tình xoá, hướng dẫn chuyển trạng thái sang `CANCELLED`.
