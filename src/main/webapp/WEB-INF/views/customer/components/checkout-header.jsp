<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<header class="ck-header">
  <div class="ck-header-inner">
    <a class="ck-back-btn" href="${ctx}/showtimes?movieId=<c:out value='${showtime.movieId}'/>"
       aria-label="Quay lại lịch chiếu">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none"
           stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"/>
        <polyline points="12 19 5 12 12 5"/>
      </svg>
    </a>
    <div class="ck-header-text">
      <h1 class="ck-title">Chọn ghế</h1>
      <p class="ck-subtitle">
        <c:out value="${showtime.movieTitle}"/>
        <span class="ck-subtitle-sep">·</span>
        <fmt:formatDate value="${showtime.startTime}" pattern="EEEE, dd/MM/yyyy HH:mm"/>
        <span class="ck-subtitle-sep">·</span>
        <c:out value="${showtime.roomName}"/>
      </p>
      <c:set var="ckBase" value="${showtime.basePrice}"/>
      <c:set var="ckEff" value="${showtime.effectivePrice != null ? showtime.effectivePrice : showtime.basePrice}"/>
      <c:if test="${showtime.effectivePrice != null and showtime.basePrice != null and showtime.effectivePrice ne showtime.basePrice}">
        <p class="ck-price-line">
          <span class="ck-price-badge">Giá suất</span>
          <strong><fmt:formatNumber value="${ckEff}" pattern="#,##0"/> ₫</strong>
          <span class="ck-price-original"><fmt:formatNumber value="${ckBase}" pattern="#,##0"/> ₫</span>
          <span class="ck-price-note">(đã áp quy tắc giá động)</span>
        </p>
      </c:if>
    </div>
    <c:if test="${not empty showtime.movieAgeRating and showtime.movieAgeRating != 'P'}">
      <span class="ck-age-badge ck-age-badge--<c:out value='${fn:toLowerCase(showtime.movieAgeRating)}'/>">
        <c:out value="${showtime.movieAgeRating}"/>
      </span>
    </c:if>
  </div>
</header>
