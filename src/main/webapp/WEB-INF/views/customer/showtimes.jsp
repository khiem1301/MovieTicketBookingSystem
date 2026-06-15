<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="${movie.title} — Lịch chiếu | ÉPCINE"/>
<c:set var="extraCss" value="customer-showtimes"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="st-page">
  <div class="movie-detail-wrapper container">
    <%-- PHẦN 1: THÔNG TIN PHIM --%>
    <jsp:include page="components/movie-info-placeholder.jsp"/>

    <%-- PHẦN 2: LỊCH CHIẾU & PHÒNG CHIẾU --%>
    <jsp:include page="components/showtimes-selector.jsp"/>

    <%-- PHẦN 3: GỢI Ý PHIM TƯƠNG TỰ --%>
    <c:if test="${not empty similarMovies}">
      <section class="sr-section">
        <h2 class="sr-heading">Có thể bạn cũng thích</h2>
        <div class="sr-grid">
          <c:forEach var="sm" items="${similarMovies}">
            <c:set var="smPoster" value="${sm.posterUrl}"/>
            <c:if test="${not empty smPoster and not fn:startsWith(smPoster,'http')}">
              <c:set var="smPoster" value="${pageContext.request.contextPath}/${smPoster}"/>
            </c:if>
            <a class="sr-card" href="${pageContext.request.contextPath}/showtimes?movieId=<c:out value='${sm.id}'/>">
              <div class="sr-poster-wrap">
                <c:choose>
                  <c:when test="${not empty smPoster}">
                    <img class="sr-poster" src="<c:out value='${smPoster}'/>" alt="<c:out value='${sm.title}'/>" loading="lazy"/>
                  </c:when>
                  <c:otherwise>
                    <div class="sr-poster sr-poster--blank">
                      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                        <rect x="3" y="3" width="18" height="18" rx="2"/>
                        <circle cx="8.5" cy="8.5" r="1.5"/>
                        <polyline points="21 15 16 10 5 21"/>
                      </svg>
                    </div>
                  </c:otherwise>
                </c:choose>
                <c:choose>
                  <c:when test="${sm.status == 'NOW_SHOWING'}">
                    <span class="sr-badge sr-badge--now">Đang chiếu</span>
                  </c:when>
                  <c:when test="${sm.status == 'EARLY_SHOWING'}">
                    <span class="sr-badge sr-badge--early">Suất sớm</span>
                  </c:when>
                  <c:otherwise>
                    <span class="sr-badge sr-badge--soon">Sắp chiếu</span>
                  </c:otherwise>
                </c:choose>
              </div>
              <div class="sr-info">
                <p class="sr-title"><c:out value="${sm.title}"/></p>
                <c:if test="${not empty sm.genres}">
                  <p class="sr-genres">
                    <c:forEach var="g" items="${sm.genres}" varStatus="gs">
                      <c:if test="${!gs.first}">, </c:if><c:out value="${g}"/>
                    </c:forEach>
                  </p>
                </c:if>
                <c:if test="${sm.averageRating != null and sm.averageRating > 0}">
                  <p class="sr-rating">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="#ffd740" stroke="none">
                      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                    </svg>
                    ${sm.averageRating}
                  </p>
                </c:if>
              </div>
            </a>
          </c:forEach>
        </div>
      </section>
    </c:if>
  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
