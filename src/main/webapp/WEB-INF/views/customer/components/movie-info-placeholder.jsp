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
        <div class="mi-poster-wrap${not empty movie.trailerUrl ? ' mi-poster-wrap--playable' : ''}"
             data-trailer="<c:out value='${movie.trailerUrl}'/>"
             data-title="<c:out value='${movie.title}'/>"
             onclick="openTrailer(this)">
          <c:choose>
            <c:when test="${not empty posterSrc}">
              <img class="mi-poster" src="<c:out value='${posterSrc}'/>"
                   alt="<c:out value='${movie.title}'/>"/>
            </c:when>
            <c:otherwise>
              <div class="mi-poster mi-poster--empty">No Poster</div>
            </c:otherwise>
          </c:choose>
          <c:if test="${not empty movie.trailerUrl}">
            <div class="play-overlay">
              <div class="play-circle">
                <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
              </div>
            </div>
          </c:if>
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

<%-- ══════════════════════════════════════════════════
     ĐÁNH GIÁ PHIM (FR-20)
     ══════════════════════════════════════════════════ --%>
<section class="mi-reviews-section" id="movie-reviews-section">
  <div class="mi-reviews-header">
    <h2 class="mi-reviews-title">Đánh giá từ khán giả</h2>
    <div class="mi-reviews-summary">
      <span class="mi-reviews-avg">
        <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1" minFractionDigits="1"/>
      </span>
      <span class="mi-reviews-count">(${movieReviewCount} đánh giá)</span>
    </div>
  </div>

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
        <div class="mi-review-stars" id="miReviewStars">
          <c:forEach begin="1" end="5" var="s">
            <span class="mi-star" data-value="${s}">★</span>
          </c:forEach>
        </div>
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
    <c:when test="${sessionScope.userRole == 'CUSTOMER' and not canReview}">
      <p class="mi-review-login-hint">
        Bạn cần mua vé và xem suất chiếu của phim này thì mới có thể đánh giá.
      </p>
    </c:when>
  </c:choose>

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
</section>

<div id="trailerModal" class="trailer-modal">
  <div class="trailer-backdrop" onclick="closeTrailer()"></div>
  <div class="trailer-wrapper">
    <div class="trailer-header">
      <span id="trailerTitle" class="trailer-movie-title"></span>
      <button class="trailer-close" onclick="closeTrailer()" aria-label="Đóng">&#x2715;</button>
    </div>
    <div class="trailer-video-wrap">
      <iframe id="trailerIframe" src="" frameborder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowfullscreen></iframe>
    </div>
  </div>
</div>

<script>
function openTrailer(el) {
  var url   = el.getAttribute('data-trailer') || '';
  var title = el.getAttribute('data-title')   || '';
  if (!url.trim()) return;
  var embedUrl = url;
  var yt = url.match(/(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)/);
  if (yt) embedUrl = 'https://www.youtube.com/embed/' + yt[1] + '?autoplay=1&rel=0';
  document.getElementById('trailerTitle').textContent = title;
  document.getElementById('trailerIframe').src = embedUrl;
  document.getElementById('trailerModal').classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeTrailer() {
  document.getElementById('trailerIframe').src = '';
  document.getElementById('trailerModal').classList.remove('open');
  document.body.style.overflow = '';
}
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeTrailer(); });
</script>
