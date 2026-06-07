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
        Đăng ký thành công!
      </div>

      <c:choose>
        <c:when test="${param.sent == '1'}">
          <p class="auth-pending-text">
            Chúng tôi đã gửi email xác thực đến
            <strong><c:out value="${param.email}"/></strong>.
            Vui lòng kiểm tra hộp thư (và thư mục spam) trong vòng 24 giờ.
          </p>
        </c:when>
        <c:otherwise>
          <p class="auth-pending-text">
            Tài khoản đã được tạo với email
            <strong><c:out value="${param.email}"/></strong>,
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
        Sau khi xác thực, bạn có thể đăng nhập bằng email và mật khẩu vừa tạo.
      </p>

      <a href="${pageContext.request.contextPath}/login" class="auth-btn-submit" style="text-align:center;display:flex;justify-content:center;">
        Đến trang đăng nhập
      </a>

      <a href="${pageContext.request.contextPath}/home" class="auth-back-home">← Về trang chủ</a>

    </div>
  </div>

</body>
</html>
