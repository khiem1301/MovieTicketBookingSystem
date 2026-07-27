<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>

<c:set var="pageTitle" value="Không tìm thấy đơn — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="container" style="max-width:520px;margin:48px auto;padding:0 16px;text-align:center">
  <h1 style="font-size:1.4rem;margin-bottom:12px;color:#f5f2f1">Không xem được đơn này</h1>
  <p style="color:#aaa;margin-bottom:24px;line-height:1.55">
    Đơn không tồn tại, chưa thanh toán thành công, hoặc không thuộc tài khoản đang đăng nhập.
  </p>
  <a href="${pageContext.request.contextPath}/booking-history" class="btn btn-primary"
     style="display:inline-flex;margin-bottom:12px">Về lịch sử đặt vé</a>
  <br/>
  <a href="${pageContext.request.contextPath}/home" style="color:#e9bcb6;font-size:14px">Về trang chủ</a>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
