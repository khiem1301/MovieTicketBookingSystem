<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Lịch sử đặt vé quầy — ÉpCine"/>
<c:set var="extraCss"  value="staff"/>
<c:set var="extraCss2" value="counter-pos"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<script>document.body.classList.add('pos-body');</script>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<div class="pos-container" style="max-width:1200px">

  <%-- Thông báo lỗi --%>
  <c:if test="${not empty errorMessage}">
    <div class="pos-alert pos-alert--error"><c:out value="${errorMessage}"/></div>
  </c:if>

  <%-- ── Filter form ─────────────────────────────────────────────── --%>
  <form method="get" action="${ctx}/staff/history" class="hist-filter-form">
    <div class="hist-filter-row">

      <div class="hist-filter-group">
        <label class="hist-filter-label">Từ ngày</label>
        <input type="date" name="dateFrom" class="hist-filter-input"
               value="<c:out value='${dateFrom}'/>"/>
      </div>

      <div class="hist-filter-group">
        <label class="hist-filter-label">Đến ngày</label>
        <input type="date" name="dateTo" class="hist-filter-input"
               value="<c:out value='${dateTo}'/>"/>
      </div>

      <div class="hist-filter-group">
        <label class="hist-filter-label">Trạng thái</label>
        <select name="status" class="hist-filter-input">
          <option value="">Tất cả</option>
          <option value="CONFIRMED" ${status == 'CONFIRMED' ? 'selected' : ''}>Đã xác nhận</option>
          <option value="CANCELLED" ${status == 'CANCELLED' ? 'selected' : ''}>Đã hủy</option>
        </select>
      </div>

      <div class="hist-filter-group hist-filter-group--search">
        <label class="hist-filter-label">Tìm kiếm</label>
        <input type="text" name="search" class="hist-filter-input"
               placeholder="Tên, SĐT hoặc mã đơn..."
               value="<c:out value='${search}'/>"/>
      </div>

      <div class="hist-filter-actions">
        <button type="submit" class="hist-btn hist-btn--primary">Lọc</button>
        <a href="${ctx}/staff/history" class="hist-btn hist-btn--ghost">Xóa lọc</a>
      </div>

    </div>

    <%-- Quick date filters --%>
    <div class="hist-quick-filters">
      <span class="hist-quick-label">Nhanh:</span>
      <a href="${ctx}/staff/history?dateFrom=${todayStr}&dateTo=${todayStr}" class="hist-quick-btn">Hôm nay</a>
      <a href="${ctx}/staff/history?dateFrom=${weekStart}&dateTo=${weekEnd}" class="hist-quick-btn">Tuần này</a>
      <a href="${ctx}/staff/history?dateFrom=${monthStart}&dateTo=${monthEnd}" class="hist-quick-btn">Tháng này</a>
    </div>
  </form>

  <%-- ── Stats summary ───────────────────────────────────────────── --%>
  <div class="hist-stats-bar">
    <span>Tổng: <strong>${totalCount}</strong> đơn</span>
    <c:if test="${not empty search or not empty status or not empty dateFrom or not empty dateTo}">
      <span class="hist-filter-active">Đang lọc</span>
    </c:if>
  </div>

  <%-- ── Booking table ────────────────────────────────────────────── --%>
  <div class="hist-table-wrap">
    <c:choose>
      <c:when test="${empty bookings}">
        <div class="hist-empty">
          <div class="hist-empty-icon">📋</div>
          <div>Không có đơn đặt vé nào phù hợp.</div>
        </div>
      </c:when>
      <c:otherwise>
        <table class="hist-table">
          <thead>
            <tr>
              <th>Mã đơn</th>
              <th>Thời gian đặt</th>
              <th>Khách hàng</th>
              <th>Phim / Suất</th>
              <th>Phòng</th>
              <th class="text-center">Ghế</th>
              <th class="text-right">Tổng tiền</th>
              <th class="text-center">Trạng thái</th>
              <th>Nhân viên</th>
              <th class="text-center">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="b" items="${bookings}">
              <tr>
                <td>
                  <span class="hist-code"><c:out value="${b.bookingCode}"/></span>
                </td>
                <td>
                  <fmt:formatDate value="${b.bookedAt}" pattern="dd/MM/yyyy"/>
                  <div class="hist-sub"><fmt:formatDate value="${b.bookedAt}" pattern="HH:mm"/></div>
                </td>
                <td>
                  <div><c:out value="${not empty b.customerName ? b.customerName : '—'}"/></div>
                  <c:if test="${not empty b.customerPhone and b.customerPhone != ''}">
                    <div class="hist-sub"><c:out value="${b.customerPhone}"/></div>
                  </c:if>
                  <c:if test="${not empty b.userId}">
                    <span class="hist-member-badge">&#9733; TV</span>
                  </c:if>
                </td>
                <td>
                  <div class="hist-movie"><c:out value="${b.movieTitle}"/></div>
                  <div class="hist-sub">
                    <fmt:formatDate value="${b.startTime}" pattern="dd/MM HH:mm"/>
                  </div>
                </td>
                <td><c:out value="${b.roomName}"/></td>
                <td class="text-center">${b.seatCount}</td>
                <td class="text-right hist-amount">
                  <fmt:formatNumber value="${b.finalAmount}" type="number" groupingUsed="true"/> ₫
                </td>
                <td class="text-center">
                  <span class="hist-badge hist-badge--${fn:toLowerCase(b.bookingStatus)}">
                    <c:choose>
                      <c:when test="${b.bookingStatus == 'CONFIRMED'}">Đã xác nhận</c:when>
                      <c:when test="${b.bookingStatus == 'CANCELLED'}">Đã hủy</c:when>
                      <c:otherwise><c:out value="${b.bookingStatus}"/></c:otherwise>
                    </c:choose>
                  </span>
                  <c:if test="${b.paymentStatus == 'PAID'}">
                    <div class="hist-sub">Đã thanh toán</div>
                  </c:if>
                </td>
                <td>
                  <c:out value="${not empty b.staffName ? b.staffName : '—'}"/>
                </td>
                <td class="text-center">
                  <a href="${ctx}/staff/history?bookingId=${b.bookingId}"
                     class="hist-btn hist-btn--sm">Xem</a>
                  <c:if test="${b.bookingStatus == 'CONFIRMED' and b.paymentStatus == 'PAID'}">
                    <a href="${ctx}/staff/counter?step=print&bookingId=${b.bookingId}"
                       class="hist-btn hist-btn--sm hist-btn--print">In vé</a>
                  </c:if>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </c:otherwise>
    </c:choose>
  </div>

  <%-- ── Pagination ────────────────────────────────────────────────── --%>
  <c:if test="${totalPages > 1}">
    <div class="hist-pagination">
      <c:if test="${page > 1}">
        <a href="${ctx}/staff/history?page=${page-1}&dateFrom=${dateFrom}&dateTo=${dateTo}&status=${status}&search=${search}"
           class="hist-page-btn">&#8249; Trước</a>
      </c:if>

      <c:forEach begin="1" end="${totalPages}" var="p">
        <c:choose>
          <c:when test="${p == page}">
            <span class="hist-page-btn hist-page-btn--active">${p}</span>
          </c:when>
          <c:when test="${p == 1 or p == totalPages or (p >= page-2 and p <= page+2)}">
            <a href="${ctx}/staff/history?page=${p}&dateFrom=${dateFrom}&dateTo=${dateTo}&status=${status}&search=${search}"
               class="hist-page-btn">${p}</a>
          </c:when>
          <c:when test="${p == page-3 or p == page+3}">
            <span class="hist-page-ellipsis">…</span>
          </c:when>
        </c:choose>
      </c:forEach>

      <c:if test="${page < totalPages}">
        <a href="${ctx}/staff/history?page=${page+1}&dateFrom=${dateFrom}&dateTo=${dateTo}&status=${status}&search=${search}"
           class="hist-page-btn">Sau &#8250;</a>
      </c:if>
    </div>
  </c:if>

</div><%-- /pos-container --%>

<script>
(function () {
  var searchInput = document.querySelector('input[name="search"]');
  var tbody = document.querySelector('.hist-table tbody');
  if (!searchInput || !tbody) return;

  searchInput.addEventListener('input', function () {
    var q = this.value.toLowerCase().trim();
    tbody.querySelectorAll('tr').forEach(function (row) {
      var codeCell = row.cells[0]; // mã đơn
      var custCell = row.cells[2]; // khách hàng
      var text = (codeCell ? codeCell.textContent.toLowerCase() : '') +
                 ' ' +
                 (custCell ? custCell.textContent.toLowerCase() : '');
      row.style.display = (q === '' || text.includes(q)) ? '' : 'none';
    });
  });
}());
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
