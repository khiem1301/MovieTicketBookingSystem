<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Quầy Bán Vé — ÉpCine</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/staff.css"/>
</head>
<body>

<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="counter-main">
  <div class="container">

    <%-- Tiêu đề --%>
    <div class="counter-header">
      <h1 class="counter-title">Quầy Bán Vé</h1>
      <span class="counter-staff-badge">
        Nhân viên: <strong><c:out value="${sessionScope.loggedUser.fullName}"/></strong>
      </span>
    </div>

    <%-- Thông báo lỗi chung --%>
    <c:if test="${not empty errorMessage}">
      <div class="alert alert--error">
        <c:out value="${errorMessage}"/>
      </div>
    </c:if>

    <%-- Step indicator --%>
    <div class="step-indicator">
      <div class="step-item <c:if test='${step == "movie"}'>step-item--active</c:if>
                           <c:if test='${step == "showtime" or step == "seat" or step == "confirm"}'>step-item--done</c:if>">
        <span class="step-num">1</span>
        <span class="step-label">Chọn phim</span>
      </div>
      <div class="step-line"></div>
      <div class="step-item <c:if test='${step == "showtime"}'>step-item--active</c:if>
                           <c:if test='${step == "seat" or step == "confirm"}'>step-item--done</c:if>">
        <span class="step-num">2</span>
        <span class="step-label">Chọn suất</span>
      </div>
      <div class="step-line"></div>
      <div class="step-item <c:if test='${step == "seat"}'>step-item--active</c:if>
                           <c:if test='${step == "confirm"}'>step-item--done</c:if>">
        <span class="step-num">3</span>
        <span class="step-label">Đặt vé</span>
      </div>
      <div class="step-line"></div>
      <div class="step-item <c:if test='${step == "confirm"}'>step-item--active</c:if>">
        <span class="step-num">4</span>
        <span class="step-label">Xác nhận</span>
      </div>
    </div>

    <%-- ═══════════════════════════════════════════════════════
         BƯỚC 1 — Chọn phim
         ═══════════════════════════════════════════════════════ --%>
    <c:if test="${step == 'movie'}">
      <div class="section-title">Chọn phim đang chiếu</div>

      <c:choose>
        <c:when test="${empty movies}">
          <div class="empty-state">
            Hiện chưa có lịch chiếu nào. Quản lý cần tạo lịch chiếu trước.
          </div>
        </c:when>
        <c:otherwise>
          <div class="movie-grid">
            <c:forEach var="movie" items="${movies}">
              <a href="${pageContext.request.contextPath}/staff/counter?step=showtime&movieId=${movie.id}"
                 class="movie-card-counter">
                <div class="movie-poster-wrap">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img src="<c:out value='${movie.posterUrl}'/>"
                           alt="<c:out value='${movie.title}'/>"
                           onerror="this.src='${pageContext.request.contextPath}/images/poster-placeholder.png'"/>
                    </c:when>
                    <c:otherwise>
                      <div class="poster-placeholder">No Image</div>
                    </c:otherwise>
                  </c:choose>
                  <c:if test="${not empty movie.ageRating}">
                    <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                  </c:if>
                </div>
                <div class="movie-card-info">
                  <p class="movie-card-title"><c:out value="${movie.title}"/></p>
                  <p class="movie-card-meta">${movie.durationMinutes} phút</p>
                </div>
              </a>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </c:if>

    <%-- ═══════════════════════════════════════════════════════
         BƯỚC 2 — Chọn suất chiếu
         ═══════════════════════════════════════════════════════ --%>
    <c:if test="${step == 'showtime'}">
      <div class="step-back">
        <a href="${pageContext.request.contextPath}/staff/counter" class="btn-back">
          ← Quay lại chọn phim
        </a>
      </div>

      <c:choose>
        <c:when test="${empty showtimes}">
          <div class="empty-state">
            Phim này hiện không có suất chiếu nào sắp diễn ra.
          </div>
        </c:when>
        <c:otherwise>
          <div class="section-title">
            Chọn suất chiếu —
            <span class="text-accent"><c:out value="${showtimes[0].movieTitle}"/></span>
          </div>
          <div class="showtime-list">
            <c:forEach var="st" items="${showtimes}">
              <a href="${pageContext.request.contextPath}/staff/counter?step=seat&showtimeId=${st.id}"
                 class="showtime-card">
                <div class="showtime-card-left">
                  <div class="showtime-time">
                    <fmt:formatDate value="${st.startTime}" pattern="HH:mm" type="time"/>
                  </div>
                  <div class="showtime-date">
                    <fmt:formatDate value="${st.startTime}" pattern="dd/MM/yyyy" type="date"/>
                  </div>
                </div>
                <div class="showtime-card-mid">
                  <div class="showtime-room">
                    Phòng: <strong><c:out value="${st.roomName}"/></strong>
                  </div>
                  <div class="showtime-status showtime-status--${st.status}">
                    <c:choose>
                      <c:when test="${st.status == 'OPEN'}">Đang mở bán</c:when>
                      <c:when test="${st.status == 'SCHEDULED'}">Sắp mở</c:when>
                      <c:otherwise><c:out value="${st.status}"/></c:otherwise>
                    </c:choose>
                  </div>
                </div>
                <div class="showtime-card-right">
                  <div class="showtime-price">
                    <fmt:formatNumber value="${st.basePrice}" type="number" groupingUsed="true"/>
                    ₫
                  </div>
                  <span class="btn-select-showtime">Chọn →</span>
                </div>
              </a>
            </c:forEach>
          </div>
        </c:otherwise>
      </c:choose>
    </c:if>

    <%-- ═══════════════════════════════════════════════════════
         BƯỚC 3 — Chọn ghế + Thông tin khách hàng
         ═══════════════════════════════════════════════════════ --%>
    <c:if test="${step == 'seat'}">
      <div class="step-back">
        <a href="${pageContext.request.contextPath}/staff/counter?step=showtime&movieId=${showtime.movieId}"
           class="btn-back">← Quay lại chọn suất</a>
      </div>

      <div class="booking-layout">

        <%-- Panel trái: sơ đồ ghế --%>
        <div class="seat-panel">
          <div class="section-title">Sơ đồ ghế</div>
          <div class="showtime-summary">
            <span class="text-accent"><c:out value="${showtime.movieTitle}"/></span>
            &nbsp;|&nbsp;
            <fmt:formatDate value="${showtime.startTime}" pattern="HH:mm dd/MM/yyyy" type="both"/>
            &nbsp;|&nbsp; Phòng: <c:out value="${showtime.roomName}"/>
          </div>

          <%-- Chú thích --%>
          <div class="seat-legend">
            <span class="legend-item"><span class="seat-sample seat--available"></span> Trống</span>
            <span class="legend-item"><span class="seat-sample seat--booked"></span> Đã đặt</span>
            <span class="legend-item"><span class="seat-sample seat--selected"></span> Đang chọn</span>
          </div>

          <%-- Màn chiếu --%>
          <div class="screen-bar">MÀN CHIẾU</div>

          <%-- Sơ đồ ghế --%>
          <div class="seat-map" id="seatMap">
            <c:choose>
              <c:when test="${empty seatsByRow}">
                <div class="empty-state">Phòng chiếu này chưa có ghế nào được cấu hình.</div>
              </c:when>
              <c:otherwise>
                <c:forEach var="rowEntry" items="${seatsByRow}">
                  <div class="seat-row-wrap">
                    <span class="seat-row-label">${rowEntry.key}</span>
                    <div class="seat-row-cells">
                      <c:forEach var="seat" items="${rowEntry.value}">
                        <button type="button"
                                class="seat-btn <c:choose><c:when test='${seat.available}'>seat--available</c:when><c:otherwise>seat--booked</c:otherwise></c:choose>
                                       seat-type--${fn:toLowerCase(seat.seatTypeName)}"
                                data-seat-id="${seat.id}"
                                data-seat-code="${seat.seatCode}"
                                data-seat-type="${seat.seatTypeName}"
                                data-price="${seat.ticketPrice}"
                                title="${seat.seatCode} — ${seat.seatTypeName}"
                                <c:if test="${!seat.available}">disabled</c:if>>
                          <c:out value="${seat.seatCode}"/>
                        </button>
                      </c:forEach>
                    </div>
                  </div>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </div>
        </div>

        <%-- Panel phải: form đặt vé --%>
        <div class="order-panel">
          <form id="bookingForm" method="post"
                action="${pageContext.request.contextPath}/staff/counter">
            <input type="hidden" name="showtimeId" value="${showtime.id}"/>

            <%-- Thông tin khách hàng --%>
            <div class="order-section">
              <div class="section-title">Thông tin khách hàng</div>

              <%-- FR-38: toggle khách vãng lai / thành viên --%>
              <div class="customer-type-toggle">
                <label class="toggle-option">
                  <input type="radio" name="customerType" value="walkin" checked
                         onchange="toggleCustomerType(this.value)"/>
                  Khách vãng lai
                </label>
                <label class="toggle-option">
                  <input type="radio" name="customerType" value="member"
                         onchange="toggleCustomerType(this.value)"/>
                  Thành viên
                </label>
              </div>

              <%-- Chú thích SP2 cho member lookup --%>
              <div id="memberNote" class="sp2-note" style="display:none;">
                Tra cứu tài khoản theo SĐT sẽ được bổ sung ở Sprint 2 (FR-42).
              </div>

              <div class="form-group">
                <label for="customerName">Họ tên khách <span class="required">*</span></label>
                <input type="text" id="customerName" name="customerName"
                       placeholder="Nhập họ và tên khách" required
                       class="form-input"/>
              </div>
              <div class="form-group">
                <label for="customerPhone">Số điện thoại <span class="required">*</span></label>
                <input type="tel" id="customerPhone" name="customerPhone"
                       placeholder="Ví dụ: 0912345678" required
                       pattern="^(0|\+84)[0-9]{9,10}$"
                       class="form-input"/>
              </div>
            </div>

            <%-- Danh sách ghế đã chọn --%>
            <div class="order-section">
              <div class="section-title">Ghế đã chọn</div>
              <div id="selectedSeatsList" class="selected-seats-list">
                <p class="text-muted">Chưa chọn ghế nào.</p>
              </div>
            </div>

            <%-- Tóm tắt tiền --%>
            <div class="order-section order-summary">
              <div class="summary-row">
                <span>Tạm tính</span>
                <span id="subtotalDisplay">0 ₫</span>
              </div>
              <div class="summary-row summary-row--total">
                <span>Tổng cộng</span>
                <strong id="totalDisplay">0 ₫</strong>
              </div>
            </div>

            <%-- Nút xác nhận --%>
            <button type="submit" id="confirmBtn" class="btn btn-primary btn-block" disabled>
              Tạo đơn đặt vé
            </button>
            <p class="confirm-note">
              Thanh toán sẽ được xử lý sau khi tạo đơn (FR-36 — Sprint 2).
            </p>
          </form>
        </div>

      </div><%-- /booking-layout --%>
    </c:if>

    <%-- ═══════════════════════════════════════════════════════
         BƯỚC 4 — Xác nhận đơn
         ═══════════════════════════════════════════════════════ --%>
    <c:if test="${step == 'confirm'}">
      <div class="confirm-card">
        <div class="confirm-icon">✓</div>
        <h2>Đặt vé thành công!</h2>
        <c:if test="${not empty booking}">
          <table class="confirm-table">
            <tr><td>Mã đơn</td><td><strong><c:out value="${booking.bookingCode}"/></strong></td></tr>
            <tr><td>Khách hàng</td><td><c:out value="${booking.customerName}"/></td></tr>
            <tr><td>Số điện thoại</td><td><c:out value="${booking.customerPhone}"/></td></tr>
            <tr><td>Trạng thái</td><td><span class="badge badge--pending">Chờ thanh toán</span></td></tr>
            <tr><td>Tổng tiền</td><td>
              <fmt:formatNumber value="${booking.finalAmount}" type="number" groupingUsed="true"/> ₫
            </td></tr>
          </table>
        </c:if>
        <div class="confirm-actions">
          <a href="${pageContext.request.contextPath}/staff/counter" class="btn btn-primary">
            Tạo đơn mới
          </a>
        </div>
        <p class="confirm-note">
          In vé và thanh toán tại quầy sẽ được bổ sung ở Sprint 2 (FR-36, FR-37).
        </p>
      </div>
    </c:if>

  </div><%-- /container --%>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/counter-booking.js"></script>
</body>
</html>
