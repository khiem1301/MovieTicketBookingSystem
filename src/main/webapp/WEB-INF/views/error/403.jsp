<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<div class="error-page">
    <h1>403 — Không có quyền truy cập</h1>
    <p>Bạn không có quyền truy cập trang này.</p>
    <c:if test="${not empty requiredRole}">
        <p class="error-detail">Yêu cầu vai trò: <strong><c:out value="${requiredRole}"/></strong></p>
    </c:if>
    <a class="btn-link" href="${pageContext.request.contextPath}/">Về trang chủ</a>
</div>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
