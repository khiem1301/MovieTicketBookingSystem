<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title><c:out value="${pageTitle != null ? pageTitle : 'Đăng nhập — CineReserve'}"/></title>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet"/>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/auth.css"/>
</head>
<body class="auth-page">
<div class="auth-bg"></div>

<div class="auth-wrapper">
    <div class="auth-card">
        <h1 class="auth-brand">CINERESERVE</h1>

        <c:if test="${not empty errorMessage}">
            <div class="auth-alert" role="alert">
                <c:out value="${errorMessage}"/>
            </div>
        </c:if>

        <c:if test="${param.verified == '1'}">
            <div class="auth-alert auth-alert--success" role="status">
                Email đã được xác thực. Bạn có thể đăng nhập.
            </div>
        </c:if>

        <form class="auth-form" method="post" action="${pageContext.request.contextPath}/login" novalidate>
            <c:set var="redirectValue" value="${not empty redirect ? redirect : param.redirect}"/>
            <c:if test="${not empty redirectValue}">
                <input type="hidden" name="redirect" value="<c:out value='${redirectValue}'/>"/>
            </c:if>

            <div class="auth-field">
                <label class="auth-label" for="identifier">Email or Username</label>
                <div class="auth-input-wrap">
                    <span class="auth-input-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <path d="M20 21a8 8 0 0 0-16 0"/>
                            <circle cx="12" cy="8" r="4"/>
                        </svg>
                    </span>
                    <input class="auth-input"
                           type="text"
                           id="identifier"
                           name="identifier"
                           placeholder="director@studio.com"
                           value="<c:out value='${identifier}'/>"
                           autocomplete="username"
                           required/>
                </div>
            </div>

            <div class="auth-field">
                <div class="auth-label-row">
                    <label class="auth-label" for="password">Password</label>
                    <a class="auth-link" href="${pageContext.request.contextPath}/forgot-password">Forgot Password?</a>
                </div>
                <div class="auth-input-wrap">
                    <span class="auth-input-icon" aria-hidden="true">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <rect x="5" y="11" width="14" height="10" rx="2"/>
                            <path d="M8 11V8a4 4 0 0 1 8 0v3"/>
                        </svg>
                    </span>
                    <input class="auth-input auth-input--password"
                           type="password"
                           id="password"
                           name="password"
                           placeholder="••••••••"
                           autocomplete="current-password"
                           required/>
                    <button class="auth-toggle-password" type="button" aria-label="Hiện mật khẩu" data-toggle-password>
                        <svg class="icon-eye" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7-10-7-10-7Z"/>
                            <circle cx="12" cy="12" r="3"/>
                        </svg>
                        <svg class="icon-eye-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <path d="M10.7 10.7a3 3 0 0 0 4.2 4.2"/>
                            <path d="M6.7 6.7C4.6 8.3 3 10.3 2 12s4 7 10 7c1.8 0 3.5-.4 5-1.1"/>
                            <path d="M17.3 17.3C19.4 15.7 21 13.7 22 12s-4-7-10-7c-1.8 0-3.5.4-5 1.1"/>
                            <path d="m2 2 20 20"/>
                        </svg>
                    </button>
                </div>
            </div>

            <label class="auth-remember">
                <input type="checkbox" name="rememberMe" <c:if test="${rememberMe}">checked</c:if>/>
                <span>Remember Me</span>
            </label>

            <button class="auth-btn auth-btn--primary" type="submit">Login</button>
        </form>

        <button class="auth-btn auth-btn--google" type="button" disabled title="Chức năng đang phát triển">
            <svg viewBox="0 0 24 24" aria-hidden="true">
                <path fill="#EA4335" d="M12 10.2v3.6h5.1c-.2 1.2-1.6 3.6-5.1 3.6-3.1 0-5.6-2.5-5.6-5.6S8.9 6.2 12 6.2c1.8 0 3 .8 3.7 1.4l2.5-2.4C16.8 3.6 14.6 2.6 12 2.6 6.9 2.6 2.6 6.9 2.6 12s4.3 9.4 9.4 9.4c5.4 0 9-3.8 9-9.2 0-.6-.1-1.1-.2-1.6H12z"/>
            </svg>
        </button>

        <p class="auth-footer-text">
            New to CineReserve?
            <a class="auth-link auth-link--bold" href="${pageContext.request.contextPath}/register">Register</a>
        </p>
    </div>
</div>

<script src="${pageContext.request.contextPath}/js/auth.js"></script>
</body>
</html>
