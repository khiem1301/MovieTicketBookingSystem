<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Đặt lại mật khẩu — ÉPCINE</title>
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
      <p class="auth-subtitle">Tạo mật khẩu mới</p>

      <c:if test="${not empty errors}">
        <div class="auth-alert auth-alert--error" role="alert">
          <c:forEach var="err" items="${errors}">
            <div><c:out value="${err}"/></div>
          </c:forEach>
        </div>
      </c:if>

      <p class="auth-pending-text">
        Mật khẩu: 8–16 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.
      </p>

      <form class="auth-form" action="${pageContext.request.contextPath}/reset-password" method="post" novalidate>
        <input type="hidden" name="token" value="<c:out value='${token}'/>"/>

        <div class="auth-field">
          <label class="auth-label" for="newPassword">Mật khẩu mới</label>
          <div class="auth-input-wrap">
            <input type="password" id="newPassword" name="newPassword"
                   class="auth-input auth-input--has-toggle"
                   placeholder="••••••••" autocomplete="new-password" required/>
            <button type="button" class="auth-toggle-pw" data-target="newPassword"
                    aria-label="Hiện hoặc ẩn mật khẩu">
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

        <div class="auth-field">
          <label class="auth-label" for="confirmPassword">Xác nhận mật khẩu</label>
          <div class="auth-input-wrap">
            <input type="password" id="confirmPassword" name="confirmPassword"
                   class="auth-input auth-input--has-toggle"
                   placeholder="••••••••" autocomplete="new-password" required/>
            <button type="button" class="auth-toggle-pw" data-target="confirmPassword"
                    aria-label="Hiện hoặc ẩn mật khẩu">
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

        <button type="submit" class="auth-btn-submit">Lưu mật khẩu mới</button>
      </form>

      <a href="${pageContext.request.contextPath}/login" class="auth-back-home">← Quay lại đăng nhập</a>

    </div>
  </div>

  <script charset="UTF-8" src="${pageContext.request.contextPath}/js/auth.js"></script>
</body>
</html>
