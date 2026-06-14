<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<div class="auth-divider"><span>hoặc</span></div>
<c:url var="googleUrl" value="/auth/google">
  <c:if test="${not empty googleRedirect}">
    <c:param name="redirect" value="${googleRedirect}"/>
  </c:if>
</c:url>
<a href="${googleUrl}" class="auth-btn-google">
  <svg class="auth-btn-google__icon" width="18" height="18" viewBox="0 0 48 48" aria-hidden="true">
    <path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303C33.654 32.657 29.083 36 24 36c-5.523 0-10-4.477-10-10s4.477-10 10-10c2.837 0 5.402 1.193 7.227 3.104l5.657-5.657C33.64 6.053 28.991 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>
    <path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c2.837 0 5.402 1.193 7.227 3.104l5.657-5.657C33.64 6.053 28.991 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>
    <path fill="#4CAF50" d="M24 44c4.991 0 9.606-1.708 13.174-4.572l-6.08-5.085C29.13 35.091 26.715 36 24 36c-5.453 0-10.01-3.657-11.62-8.623l-6.57 5.07C9.63 39.556 16.318 44 24 44z"/>
    <path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303c-1.014 2.828-3.003 5.176-5.629 6.657l6.08 5.085C39.89 36.396 44 30.638 44 24c0-1.341-.138-2.65-.389-3.917z"/>
  </svg>
  Đăng nhập bằng Google
</a>
