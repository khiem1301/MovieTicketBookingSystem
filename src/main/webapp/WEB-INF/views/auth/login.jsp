<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Đăng nhập — ÉPCINE</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css"/>
</head>
<body class="auth-page">

  <div class="auth-wrapper">
    <div class="auth-card">

      <a href="${pageContext.request.contextPath}/home" class="auth-brand">
        <img src="${pageContext.request.contextPath}/images/logorapchieuphim.png"
             alt="ÉpCine" class="auth-logo-img"
             onerror="this.style.display='none'; this.nextElementSibling.style.display='inline'"/>
        <span class="auth-logo-fallback" style="display:none;">ÉpCine</span>
      </a>
      <p class="auth-subtitle">Hệ thống đặt vé xem phim</p>

      <c:if test="${not empty errorMessage}">
        <div class="auth-alert auth-alert--error" role="alert">
          <c:out value="${errorMessage}"/>
        </div>
      </c:if>

      <c:if test="${param.registered == '1'}">
        <div class="auth-alert auth-alert--success" role="status">
          Đăng ký thành công.
          <c:if test="${not empty param.username}">
            Đăng nhập bằng tên đăng nhập: <strong><c:out value="${param.username}"/></strong>
          </c:if>
          <c:if test="${empty param.username}">
            Vui lòng đăng nhập.
          </c:if>
        </div>
      </c:if>

      <c:if test="${param.verified == '1'}">
        <div class="auth-alert auth-alert--success" role="status">
          Email đã được xác thực. Bạn có thể đăng nhập ngay.
        </div>
      </c:if>

      <c:if test="${param.verify == 'invalid'}">
        <div class="auth-alert auth-alert--error" role="alert">
          Liên kết xác thực không hợp lệ hoặc đã hết hạn.
        </div>
      </c:if>

      <c:if test="${param.verify == 'error'}">
        <div class="auth-alert auth-alert--error" role="alert">
          Không thể xác thực email. Vui lòng thử lại sau.
        </div>
      </c:if>

      <c:if test="${param.google == 'not_configured'}">
        <div class="auth-alert auth-alert--error" role="alert">
          Chưa cấu hình Google OAuth. Xem hướng dẫn trong <code>google.properties.example</code>.
        </div>
      </c:if>
      <c:if test="${param.google == 'cancelled'}">
        <div class="auth-alert auth-alert--error" role="alert">Bạn đã hủy đăng nhập Google.</div>
      </c:if>
      <c:if test="${param.google == 'error' or param.google == 'invalid_state' or param.google == 'missing_code'}">
        <div class="auth-alert auth-alert--error" role="alert">
          Đăng nhập Google thất bại. Kiểm tra lại <code>google.redirect.uri</code> trong Google Cloud Console.
        </div>
      </c:if>
      <c:if test="${param.google == 'no_email'}">
        <div class="auth-alert auth-alert--error" role="alert">
          Tài khoản Google không có email. Vui lòng dùng tài khoản Google khác.
        </div>
      </c:if>
      <c:if test="${param.google == 'banned'}">
        <div class="auth-alert auth-alert--error" role="alert">Tài khoản đã bị khóa.</div>
      </c:if>
      <c:if test="${param.google == 'session_expired'}">
        <div class="auth-alert auth-alert--error" role="alert">
          Phiên Google hết hạn. Vui lòng thử lại.
        </div>
      </c:if>

      <c:if test="${param.logout == 'success'}">
        <div class="auth-alert auth-alert--success" role="status" id="logout-success-banner">
          Đăng xuất thành công. Vui lòng đăng nhập lại nếu cần.
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
                  window.history.replaceState(null, '', '${pageContext.request.contextPath}/login');
                }
              }, 400);
            }, 4000);
          })();
        </script>
      </c:if>

      <form class="auth-form" action="${pageContext.request.contextPath}/login" method="post" novalidate>
        <c:if test="${not empty param.redirect}">
          <input type="hidden" name="redirect" value="<c:out value='${param.redirect}'/>"/>
        </c:if>

        <div class="auth-field">
          <label class="auth-label" for="identifier">Email hoặc tên đăng nhập</label>
          <div class="auth-input-wrap">
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
            </span>
            <input type="text" id="identifier" name="identifier" class="auth-input"
                   placeholder="email@example.com hoặc username"
                   value="<c:out value='${identifier}'/>"
                   autocomplete="username" required/>
          </div>
        </div>

        <div class="auth-field">
          <div class="auth-label-row">
            <label class="auth-label" for="password">Mật khẩu</label>
            <a href="${pageContext.request.contextPath}/forgot-password" class="auth-link-sm">
              Quên mật khẩu?
            </a>
          </div>
          <div class="auth-input-wrap">
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
              </svg>
            </span>
            <input type="password" id="password" name="password"
                   class="auth-input auth-input--has-toggle"
                   placeholder="••••••••" autocomplete="current-password" required/>
            <button type="button" class="auth-toggle-pw" id="togglePassword"
                    data-target="password" aria-label="Hiện hoặc ẩn mật khẩu">
              <svg class="icon-eye" width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
              <svg class="icon-eye-off" width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                   style="display:none">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                <line x1="1" y1="1" x2="23" y2="23"/>
              </svg>
            </button>
          </div>
        </div>

        <label class="auth-remember">
          <input type="checkbox" name="rememberMe" value="on"
                 <c:if test="${rememberMe}">checked</c:if>/>
          <span>Ghi nhớ đăng nhập</span>
        </label>

        <button type="submit" class="auth-btn-submit">Đăng nhập</button>
      </form>

      <%@ include file="/WEB-INF/views/auth/google-button.jsp" %>

      <p class="auth-footer-text">
        Chưa có tài khoản?
        <a href="${pageContext.request.contextPath}/register" class="auth-link">Đăng ký ngay</a>
      </p>

      <a href="${pageContext.request.contextPath}/home" class="auth-back-home">← Về trang chủ</a>

    </div>
  </div>

  <script charset="UTF-8" src="${pageContext.request.contextPath}/js/auth.js"></script>
</body>
</html>
