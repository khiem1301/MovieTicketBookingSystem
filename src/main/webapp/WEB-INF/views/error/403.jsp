<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Không có quyền — ÉPCINE</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/error-pages.css"/>
</head>
<body class="error-page error-page--403">

  <div class="error-card">
    <div class="error-icon-wrap" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75"
           stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
        <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
        <circle cx="12" cy="16" r="1" fill="currentColor" stroke="none"/>
      </svg>
    </div>

    <div class="error-code">403</div>
    <h1 class="error-title">KHÔNG ĐỦ QUYỀN HẠN</h1>
    <p class="error-desc">
      Bạn không có quyền xem trang này. Vui lòng kiểm tra tài khoản hoặc liên hệ quản trị viên.
    </p>

    <div class="error-actions">
      <a href="${pageContext.request.contextPath}/home" class="error-btn error-btn--home">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <line x1="19" y1="12" x2="5" y2="12"/>
          <polyline points="12 19 5 12 12 5"/>
        </svg>
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
