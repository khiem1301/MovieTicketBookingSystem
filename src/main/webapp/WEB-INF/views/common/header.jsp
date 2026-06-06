<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title><c:out value="${pageTitle != null ? pageTitle : 'Movie Ticket Booking'}"/></title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
</head>
<body>
<header class="site-header">
    <div class="container site-header__inner">
        <a href="${pageContext.request.contextPath}/" class="logo">FPT Cinema</a>

        <nav class="site-nav">
            <c:choose>
                <c:when test="${not empty sessionScope.authUser}">
                    <span class="site-nav__user">
                        Xin chào, <c:out value="${sessionScope.authUser.fullName}"/>
                        <span class="site-nav__role">(<c:out value="${sessionScope.authRole}"/>)</span>
                    </span>

                    <c:choose>
                        <c:when test="${sessionScope.authRole == 'CUSTOMER'}">
                            <a href="${pageContext.request.contextPath}/">Trang chủ</a>
                            <a href="${pageContext.request.contextPath}/customer/profile">Tài khoản</a>
                            <a href="${pageContext.request.contextPath}/customer/bookings">Lịch sử đặt vé</a>
                            <a href="${pageContext.request.contextPath}/customer/points">Điểm tích lũy</a>
                        </c:when>
                        <c:when test="${sessionScope.authRole == 'STAFF'}">
                            <a href="${pageContext.request.contextPath}/staff/home">Quầy vé</a>
                        </c:when>
                        <c:when test="${sessionScope.authRole == 'MANAGER'}">
                            <a href="${pageContext.request.contextPath}/manager/home">Quản lý</a>
                        </c:when>
                        <c:when test="${sessionScope.authRole == 'ADMIN'}">
                            <a href="${pageContext.request.contextPath}/admin/home">Quản trị</a>
                        </c:when>
                    </c:choose>

                    <a href="${pageContext.request.contextPath}/change-password">Đổi mật khẩu</a>
                    <a href="${pageContext.request.contextPath}/logout" class="site-nav__logout">Đăng xuất</a>
                </c:when>
                <c:otherwise>
                    <a href="${pageContext.request.contextPath}/login">Đăng nhập</a>
                    <a href="${pageContext.request.contextPath}/register">Đăng ký</a>
                </c:otherwise>
            </c:choose>
        </nav>
    </div>
</header>
<main class="site-main container">
