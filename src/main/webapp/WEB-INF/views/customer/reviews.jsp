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
  gap: 28px;
  margin-bottom: 40px;
  border-bottom: 1px solid var(--border);
}
.rv-subnav-link {
  padding: 12px 2px;
  font-size: 13px;
  font-weight: 600;
  color: var(--text-muted);
  border-bottom: 2px solid transparent;
  transition: var(--transition);
  white-space: nowrap;
}
.rv-subnav-link:hover { color: var(--text); }
.rv-subnav-link.is-active { color: var(--accent); border-bottom-color: var(--accent); }

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

.rv-pending-list { display: flex; flex-direction: column; gap: 16px; }
.rv-pending-card {
  padding: 16px;
  background: var(--bg-card);
  border: 1px solid rgba(229,57,53,.25);
  border-radius: 12px;
}
.rv-pending-tags {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 12px;
}
.rv-pending-eligible {
  padding: 3px 9px;
  border-radius: 999px;
  background: rgba(229,57,53,.15);
  color: #ff8a80;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .03em;
  white-space: nowrap;
}
.rv-pending-genre {
  padding: 3px 9px;
  border-radius: 999px;
  background: rgba(255,255,255,.08);
  color: var(--text-muted);
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: .03em;
  white-space: nowrap;
}
.rv-pending-row { display: flex; gap: 14px; margin-bottom: 14px; }
.rv-pending-poster {
  width: 72px;
  height: 104px;
  border-radius: 8px;
  object-fit: cover;
  flex-shrink: 0;
  background: #1e1e1e;
}
.rv-pending-poster--placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  border: 1px solid var(--border);
}
.rv-pending-title { font-size: 15px; font-weight: 700; align-self: center; }
.rv-pending-cta {
  display: block;
  text-align: center;
  padding: 10px;
  border-radius: 8px;
  background: var(--accent);
  color: #fff;
  font-size: 13px;
  font-weight: 700;
  transition: background .2s;
}
.rv-pending-cta:hover { background: var(--accent-hover); }

.rv-count-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 22px;
  height: 22px;
  padding: 0 6px;
  border-radius: 999px;
  background: rgba(229,57,53,.15);
  color: var(--accent);
  font-size: 12px;
  font-weight: 700;
  vertical-align: middle;
}

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

.rv-item--mine { position: relative; align-items: flex-start; }
.rv-item-poster--mine { width: 48px; height: 48px; border-radius: 8px; }
.rv-item--mine .rv-item-header { justify-content: space-between; flex-wrap: nowrap; margin-bottom: 6px; }
.rv-item--mine .rv-item-movie { font-size: 15px; }
.rv-item-stars--row { display: block; font-size: 14px; margin-bottom: 8px; }
.rv-item-delete-form { flex-shrink: 0; }
.rv-item-delete-icon {
  width: 26px;
  height: 26px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: 1px solid rgba(229,57,53,.3);
  border-radius: 6px;
  color: #ff8a80;
  font-size: 12px;
  cursor: pointer;
  transition: background .2s;
}
.rv-item-delete-icon:hover { background: rgba(229,57,53,.15); }
.rv-item-timestamp {
  font-size: 11px;
  color: var(--text-dim);
  text-transform: uppercase;
  letter-spacing: .02em;
  margin-top: 8px;
}

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
          <c:when test="${isMine}">Quản lý đánh giá phim của bạn và chia sẻ trải nghiệm với những bộ phim bạn đã xem.</c:when>
          <c:when test="${sort == 'latest'}">Những nhận xét mới nhất từ khán giả ÉPCINE</c:when>
          <c:when test="${sort == 'popular'}">Phim có nhiều lượt đánh giá nhất</c:when>
          <c:otherwise>Xếp hạng theo điểm trung bình từ khán giả</c:otherwise>
        </c:choose>
      </p>
    </div>

    <div class="rv-subnav">
      <a class="rv-subnav-link ${!isMine and sort == 'top' ? 'is-active' : ''}"
         href="${ctx}/reviews?sort=top">Đánh giá cao nhất</a>
      <a class="rv-subnav-link ${!isMine and sort == 'latest' ? 'is-active' : ''}"
         href="${ctx}/reviews?sort=latest">Mới nhất</a>
      <a class="rv-subnav-link ${!isMine and sort == 'popular' ? 'is-active' : ''}"
         href="${ctx}/reviews?sort=popular">Yêu thích nhất</a>
      <c:if test="${not empty sessionScope.loggedUser}">
        <a class="rv-subnav-link ${isMine ? 'is-active' : ''}"
           href="${ctx}/reviews/mine">Đánh giá của tôi</a>
      </c:if>
    </div>

    <%-- /reviews/mine: 2 cột — phim có thể đánh giá (trái) / đánh giá của bạn (phải) --%>
    <c:if test="${isMine}">
      <div class="rv-mine-layout">
        <div class="rv-mine-col">
          <h2 class="rv-section-heading">Phim bạn có thể đánh giá <span class="rv-count-badge">${fn:length(pendingMovies)}</span></h2>
          <c:choose>
            <c:when test="${not empty pendingMovies}">
              <div class="rv-pending-list">
                <c:forEach var="movie" items="${pendingMovies}">
                  <c:set var="cardPoster" value="${movie.posterUrl}"/>
                  <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
                    <c:set var="cardPoster" value="${ctx}/${cardPoster}"/>
                  </c:if>
                  <div class="rv-pending-card">
                    <div class="rv-pending-tags">
                      <span class="rv-pending-eligible">Đã đủ điều kiện</span>
                      <c:if test="${not empty movie.genres}">
                        <span class="rv-pending-genre"><c:out value="${movie.genres[0]}"/></span>
                      </c:if>
                    </div>
                    <div class="rv-pending-row">
                      <c:choose>
                        <c:when test="${not empty movie.posterUrl}">
                          <img class="rv-pending-poster" src="<c:out value='${cardPoster}'/>" alt="<c:out value='${movie.title}'/>"/>
                        </c:when>
                        <c:otherwise>
                          <div class="rv-pending-poster rv-pending-poster--placeholder">🎬</div>
                        </c:otherwise>
                      </c:choose>
                      <h3 class="rv-pending-title"><c:out value="${movie.title}"/></h3>
                    </div>
                    <a href="${ctx}/showtimes?movieId=${movie.id}#movie-reviews-section" class="rv-pending-cta">✍ Viết đánh giá</a>
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
        <h2 class="rv-section-heading">Đánh giá của bạn <span class="rv-count-badge">${total}</span></h2>
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
              <c:choose>
                <c:when test="${isMine}">
                  <div class="rv-item rv-item--mine">
                    <c:choose>
                      <c:when test="${not empty rvPoster}">
                        <img class="rv-item-poster rv-item-poster--mine" src="<c:out value='${rvPoster}'/>" alt=""/>
                      </c:when>
                      <c:otherwise>
                        <div class="rv-item-poster rv-item-poster--mine"></div>
                      </c:otherwise>
                    </c:choose>
                    <div class="rv-item-body">
                      <div class="rv-item-header">
                        <a class="rv-item-movie" href="${ctx}/showtimes?movieId=${rv.movieId}">
                          <c:out value="${rv.movieTitle}"/>
                        </a>
                        <form method="post" action="${ctx}/reviews/delete"
                              onsubmit="return confirm('Xóa đánh giá này?');" class="rv-item-delete-form">
                          <input type="hidden" name="reviewId" value="<c:out value='${rv.id}'/>"/>
                          <input type="hidden" name="redirectTo" value="/reviews/mine"/>
                          <button type="submit" class="rv-item-delete-icon" aria-label="Xóa đánh giá">🗑</button>
                        </form>
                      </div>
                      <span class="rv-item-stars rv-item-stars--row">
                        <c:forEach begin="1" end="5" var="s">
                          <span class="${s <= rv.rating ? 'is-filled' : ''}">★</span>
                        </c:forEach>
                      </span>
                      <c:if test="${not empty rv.reviewContent}">
                        <p class="rv-item-content"><c:out value="${rv.reviewContent}"/></p>
                      </c:if>
                      <div class="rv-item-timestamp">
                        Đã đánh giá lúc <fmt:formatDate value="${rv.createdAt}" pattern="HH:mm"/>
                        ngày <fmt:formatDate value="${rv.createdAt}" pattern="dd/MM/yyyy"/>
                      </div>
                    </div>
                  </div>
                </c:when>
                <c:otherwise>
                  <div class="rv-item">
                    <c:choose>
                      <c:when test="${not empty rvPoster}">
                        <img class="rv-item-poster" src="<c:out value='${rvPoster}'/>" alt=""/>
                      </c:when>
                      <c:otherwise>
                        <div class="rv-item-poster"></div>
                      </c:otherwise>
                    </c:choose>
                    <c:choose>
                      <c:when test="${not empty rvAvatar}">
                        <img class="rv-item-avatar" src="<c:out value='${rvAvatar}'/>" alt=""/>
                      </c:when>
                      <c:otherwise>
                        <div class="rv-item-avatar rv-item-avatar--placeholder">👤</div>
                      </c:otherwise>
                    </c:choose>
                    <div class="rv-item-body">
                      <div class="rv-item-header">
                        <a class="rv-item-movie" href="${ctx}/showtimes?movieId=${rv.movieId}">
                          <c:out value="${rv.movieTitle}"/>
                        </a>
                        <span class="rv-item-user">— <c:out value="${rv.userFullName}"/></span>
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
                    </div>
                  </div>
                </c:otherwise>
              </c:choose>
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
