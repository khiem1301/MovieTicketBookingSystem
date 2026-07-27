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
      <span class="bh-badge bh-badge--confirmed">Đã thanh toán</span>
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
            <dt>Giảm giá<c:if test="${not empty detail.appliedPromoCode}"> (<c:out value="${detail.appliedPromoCode}"/>)</c:if></dt>
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
      <section class="bh-detail-section bh-detail-section--eticket">
        <h2 class="bh-detail-section-title">Vé điện tử</h2>
        <article class="bh-eticket">
          <div class="bh-eticket-qr-col">
            <c:if test="${not empty eticketQrImageUrl}">
              <div class="bh-eticket-qr-frame">
                <img src="<c:out value='${eticketQrImageUrl}'/>"
                     alt="QR đơn vé"
                     class="bh-eticket-qr"
                     width="160" height="160"/>
              </div>
            </c:if>
            <p class="bh-eticket-qr-caption">Quét để mở toàn bộ vé</p>
          </div>
          <div class="bh-eticket-divider" aria-hidden="true"></div>
          <div class="bh-eticket-body">
            <p class="bh-eticket-brand">ÉPCINE PREMIUM</p>
            <p class="bh-eticket-label">Mã đơn</p>
            <p class="bh-eticket-code"><c:out value="${detail.bookingCode}"/></p>
            <p class="bh-eticket-label">Ghế</p>
            <div class="bh-eticket-seats">
              <c:forEach var="ticket" items="${detail.tickets}">
                <span class="bh-eticket-seat-chip" title="<c:out value='${ticket.ticketCode}'/>">
                  <c:out value="${ticket.seatCode}"/>
                </span>
              </c:forEach>
            </div>
            <c:if test="${not empty eticketViewUrl}">
              <a href="<c:out value='${eticketViewUrl}'/>"
                 class="bh-btn bh-btn--primary bh-eticket-cta"
                 target="_blank" rel="noopener">
                Mở vé điện tử
              </a>
            </c:if>
          </div>
        </article>
      </section>
    </c:if>
  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
