<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%-- Redirect về servlet /home (sẽ tạo sau) --%>
<% response.sendRedirect(request.getContextPath() + "/home"); %>
