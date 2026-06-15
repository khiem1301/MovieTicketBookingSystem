<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Thanh toán — ${detail.movieTitle} | ÉPCINE"/>
<c:set var="extraCss" value="customer-checkout"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="poster" value="${detail.moviePosterUrl}"/>
<c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
  <c:set var="poster" value="${ctx}/${poster}"/>
</c:if>

<c:set var="discount" value="${detail.discountAmount != null ? detail.discountAmount : 0}"/>
<c:set var="vatAmount" value="${detail.vatAmount != null ? detail.vatAmount : 0}"/>

<div class="pay-page"
     data-ctx="${ctx}"
     data-expires="<c:out value='${detail.expiredAt.time}'/>"
     data-showtime-id="<c:out value='${detail.showtimeId}'/>">

  <header class="pay-header">
    <div class="pay-header-inner container">
      <a href="${ctx}/checkout?showtimeId=${detail.showtimeId}" class="ck-back-btn" aria-label="Quay lại chọn ghế">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="15 18 9 12 15 6"/>
        </svg>
      </a>
      <div class="pay-header-text">
        <h1 class="pay-title">Xác nhận &amp; thanh toán</h1>
        <p class="pay-subtitle">Hoàn tất đơn trong thời gian quy định</p>
      </div>
      <div class="pay-secure-badge">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="3" y="11" width="18" height="11" rx="2"/>
          <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        </svg>
        Thanh toán bảo mật
      </div>
    </div>
  </header>

  <c:if test="${not empty errorMessage}">
    <div class="ck-alert ck-alert--error container">
      <c:out value="${errorMessage}"/>
    </div>
  </c:if>

  <c:if test="${not empty infoMessage}">
    <div class="ck-alert ck-alert--info container">
      <c:out value="${infoMessage}"/>
    </div>
  </c:if>

  <div class="pay-expiry-bar container">
    <span class="pay-expiry-label">Thời gian giữ đơn</span>
    <span class="pay-expiry-value" id="payCountdown">--:--</span>
  </div>

  <div class="pay-layout container">
    <section class="pay-details" aria-label="Chi tiết đơn hàng">
      <div class="pay-card pay-card--movie">
        <div class="pay-card-tag">ONLINE BOOKING</div>
        <div class="pay-ref">
          Mã đơn: <strong><c:out value="${detail.bookingCode}"/></strong>
        </div>

        <div class="pay-movie-row">
          <div class="pay-movie-poster">
            <c:choose>
              <c:when test="${not empty poster}">
                <img src="<c:out value='${poster}'/>" alt="Poster phim"
                     onerror="this.style.display='none'"/>
              </c:when>
              <c:otherwise>
                <div class="pay-poster-fallback">🎬</div>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="pay-movie-info">
            <h2 class="pay-movie-title"><c:out value="${detail.movieTitle}"/></h2>
            <p class="pay-movie-meta">
              <fmt:formatDate value="${detail.startTime}" pattern="EEE, dd/MM/yyyy • HH:mm"/>
            </p>
            <p class="pay-movie-meta">Phòng: <c:out value="${detail.roomName}"/></p>
          </div>
        </div>

        <div class="pay-seats-block">
          <h3 class="pay-section-title">Ghế đã chọn</h3>
          <ul class="pay-seat-list">
            <c:forEach var="seat" items="${detail.seats}">
              <li class="pay-seat-item">
                <span>Vé <c:out value="${seat.seatType}"/> — Ghế <c:out value="${seat.seatCode}"/></span>
                <span><fmt:formatNumber value="${seat.price}" type="number" groupingUsed="true"/> ₫</span>
              </li>
            </c:forEach>
          </ul>
        </div>
      </div>
    </section>

    <aside class="pay-summary" aria-label="Tóm tắt thanh toán">
      <div class="pay-card pay-card--summary">
        <h3 class="pay-section-title">Tóm tắt đơn</h3>

        <div class="pay-promo-block">
          <label class="pay-promo-label" for="payPromoCode">Mã giảm giá / Voucher</label>
          <c:choose>
            <c:when test="${not empty detail.appliedPromoCode}">
              <div class="pay-promo-applied">
                <span class="pay-promo-applied-code"><c:out value="${detail.appliedPromoCode}"/></span>
                <span class="pay-promo-applied-title"><c:out value="${detail.appliedPromoTitle}"/></span>
              </div>
              <form method="post" action="${ctx}/payment" class="pay-promo-form">
                <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
                <input type="hidden" name="action" value="removePromo"/>
                <button type="submit" class="pay-promo-remove-btn">Gỡ mã</button>
              </form>
            </c:when>
            <c:otherwise>
              <form method="post" action="${ctx}/payment" class="pay-promo-form">
                <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
                <input type="hidden" name="action" value="applyPromo"/>
                <div class="pay-promo-row">
                  <input type="text" id="payPromoCode" name="promoCode" class="pay-promo-input"
                         placeholder="Nhập mã voucher" maxlength="50" autocomplete="off"/>
                  <button type="submit" class="pay-promo-apply-btn">Áp dụng</button>
                </div>
              </form>
            </c:otherwise>
          </c:choose>
        </div>

        <div class="pay-breakdown">
          <div class="pay-breakdown-row">
            <span>Tạm tính (<c:out value="${fn:length(detail.seats)}"/> vé)</span>
            <span><fmt:formatNumber value="${detail.totalAmount}" type="number" groupingUsed="true"/> ₫</span>
          </div>
          <c:if test="${discount gt 0}">
            <div class="pay-breakdown-row pay-breakdown-row--discount">
              <span>Giảm giá (<c:out value="${detail.appliedPromoCode}"/>)</span>
              <span>-<fmt:formatNumber value="${discount}" type="number" groupingUsed="true"/> ₫</span>
            </div>
          </c:if>
          <div class="pay-breakdown-row">
            <span>VAT (<fmt:formatNumber value="${detail.vatRate}" maxFractionDigits="1"/>%)</span>
            <span><fmt:formatNumber value="${vatAmount}" type="number" groupingUsed="true"/> ₫</span>
          </div>
          <div class="pay-breakdown-row pay-breakdown-row--total">
            <span>Tổng thanh toán</span>
            <span class="pay-final-amount">
              <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
            </span>
          </div>
        </div>

        <p class="pay-vat-note">Đã bao gồm VAT</p>

        <div class="pay-methods">
          <p class="pay-section-title">Phương thức thanh toán</p>
          <form method="post" action="${ctx}/payment">
            <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
            <button type="submit" class="pay-method-btn" disabled title="Sắp có">
              VNPay
            </button>
            <button type="submit" class="pay-method-btn" disabled title="Sắp có">
              MoMo
            </button>
          </form>
          <p class="pay-stub-note">Cổng thanh toán VNPay / MoMo sẽ được kích hoạt ở FR-16.</p>
        </div>

        <form method="post" action="${ctx}/payment" class="pay-cancel-form"
              onsubmit="return confirm('Hủy đơn này và giải phóng ghế ngay?');">
          <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
          <input type="hidden" name="action" value="cancel"/>
          <button type="submit" class="pay-cancel-btn">Hủy đơn &amp; giải phóng ghế</button>
        </form>

        <a href="${ctx}/checkout?showtimeId=${detail.showtimeId}" class="pay-back-link">
          ← Quay lại chọn ghế
        </a>
      </div>
    </aside>
  </div>
</div>

<script charset="UTF-8" src="${ctx}/js/customer-payment.js"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
