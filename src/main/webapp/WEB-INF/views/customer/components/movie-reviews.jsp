<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<%-- ĐÁNH GIÁ PHIM (FR-20) — bố cục 2 cột: danh sách bên trái, form đánh giá bên phải --%>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<section class="mi-reviews-section" id="movie-reviews-section">
  <div class="mi-reviews-columns">
    <div class="mi-reviews-list-col">
      <div class="mi-reviews-header">
        <h2 class="mi-reviews-title">Đánh giá từ khán giả</h2>
        <div class="mi-reviews-summary">
          <span class="mi-reviews-avg">
            <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1" minFractionDigits="1"/>
          </span>
          <span class="mi-reviews-count">(${movieReviewCount} đánh giá)</span>
        </div>
      </div>

      <div class="mi-review-list">
        <c:choose>
          <c:when test="${not empty movieReviews}">
            <c:forEach var="rv" items="${movieReviews}">
              <c:set var="rvAvatar" value="${rv.userAvatarUrl}"/>
              <c:if test="${not empty rvAvatar and not fn:startsWith(rvAvatar, 'http')}">
                <c:set var="rvAvatar" value="${ctx}/${rvAvatar}"/>
              </c:if>
              <div class="mi-review-item">
                <c:choose>
                  <c:when test="${not empty rvAvatar}">
                    <img class="mi-review-avatar" src="<c:out value='${rvAvatar}'/>" alt=""/>
                  </c:when>
                  <c:otherwise>
                    <div class="mi-review-avatar mi-review-avatar--placeholder">👤</div>
                  </c:otherwise>
                </c:choose>
                <div class="mi-review-body">
                  <div class="mi-review-item-header">
                    <span class="mi-review-user"><c:out value="${rv.userFullName}"/></span>
                    <span class="mi-review-stars-display">
                      <c:forEach begin="1" end="5" var="s">
                        <span class="${s <= rv.rating ? 'is-filled' : ''}">★</span>
                      </c:forEach>
                    </span>
                    <span class="mi-review-date"><fmt:formatDate value="${rv.createdAt}" pattern="dd/MM/yyyy"/></span>
                  </div>
                  <c:if test="${not empty rv.reviewContent}">
                    <p class="mi-review-content"><c:out value="${rv.reviewContent}"/></p>
                  </c:if>
                </div>
              </div>
            </c:forEach>
          </c:when>
          <c:otherwise>
            <p class="mi-review-empty">Chưa có đánh giá nào cho phim này. Hãy là người đầu tiên!</p>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

    <aside class="mi-reviews-form-col">
      <div class="mi-reviews-form-card">
        <h3 class="mi-reviews-form-title">Đánh giá của bạn</h3>

        <c:if test="${sessionScope.userRole == 'CUSTOMER' and not canReview}">
          <p class="mi-reviews-form-hint">
            <span class="mi-reviews-form-hint-icon">ⓘ</span>
            Chỉ khách hàng đã mua vé và xem suất chiếu của phim này mới có thể đánh giá.
          </p>
        </c:if>

        <c:if test="${not empty param.reviewError}">
          <div class="mi-review-alert mi-review-alert--error">
            Không thể gửi đánh giá. Vui lòng chọn số sao và thử lại.
          </div>
        </c:if>
        <c:if test="${not empty param.reviewSuccess}">
          <div class="mi-review-alert mi-review-alert--success">Cảm ơn bạn đã đánh giá phim!</div>
        </c:if>

        <c:choose>
          <c:when test="${sessionScope.userRole == 'CUSTOMER' and canReview}">
            <form class="mi-review-form" method="post" action="${ctx}/reviews/submit">
              <input type="hidden" name="movieId" value="<c:out value='${movie.id}'/>"/>
              <input type="hidden" name="rating" id="miReviewRatingInput" value="<c:out value='${myReview.rating}'/>"/>
              <label class="mi-review-form-label">Xếp hạng</label>
              <div class="mi-review-stars" id="miReviewStars">
                <c:forEach begin="1" end="5" var="s">
                  <span class="mi-star" data-value="${s}">★</span>
                </c:forEach>
              </div>
              <label class="mi-review-form-label">Nhận xét</label>
              <textarea name="content" class="mi-review-textarea" maxlength="2000"
                        placeholder="Chia sẻ cảm nhận của bạn về bộ phim..."><c:out value="${myReview.reviewContent}"/></textarea>
              <div style="display:flex;gap:10px;">
                <button type="submit" class="mi-review-submit">
                  <c:choose>
                    <c:when test="${not empty myReview}">Cập nhật đánh giá</c:when>
                    <c:otherwise>Gửi đánh giá</c:otherwise>
                  </c:choose>
                </button>
              </div>
            </form>
            <c:if test="${not empty myReview}">
              <form method="post" action="${ctx}/reviews/delete"
                    onsubmit="return confirm('Xóa đánh giá này?');" style="margin-top:8px;">
                <input type="hidden" name="reviewId" value="<c:out value='${myReview.id}'/>"/>
                <input type="hidden" name="redirectTo" value="/showtimes?movieId=${movie.id}#movie-reviews-section"/>
                <button type="submit" class="mi-review-delete">Xóa đánh giá</button>
              </form>
            </c:if>
            <script>
              (function () {
                var stars = document.querySelectorAll('#miReviewStars .mi-star');
                var input = document.getElementById('miReviewRatingInput');
                function paint(value) {
                  stars.forEach(function (star) {
                    star.classList.toggle('is-filled', Number(star.dataset.value) <= value);
                  });
                }
                stars.forEach(function (star) {
                  star.addEventListener('click', function () {
                    input.value = star.dataset.value;
                    paint(Number(star.dataset.value));
                  });
                });
                paint(Number(input.value) || 0);
              })();
            </script>
          </c:when>
          <c:when test="${empty sessionScope.loggedUser}">
            <p class="mi-review-login-hint">
              <a href="${ctx}/login">Đăng nhập</a> để chia sẻ đánh giá của bạn về bộ phim này.
            </p>
          </c:when>
        </c:choose>
      </div>
    </aside>
  </div>
</section>
