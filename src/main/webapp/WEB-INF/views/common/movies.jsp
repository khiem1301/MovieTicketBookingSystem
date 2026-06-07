<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Danh sách phim — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<c:choose>
  <c:when test="${activeStatus == 'COMING_SOON'}">
    <c:set var="activeTab" value="tab-coming"/>
  </c:when>
  <c:when test="${activeStatus == 'EARLY'}">
    <c:set var="activeTab" value="tab-early"/>
  </c:when>
  <c:otherwise>
    <c:set var="activeTab" value="tab-showing"/>
  </c:otherwise>
</c:choose>

<c:if test="${not empty dbError}">
  <div style="background:#b71c1c;color:#fff;padding:10px 20px;font-size:13px;font-family:monospace;position:fixed;bottom:0;left:0;right:0;z-index:9999;word-break:break-all;">
    <strong>DB ERROR:</strong> <c:out value="${dbError}"/>
  </div>
</c:if>

<section class="movies-page">
  <div class="container">

    <div class="movies-page-header">
      <h1 class="movies-page-title">
        <c:choose>
          <c:when test="${not empty searchKeyword}">
            Kết quả tìm kiếm: &ldquo;<c:out value="${searchKeyword}"/>&rdquo;
          </c:when>
          <c:when test="${not empty selectedGenre}">
            Phim <c:out value="${selectedGenre.genreName}"/>
          </c:when>
          <c:otherwise>Danh sách phim</c:otherwise>
        </c:choose>
      </h1>
      <p class="movies-page-sub">
        <c:choose>
          <c:when test="${not empty activeStatus and activeStatus == 'COMING_SOON'}">
            Các bộ phim sắp ra mắt tại ÉPCINE
          </c:when>
          <c:when test="${not empty activeStatus and activeStatus == 'NOW_SHOWING'}">
            Các bộ phim đang chiếu tại ÉPCINE
          </c:when>
          <c:when test="${not empty activeStatus and activeStatus == 'EARLY'}">
            Suất chiếu sớm — đặt vé trước ngày công chiếu
          </c:when>
          <c:otherwise>
            Khám phá phim sắp chiếu, đang chiếu và suất chiếu sớm
          </c:otherwise>
        </c:choose>
      </p>
    </div>

    <c:if test="${empty activeStatus}">
      <div class="tabs-wrapper">
        <button type="button"
                class="tab-btn ${activeTab == 'tab-coming' ? 'active' : ''}"
                data-tab="tab-coming">Sắp chiếu</button>
        <button type="button"
                class="tab-btn ${activeTab == 'tab-showing' ? 'active' : ''}"
                data-tab="tab-showing">Đang chiếu</button>
        <button type="button"
                class="tab-btn ${activeTab == 'tab-early' ? 'active' : ''}"
                data-tab="tab-early">Suất chiếu sớm</button>
      </div>
    </c:if>

    <%-- TAB: Sắp chiếu --%>
    <c:if test="${empty activeStatus or activeStatus == 'COMING_SOON'}">
      <div class="tab-panel movies-grid ${activeTab == 'tab-coming' ? 'active' : ''}" id="tab-coming">
        <c:choose>
          <c:when test="${not empty comingSoonMovies}">
            <c:forEach var="movie" items="${comingSoonMovies}">
              <c:set var="cardPoster" value="${movie.posterUrl}"/>
              <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
                <c:set var="cardPoster" value="${ctx}/${cardPoster}"/>
              </c:if>
              <div class="movie-card">
                <div class="card-poster">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img src="<c:out value='${cardPoster}'/>"
                           alt="<c:out value='${movie.title}'/>"/>
                    </c:when>
                    <c:otherwise>
                      <div class="poster-placeholder">🎬</div>
                    </c:otherwise>
                  </c:choose>
                  <div class="card-overlay">
                    <span class="btn-book btn-book--muted">Sắp chiếu</span>
                  </div>
                  <c:if test="${not empty movie.ageRating}">
                    <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                  </c:if>
                </div>
                <div class="card-info">
                  <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                  <div class="card-meta">
                    <span><c:out value="${movie.durationMinutes}"/> phút</span>
                    <c:if test="${not empty movie.releaseDate}">
                      <span><fmt:formatDate value="${movie.releaseDate}" pattern="dd/MM/yyyy"/></span>
                    </c:if>
                  </div>
                  <div class="card-genres">
                    <c:forEach var="genre" items="${movie.genres}" end="1">
                      <span class="genre-tag"><c:out value="${genre}"/></span>
                    </c:forEach>
                  </div>
                </div>
              </div>
            </c:forEach>
          </c:when>
          <c:otherwise>
            <p class="movies-empty">Chưa có phim sắp chiếu.</p>
          </c:otherwise>
        </c:choose>
      </div>
    </c:if>

    <%-- TAB: Đang chiếu --%>
    <c:if test="${empty activeStatus or activeStatus == 'NOW_SHOWING'}">
      <div class="tab-panel movies-grid ${activeTab == 'tab-showing' ? 'active' : ''}" id="tab-showing">
        <c:choose>
          <c:when test="${not empty nowShowingMovies}">
            <c:forEach var="movie" items="${nowShowingMovies}">
              <c:set var="cardPoster" value="${movie.posterUrl}"/>
              <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
                <c:set var="cardPoster" value="${ctx}/${cardPoster}"/>
              </c:if>
              <div class="movie-card">
                <div class="card-poster">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img src="<c:out value='${cardPoster}'/>"
                           alt="<c:out value='${movie.title}'/>"/>
                    </c:when>
                    <c:otherwise>
                      <div class="poster-placeholder">🎬</div>
                    </c:otherwise>
                  </c:choose>
                  <div class="card-overlay">
                    <a href="${ctx}/showtimes?movieId=${movie.id}" class="btn-book">Đặt vé</a>
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
          </c:when>
          <c:otherwise>
            <p class="movies-empty">Chưa có phim đang chiếu.</p>
          </c:otherwise>
        </c:choose>
      </div>
    </c:if>

    <%-- TAB: Suất chiếu sớm --%>
    <c:if test="${empty activeStatus or activeStatus == 'EARLY'}">
      <div class="tab-panel movies-grid ${activeTab == 'tab-early' ? 'active' : ''}" id="tab-early">
            <c:forEach var="movie" items="${earlyMovies}">
              <c:set var="cardPoster" value="${movie.posterUrl}"/>
              <c:if test="${not empty cardPoster and not fn:startsWith(cardPoster, 'http')}">
                <c:set var="cardPoster" value="${ctx}/${cardPoster}"/>
              </c:if>
              <div class="movie-card">
                <div class="card-poster">
                  <c:choose>
                    <c:when test="${not empty movie.posterUrl}">
                      <img src="<c:out value='${cardPoster}'/>"
                           alt="<c:out value='${movie.title}'/>"/>
                    </c:when>
                    <c:otherwise>
                      <div class="poster-placeholder">🎬</div>
                    </c:otherwise>
                  </c:choose>
                  <div class="card-overlay">
                    <a href="${ctx}/showtimes?movieId=${movie.id}" class="btn-book">Đặt vé sớm</a>
                  </div>
                  <c:if test="${not empty movie.ageRating}">
                    <span class="age-badge"><c:out value="${movie.ageRating}"/></span>
                  </c:if>
                </div>
                <div class="card-info">
                  <h3 class="card-title"><c:out value="${movie.title}"/></h3>
                  <div class="card-meta">
                    <span><c:out value="${movie.durationMinutes}"/> phút</span>
                    <c:if test="${not empty movie.releaseDate}">
                      <span>CC: <fmt:formatDate value="${movie.releaseDate}" pattern="dd/MM/yyyy"/></span>
                    </c:if>
                  </div>
                  <div class="card-genres">
                    <c:forEach var="genre" items="${movie.genres}" end="1">
                      <span class="genre-tag"><c:out value="${genre}"/></span>
                    </c:forEach>
                  </div>
                </div>
              </div>
            </c:forEach>
      </div>
    </c:if>

  </div>
</section>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
