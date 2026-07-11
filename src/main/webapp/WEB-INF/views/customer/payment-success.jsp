<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Đặt vé thành công | ÉPCINE"/>
<c:set var="extraCss" value="customer-checkout"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="poster" value="${detail.moviePosterUrl}"/>
<c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
  <c:set var="poster" value="${ctx}/${poster}"/>
</c:if>

<div class="pay-page pay-page--success container">
  <div class="pay-success-card">
    <div class="pay-success-icon" aria-hidden="true">✓</div>
    <h1 class="pay-success-title">Đặt vé thành công!</h1>
    <p class="pay-success-sub">
      Mã đơn <strong><c:out value="${detail.bookingCode}"/></strong> đã được thanh toán và xác nhận.
    </p>

    <div class="pay-success-movie">
      <c:if test="${not empty poster}">
        <img src="<c:out value='${poster}'/>" alt="" class="pay-success-poster"/>
      </c:if>
      <div>
        <h2><c:out value="${detail.movieTitle}"/></h2>
        <p>
          <fmt:formatDate value="${detail.startTime}" pattern="EEE, dd/MM/yyyy • HH:mm"/>
          — <c:out value="${detail.roomName}"/>
        </p>
        <p class="pay-success-amount">
          <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
        </p>
      </div>
    </div>

    <div class="pay-success-tickets">
      <h3 class="pay-success-tickets-title">Thông tin vé</h3>
      <c:choose>
        <c:when test="${not empty detail.tickets}">
          <ul class="pay-success-ticket-list">
            <c:forEach var="t" items="${detail.tickets}">
              <li class="pay-success-ticket-item">
                <span class="pay-success-ticket-seat">Ghế <c:out value="${t.seatCode}"/></span>
                <span class="pay-success-ticket-code"><c:out value="${t.ticketCode}"/></span>
              </li>
            </c:forEach>
          </ul>
        </c:when>
        <c:otherwise>
          <p class="pay-success-ticket-fallback">
            Ghế:
            <c:forEach var="seat" items="${detail.seats}" varStatus="st">
              <c:out value="${seat.seatCode}"/><c:if test="${not st.last}">, </c:if>
            </c:forEach>
          </p>
        </c:otherwise>
      </c:choose>
    </div>

    <p class="pay-success-note">
      Email xác nhận (kèm mã vé) đã được gửi tới hộp thư đăng ký của bạn nếu SMTP đã cấu hình.
      Vui lòng xuất trình mã vé khi vào rạp.
    </p>

    <div class="pay-success-actions">
      <a href="${ctx}/home" class="pay-momo-pay-btn">Về trang chủ</a>
      <a href="${ctx}/booking-history" class="pay-back-link">Xem lịch sử đặt vé</a>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
