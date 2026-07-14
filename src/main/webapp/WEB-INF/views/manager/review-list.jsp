<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý đánh giá — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<style>
.mrv-poster {
  width: 40px;
  height: 58px;
  border-radius: 6px;
  object-fit: cover;
  flex-shrink: 0;
  background: #1e1e1e;
}
.mrv-movie-cell { display: flex; align-items: center; gap: 10px; }
.mrv-stars { font-size: 13px; color: rgba(255,255,255,.18); white-space: nowrap; }
.mrv-stars .is-filled { color: #ffd740; }
.mrv-content {
  max-width: 360px;
  font-size: 13px;
  color: var(--text-muted);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.mrv-content--empty { color: var(--text-dim); font-style: italic; }

.mrv-modal-backdrop {
  display: none;
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,.6);
  z-index: 1000;
  align-items: center;
  justify-content: center;
}
.mrv-modal-backdrop.open { display: flex; }
.mrv-modal {
  width: 100%;
  max-width: 440px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 24px;
}
.mrv-modal h2 { font-size: 18px; font-weight: 700; margin-bottom: 6px; }
.mrv-modal-movie { font-size: 13px; color: var(--text-muted); margin-bottom: 16px; }
.mrv-modal-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 16px; }
</style>

<main class="admin-page">
  <div class="container">

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Quản lý đánh giá</h1>
        <p class="admin-page-subtitle">Duyệt và xóa đánh giá vi phạm của khách hàng</p>
      </div>
    </div>

    <c:if test="${param.success == 'deleted'}">
      <div class="admin-alert admin-alert--success" role="status">Đã xóa đánh giá và gửi thông báo cho khách hàng (nếu có email).</div>
    </c:if>
    <c:if test="${param.error == 'reason-required'}">
      <div class="admin-alert admin-alert--error" role="alert">Vui lòng nhập lý do trước khi xóa đánh giá.</div>
    </c:if>

    <div class="admin-card">
      <form class="admin-filter" method="get" action="${pageContext.request.contextPath}/manager/reviews">
        <div class="admin-field admin-field--grow">
          <label class="admin-label" for="q">Tìm kiếm</label>
          <input type="text" id="q" name="q" class="admin-input"
                 placeholder="Tên phim..."
                 value="<c:out value='${filterQ}'/>"/>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="rating">Số sao</label>
          <select id="rating" name="rating" class="admin-select">
            <option value="">Tất cả</option>
            <c:forEach begin="1" end="5" var="s">
              <option value="${s}" <c:if test="${filterRating == s}">selected</c:if>>${s} sao</option>
            </c:forEach>
          </select>
        </div>
        <button type="submit" class="admin-btn admin-btn--ghost">Lọc</button>
        <a href="${pageContext.request.contextPath}/manager/reviews" class="admin-btn admin-btn--ghost">Xóa lọc</a>
      </form>

      <p class="admin-stats">Tổng: <strong><c:out value="${totalReviews}"/></strong> đánh giá</p>

      <c:choose>
        <c:when test="${not empty reviews}">
          <div class="admin-table-wrap">
            <table class="admin-table">
              <thead>
                <tr>
                  <th>Phim</th>
                  <th>Người đánh giá</th>
                  <th>Số sao</th>
                  <th>Nội dung</th>
                  <th>Ngày</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="r" items="${reviews}">
                  <c:set var="rvPoster" value="${r.moviePosterUrl}"/>
                  <c:if test="${not empty rvPoster and not fn:startsWith(rvPoster, 'http')}">
                    <c:set var="rvPoster" value="${pageContext.request.contextPath}/${rvPoster}"/>
                  </c:if>
                  <tr>
                    <td>
                      <div class="mrv-movie-cell">
                        <c:choose>
                          <c:when test="${not empty rvPoster}">
                            <img class="mrv-poster" src="<c:out value='${rvPoster}'/>" alt=""/>
                          </c:when>
                          <c:otherwise>
                            <div class="mrv-poster"></div>
                          </c:otherwise>
                        </c:choose>
                        <c:out value="${r.movieTitle}"/>
                      </div>
                    </td>
                    <td class="cell-muted"><c:out value="${r.userFullName}"/></td>
                    <td>
                      <span class="mrv-stars">
                        <c:forEach begin="1" end="5" var="s">
                          <span class="${s <= r.rating ? 'is-filled' : ''}">★</span>
                        </c:forEach>
                      </span>
                    </td>
                    <td>
                      <c:choose>
                        <c:when test="${not empty r.reviewContent}">
                          <p class="mrv-content"><c:out value="${r.reviewContent}"/></p>
                        </c:when>
                        <c:otherwise>
                          <span class="mrv-content mrv-content--empty">Không có nhận xét</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="cell-muted"><fmt:formatDate value="${r.createdAt}" pattern="dd/MM/yyyy HH:mm"/></td>
                    <td>
                      <button type="button" class="admin-btn admin-btn--danger admin-btn--sm mrv-delete-btn"
                              data-review-id="<c:out value='${r.id}'/>"
                              data-movie-title="<c:out value='${r.movieTitle}'/>">
                        Xóa
                      </button>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>

          <%@ include file="/WEB-INF/views/admin/pagination.jspf" %>
        </c:when>
        <c:otherwise>
          <div class="admin-empty">Không tìm thấy đánh giá nào.</div>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</main>

<%-- ── Modal xóa đánh giá: bắt buộc nhập lý do, hệ thống sẽ gửi email báo cho khách hàng ── --%>
<div class="mrv-modal-backdrop" id="mrvDeleteModal">
  <div class="mrv-modal">
    <h2>Xóa đánh giá</h2>
    <p class="mrv-modal-movie">Phim: <strong id="mrvDeleteMovieTitle"></strong></p>
    <form method="post" action="${pageContext.request.contextPath}/manager/reviews">
      <input type="hidden" name="id" id="mrvDeleteReviewId"/>
      <input type="hidden" name="page" value="<c:out value='${pgCurrent}'/>"/>
      <input type="hidden" name="q" value="<c:out value='${filterQ}'/>"/>
      <input type="hidden" name="rating" value="<c:out value='${filterRating}'/>"/>

      <label class="admin-label" for="mrvDeleteReason">Lý do xóa <span class="required">*</span></label>
      <p class="admin-field-hint">Bắt buộc — lý do sẽ được gửi qua email cho khách hàng đã đánh giá.</p>
      <textarea id="mrvDeleteReason" name="reason" class="admin-input admin-textarea" rows="4"
                maxlength="500" required
                placeholder="VD: Nội dung đánh giá chứa ngôn từ xúc phạm / spam quảng cáo..."></textarea>

      <div class="mrv-modal-actions">
        <button type="button" class="admin-btn admin-btn--ghost" onclick="closeDeleteModal()">Hủy</button>
        <button type="submit" class="admin-btn admin-btn--danger">Xóa và gửi thông báo</button>
      </div>
    </form>
  </div>
</div>

<script>
  function openDeleteModal(reviewId, movieTitle) {
    document.getElementById('mrvDeleteReviewId').value = reviewId;
    document.getElementById('mrvDeleteMovieTitle').textContent = movieTitle;
    document.getElementById('mrvDeleteReason').value = '';
    document.getElementById('mrvDeleteModal').classList.add('open');
  }
  function closeDeleteModal() {
    document.getElementById('mrvDeleteModal').classList.remove('open');
  }
  document.querySelectorAll('.mrv-delete-btn').forEach(function (btn) {
    btn.addEventListener('click', function () {
      openDeleteModal(btn.dataset.reviewId, btn.dataset.movieTitle);
    });
  });
  document.getElementById('mrvDeleteModal').addEventListener('click', function (e) {
    if (e.target === this) closeDeleteModal();
  });
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
