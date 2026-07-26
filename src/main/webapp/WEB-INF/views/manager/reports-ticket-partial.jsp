<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%-- Fragment AJAX: bảng thống kê vé + phân trang (partial=tickets) --%>
<c:choose>
  <c:when test="${filterViewBy == 'showtime'}">
    <c:choose>
      <c:when test="${not empty showtimeStats}">
        <div class="admin-table-wrap">
          <table class="admin-table admin-table--ticket-showtime">
            <thead>
              <tr>
                <th>#</th>
                <th>Phim</th>
                <th>Phòng</th>
                <th>Giờ chiếu</th>
                <th>Trạng thái</th>
                <th>Số vé</th>
                <th>Số đơn</th>
                <th>Doanh thu</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="row" items="${showtimeStats}" varStatus="st">
                <tr>
                  <td><c:out value="${rankStart + st.index}"/></td>
                  <td><strong><c:out value="${row.movieTitle}"/></strong></td>
                  <td><c:out value="${row.roomName}"/></td>
                  <td>
                    <fmt:formatDate value="${row.startTime}" pattern="dd/MM/yyyy HH:mm"/>
                  </td>
                  <td>
                    <span class="admin-badge admin-badge--showtime">
                      <c:out value="${row.showtimeStatus}"/>
                    </span>
                  </td>
                  <td><c:out value="${row.ticketCount}"/></td>
                  <td><c:out value="${row.bookingCount}"/></td>
                  <td>
                    <fmt:formatNumber value="${row.revenue}" type="number" groupingUsed="true" maxFractionDigits="0"/>đ
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <c:set var="pgCurrent" value="${currentPage}"/>
        <c:set var="pgTotal" value="${totalPages}"/>
        <c:set var="pgTotalItems" value="${ticketStatsTotal}"/>
        <%@ include file="/WEB-INF/views/admin/pagination.jspf" %>
      </c:when>
      <c:otherwise>
        <p class="admin-empty">Chưa có vé bán theo suất chiếu trong khoảng thời gian này.</p>
      </c:otherwise>
    </c:choose>
  </c:when>
  <c:otherwise>
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
        <c:set var="pgTotalItems" value="${ticketStatsTotal}"/>
        <%@ include file="/WEB-INF/views/admin/pagination.jspf" %>
      </c:when>
      <c:otherwise>
        <p class="admin-empty">Chưa có vé bán theo phim trong khoảng thời gian này.</p>
      </c:otherwise>
    </c:choose>
  </c:otherwise>
</c:choose>
