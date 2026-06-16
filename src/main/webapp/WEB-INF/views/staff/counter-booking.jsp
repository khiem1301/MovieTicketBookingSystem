<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <meta name="ctx" content="${pageContext.request.contextPath}"/>
  <title>Quầy Bán Vé — ÉpCine POS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/staff.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/counter-pos.css"/>
</head>
<body class="pos-body">

<div class="pos-container">

  <%-- ── POS Header ──────────────────────────────────────────── --%>
  <div class="pos-header">
    <div class="pos-header-left">
      <a href="${pageContext.request.contextPath}/home" class="pos-logo">
        <img src="${pageContext.request.contextPath}/images/logorapchieuphim.png"
             alt="ÉpCine" class="pos-logo-img"
             onerror="this.style.display='none';this.nextElementSibling.style.display='inline'"/>
        <span class="pos-logo-fallback" style="display:none">ÉpCine</span>
      </a>
      <span class="pos-title">Quầy Bán Vé</span>
    </div>
    <div class="pos-header-right">
      <span class="pos-staff-name">
        Nhân viên: <strong><c:out value="${sessionScope.loggedUser.fullName}"/></strong>
      </span>
      <span class="pos-offline-badge">&#9679; OFFLINE</span>
    </div>
  </div>

  <%-- Thông báo lỗi --%>
  <c:if test="${not empty errorMessage}">
    <div class="pos-alert pos-alert--error"><c:out value="${errorMessage}"/></div>
  </c:if>

  <%-- ── 3-Panel Layout ─────────────────────────────────────── --%>
  <div class="pos-layout">

    <%-- ════════════════════════════════
         PANEL TRÁI: Chọn phim + suất
         ════════════════════════════════ --%>
    <div class="pos-panel pos-left">

      <%-- Search --%>
      <div class="pos-search-wrap">
        <input type="text" id="movieSearch" class="pos-search-input"
               placeholder="Tìm kiếm phim..." autocomplete="off"
               oninput="filterMovies(this.value)"/>
      </div>

      <%-- Tabs --%>
      <div class="pos-tab-bar">
        <button class="pos-tab pos-tab--active" id="tabNowShowing"
                onclick="switchTab('now')">Đang chiếu</button>
        <button class="pos-tab" id="tabComingSoon"
                onclick="switchTab('coming')">Sắp chiếu</button>
      </div>

      <%-- Danh sách phim (server-rendered) --%>
      <div class="pos-movie-list" id="movieList">
        <c:choose>
          <c:when test="${empty movies}">
            <div class="pos-empty">
              Chưa có phim nào.<br/>
              <small>Quản lý cần thêm phim vào hệ thống.</small>
            </div>
          </c:when>
          <c:otherwise>
            <c:forEach var="movie" items="${movies}">
              <div class="pos-movie-item"
                   data-movie-id="${movie.id}"
                   data-movie-status="${movie.status}"
                   data-movie-title="${fn:toLowerCase(movie.title)}"
                   onclick="selectMovie(this)">
                <div class="pos-movie-thumb-wrap">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img class="pos-movie-thumb"
                           src="<c:out value='${movie.posterUrl}'/>"
                           alt="<c:out value='${movie.title}'/>"
                           onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"/>
                      <div class="pos-movie-thumb-placeholder" style="display:none">
                        <c:out value="${fn:substring(movie.title,0,1)}"/>
                      </div>
                    </c:when>
                    <c:otherwise>
                      <div class="pos-movie-thumb-placeholder">
                        <c:out value="${fn:substring(movie.title,0,1)}"/>
                      </div>
                    </c:otherwise>
                  </c:choose>
                </div>
                <div class="pos-movie-info">
                  <div class="pos-movie-title"><c:out value="${movie.title}"/></div>
                  <div class="pos-movie-meta">${movie.durationMinutes} phút</div>
                  <div class="pos-movie-badges">
                    <c:if test="${not empty movie.ageRating}">
                      <span class="pos-badge pos-badge--rating">
                        <c:out value="${movie.ageRating}"/>
                      </span>
                    </c:if>
                    <c:if test="${movie.averageRating > 0}">
                      <span class="pos-badge pos-badge--star">
                        ★ <c:out value="${movie.averageRating}"/>
                      </span>
                    </c:if>
                  </div>
                </div>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>

      <%-- Showtime Picker (ẩn cho đến khi chọn phim) --%>
      <div class="pos-showtime-picker" id="showtimePicker" style="display:none">
        <div class="pos-section-label">Chọn suất chiếu</div>
        <div class="pos-date-tabs" id="dateTabs"></div>
        <div class="pos-time-grid" id="timeGrid"></div>
        <div class="pos-loading hidden" id="showtimeLoading">Đang tải suất chiếu...</div>
      </div>

    </div><%-- /pos-left --%>

    <%-- ════════════════════════════════
         PANEL GIỮA: Sơ đồ ghế
         ════════════════════════════════ --%>
    <div class="pos-panel pos-mid">

      <div class="pos-screen-wrap">
        <div class="pos-screen-bar">MÀN CHIẾU</div>
      </div>

      <div class="pos-seat-area" id="seatArea">
        <div class="pos-seat-placeholder" id="seatPlaceholder">
          <div class="placeholder-icon">🎬</div>
          <div>Chọn phim và suất chiếu<br/>để xem sơ đồ ghế</div>
        </div>
      </div>

      <div class="pos-seat-legend">
        <span class="legend-item"><span class="leg-dot leg-standard"></span>Thường</span>
        <span class="legend-item"><span class="leg-dot leg-vip"></span>VIP</span>
        <span class="legend-item"><span class="leg-dot leg-couple"></span>Cặp đôi</span>
        <span class="legend-item"><span class="leg-dot leg-selected"></span>Đang chọn</span>
        <span class="legend-item"><span class="leg-dot leg-sold"></span>Đã bán</span>
      </div>

    </div><%-- /pos-mid --%>

    <%-- ════════════════════════════════
         PANEL PHẢI: Tóm tắt đặt vé
         ════════════════════════════════ --%>
    <div class="pos-panel pos-right">

      <div class="pos-summary-header">
        <span class="summary-title">Tóm tắt đặt vé</span>
        <span class="pos-offline-badge">OFFLINE</span>
      </div>

      <%-- Thông tin phim / suất đã chọn --%>
      <div class="pos-summary-movie" id="summaryMovie">
        <div class="pos-summary-placeholder">Chưa chọn phim</div>
      </div>

      <%-- Danh sách ghế đã chọn --%>
      <div class="pos-summary-seats">
        <div class="pos-section-label">Ghế đã chọn</div>
        <div id="seatSummaryList" class="pos-seat-list">
          <span class="pos-empty-small">Chưa có ghế nào</span>
        </div>
      </div>

      <%-- FR-42: Tra cứu thành viên theo SĐT --%>
      <div class="pos-customer-section">
        <div class="pos-section-label">Tra cứu thành viên (tuỳ chọn)</div>
        <div class="pos-lookup-row">
          <input type="tel" id="lookupPhone" class="pos-form-input pos-lookup-input"
                 placeholder="Nhập SĐT thành viên..."
                 onkeydown="if(event.key==='Enter'){event.preventDefault();lookupMember();}"/>
          <button type="button" class="pos-lookup-btn" onclick="lookupMember()">Tìm</button>
        </div>
        <div id="memberResult" class="pos-member-result" style="display:none"></div>
      </div>

      <%-- Thông tin khách hàng --%>
      <div class="pos-customer-section" style="margin-top:8px">
        <div class="pos-section-label">Thông tin khách hàng</div>
        <input type="text" id="custName"
               class="pos-form-input"
               placeholder="Họ tên khách hàng *"
               oninput="checkProceedBtn()"/>
        <input type="tel" id="custPhone"
               class="pos-form-input"
               placeholder="Số điện thoại *"
               oninput="checkProceedBtn()"/>
      </div>

      <%-- Tổng tiền --%>
      <div class="pos-total-row">
        <span>Tổng tiền</span>
        <strong id="totalDisplay" class="pos-total-amount">0 ₫</strong>
      </div>

      <%-- Nút tiến hành --%>
      <button id="proceedBtn" class="pos-proceed-btn" disabled
              onclick="proceedToPayment()">
        Tiến hành thanh toán →
      </button>

      <%-- Hidden form gửi lên server --%>
      <form id="bookingForm" method="post"
            action="${pageContext.request.contextPath}/staff/counter">
        <input type="hidden" name="showtimeId"    id="formShowtimeId"/>
        <input type="hidden" name="customerName"  id="formCustName"/>
        <input type="hidden" name="customerPhone" id="formCustPhone"/>
        <input type="hidden" name="memberId"      id="formMemberId" value=""/>
      </form>

    </div><%-- /pos-right --%>

  </div><%-- /pos-layout --%>
</div><%-- /pos-container --%>

<script src="${pageContext.request.contextPath}/js/counter-booking.js"></script>
</body>
</html>
