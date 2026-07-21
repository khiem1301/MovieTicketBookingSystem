<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Lịch sử đặt vé | ÉPCINE"/>
<c:set var="extraCss" value="customer-booking-history"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="bh-page">
  <div class="bh-page-inner container">
    <a href="${ctx}/home" class="bh-back">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" aria-hidden="true">
        <path d="M15 18l-6-6 6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
      </svg>
      Trang chủ
    </a>

    <header class="bh-header">
      <h1 class="bh-title">Lịch sử đặt vé</h1>
      <p class="bh-subtitle">Các đơn đã thanh toán thành công — xem lại suất chiếu và vé của bạn.</p>
    </header>

    <c:choose>
      <c:when test="${empty bookings}">
        <div class="bh-empty">
          <div class="bh-empty-icon" aria-hidden="true">🎟️</div>
          <p class="bh-empty-title">Chưa có vé nào</p>
          <p class="bh-empty-sub">Bạn chưa có đơn đã thanh toán. Hãy khám phá phim và đặt vé ngay!</p>
          <a href="${ctx}/movies" class="bh-btn bh-btn--primary">Xem phim đang chiếu</a>
        </div>
      </c:when>
      <c:otherwise>
        <p class="bh-stats"><strong><c:out value="${totalBookings}"/></strong> đơn đã thanh toán</p>

        <div class="bh-list">
          <c:forEach var="b" items="${bookings}">
            <c:set var="poster" value="${b.moviePosterUrl}"/>
            <c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
              <c:set var="poster" value="${ctx}/${poster}"/>
            </c:if>

            <article class="bh-card">
              <div class="bh-card-media">
                <c:if test="${not empty poster}">
                  <img src="<c:out value='${poster}'/>" alt="" class="bh-card-poster"/>
                </c:if>
                <c:if test="${empty poster}">
                  <div class="bh-card-poster bh-card-poster--placeholder" aria-hidden="true">🎬</div>
                </c:if>
              </div>

              <div class="bh-card-body">
                <div class="bh-card-top">
                  <span class="bh-badge bh-badge--confirmed">Đã thanh toán</span>
                  <span class="bh-card-id">ID: <c:out value="${b.bookingCode}"/></span>
                </div>

                <h2 class="bh-card-title"><c:out value="${b.movieTitle}"/></h2>

                <p class="bh-card-datetime">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                    <rect x="3" y="5" width="18" height="16" rx="2" stroke="currentColor" stroke-width="1.75"/>
                    <path d="M3 9h18M8 3v4M16 3v4" stroke="currentColor" stroke-width="1.75" stroke-linecap="round"/>
                  </svg>
                  <fmt:formatDate value="${b.startTime}" pattern="EEE, dd/MM/yyyy • HH:mm"/>
                </p>

                <div class="bh-card-facts">
                  <div class="bh-fact">
                    <span class="bh-fact-label">Phòng chiếu</span>
                    <span class="bh-fact-value"><c:out value="${b.roomName}"/></span>
                  </div>
                  <div class="bh-fact">
                    <span class="bh-fact-label">Ghế</span>
                    <span class="bh-fact-value">
                      <c:out value="${not empty b.seatCodesSummary ? b.seatCodesSummary : '—'}"/>
                      · <c:out value="${b.seatCount}"/> vé
                    </span>
                  </div>
                </div>

                <p class="bh-card-source">
                  <c:choose>
                    <c:when test="${b.online}">Đặt online</c:when>
                    <c:otherwise>Đặt tại quầy</c:otherwise>
                  </c:choose>
                  · Đặt lúc <fmt:formatDate value="${b.bookedAt}" pattern="dd/MM/yyyy HH:mm"/>
                </p>

                <div class="bh-card-footer">
                  <div class="bh-card-total">
                    <span class="bh-card-total-label">Tổng tiền</span>
                    <span class="bh-card-amount">
                      <fmt:formatNumber value="${b.finalAmount}" type="number" groupingUsed="true"/> ₫
                    </span>
                  </div>

                  <div class="bh-card-actions">
                    <a href="${ctx}/booking-history/detail?bookingId=${b.bookingId}" class="bh-btn bh-btn--primary">
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                        <path d="M4 8h16v10a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V8z" stroke="currentColor" stroke-width="1.75"/>
                        <path d="M8 8V6a4 4 0 0 1 8 0v2" stroke="currentColor" stroke-width="1.75"/>
                      </svg>
                      Xem vé
                    </a>
                  </div>
                </div>
              </div>
            </article>
          </c:forEach>
        </div>

        <%@ include file="/WEB-INF/views/common/pagination.jspf" %>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
