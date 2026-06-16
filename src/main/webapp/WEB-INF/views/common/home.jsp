<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="ÉPCINE — Đặt vé xem phim"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:if test="${param.logout == 'success'}">
  <div class="container" style="padding-top:16px;" id="logout-success-banner">
    <div style="padding:11px 14px;border-radius:8px;background:rgba(76,175,80,0.1);border:1px solid rgba(76,175,80,0.35);color:#a5d6a7;font-size:14px;">
      Đăng xuất thành công.
    </div>
  </div>
  <script>
    (function () {
      var banner = document.getElementById('logout-success-banner');
      if (!banner) return;
      setTimeout(function () {
        banner.style.transition = 'opacity 0.4s ease';
        banner.style.opacity = '0';
        setTimeout(function () {
          banner.remove();
          if (window.history.replaceState) {
            window.history.replaceState(null, '', '${pageContext.request.contextPath}/home');
          }
        }, 400);
      }, 4000);
    })();
  </script>
</c:if>

<%-- DEBUG BANNER: chỉ hiện khi DB lỗi — xóa sau khi fix xong --%>
<c:if test="${not empty dbError}">
  <div style="background:#b71c1c;color:#fff;padding:10px 20px;font-size:13px;font-family:monospace;position:fixed;bottom:0;left:0;right:0;z-index:9999;word-break:break-all;">
    <strong>DB ERROR:</strong> <c:out value="${dbError}"/>
  </div>
</c:if>

<!-- ══════════════════════════════════════════════════
     HERO SLIDER
     ══════════════════════════════════════════════════ -->
<section class="hero">

  <%-- Nền full màn: backdrop_url (ảnh ngang), fallback poster_url --%>
  <div class="hero-bg">
    <c:if test="${not empty featuredMovies}">
      <c:set var="firstBg" value="${not empty featuredMovies[0].backdropUrl ? featuredMovies[0].backdropUrl : featuredMovies[0].posterUrl}"/>
      <c:if test="${not empty firstBg and not fn:startsWith(firstBg, 'http')}">
        <c:set var="firstBg" value="${pageContext.request.contextPath}/${firstBg}"/>
      </c:if>
      <c:set var="firstPoster" value="${featuredMovies[0].posterUrl}"/>
      <c:if test="${not empty firstPoster and not fn:startsWith(firstPoster, 'http')}">
        <c:set var="firstPoster" value="${pageContext.request.contextPath}/${firstPoster}"/>
      </c:if>
      <img class="hero-bg-img"
           src="<c:out value='${firstBg}'/>"
           alt=""
           data-fallback="<c:out value='${firstPoster}'/>"/>
    </c:if>
  </div>
  <div class="hero-bg-overlay"></div>

  <c:choose>
    <c:when test="${not empty featuredMovies}">
      <c:forEach var="movie" items="${featuredMovies}" varStatus="loop">
        <c:set var="bg" value="${not empty movie.backdropUrl ? movie.backdropUrl : movie.posterUrl}"/>
        <c:if test="${not empty bg and not fn:startsWith(bg, 'http')}">
          <c:set var="bg" value="${pageContext.request.contextPath}/${bg}"/>
        </c:if>
        <c:set var="posterSrc" value="${movie.posterUrl}"/>
        <c:if test="${not empty posterSrc and not fn:startsWith(posterSrc, 'http')}">
          <c:set var="posterSrc" value="${pageContext.request.contextPath}/${posterSrc}"/>
        </c:if>

        <div class="hero-slide ${loop.first ? 'active' : ''}"
             data-poster="<c:out value='${posterSrc}'/>"
             data-backdrop="<c:out value='${bg}'/>"
             style="display:${loop.first ? 'flex' : 'none'}; position:${loop.first ? 'relative' : 'absolute'};
                    inset:0; width:100%; z-index:${loop.first ? '2' : '1'};">

          <div class="hero-inner">

            <%-- Left info --%>
            <div class="hero-info">

              <div class="hero-badges">
                <c:forEach var="genre" items="${movie.genres}" end="1">
                  <span class="hero-badge"><c:out value="${genre}"/></span>
                </c:forEach>
                <c:if test="${not empty movie.language}">
                  <span class="hero-badge"><c:out value="${movie.language}"/></span>
                </c:if>
              </div>

              <h1 class="hero-title"><c:out value="${movie.title}"/></h1>

              <p class="hero-desc">
                <c:out value="${movie.description}"/>
              </p>

              <div class="hero-meta">
                <c:if test="${not empty movie.ageRating}">
                  <span class="hero-age"><c:out value="${movie.ageRating}"/></span>
                </c:if>
                <div class="hero-rating">
                  <span class="star">★</span>
                  <span class="score">
                    <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1"/>
                  </span>
                  <span class="count">(đánh giá)</span>
                </div>
              </div>

              <div class="hero-actions">
                <a href="${pageContext.request.contextPath}/showtimes?movieId=${movie.id}"
                   class="btn btn-primary">
                  🎫 Đặt vé ngay
                </a>
                <c:if test="${not empty movie.trailerUrl}">
                  <a href="<c:out value='${movie.trailerUrl}'/>" target="_blank"
                     rel="noopener noreferrer" class="btn btn-ghost">
                    ▶ Xem Trailer
                  </a>
                </c:if>
              </div>

            </div>

            <%-- Right: phone mockup hiển thị poster --%>
            <div class="hero-visual">
              <div class="phone-wrap">
                <div class="phone-frame">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img src="<c:out value='${posterSrc}'/>"
                           alt="<c:out value='${movie.title}'/>"/>
                    </c:when>
                    <c:otherwise>
                      <div class="poster-placeholder">🎬</div>
                    </c:otherwise>
                  </c:choose>
                </div>
                <div class="phone-glow"></div>
              </div>
            </div>

          </div><%-- /hero-inner --%>
        </div><%-- /hero-slide --%>

      </c:forEach>

      <%-- Slider dots --%>
      <div class="slider-dots">
        <c:forEach var="movie" items="${featuredMovies}" varStatus="loop">
          <span class="dot ${loop.first ? 'active' : ''}"></span>
        </c:forEach>
      </div>

    </c:when>
    <c:otherwise>
      <%-- Fallback khi chưa có phim trong DB --%>
      <div class="hero-inner" style="position:relative;z-index:2;">
        <div class="hero-info">
          <div class="hero-badges">
            <span class="hero-badge">VIỄN TƯỞNG</span>
            <span class="hero-badge">IMAX</span>
          </div>
          <h1 class="hero-title">Chào mừng đến ÉPCINE</h1>
          <p class="hero-desc">
            Trải nghiệm điện ảnh đỉnh cao tại rạp chiếu phim cao cấp.
            Đặt vé online, chọn ghế yêu thích, tận hưởng bộ phim bạn yêu thích.
          </p>
          <div class="hero-actions">
            <a href="${pageContext.request.contextPath}/movies" class="btn btn-primary">
              🎬 Xem phim
            </a>
          </div>
        </div>
        <div class="hero-visual">
          <div class="phone-wrap">
            <div class="phone-frame">
              <div class="poster-placeholder">🎬</div>
            </div>
            <div class="phone-glow"></div>
          </div>
        </div>
      </div>
    </c:otherwise>
  </c:choose>

</section>

<!-- ══════════════════════════════════════════════════
     MOVIES SECTION
     ══════════════════════════════════════════════════ -->
<section class="movies-section">
  <div class="container">

    <%-- Tab bar --%>
    <div class="tabs-wrapper">
      <button class="tab-btn" data-tab="tab-coming">Sắp chiếu</button>
      <button class="tab-btn active" data-tab="tab-showing">Đang chiếu</button>
      <button class="tab-btn" data-tab="tab-early">Suất chiếu sớm</button>
    </div>

    <%-- TAB: Sắp chiếu --%>
    <div class="tab-panel movies-grid" id="tab-coming">
      <c:choose>
        <c:when test="${not empty comingSoonMovies}">
          <c:forEach var="movie" items="${comingSoonMovies}">
            <c:set var="cardPoster" value="${movie.posterUrl}"/>
            <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
              <c:set var="cardPoster" value="${pageContext.request.contextPath}/${cardPoster}"/>
            </c:if>
            <div class="movie-card">
              <div class="card-poster"
                   data-trailer="<c:out value='${movie.trailerUrl}'/>"
                   data-title="<c:out value='${movie.title}'/>"
                   onclick="openTrailer(this)">
                <c:choose>
                  <c:when test="${not empty movie.posterUrl}">
                    <img src="<c:out value='${cardPoster}'/>"
                         alt="<c:out value='${movie.title}'/>"/>
                  </c:when>
                  <c:otherwise>
                    <div class="poster-placeholder">🎬</div>
                  </c:otherwise>
                </c:choose>
                <div class="play-overlay">
                  <div class="play-circle">
                    <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                  </div>
                </div>
                <c:if test="${not empty movie.ageRating}">
                  <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                </c:if>
                <span class="status-badge status-coming">SẮP CHIẾU</span>
              </div>
              <div class="card-info">
                <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                <div class="card-detail-row">
                  <span class="detail-label">Thể loại:</span>
                  <span class="detail-value">
                    <c:forEach var="genre" items="${movie.genres}" varStatus="gs" end="1">
                      <c:if test="${!gs.first}">, </c:if><c:out value="${genre}"/>
                    </c:forEach>
                  </span>
                </div>
                <div class="card-detail-row">
                  <span class="detail-label">Thời lượng:</span>
                  <span class="detail-value"><c:out value="${movie.durationMinutes}"/> phút</span>
                </div>
              </div>
              <div class="card-footer">
                <a href="${pageContext.request.contextPath}/movies/${movie.slug}"
                   class="btn-buy-ticket" onclick="event.stopPropagation()">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M22 10V6c0-1.11-.9-2-2-2H4c-1.11 0-2 .89-2 2v4c1.11 0 2 .89 2 2s-.89 2-2 2v4c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2v-4c-1.11 0-2-.89-2-2s.89-2 2-2z"/></svg>
                  MUA VÉ
                </a>
              </div>
            </div>
          </c:forEach>

          <c:if test="${comingSoonMovies.size() >= 8}">
            <div class="movie-card more-card">
              <a href="${pageContext.request.contextPath}/movies?status=COMING_SOON"
                 style="display:flex;flex-direction:column;height:100%;text-decoration:none;">
                <div class="card-poster" style="flex:1;">
                  <div class="more-label">Nhiều phim hơn</div>
                </div>
              </a>
            </div>
          </c:if>
        </c:when>
        <c:otherwise>
          <p style="color:var(--text-muted);text-align:center;padding:40px;grid-column:1/-1;">
            Chưa có phim sắp chiếu.
          </p>
        </c:otherwise>
      </c:choose>
    </div>

    <%-- TAB: Đang chiếu --%>
    <div class="tab-panel active movies-grid" id="tab-showing">
      <c:choose>
        <c:when test="${not empty nowShowingMovies}">
          <c:forEach var="movie" items="${nowShowingMovies}">
            <c:set var="cardPoster" value="${movie.posterUrl}"/>
            <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
              <c:set var="cardPoster" value="${pageContext.request.contextPath}/${cardPoster}"/>
            </c:if>
            <div class="movie-card">
              <div class="card-poster"
                   data-trailer="<c:out value='${movie.trailerUrl}'/>"
                   data-title="<c:out value='${movie.title}'/>"
                   onclick="openTrailer(this)">
                <c:choose>
                  <c:when test="${not empty movie.posterUrl}">
                    <img src="<c:out value='${cardPoster}'/>"
                         alt="<c:out value='${movie.title}'/>"/>
                  </c:when>
                  <c:otherwise>
                    <div class="poster-placeholder">🎬</div>
                  </c:otherwise>
                </c:choose>
                <div class="play-overlay">
                  <div class="play-circle">
                    <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                  </div>
                </div>
                <c:if test="${not empty movie.ageRating}">
                  <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                </c:if>
                <span class="status-badge status-hot">HOT</span>
              </div>
              <div class="card-info">
                <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                <div class="card-detail-row">
                  <span class="detail-label">Thể loại:</span>
                  <span class="detail-value">
                    <c:forEach var="genre" items="${movie.genres}" varStatus="gs" end="1">
                      <c:if test="${!gs.first}">, </c:if><c:out value="${genre}"/>
                    </c:forEach>
                  </span>
                </div>
                <div class="card-detail-row">
                  <span class="detail-label">Thời lượng:</span>
                  <span class="detail-value"><c:out value="${movie.durationMinutes}"/> phút</span>
                </div>
              </div>
              <div class="card-footer">
                <a href="${pageContext.request.contextPath}/showtimes?movieId=${movie.id}"
                   class="btn-buy-ticket" onclick="event.stopPropagation()">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M22 10V6c0-1.11-.9-2-2-2H4c-1.11 0-2 .89-2 2v4c1.11 0 2 .89 2 2s-.89 2-2 2v4c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2v-4c-1.11 0-2-.89-2-2s.89-2 2-2z"/></svg>
                  MUA VÉ
                </a>
              </div>
            </div>
          </c:forEach>

          <%-- "Nhiều phim hơn" --%>
          <c:if test="${nowShowingMovies.size() >= 8}">
            <div class="movie-card more-card">
              <a href="${pageContext.request.contextPath}/movies?status=NOW_SHOWING"
                 style="display:flex;flex-direction:column;height:100%;text-decoration:none;">
                <div class="card-poster" style="flex:1;">
                  <div class="more-label">Nhiều phim hơn</div>
                </div>
              </a>
            </div>
          </c:if>
        </c:when>
        <c:otherwise>
          <p style="color:var(--text-muted);text-align:center;padding:40px;grid-column:1/-1;">
            Chưa có phim đang chiếu.
          </p>
        </c:otherwise>
      </c:choose>
    </div>

    <%-- TAB: Suất chiếu sớm --%>
    <div class="tab-panel movies-grid" id="tab-early">
          <c:forEach var="movie" items="${earlyMovies}">
            <c:set var="cardPoster" value="${movie.posterUrl}"/>
            <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
              <c:set var="cardPoster" value="${pageContext.request.contextPath}/${cardPoster}"/>
            </c:if>
            <div class="movie-card">
              <div class="card-poster"
                   data-trailer="<c:out value='${movie.trailerUrl}'/>"
                   data-title="<c:out value='${movie.title}'/>"
                   onclick="openTrailer(this)">
                <c:choose>
                  <c:when test="${not empty movie.posterUrl}">
                    <img src="<c:out value='${cardPoster}'/>"
                         alt="<c:out value='${movie.title}'/>"/>
                  </c:when>
                  <c:otherwise>
                    <div class="poster-placeholder">🎬</div>
                  </c:otherwise>
                </c:choose>
                <div class="play-overlay">
                  <div class="play-circle">
                    <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
                  </div>
                </div>
                <c:if test="${not empty movie.ageRating}">
                  <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                </c:if>
                <span class="status-badge status-early">SUẤT SỚM</span>
              </div>
              <div class="card-info">
                <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                <div class="card-detail-row">
                  <span class="detail-label">Thể loại:</span>
                  <span class="detail-value">
                    <c:forEach var="genre" items="${movie.genres}" varStatus="gs" end="1">
                      <c:if test="${!gs.first}">, </c:if><c:out value="${genre}"/>
                    </c:forEach>
                  </span>
                </div>
                <div class="card-detail-row">
                  <span class="detail-label">Thời lượng:</span>
                  <span class="detail-value"><c:out value="${movie.durationMinutes}"/> phút</span>
                </div>
              </div>
              <div class="card-footer">
                <a href="${pageContext.request.contextPath}/showtimes?movieId=${movie.id}"
                   class="btn-buy-ticket" onclick="event.stopPropagation()">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M22 10V6c0-1.11-.9-2-2-2H4c-1.11 0-2 .89-2 2v4c1.11 0 2 .89 2 2s-.89 2-2 2v4c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2v-4c-1.11 0-2-.89-2-2s.89-2 2-2z"/></svg>
                  MUA VÉ
                </a>
              </div>
            </div>
          </c:forEach>

          <c:if test="${not empty earlyMovies and earlyMovies.size() >= 8}">
            <div class="movie-card more-card">
              <a href="${pageContext.request.contextPath}/movies?status=EARLY"
                 style="display:flex;flex-direction:column;height:100%;text-decoration:none;">
                <div class="card-poster" style="flex:1;">
                  <div class="more-label">Nhiều phim hơn</div>
                </div>
              </a>
            </div>
          </c:if>
    </div>

  </div><%-- /container --%>
</section>

<%-- ══════════════════════════════════════════════════
     TRAILER MODAL
     ══════════════════════════════════════════════════ --%>
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

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
