<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Hoàn tất đăng ký Google — ÉPCINE</title>
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
      <p class="auth-subtitle">Hoàn tất tài khoản Google</p>

      <c:if test="${not empty errors}">
        <div class="auth-alert auth-alert--error" role="alert">
          <c:forEach var="err" items="${errors}">
            <div><c:out value="${err}"/></div>
          </c:forEach>
        </div>
      </c:if>

      <div class="auth-google-profile">
        <c:if test="${not empty pending.picture}">
          <img src="<c:out value='${pending.picture}'/>" alt="" class="auth-google-profile__avatar"/>
        </c:if>
        <div>
          <div class="auth-google-profile__name"><c:out value="${pending.name}"/></div>
          <div class="auth-google-profile__email"><c:out value="${pending.email}"/></div>
        </div>
      </div>

      <form class="auth-form" action="${pageContext.request.contextPath}/register/google-complete" method="post">
        <div class="auth-field">
          <label class="auth-label" for="dateOfBirth">Ngày sinh <span style="color:var(--accent)">*</span></label>
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
                   value="<c:out value='${dateOfBirth}'/>" required/>
          </div>
        </div>

        <div class="auth-field">
          <label class="auth-label" for="phoneNumber">Số điện thoại (tùy chọn)</label>
          <div class="auth-input-wrap">
            <span class="auth-input-icon" aria-hidden="true">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.12.81.3 1.6.57 2.34a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.74-1.14a2 2 0 0 1 2.11-.45c.74.27 1.53.45 2.34.57A2 2 0 0 1 22 16.92z"/>
              </svg>
            </span>
            <input type="tel" id="phoneNumber" name="phoneNumber" class="auth-input"
                   placeholder="0901234567" value="<c:out value='${phoneNumber}'/>"/>
          </div>
        </div>

        <p class="auth-hint">Ngày sinh bắt buộc để đặt vé phim có giới hạn độ tuổi (FR-01).</p>

        <button type="submit" class="auth-btn-submit">Hoàn tất và vào hệ thống</button>
      </form>

      <a href="${pageContext.request.contextPath}/login" class="auth-back-home">← Quay lại đăng nhập</a>
    </div>
  </div>

</body>
</html>
