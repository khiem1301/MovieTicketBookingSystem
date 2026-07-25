<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Xác thực email — ÉPCINE</title>
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

      <div class="auth-alert auth-alert--success" role="status">
        Đã nhận yêu cầu đăng ký!
      </div>

      <c:choose>
        <c:when test="${param.sent == '1'}">
          <p class="auth-pending-text">
            Chúng tôi đã gửi email xác thực đến
            <strong><c:out value="${param.email}"/></strong>.
            Vui lòng kiểm tra hộp thư (và thư mục spam) trong vòng 1 phút để hoàn tất đăng ký (đang test hết hạn).
          </p>
        </c:when>
        <c:otherwise>
          <p class="auth-pending-text">
            Yêu cầu đăng ký với email
            <strong><c:out value="${param.email}"/></strong> đã được ghi nhận,
            nhưng hệ thống chưa gửi được email (chưa cấu hình SMTP).
          </p>
          <c:if test="${not empty param.devLink}">
            <p class="auth-pending-text auth-pending-text--dev">
              Link xác thực (dev):
              <a href="<c:out value='${param.devLink}'/>" class="auth-link">
                <c:out value="${param.devLink}"/>
              </a>
            </p>
          </c:if>
        </c:otherwise>
      </c:choose>

      <p class="auth-pending-text">
        Tài khoản chỉ được tạo sau khi bạn xác thực email.
        Nếu link hết hạn, bạn có thể <a href="${pageContext.request.contextPath}/register" class="auth-link">đăng ký lại</a>.
      </p>

      <a href="${pageContext.request.contextPath}/login" class="auth-btn-submit" style="text-align:center;display:flex;justify-content:center;">
        Đến trang đăng nhập
      </a>

    </div>
  </div>

  <script charset="UTF-8" src="${pageContext.request.contextPath}/js/flash-alerts.js?v=2"></script>
</body>
</html>
