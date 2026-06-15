<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Thanh toán thành công | ÉPCINE"/>
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
    <h1 class="pay-success-title">Thanh toán thành công!</h1>
    <p class="pay-success-sub">Mã đơn <strong><c:out value="${detail.bookingCode}"/></strong> đã được xác nhận.</p>

    <div class="pay-success-movie">
      <c:if test="${not empty poster}">
        <img src="<c:out value='${poster}'/>" alt="" class="pay-success-poster"/>
      </c:if>
      <div>
        <h2><c:out value="${detail.movieTitle}"/></h2>
        <p><fmt:formatDate value="${detail.startTime}" pattern="EEE, dd/MM/yyyy • HH:mm"/> — <c:out value="${detail.roomName}"/></p>
        <p>Ghế:
          <c:forEach var="seat" items="${detail.seats}" varStatus="st">
            <c:out value="${seat.seatCode}"/><c:if test="${not st.last}">, </c:if>
          </c:forEach>
        </p>
        <p class="pay-success-amount">
          <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
        </p>
      </div>
    </div>

    <p class="pay-success-note">Vé điện tử đã được phát hành. Email xác nhận sẽ có trong phiên bản tiếp theo (FR-19).</p>

    <div class="pay-success-actions">
      <a href="${ctx}/home" class="pay-momo-pay-btn">Về trang chủ</a>
      <a href="${ctx}/movies" class="pay-back-link">Xem thêm phim</a>
    </div>
  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
