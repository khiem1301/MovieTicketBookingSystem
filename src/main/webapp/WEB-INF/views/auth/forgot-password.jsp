<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Quên mật khẩu — ÉPCINE</title>
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
      <p class="auth-subtitle">Đặt lại mật khẩu</p>

      <c:if test="${not empty errorMessage}">
        <div class="auth-alert auth-alert--error" role="alert">
          <c:out value="${errorMessage}"/>
        </div>
      </c:if>

      <c:if test="${not empty successMessage}">
        <div class="auth-alert auth-alert--success" role="status">
          <c:out value="${successMessage}"/>
        </div>
      </c:if>

      <c:if test="${empty successMessage}">
        <p class="auth-pending-text">
          Nhập email đã đăng ký. Chúng tôi sẽ gửi link đặt lại mật khẩu nếu tài khoản tồn tại.
        </p>

        <form class="auth-form" action="${pageContext.request.contextPath}/forgot-password" method="post" novalidate>
          <div class="auth-field">
            <label class="auth-label" for="email">Email</label>
            <div class="auth-input-wrap">
              <span class="auth-input-icon" aria-hidden="true">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                     stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                  <polyline points="22,6 12,13 2,6"/>
                </svg>
              </span>
              <input type="email" id="email" name="email" class="auth-input"
                     placeholder="email@example.com"
                     value="<c:out value='${email}'/>"
                     autocomplete="email" required/>
            </div>
          </div>

          <button type="submit" class="auth-btn-submit">Gửi link đặt lại</button>
        </form>
      </c:if>

      <p class="auth-footer-text">
        <a href="${pageContext.request.contextPath}/login" class="auth-link">← Quay lại đăng nhập</a>
      </p>

      <a href="${pageContext.request.contextPath}/home" class="auth-back-home">← Về trang chủ</a>

    </div>
  </div>

</body>
</html>
