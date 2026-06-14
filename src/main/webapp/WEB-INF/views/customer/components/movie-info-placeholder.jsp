<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<%--
  ══════════════════════════════════════════════════════════════════
  PHẦN TRÊN — THÔNG TIN CHI TIẾT PHIM
  File này dành cho đồng nghiệp phát triển (trailer, cast, mô tả đầy đủ…).
  Servlet đã nạp sẵn: request attribute "movie" (model.entity.Movie).
  Ví dụ: ${movie.title}, ${movie.description}, ${movie.director}, ${movie.genres}
  ══════════════════════════════════════════════════════════════════
--%>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<c:set var="posterSrc" value="${movie.posterUrl}"/>
<c:if test="${not empty posterSrc and not fn:startsWith(posterSrc, 'http')}">
  <c:set var="posterSrc" value="${ctx}/${posterSrc}"/>
</c:if>

<c:set var="backdropSrc" value="${not empty movie.backdropUrl ? movie.backdropUrl : movie.posterUrl}"/>
<c:if test="${not empty backdropSrc and not fn:startsWith(backdropSrc, 'http')}">
  <c:set var="backdropSrc" value="${ctx}/${backdropSrc}"/>
</c:if>

<section class="mi-section" id="movie-info-section">
  <%-- Banner backdrop (đồng nghiệp có thể thêm nút Play trailer tại đây) --%>
  <div class="mi-banner">
    <c:if test="${not empty backdropSrc}">
      <img class="mi-banner-img" src="<c:out value='${backdropSrc}'/>" alt=""/>
    </c:if>
    <div class="mi-banner-overlay"></div>
  </div>

  <div class="mi-body">
    <div class="mi-grid">
      <%-- Poster --%>
      <div class="mi-poster-col">
        <div class="mi-poster-wrap">
          <c:choose>
            <c:when test="${not empty posterSrc}">
              <img class="mi-poster" src="<c:out value='${posterSrc}'/>"
                   alt="<c:out value='${movie.title}'/>"/>
            </c:when>
            <c:otherwise>
              <div class="mi-poster mi-poster--empty">No Poster</div>
            </c:otherwise>
          </c:choose>
          <c:if test="${movie.averageRating != null and movie.averageRating > 0}">
            <div class="mi-rating-badge">
              <span class="mi-rating-star">★</span>
              <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1" minFractionDigits="1"/>
            </div>
          </c:if>
        </div>
      </div>

      <%-- Thông tin cơ bản --%>
      <div class="mi-info-col">
        <h1 class="mi-title"><c:out value="${movie.title}"/></h1>

        <div class="mi-meta">
          <c:if test="${not empty movie.ageRating}">
            <span class="mi-meta-badge"><c:out value="${movie.ageRating}"/></span>
          </c:if>
          <c:if test="${movie.durationMinutes > 0}">
            <span class="mi-meta-item">
              <span class="mi-meta-icon">⏱</span>
              ${movie.durationMinutes div 60}h
              <fmt:formatNumber value="${movie.durationMinutes mod 60}" minIntegerDigits="2" maxFractionDigits="0"/>m
            </span>
          </c:if>
          <c:if test="${not empty movie.releaseDate}">
            <span class="mi-meta-item">
              <span class="mi-meta-icon">📅</span>
              <fmt:formatDate value="${movie.releaseDate}" pattern="dd/MM/yyyy"/>
            </span>
          </c:if>
          <c:if test="${not empty movie.genres}">
            <span class="mi-meta-item">
              <span class="mi-meta-icon">🎬</span>
              <c:forEach var="genre" items="${movie.genres}" varStatus="gs">
                <c:out value="${genre}"/><c:if test="${not gs.last}"> / </c:if>
              </c:forEach>
            </span>
          </c:if>
        </div>

        <c:if test="${not empty movie.director}">
          <p class="mi-director">
            <strong>Đạo diễn:</strong> <c:out value="${movie.director}"/>
          </p>
        </c:if>

        <c:choose>
          <c:when test="${not empty movie.description}">
            <p class="mi-description"><c:out value="${movie.description}"/></p>
          </c:when>
          <c:otherwise>
            <p class="mi-description mi-description--placeholder">
              Đồng nghiệp có thể bổ sung mô tả chi tiết, trailer và danh sách diễn viên tại file này.
            </p>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </div>
</section>
