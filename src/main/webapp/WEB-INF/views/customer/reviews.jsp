<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Đánh giá phim — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<style>
.rv-page { padding: 40px 0 80px; }
.rv-header { text-align: center; margin-bottom: 32px; }
.rv-title { font-size: 32px; font-weight: 700; margin-bottom: 10px; }
.rv-sub { color: var(--text-muted); font-size: 15px; }

.rv-subnav {
  display: flex;
  justify-content: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 40px;
}
.rv-subnav-link {
  padding: 9px 18px;
  border-radius: 999px;
  border: 1px solid var(--border);
  font-size: 13px;
  font-weight: 600;
  color: var(--text-muted);
  transition: var(--transition);
  white-space: nowrap;
}
.rv-subnav-link:hover { color: var(--text); background: rgba(255,255,255,0.05); }
.rv-subnav-link.is-active { background: var(--accent); border-color: var(--accent); color: #fff; }

.rv-movie-rating-badge {
  position: absolute;
  top: 10px;
  left: 10px;
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border-radius: 6px;
  background: rgba(0,0,0,0.65);
  font-size: 12px;
  font-weight: 700;
  color: #ffd740;
}
.rv-movie-review-count {
  font-size: 11px;
  color: var(--text-dim);
  margin-top: 2px;
}

.rv-list { display: flex; flex-direction: column; gap: 16px; max-width: 820px; margin: 0 auto; }
.rv-item {
  display: flex;
  gap: 14px;
  padding: 18px 20px;
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 12px;
}
.rv-item-poster {
  width: 110px;
  height: 165px;
  border-radius: 8px;
  object-fit: cover;
  flex-shrink: 0;
  background: #1e1e1e;
}

.rv-pending-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 16px;
}
.rv-pending-grid .card-info { padding: 10px 10px 6px; }
.rv-pending-grid .card-title { font-size: 13px; }

.rv-mine-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 32px;
  align-items: start;
}
.rv-mine-col .rv-list { max-width: none; margin: 0; }
@media (max-width: 900px) {
  .rv-mine-layout { grid-template-columns: 1fr; }
}
.rv-item-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
  flex-shrink: 0;
  background: #1e1e1e;
}
.rv-item-avatar--placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  border: 1px solid var(--border);
}
.rv-item-body { flex: 1; min-width: 0; }
.rv-item-header {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 4px;
}
.rv-item-movie { font-weight: 700; font-size: 14px; }
.rv-item-movie:hover { color: var(--accent); }
.rv-item-user { font-weight: 600; font-size: 13px; color: var(--text-muted); }
.rv-item-stars { font-size: 12px; color: rgba(255,255,255,.18); }
.rv-item-stars .is-filled { color: #ffd740; }
.rv-item-date { font-size: 11px; color: var(--text-dim); margin-left: auto; }
.rv-item-content { font-size: 13px; color: var(--text-muted); line-height: 1.6; }
.rv-item-delete {
  padding: 5px 12px;
  background: transparent;
  border: 1px solid rgba(229,57,53,.3);
  border-radius: 6px;
  color: #ff8a80;
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background .2s;
}
.rv-item-delete:hover { background: rgba(229,57,53,.15); }

.rv-empty {
  text-align: center;
  color: var(--text-muted);
  padding: 60px 0;
  font-size: 15px;
}

.rv-section-heading {
  font-size: 18px;
  font-weight: 700;
  margin-bottom: 18px;
}
</style>

<c:if test="${not empty dbError}">
  <div style="background:#b71c1c;color:#fff;padding:10px 20px;font-size:13px;font-family:monospace;position:fixed;bottom:0;left:0;right:0;z-index:9999;word-break:break-all;">
    <strong>DB ERROR:</strong> <c:out value="${dbError}"/>
  </div>
</c:if>

<section class="rv-page">
  <div class="container">

    <div class="rv-header">
      <h1 class="rv-title">
        <c:choose>
          <c:when test="${isMine}">Đánh giá của tôi</c:when>
          <c:when test="${sort == 'latest'}">Đánh giá mới nhất</c:when>
          <c:when test="${sort == 'popular'}">Phim được yêu thích</c:when>
          <c:otherwise>Phim đánh giá cao nhất</c:otherwise>
        </c:choose>
      </h1>
      <p class="rv-sub">
        <c:choose>
          <c:when test="${isMine}">Những bộ phim bạn đã chấm sao và nhận xét</c:when>
          <c:when test="${sort == 'latest'}">Những nhận xét mới nhất từ khán giả ÉPCINE</c:when>
          <c:when test="${sort == 'popular'}">Phim có nhiều lượt đánh giá nhất</c:when>
          <c:otherwise>Xếp hạng theo điểm trung bình từ khán giả</c:otherwise>
        </c:choose>
      </p>
    </div>

    <div class="rv-subnav">
      <a class="rv-subnav-link ${!isMine and sort == 'top' ? 'is-active' : ''}"
         href="${ctx}/reviews?sort=top">⭐ Đánh giá cao nhất</a>
      <a class="rv-subnav-link ${!isMine and sort == 'latest' ? 'is-active' : ''}"
         href="${ctx}/reviews?sort=latest">🕐 Mới nhất</a>
      <a class="rv-subnav-link ${!isMine and sort == 'popular' ? 'is-active' : ''}"
         href="${ctx}/reviews?sort=popular">🔥 Được yêu thích</a>
      <c:if test="${not empty sessionScope.loggedUser}">
        <a class="rv-subnav-link ${isMine ? 'is-active' : ''}"
           href="${ctx}/reviews/mine">📝 Đánh giá của tôi</a>
      </c:if>
    </div>

    <%-- /reviews/mine: 2 cột — phim có thể đánh giá (trái) / đánh giá của bạn (phải) --%>
    <c:if test="${isMine}">
      <div class="rv-mine-layout">
        <div class="rv-mine-col">
          <h2 class="rv-section-heading">Phim bạn có thể đánh giá</h2>
          <c:choose>
            <c:when test="${not empty pendingMovies}">
              <div class="rv-pending-grid">
                <c:forEach var="movie" items="${pendingMovies}">
                  <c:set var="cardPoster" value="${movie.posterUrl}"/>
                  <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
                    <c:set var="cardPoster" value="${ctx}/${cardPoster}"/>
                  </c:if>
                  <div class="movie-card">
                    <div class="card-poster">
                      <c:choose>
                        <c:when test="${not empty movie.posterUrl}">
                          <img src="<c:out value='${cardPoster}'/>" alt="<c:out value='${movie.title}'/>"/>
                        </c:when>
                        <c:otherwise>
                          <div class="poster-placeholder">🎬</div>
                        </c:otherwise>
                      </c:choose>
                      <div class="card-overlay">
                        <a href="${ctx}/showtimes?movieId=${movie.id}#movie-reviews-section" class="btn-book">Đánh giá ngay</a>
                      </div>
                    </div>
                    <div class="card-info">
                      <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                    </div>
                  </div>
                </c:forEach>
              </div>
            </c:when>
            <c:otherwise>
              <p class="rv-empty">Bạn đã đánh giá hết các phim đã xem.</p>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="rv-mine-col">
    </c:if>

    <%-- Chế độ danh sách phim: top / popular --%>
    <c:if test="${not isMine and (sort == 'top' or sort == 'popular')}">
      <c:choose>
        <c:when test="${not empty movies}">
          <div class="movies-grid" style="display:grid;">
            <c:forEach var="movie" items="${movies}">
              <c:set var="cardPoster" value="${movie.posterUrl}"/>
              <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
                <c:set var="cardPoster" value="${ctx}/${cardPoster}"/>
              </c:if>
              <div class="movie-card">
                <div class="card-poster">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img src="<c:out value='${cardPoster}'/>" alt="<c:out value='${movie.title}'/>"/>
                    </c:when>
                    <c:otherwise>
                      <div class="poster-placeholder">🎬</div>
                    </c:otherwise>
                  </c:choose>
                  <div class="card-overlay">
                    <a href="${ctx}/showtimes?movieId=${movie.id}" class="btn-book">Xem chi tiết</a>
                  </div>
                  <div class="rv-movie-rating-badge">
                    <span>★</span>
                    <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1"/>
                  </div>
                </div>
                <div class="card-info">
                  <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                  <div class="card-genres">
                    <c:forEach var="genre" items="${movie.genres}" end="1">
                      <span class="genre-tag"><c:out value="${genre}"/></span>
                    </c:forEach>
                  </div>
                  <div class="rv-movie-review-count">${movie.reviewCount} đánh giá</div>
                </div>
              </div>
            </c:forEach>
          </div>
        </c:when>
        <c:otherwise>
          <p class="rv-empty">Chưa có phim nào được đánh giá.</p>
        </c:otherwise>
      </c:choose>
    </c:if>

    <%-- Chế độ danh sách review: latest / mine --%>
    <c:if test="${isMine or sort == 'latest'}">
      <c:if test="${isMine}">
        <h2 class="rv-section-heading">Đánh giá của bạn</h2>
      </c:if>
      <c:choose>
        <c:when test="${not empty reviews}">
          <div class="rv-list">
            <c:forEach var="rv" items="${reviews}">
              <c:set var="rvPoster" value="${rv.moviePosterUrl}"/>
              <c:if test="${not empty rvPoster and not fn:startsWith(rvPoster, 'http')}">
                <c:set var="rvPoster" value="${ctx}/${rvPoster}"/>
              </c:if>
              <c:set var="rvAvatar" value="${rv.userAvatarUrl}"/>
              <c:if test="${not empty rvAvatar and not fn:startsWith(rvAvatar, 'http')}">
                <c:set var="rvAvatar" value="${ctx}/${rvAvatar}"/>
              </c:if>
              <div class="rv-item">
                <c:choose>
                  <c:when test="${not empty rvPoster}">
                    <img class="rv-item-poster" src="<c:out value='${rvPoster}'/>" alt=""/>
                  </c:when>
                  <c:otherwise>
                    <div class="rv-item-poster"></div>
                  </c:otherwise>
                </c:choose>
                <c:if test="${!isMine}">
                  <c:choose>
                    <c:when test="${not empty rvAvatar}">
                      <img class="rv-item-avatar" src="<c:out value='${rvAvatar}'/>" alt=""/>
                    </c:when>
                    <c:otherwise>
                      <div class="rv-item-avatar rv-item-avatar--placeholder">👤</div>
                    </c:otherwise>
                  </c:choose>
                </c:if>
                <div class="rv-item-body">
                  <div class="rv-item-header">
                    <a class="rv-item-movie" href="${ctx}/showtimes?movieId=${rv.movieId}">
                      <c:out value="${rv.movieTitle}"/>
                    </a>
                    <c:if test="${!isMine}">
                      <span class="rv-item-user">— <c:out value="${rv.userFullName}"/></span>
                    </c:if>
                    <span class="rv-item-stars">
                      <c:forEach begin="1" end="5" var="s">
                        <span class="${s <= rv.rating ? 'is-filled' : ''}">★</span>
                      </c:forEach>
                    </span>
                    <span class="rv-item-date"><fmt:formatDate value="${rv.createdAt}" pattern="dd/MM/yyyy"/></span>
                  </div>
                  <c:if test="${not empty rv.reviewContent}">
                    <p class="rv-item-content"><c:out value="${rv.reviewContent}"/></p>
                  </c:if>
                  <c:if test="${isMine}">
                    <form method="post" action="${ctx}/reviews/delete"
                          onsubmit="return confirm('Xóa đánh giá này?');" style="margin-top:8px;">
                      <input type="hidden" name="reviewId" value="<c:out value='${rv.id}'/>"/>
                      <input type="hidden" name="redirectTo" value="/reviews/mine"/>
                      <button type="submit" class="rv-item-delete">🗑 Xóa đánh giá</button>
                    </form>
                  </c:if>
                </div>
              </div>
            </c:forEach>
          </div>
        </c:when>
        <c:otherwise>
          <p class="rv-empty">
            <c:choose>
              <c:when test="${isMine}">Bạn chưa đánh giá bộ phim nào. Hãy xem phim và chia sẻ cảm nhận nhé!</c:when>
              <c:otherwise>Chưa có đánh giá nào.</c:otherwise>
            </c:choose>
          </p>
        </c:otherwise>
      </c:choose>
    </c:if>

    <c:if test="${isMine}">
        </div>
      </div>
    </c:if>

    <%-- Phân trang --%>
    <c:if test="${totalPages > 1}">
      <c:choose>
        <c:when test="${isMine}">
          <c:set var="pgBase" value="${ctx}/reviews/mine?page="/>
        </c:when>
        <c:otherwise>
          <c:set var="pgBase" value="${ctx}/reviews?sort=${sort}&page="/>
        </c:otherwise>
      </c:choose>
      <div class="movies-pagination">
        <c:if test="${page > 1}">
          <a class="movies-page-btn" href="${pgBase}${page - 1}">‹</a>
        </c:if>
        <c:forEach begin="1" end="${totalPages}" var="pg">
          <a class="movies-page-btn ${pg == page ? 'is-active' : ''}" href="${pgBase}${pg}">${pg}</a>
        </c:forEach>
        <c:if test="${page < totalPages}">
          <a class="movies-page-btn" href="${pgBase}${page + 1}">›</a>
        </c:if>
      </div>
    </c:if>

  </div>
</section>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
