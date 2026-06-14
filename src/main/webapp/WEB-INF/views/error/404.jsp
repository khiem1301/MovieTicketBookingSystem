<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Không tìm thấy trang — ÉPCINE</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/error-pages.css"/>
</head>
<body class="error-page error-page--404">

  <div class="error-card">
    <div class="error-icon-wrap" aria-hidden="true">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75"
           stroke-linecap="round" stroke-linejoin="round">
        <circle cx="11" cy="11" r="7"/>
        <line x1="16.5" y1="16.5" x2="21" y2="21"/>
        <path d="M9.5 10.5a2 2 0 0 1 3 2.5"/>
        <circle cx="11" cy="9" r="0.5" fill="currentColor" stroke="none"/>
      </svg>
    </div>

    <div class="error-code">404</div>
    <h1 class="error-title">KHÔNG TÌM THẤY TRANG</h1>
    <p class="error-desc">
      Đường dẫn bạn truy cập không tồn tại.
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
  </div>

</body>
</html>
