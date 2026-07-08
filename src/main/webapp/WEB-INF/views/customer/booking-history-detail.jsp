<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Chi tiết đơn đặt vé | ÉPCINE"/>
<c:set var="extraCss" value="customer-booking-history"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="poster" value="${detail.moviePosterUrl}"/>
<c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
  <c:set var="poster" value="${ctx}/${poster}"/>
</c:if>

<div class="bh-page bh-page--detail container">
  <a href="${ctx}/booking-history" class="bh-back-link">← Quay lại lịch sử</a>

  <div class="bh-detail-card">
    <div class="bh-detail-header">
      <span class="bh-badge bh-badge--${fn:toLowerCase(detail.bookingStatus)}">
        <c:choose>
          <c:when test="${detail.bookingStatus == 'PENDING'}">Chờ thanh toán</c:when>
          <c:when test="${detail.bookingStatus == 'CONFIRMED'}">Đã xác nhận</c:when>
          <c:when test="${detail.bookingStatus == 'CANCELLED'}">Đã hủy</c:when>
          <c:when test="${detail.bookingStatus == 'EXPIRED'}">Hết hạn</c:when>
          <c:when test="${detail.bookingStatus == 'REFUNDED'}">Hoàn tiền</c:when>
          <c:otherwise><c:out value="${detail.bookingStatus}"/></c:otherwise>
        </c:choose>
      </span>
      <span class="bh-detail-source">
        <c:choose>
          <c:when test="${detail.bookingSource == 'ONLINE'}">Đặt online</c:when>
          <c:otherwise>Đặt tại quầy</c:otherwise>
        </c:choose>
      </span>
    </div>

    <div class="bh-detail-movie">
      <c:if test="${not empty poster}">
        <img src="<c:out value='${poster}'/>" alt="" class="bh-detail-poster"/>
      </c:if>
      <div>
        <h1 class="bh-detail-title"><c:out value="${detail.movieTitle}"/></h1>
        <p class="bh-detail-meta">
          <fmt:formatDate value="${detail.startTime}" pattern="EEE, dd/MM/yyyy • HH:mm"/>
          — <c:out value="${detail.roomName}"/>
        </p>
        <p class="bh-detail-meta">Mã đơn: <strong><c:out value="${detail.bookingCode}"/></strong></p>
      </div>
    </div>

    <section class="bh-detail-section">
      <h2 class="bh-detail-section-title">Ghế đã chọn</h2>
      <ul class="bh-seat-list">
        <c:forEach var="seat" items="${detail.seats}">
          <li>
            <span class="bh-seat-code"><c:out value="${seat.seatCode}"/></span>
            <span class="bh-seat-type"><c:out value="${seat.seatType}"/></span>
            <span class="bh-seat-price">
              <fmt:formatNumber value="${seat.price}" type="number" groupingUsed="true"/> ₫
            </span>
          </li>
        </c:forEach>
      </ul>
    </section>

    <section class="bh-detail-section">
      <h2 class="bh-detail-section-title">Thanh toán</h2>
      <dl class="bh-amount-list">
        <div class="bh-amount-row">
          <dt>Tạm tính</dt>
          <dd><fmt:formatNumber value="${detail.totalAmount}" type="number" groupingUsed="true"/> ₫</dd>
        </div>
        <c:if test="${detail.discountAmount != null and detail.discountAmount > 0}">
          <div class="bh-amount-row">
            <dt>Giảm giá<c:if test="${detail.hasAppliedPromo}"> (<c:out value="${detail.appliedPromoCode}"/>)</c:if></dt>
            <dd>-<fmt:formatNumber value="${detail.discountAmount}" type="number" groupingUsed="true"/> ₫</dd>
          </div>
        </c:if>
        <c:if test="${detail.vatAmount != null and detail.vatAmount > 0}">
          <div class="bh-amount-row">
            <dt>VAT (<fmt:formatNumber value="${detail.vatRate}" minFractionDigits="0" maxFractionDigits="2"/>%)</dt>
            <dd><fmt:formatNumber value="${detail.vatAmount}" type="number" groupingUsed="true"/> ₫</dd>
          </div>
        </c:if>
        <div class="bh-amount-row bh-amount-row--total">
          <dt>Tổng thanh toán</dt>
          <dd><fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫</dd>
        </div>
      </dl>
      <p class="bh-detail-meta">Trạng thái thanh toán:
        <c:choose>
          <c:when test="${detail.paymentStatus == 'PAID'}">Đã thanh toán</c:when>
          <c:when test="${detail.paymentStatus == 'UNPAID'}">Chưa thanh toán</c:when>
          <c:otherwise><c:out value="${detail.paymentStatus}"/></c:otherwise>
        </c:choose>
      </p>
    </section>

    <c:if test="${not empty detail.tickets}">
      <section class="bh-detail-section">
        <h2 class="bh-detail-section-title">Vé điện tử</h2>
        <div class="bh-ticket-grid">
          <c:forEach var="ticket" items="${detail.tickets}">
            <div class="bh-ticket-card">
              <p class="bh-ticket-seat">Ghế <c:out value="${ticket.seatCode}"/></p>
              <p class="bh-ticket-code"><c:out value="${ticket.ticketCode}"/></p>
              <c:if test="${not empty ticket.qrCode}">
                <c:set var="qr" value="${ticket.qrCode}"/>
                <c:if test="${not fn:startsWith(qr,'http')}">
                  <c:set var="qr" value="${ctx}/${qr}"/>
                </c:if>
                <img src="<c:out value='${qr}'/>" alt="QR vé ${ticket.seatCode}" class="bh-ticket-qr"/>
              </c:if>
            </div>
          </c:forEach>
        </div>
      </section>
    </c:if>

    <div class="bh-detail-actions">
      <c:if test="${detail.bookingStatus == 'PENDING' and detail.bookingSource == 'ONLINE'}">
        <a href="${ctx}/payment?bookingId=${detail.bookingId}" class="bh-btn bh-btn--primary">Tiếp tục thanh toán</a>
      </c:if>
      <a href="${ctx}/booking-history" class="bh-btn bh-btn--ghost">Quay lại lịch sử</a>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
