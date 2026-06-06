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
    <div class="container">
        <a href="${pageContext.request.contextPath}/" class="logo">FPT Cinema</a>
        <nav><!-- menu theo role --></nav>
    </div>
</header>
<main class="site-main container">
