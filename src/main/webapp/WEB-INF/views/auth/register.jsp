<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Đăng ký — ÉPCINE</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css"/>
</head>
<body class="auth-page">

  <div class="auth-wrapper auth-wrapper--wide">
    <div class="auth-card">

      <a href="${pageContext.request.contextPath}/home" class="auth-brand">
        <img src="${pageContext.request.contextPath}/images/logorapchieuphim.png"
             alt="ÉpCine" class="auth-logo-img"
             onerror="this.style.display='none'; this.nextElementSibling.style.display='inline'"/>
        <span class="auth-logo-fallback" style="display:none;">ÉpCine</span>
      </a>
      <p class="auth-subtitle">Tạo tài khoản khách hàng</p>

      <c:if test="${not empty errors}">
        <div class="auth-alert auth-alert--error" role="alert">
          <c:forEach var="err" items="${errors}">
            <div><c:out value="${err}"/></div>
          </c:forEach>
        </div>
      </c:if>

      <form class="auth-form" action="${pageContext.request.contextPath}/register" method="post" novalidate>

        <div class="auth-field">
          <label class="auth-label" for="fullName">Họ và tên</label>
          <div class="auth-input-wrap">
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                <circle cx="12" cy="7" r="4"/>
              </svg>
            </span>
            <input type="text" id="fullName" name="fullName" class="auth-input"
                   placeholder="Nguyễn Văn A"
                   value="<c:out value='${form.fullName}'/>"
                   autocomplete="name" required/>
          </div>
        </div>

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
                   value="<c:out value='${form.email}'/>"
                   autocomplete="email"/>
          </div>
        </div>

        <div class="auth-field">
          <label class="auth-label" for="phoneNumber">Số điện thoại</label>
          <div class="auth-input-wrap">
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.12.81.3 1.6.57 2.34a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.74-1.14a2 2 0 0 1 2.11-.45c.74.27 1.53.45 2.34.57A2 2 0 0 1 22 16.92z"/>
              </svg>
            </span>
            <input type="tel" id="phoneNumber" name="phoneNumber" class="auth-input"
                   placeholder="0901234567"
                   value="<c:out value='${form.phoneNumber}'/>"
                   autocomplete="tel"/>
          </div>
        </div>

        <div class="auth-field">
          <label class="auth-label" for="dateOfBirth">Ngày sinh</label>
          <div class="auth-input-wrap">
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"/>
                <line x1="16" y1="2" x2="16" y2="6"/>
                <line x1="8" y1="2" x2="8" y2="6"/>
                <line x1="3" y1="10" x2="21" y2="10"/>
              </svg>
            </span>
            <input type="date" id="dateOfBirth" name="dateOfBirth" class="auth-input auth-input--date"
                   <c:if test="${not empty form.dateOfBirth}">
                     value="<fmt:formatDate value='${form.dateOfBirth}' pattern='yyyy-MM-dd'/>"
                   </c:if>
                   required/>
          </div>
        </div>

        <div class="auth-field">
          <label class="auth-label" for="password">Mật khẩu</label>
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
                   placeholder="Ít nhất 8 ký tự" autocomplete="new-password" required/>
            <button type="button" class="auth-toggle-pw" data-target="password"
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
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="23 4 23 10 17 10"/>
                <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
              </svg>
            </span>
            <input type="password" id="confirmPassword" name="confirmPassword"
                   class="auth-input auth-input--has-toggle"
                   placeholder="Nhập lại mật khẩu" autocomplete="new-password" required/>
            <button type="button" class="auth-toggle-pw" data-target="confirmPassword"
                    aria-label="Hiện hoặc ẩn xác nhận mật khẩu">
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

        <p class="auth-hint">Cần nhập ít nhất email hoặc số điện thoại. Có email sẽ gửi link xác thực.</p>

        <button type="submit" class="auth-btn-submit">
          Tạo tài khoản
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="5" y1="12" x2="19" y2="12"/>
            <polyline points="12 5 19 12 12 19"/>
          </svg>
        </button>
      </form>

      <%@ include file="/WEB-INF/views/auth/google-button.jsp" %>

      <p class="auth-footer-text">
        Đã có tài khoản?
        <a href="${pageContext.request.contextPath}/login" class="auth-link">Đăng nhập</a>
      </p>

      <a href="${pageContext.request.contextPath}/home" class="auth-back-home">← Về trang chủ</a>

    </div>
  </div>

  <script src="${pageContext.request.contextPath}/js/auth.js"></script>
</body>
</html>
