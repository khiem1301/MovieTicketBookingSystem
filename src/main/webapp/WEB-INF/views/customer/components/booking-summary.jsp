<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:set var="poster" value="${showtime.moviePosterUrl}"/>
<c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
  <c:set var="poster" value="${ctx}/${poster}"/>
</c:if>

<aside class="ck-summary" aria-label="Tóm tắt đặt vé">
  <div class="ck-summary-card">
    <div class="ck-summary-hero">
      <c:choose>
        <c:when test="${not empty poster}">
          <img class="ck-summary-bg" src="<c:out value='${poster}'/>"
               alt="" aria-hidden="true"/>
        </c:when>
        <c:otherwise>
          <div class="ck-summary-bg ck-summary-bg--empty"></div>
        </c:otherwise>
      </c:choose>
      <div class="ck-summary-hero-overlay"></div>
      <div class="ck-summary-hero-text">
        <h2 class="ck-summary-movie"><c:out value="${showtime.movieTitle}"/></h2>
        <div class="ck-summary-meta">
          <span class="ck-summary-room"><c:out value="${showtime.roomName}"/></span>
          <c:if test="${showtime.movieDurationMinutes > 0}">
            <span class="ck-summary-duration">${showtime.movieDurationMinutes} phút</span>
          </c:if>
        </div>
      </div>
    </div>

    <div class="ck-summary-body">
      <h3 class="ck-summary-heading">Ghế đã chọn</h3>
      <div class="ck-seat-list" id="ckSeatList" hidden></div>
      <p class="ck-empty-msg" id="ckEmptyMsg">Chưa chọn ghế nào</p>

      <hr class="ck-divider"/>

      <div class="ck-total-row">
        <span class="ck-total-label">Tạm tính</span>
        <span class="ck-total-value" id="ckTotal">0 ₫</span>
      </div>
      <p class="ck-total-note">Chưa bao gồm VAT và phí dịch vụ</p>

      <div class="ck-hold-timer" id="ckHoldTimer"
           <c:if test="${empty holdExpiresAt}">hidden</c:if>
           data-expires="<c:out value='${holdExpiresAt}'/>">
        <span class="ck-hold-timer-label">Thời gian giữ ghế</span>
        <span class="ck-hold-timer-value" id="ckHoldCountdown">--:--</span>
      </div>

      <c:if test="${not empty pendingBookingId}">
        <div class="ck-pending-actions">
          <a class="ck-pending-pay-link" href="${ctx}/payment?bookingId=${pendingBookingId}">
            Tiếp tục thanh toán đơn đang chờ &rarr;
          </a>
          <form method="post" action="${ctx}/payment" class="ck-cancel-form"
                onsubmit="return confirm('Hủy đơn đang chờ và giải phóng ghế?');">
            <input type="hidden" name="bookingId" value="<c:out value='${pendingBookingId}'/>"/>
            <input type="hidden" name="action" value="cancel"/>
            <button type="submit" class="ck-cancel-btn">Hủy đơn đang chờ</button>
          </form>
        </div>
      </c:if>

      <form id="ckCheckoutForm" method="post" action="${ctx}/checkout">
        <input type="hidden" name="showtimeId" value="<c:out value='${showtime.id}'/>"/>
        <div id="ckHiddenSeats"></div>
        <button type="submit" class="ck-proceed-btn" id="ckProceedBtn" disabled>
          Tiếp tục thanh toán
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="5" y1="12" x2="19" y2="12"/>
            <polyline points="12 5 19 12 12 19"/>
          </svg>
        </button>
      </form>
      <p class="ck-disclaimer">Vé không hoàn tiền sau khi mua.</p>
    </div>
  </div>
</aside>
