<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>403 — Không có quyền — ÉPCINE</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/error-pages.css"/>
</head>
<body class="error-page error-page--403">

  <div class="error-card">
    <div class="error-icon-wrap" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
           stroke-linecap="round" stroke-linejoin="round">
        <circle cx="12" cy="12" r="9"/>
        <line x1="5.5" y1="5.5" x2="18.5" y2="18.5"/>
      </svg>
    </div>

    <div class="error-code">403</div>
    <h1 class="error-title">Không có quyền truy cập</h1>
    <p class="error-desc">
      Bạn không có quyền truy cập trang này.
      Vui lòng kiểm tra tài khoản hoặc liên hệ quản trị viên rạp.
    </p>

    <div class="error-actions">
      <button type="button" class="error-btn error-btn--primary" onclick="history.back()">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"/>
          <polyline points="12 19 5 12 12 5"/>
        </svg>
        Quay lại
      </button>
      <a href="${pageContext.request.contextPath}/home" class="error-btn error-btn--ghost">
        Về trang chủ
      </a>
    </div>

    <c:if test="${not empty requestedPath}">
      <p class="error-path">
        Đường dẫn: <c:out value="${requestedPath}"/>
      </p>
    </c:if>
  </div>

</body>
</html>
