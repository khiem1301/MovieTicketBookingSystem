<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %> <%@
taglib prefix="c" uri="jakarta.tags.core" %> <%@ taglib prefix="fn"
uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>
      <c:out value="${not empty pageTitle ? pageTitle : 'ÉpCine'}"/>
    </title>
    <link
      rel="stylesheet"
      href="${pageContext.request.contextPath}/css/main.css"
    />
    <c:if test="${not empty extraCss}">
      <link
        rel="stylesheet"
        href="${pageContext.request.contextPath}/css/${extraCss}.css"
      />
    </c:if>
    <c:if test="${not empty extraCss2}">
      <link
        rel="stylesheet"
        href="${pageContext.request.contextPath}/css/${extraCss2}.css"
      />
    </c:if>
  </head>
  <body>
    <header class="site-header">
      <div class="header-inner">
        <%-- Logo (ảnh) --%>
        <a href="${pageContext.request.contextPath}/home" class="logo">
          <img
            src="${pageContext.request.contextPath}/images/logorapchieuphim.png"
            alt="ÉpCine"
            class="logo-img"
            onerror="
              this.style.display = 'none';
              this.nextElementSibling.style.display = 'inline';
            "
          />
          <span class="logo-text" style="display: none">ÉpCine</span>
        </a>

        <%-- Search --%>
        <form
          class="header-search"
          action="${pageContext.request.contextPath}/movies"
          method="get"
        >
          <svg
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="2"
            stroke-linecap="round"
            stroke-linejoin="round"
          >
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            type="text"
            name="q"
            placeholder="Tìm kiếm phim..."
            autocomplete="off"
            value="<c:out value='${param.q}'/>"
          />
        </form>

        <%-- Main Nav --%>
        <nav class="main-nav">
          <%-- Phim: click thẳng, KHÔNG dropdown --%>
          <div class="nav-item">
            <a href="${pageContext.request.contextPath}/movies" class="nav-link"
              >Phim</a
            >
          </div>

          <%-- Thể loại: hover dropdown --%>
          <div class="nav-item">
            <a
              href="${pageContext.request.contextPath}/movies"
              class="nav-link"
            >
              Thể loại <span class="nav-arrow">▾</span>
            </a>
            <div class="dropdown-menu dropdown-genres">
              <c:choose>
                <c:when test="${not empty genreList}">
                  <c:forEach var="genre" items="${genreList}">
                    <a
                      href="${pageContext.request.contextPath}/movies?genre=${genre.id}"
                    >
                      <c:out value="${genre.genreName}" />
                    </a>
                  </c:forEach>
                </c:when>
                <c:otherwise>
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=action"
                    >Hành động</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=romance"
                    >Tình cảm</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=horror"
                    >Kinh dị</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=scifi"
                    >Viễn tưởng</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=animation"
                    >Hoạt hình</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=comedy"
                    >Hài</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=drama"
                    >Chính kịch</a
                  >
                  <a
                    href="${pageContext.request.contextPath}/movies?genre=thriller"
                    >Kịch tính</a
                  >
                </c:otherwise>
              </c:choose>
            </div>
          </div>

          <%-- Đánh giá: click dropdown --%>
          <div class="nav-item nav-item--click">
            <a href="#" class="nav-link" data-toggle="reviews-dropdown">
              Đánh giá <span class="nav-arrow" id="reviews-arrow">▾</span>
            </a>
            <div class="dropdown-menu" id="reviews-dropdown">
              <a href="${pageContext.request.contextPath}/reviews?sort=top">
                ⭐ Phim đánh giá cao nhất
              </a>
              <a href="${pageContext.request.contextPath}/reviews?sort=latest">
                🕐 Đánh giá mới nhất
              </a>
              <a href="${pageContext.request.contextPath}/reviews?sort=popular">
                🔥 Phim được yêu thích
              </a>
              <c:if test="${not empty sessionScope.loggedUser}">
                <a href="${pageContext.request.contextPath}/reviews/mine">
                  📝 Đánh giá của tôi
                </a>
              </c:if>
            </div>
          </div>
        </nav>

        <%-- Auth / User area --%>
        <div class="header-auth">
          <c:choose>
            <c:when test="${not empty sessionScope.loggedUser}">
              <div class="user-menu nav-item">
                <div class="user-info">
                  <c:choose>
                    <c:when
                      test="${not empty sessionScope.loggedUser.avatarUrl}"
                    >
                      <c:set var="rawAvatar" value="${sessionScope.loggedUser.avatarUrl}"/>
                      <c:choose>
                        <c:when test="${fn:startsWith(rawAvatar, 'http://') or fn:startsWith(rawAvatar, 'https://')}">
                          <c:set var="userAvatarSrc" value="${rawAvatar}"/>
                        </c:when>
                        <c:otherwise>
                          <c:set var="userAvatarSrc" value="${pageContext.request.contextPath}/${rawAvatar}"/>
                        </c:otherwise>
                      </c:choose>
                      <img
                        class="user-avatar"
                        src="<c:out value='${userAvatarSrc}'/>"
                        alt="Avatar"
                      />
                    </c:when>
                    <c:otherwise>
                      <div class="user-avatar user-avatar--placeholder">👤</div>
                    </c:otherwise>
                  </c:choose>
                  <span class="user-name"
                    ><c:out value="${sessionScope.loggedUser.fullName}"
                  /></span>
                  <span
                    class="nav-arrow"
                    style="font-size: 10px; color: var(--text-muted)"
                    >▾</span
                  >
                </div>
                <div class="dropdown-menu" style="right: 0; left: auto">
                  <a href="${pageContext.request.contextPath}/profile"
                    >Tài khoản</a
                  >
                  <c:if test="${sessionScope.userRole == 'CUSTOMER'}">
                    <a href="${pageContext.request.contextPath}/booking-history"
                      >Lịch sử đặt vé</a
                    >
                    <a href="${pageContext.request.contextPath}/loyalty"
                      >Điểm thưởng</a
                    >
                  </c:if>
                  <c:if test="${sessionScope.userRole == 'STAFF'}">
                    <a href="${pageContext.request.contextPath}/staff/counter"
                      >Quầy vé</a
                    >
                  </c:if>
                  <c:if test="${sessionScope.userRole == 'MANAGER'}">
                    <a
                      href="${pageContext.request.contextPath}/manager/dashboard"
                      >Quản lý</a
                    >
                  </c:if>
                  <c:if test="${sessionScope.userRole == 'ADMIN'}">
                    <a href="${pageContext.request.contextPath}/admin/users"
                      >Quản trị</a
                    >
                  </c:if>
                  <a
                    href="${pageContext.request.contextPath}/logout"
                    style="color: #ef5350 !important"
                    >Đăng xuất</a
                  >
                </div>
              </div>
            </c:when>
            <c:otherwise>
              <a
                href="${pageContext.request.contextPath}/login"
                class="btn-login"
                >Đăng nhập</a
              >
              <a
                href="${pageContext.request.contextPath}/register"
                class="btn-register"
                >Đăng ký</a
              >
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </header>
