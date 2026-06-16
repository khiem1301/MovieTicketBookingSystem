<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Báo cáo &amp; thống kê — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <nav class="admin-breadcrumb">
      <a href="${pageContext.request.contextPath}/admin/dashboard">Bảng điều khiển</a>
      <span class="admin-breadcrumb-sep">/</span>
      <span>Báo cáo &amp; thống kê</span>
    </nav>

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Báo cáo &amp; thống kê</h1>
        <p class="admin-page-subtitle">
          Tổng quan doanh thu, số vé bán và phim được đặt nhiều nhất
          — <c:out value="${rangeLabel}"/>
        </p>
      </div>
    </div>

    <c:if test="${not empty dateRangeWarning}">
      <div class="admin-alert admin-alert--error" role="alert">
        <c:out value="${dateRangeWarning}"/>
      </div>
    </c:if>
    <c:if test="${not empty flashSuccess}">
      <div class="admin-alert admin-alert--success" role="status">
        <c:out value="${flashSuccess}"/>
      </div>
    </c:if>
    <c:if test="${not empty flashError}">
      <div class="admin-alert admin-alert--error" role="alert">
        <c:out value="${flashError}"/>
      </div>
    </c:if>

    <div class="admin-card" style="margin-bottom:24px;">
      <form class="admin-filter" method="get" action="${pageContext.request.contextPath}/admin/reports">
        <div class="admin-field">
          <label class="admin-label" for="range">Khoảng thời gian</label>
          <select id="range" name="range" class="admin-select">
            <option value="7d"     <c:if test="${filterRange == '7d'}">selected</c:if>>7 ngày gần nhất</option>
            <option value="30d"    <c:if test="${filterRange == '30d'}">selected</c:if>>30 ngày gần nhất</option>
            <option value="month"  <c:if test="${filterRange == 'month'}">selected</c:if>>Tháng hiện tại</option>
            <option value="all"    <c:if test="${filterRange == 'all'}">selected</c:if>>Toàn bộ</option>
          </select>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="from">Từ ngày</label>
          <input type="date" id="from" name="from" class="admin-input"
                 value="<c:out value='${filterFrom}'/>"/>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="to">Đến ngày</label>
          <input type="date" id="to" name="to" class="admin-input"
                 value="<c:out value='${filterTo}'/>"/>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="groupBy">Nhóm theo</label>
          <select id="groupBy" name="groupBy" class="admin-select">
            <option value="day"   <c:if test="${filterGroupBy == 'day'}">selected</c:if>>Ngày</option>
            <option value="month" <c:if test="${filterGroupBy == 'month'}">selected</c:if>>Tháng</option>
            <option value="year"  <c:if test="${filterGroupBy == 'year'}">selected</c:if>>Năm</option>
          </select>
        </div>
        <button type="submit" class="admin-btn admin-btn--primary">Áp dụng</button>
        <a href="${pageContext.request.contextPath}/admin/reports" class="admin-btn admin-btn--ghost">Xóa lọc</a>
        <a href="${pageContext.request.contextPath}/admin/reports/export?${exportQuery}"
           class="admin-btn admin-btn--ghost admin-btn--export">
          Xuất CSV
        </a>
      </form>
      <p class="admin-stats" style="margin-top:12px;margin-bottom:0;">
        Chỉ tính đơn đã thanh toán (<strong>CONFIRMED</strong> + <strong>PAID</strong>).
        Nhập từ/đến ngày để lọc tùy chọn; để trống cả hai sẽ dùng preset bên trái.
      </p>
    </div>

    <div class="admin-stats-grid admin-stats-grid--3">
      <div class="admin-stat-card">
        <span class="admin-stat-value admin-stat-value--money">
          <fmt:formatNumber value="${overview.revenue}" type="number" groupingUsed="true" maxFractionDigits="0"/>đ
        </span>
        <span class="admin-stat-label">Doanh thu</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${overview.ticketCount}"/></span>
        <span class="admin-stat-label">Vé đã bán</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${overview.bookingCount}"/></span>
        <span class="admin-stat-label">Đơn đã thanh toán</span>
      </div>
    </div>

    <div class="admin-card" style="margin-top:24px;">
      <h2 class="admin-section-title">Doanh thu theo kỳ</h2>
      <p class="admin-stats">
        Chi tiết nhóm theo <strong><c:out value="${periodColumnLabel}"/></strong>
        — <c:out value="${rangeLabel}"/>.
        Bấm <strong>Xuất CSV</strong> để tải file.
      </p>
      <c:choose>
        <c:when test="${not empty periodStats}">
          <div class="admin-table-wrap">
            <table class="admin-table admin-table--revenue-period">
              <thead>
                <tr>
                  <th><c:out value="${periodColumnLabel}"/></th>
                  <th>Doanh thu</th>
                  <th>Số đơn</th>
                  <th>Số vé</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="row" items="${periodStats}">
                  <tr>
                    <td><strong><c:out value="${row.periodLabel}"/></strong></td>
                    <td>
                      <fmt:formatNumber value="${row.revenue}" type="number" groupingUsed="true" maxFractionDigits="0"/>đ
                    </td>
                    <td><c:out value="${row.bookingCount}"/></td>
                    <td><c:out value="${row.ticketCount}"/></td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:when>
        <c:otherwise>
          <p class="admin-empty">Chưa có doanh thu trong khoảng thời gian này.</p>
        </c:otherwise>
      </c:choose>
    </div>

    <div class="admin-card" style="margin-top:24px;">
      <h2 class="admin-section-title">Top phim được đặt nhiều</h2>
      <p class="admin-stats">
        Xếp hạng theo số vé bán trong khoảng thời gian đã chọn
        <c:if test="${not empty topMoviesTotal}">
          — <strong><c:out value="${topMoviesTotal}"/></strong> phim
        </c:if>
      </p>

      <c:choose>
        <c:when test="${not empty topMovies}">
          <div class="admin-table-wrap">
            <table class="admin-table admin-table--top-movies">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Phim</th>
                  <th>Số vé</th>
                  <th>Số đơn</th>
                  <th>Doanh thu</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="movie" items="${topMovies}" varStatus="st">
                  <tr>
                    <td><c:out value="${rankStart + st.index}"/></td>
                    <td><strong><c:out value="${movie.title}"/></strong></td>
                    <td><c:out value="${movie.ticketCount}"/></td>
                    <td><c:out value="${movie.bookingCount}"/></td>
                    <td>
                      <fmt:formatNumber value="${movie.revenue}" type="number" groupingUsed="true" maxFractionDigits="0"/>đ
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
          <c:set var="pgCurrent" value="${currentPage}"/>
          <c:set var="pgTotal" value="${totalPages}"/>
          <c:set var="pgTotalItems" value="${topMoviesTotal}"/>
          <%@ include file="/WEB-INF/views/admin/pagination.jspf" %>
        </c:when>
        <c:otherwise>
          <p class="admin-empty">Chưa có đơn đã thanh toán trong khoảng thời gian này.</p>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
