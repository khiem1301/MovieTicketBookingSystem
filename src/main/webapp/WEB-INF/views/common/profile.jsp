<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Tài khoản — ÉPCINE"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<link rel="stylesheet" href="${ctx}/css/profile.css"/>

<main class="profile-page container">
  <h1 class="profile-title">Tài khoản của tôi</h1>

  <c:if test="${param.security == 'verified'}">
    <div class="profile-alert profile-alert--success" role="status">
      Xác minh thành công. Bạn có thể đổi mật khẩu trong vòng 15 phút.
    </div>
  </c:if>
  <c:if test="${param.security == 'required'}">
    <div class="profile-alert profile-alert--warn" role="alert">
      Vui lòng xác minh tài khoản trước khi đổi mật khẩu.
    </div>
  </c:if>
  <c:if test="${param.password == 'changed'}">
    <div class="profile-alert profile-alert--success" role="status">
      Mật khẩu đã được cập nhật thành công.
    </div>
  </c:if>
  <c:if test="${not empty passwordChangeErrors}">
    <div class="profile-alert profile-alert--error" role="alert">
      <c:forEach var="err" items="${passwordChangeErrors}">
        <div><c:out value="${err}"/></div>
      </c:forEach>
    </div>
  </c:if>

  <section class="profile-card">
    <h2 class="profile-card-title">Thông tin cơ bản</h2>
    <dl class="profile-dl">
      <div class="profile-dl-row">
        <dt>Họ và tên</dt>
        <dd><c:out value="${user.fullName}"/></dd>
      </div>
      <div class="profile-dl-row">
        <dt>Email</dt>
        <dd><c:out value="${user.email}"/></dd>
      </div>
      <div class="profile-dl-row">
        <dt>Tên đăng nhập</dt>
        <dd><c:out value="${user.username}"/></dd>
      </div>
      <div class="profile-dl-row">
        <dt>Số điện thoại</dt>
        <dd><c:out value="${user.phoneNumber}"/></dd>
      </div>
    </dl>
    <p class="profile-note">Chỉnh sửa thông tin cá nhân sẽ có trong FR-05.</p>
  </section>

  <%@ include file="/WEB-INF/views/common/profile-security.jspf" %>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
