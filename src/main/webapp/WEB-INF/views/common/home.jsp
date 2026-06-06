<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="ÉPCINE — Đặt vé xem phim"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

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

  <c:choose>
    <c:when test="${not empty featuredMovies}">
      <c:forEach var="movie" items="${featuredMovies}" varStatus="loop">
        <c:set var="bg" value="${not empty movie.backdropUrl ? movie.backdropUrl : movie.posterUrl}"/>

        <div class="hero-slide ${loop.first ? 'active' : ''}"
             data-poster="<c:out value='${movie.posterUrl}'/>"
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

            <%-- Right: ảnh backdrop ngang, cùng hàng với phần giới thiệu --%>
            <div class="hero-backdrop">
              <c:choose>
                <c:when test="${not empty bg}">
                  <img class="hero-backdrop-img"
                       src="<c:out value='${bg}'/>"
                       alt="<c:out value='${movie.title}'/>"/>
                </c:when>
                <c:otherwise>
                  <div class="hero-backdrop-placeholder">🎬</div>
                </c:otherwise>
              </c:choose>
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
        <div class="hero-backdrop">
          <div class="hero-backdrop-placeholder">🎬</div>
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

    <%-- TAB: Đang chiếu --%>
    <div class="tab-panel active movies-grid" id="tab-showing">
      <c:choose>
        <c:when test="${not empty nowShowingMovies}">
          <c:forEach var="movie" items="${nowShowingMovies}">
            <div class="movie-card">
              <div class="card-poster">
                <c:choose>
                  <c:when test="${not empty movie.posterUrl}">
                    <img src="<c:out value='${movie.posterUrl}'/>"
                         alt="<c:out value='${movie.title}'/>"/>
                  </c:when>
                  <c:otherwise>
                    <div class="poster-placeholder">🎬</div>
                  </c:otherwise>
                </c:choose>

                <div class="card-overlay">
                  <a href="${pageContext.request.contextPath}/showtimes?movieId=${movie.id}"
                     class="btn-book">Đặt vé</a>
                </div>

                <c:if test="${not empty movie.ageRating}">
                  <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                </c:if>
              </div>

              <div class="card-info">
                <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                <div class="card-meta">
                  <span><c:out value="${movie.durationMinutes}"/> phút</span>
                  <span class="rating">
                    <span class="star">★</span>
                    <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1"/>
                  </span>
                </div>
                <div class="card-genres">
                  <c:forEach var="genre" items="${movie.genres}" end="1">
                    <span class="genre-tag"><c:out value="${genre}"/></span>
                  </c:forEach>
                </div>
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

    <%-- TAB: Sắp chiếu --%>
    <div class="tab-panel movies-grid" id="tab-coming">
      <c:choose>
        <c:when test="${not empty comingSoonMovies}">
          <c:forEach var="movie" items="${comingSoonMovies}">
            <div class="movie-card">
              <div class="card-poster">
                <c:choose>
                  <c:when test="${not empty movie.posterUrl}">
                    <img src="<c:out value='${movie.posterUrl}'/>"
                         alt="<c:out value='${movie.title}'/>"/>
                  </c:when>
                  <c:otherwise>
                    <div class="poster-placeholder">🎬</div>
                  </c:otherwise>
                </c:choose>
                <div class="card-overlay">
                  <a href="${pageContext.request.contextPath}/movies/${movie.slug}"
                     class="btn-book">Chi tiết</a>
                </div>
                <c:if test="${not empty movie.ageRating}">
                  <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                </c:if>
              </div>
              <div class="card-info">
                <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                <div class="card-meta">
                  <span><c:out value="${movie.durationMinutes}"/> phút</span>
                  <span class="rating">
                    <span class="star">★</span>
                    <fmt:formatNumber value="${movie.averageRating}" maxFractionDigits="1"/>
                  </span>
                </div>
                <div class="card-genres">
                  <c:forEach var="genre" items="${movie.genres}" end="1">
                    <span class="genre-tag"><c:out value="${genre}"/></span>
                  </c:forEach>
                </div>
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

    <%-- TAB: Suất chiếu sớm (hiện dùng chung với coming soon, team showtime sẽ mở rộng) --%>
    <div class="tab-panel movies-grid" id="tab-early">
      <p style="color:var(--text-muted);text-align:center;padding:60px;grid-column:1/-1;">
        Chưa có suất chiếu sớm được lên lịch.
      </p>
    </div>

  </div><%-- /container --%>
</section>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
