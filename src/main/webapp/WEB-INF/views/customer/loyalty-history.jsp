<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"  %>

<c:set var="pageTitle" value="Lịch sử điểm tích luỹ | ÉPCINE"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<style>
.lh-page { max-width: 860px; margin: 40px auto; padding: 0 16px 60px; }
.lh-heading { font-size: 1.5rem; font-weight: 700; margin-bottom: 24px; }
.lh-table-wrap { overflow-x: auto; }
.lh-table { width: 100%; border-collapse: collapse; font-size: .9rem; }
.lh-table th { text-align: left; padding: 10px 14px; border-bottom: 2px solid rgba(255,255,255,.12); opacity: .6; }
.lh-table td { padding: 12px 14px; border-bottom: 1px solid rgba(255,255,255,.07); vertical-align: middle; }
.lh-badge { display: inline-block; padding: 2px 10px; border-radius: 20px; font-size: .78rem; font-weight: 600; }
.lh-badge--earn   { background: rgba(52,211,153,.15); color: #34d399; }
.lh-badge--redeem { background: rgba(251,146,60,.15);  color: #fb923c; }
.lh-badge--refund { background: rgba(96,165,250,.15);  color: #60a5fa; }
.lh-pts-earn   { color: #34d399; font-weight: 700; }
.lh-pts-redeem { color: #fb923c; font-weight: 700; }
.lh-empty { text-align: center; padding: 60px 0; opacity: .5; }
.lh-pagination { display: flex; gap: 8px; justify-content: center; margin-top: 28px; flex-wrap: wrap; }
.lh-pagination a, .lh-pagination span {
  padding: 6px 14px; border-radius: 8px; font-size: .875rem;
  border: 1px solid rgba(255,255,255,.15); text-decoration: none;
}
.lh-pagination .active { background: #e11d48; border-color: #e11d48; color: #fff; }
.lh-pagination a:hover { background: rgba(255,255,255,.08); }
.lh-balance-card {
  display: flex; align-items: center; gap: 20px;
  background: linear-gradient(135deg, #be123c 0%, #e11d48 100%);
  border-radius: 16px; padding: 24px 28px; margin-bottom: 28px;
}
.lh-balance-icon { font-size: 2.4rem; line-height: 1; }
.lh-balance-label { font-size: .85rem; opacity: .85; margin-bottom: 4px; }
.lh-balance-value { font-size: 2rem; font-weight: 800; letter-spacing: -.5px; }
.lh-balance-unit { font-size: .9rem; font-weight: 400; margin-left: 4px; opacity: .8; }
@media (prefers-color-scheme: light) {
  .lh-table th { border-bottom-color: rgba(0,0,0,.12); }
  .lh-table td { border-bottom-color: rgba(0,0,0,.07); }
  .lh-pagination a, .lh-pagination span { border-color: rgba(0,0,0,.2); }
}
</style>

<div class="lh-page">
  <h1 class="lh-heading">Lịch sử điểm tích luỹ</h1>

  <div class="lh-balance-card">
    <div class="lh-balance-icon">🏅</div>
    <div>
      <div class="lh-balance-label">Tổng điểm tích luỹ hiện tại</div>
      <div class="lh-balance-value">
        <c:choose>
          <c:when test="${loyaltyPoints != null}">
            <fmt:formatNumber value="${loyaltyPoints}" type="number" groupingUsed="true"/>
          </c:when>
          <c:otherwise>0</c:otherwise>
        </c:choose>
        <span class="lh-balance-unit">điểm</span>
      </div>
    </div>
  </div>

  <c:choose>
    <c:when test="${empty items}">
      <div class="lh-empty">
        <p>Bạn chưa có giao dịch điểm nào.</p>
        <a href="${ctx}/movies">Đặt vé ngay →</a>
      </div>
    </c:when>
    <c:otherwise>
      <div class="lh-table-wrap">
        <table class="lh-table">
          <thead>
            <tr>
              <th>Thời gian</th>
              <th>Mã đơn</th>
              <th>Loại</th>
              <th>Ghi chú</th>
              <th style="text-align:right">Điểm</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="item" items="${items}">
              <tr>
                <td><fmt:formatDate value="${item.createdAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                <td>
                  <c:choose>
                    <c:when test="${not empty item.bookingCode}">
                      <a href="${ctx}/booking-detail?bookingId=${item.bookingId}">
                        <c:out value="${item.bookingCode}"/>
                      </a>
                    </c:when>
                    <c:otherwise>—</c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${item.earn}">
                      <span class="lh-badge lh-badge--earn">Tích điểm</span>
                    </c:when>
                    <c:when test="${item.redeem}">
                      <span class="lh-badge lh-badge--redeem">Đổi điểm</span>
                    </c:when>
                    <c:otherwise>
                      <span class="lh-badge lh-badge--refund">Hoàn điểm</span>
                    </c:otherwise>
                  </c:choose>
                </td>
                <td><c:out value="${item.note}"/></td>
                <td style="text-align:right">
                  <c:choose>
                    <c:when test="${item.pointsDelta >= 0}">
                      <span class="lh-pts-earn">+<fmt:formatNumber value="${item.pointsDelta}" type="number" groupingUsed="true"/></span>
                    </c:when>
                    <c:otherwise>
                      <span class="lh-pts-redeem"><fmt:formatNumber value="${item.pointsDelta}" type="number" groupingUsed="true"/></span>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>

      <c:if test="${totalPages > 1}">
        <nav class="lh-pagination" aria-label="Phân trang">
          <c:if test="${currentPage > 1}">
            <a href="${ctx}/customer/loyalty-history?page=${currentPage - 1}">‹</a>
          </c:if>
          <c:forEach begin="1" end="${totalPages}" var="p">
            <c:choose>
              <c:when test="${p == currentPage}"><span class="active">${p}</span></c:when>
              <c:otherwise><a href="${ctx}/customer/loyalty-history?page=${p}">${p}</a></c:otherwise>
            </c:choose>
          </c:forEach>
          <c:if test="${currentPage < totalPages}">
            <a href="${ctx}/customer/loyalty-history?page=${currentPage + 1}">›</a>
          </c:if>
        </nav>
      </c:if>
    </c:otherwise>
  </c:choose>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
