<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="pageTitle" value="Không tìm thấy vé — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="container" style="max-width:480px;margin:48px auto;padding:0 16px;text-align:center">
  <h1 style="font-size:1.4rem;margin-bottom:12px">Không tìm thấy vé</h1>
  <p style="color:#888;margin-bottom:24px">
    Mã vé không hợp lệ, đơn chưa thanh toán, hoặc bạn không phải người đặt vé này.
    Hãy đăng nhập đúng tài khoản đã đặt để xem vé.
  </p>
  <a href="${pageContext.request.contextPath}/home" class="btn btn-primary">Về trang chủ</a>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
