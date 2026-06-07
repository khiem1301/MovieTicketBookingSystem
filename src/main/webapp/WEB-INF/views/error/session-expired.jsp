<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Phiên hết hạn — ÉPCINE</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/error-pages.css"/>
</head>
<body class="error-page">

  <div class="error-card">
    <div class="error-icon-wrap" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
           stroke-linecap="round" stroke-linejoin="round">
        <rect x="5" y="11" width="14" height="10" rx="2"/>
        <path d="M8 11V8a4 4 0 0 1 8 0v3"/>
      </svg>
    </div>

    <h1 class="error-title">Phiên đăng nhập đã hết hạn</h1>
    <p class="error-desc">
      Phiên làm việc của bạn đã hết hạn vì lý do bảo mật.
      Vui lòng đăng nhập lại để tiếp tục.
    </p>

    <div class="error-actions">
      <c:url var="loginUrl" value="/login">
        <c:if test="${not empty param.redirect}">
          <c:param name="redirect" value="${param.redirect}"/>
        </c:if>
      </c:url>
      <a href="${loginUrl}" class="error-btn error-btn--primary">
        Đăng nhập ngay
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="5" y1="12" x2="19" y2="12"/>
          <polyline points="12 5 19 12 12 19"/>
        </svg>
      </a>
      <a href="${pageContext.request.contextPath}/home" class="error-btn error-btn--ghost">
        Về trang chủ
      </a>
    </div>
  </div>

</body>
</html>
