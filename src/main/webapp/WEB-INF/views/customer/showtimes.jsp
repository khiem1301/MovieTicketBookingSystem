<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="pageTitle" value="${movie.title} — Lịch chiếu | ÉPCINE"/>
<c:set var="extraCss" value="customer-showtimes"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="st-page">
  <div class="movie-detail-wrapper container">
    <%-- PHẦN 1: THÔNG TIN PHIM (Đồng nghiệp phát triển — chỉ sửa movie-info-placeholder.jsp) --%>
    <jsp:include page="components/movie-info-placeholder.jsp"/>

    <%-- PHẦN 2: LỊCH CHIẾU & PHÒNG CHIẾU (FR-11 — độc lập, không chỉnh khi đồng nghiệp làm phần trên) --%>
    <jsp:include page="components/showtimes-selector.jsp"/>
  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
