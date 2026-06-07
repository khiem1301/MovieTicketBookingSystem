<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Tạo tài khoản — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <nav class="admin-breadcrumb">
      <a href="${pageContext.request.contextPath}/admin/dashboard">Bảng điều khiển</a>
      <span class="admin-breadcrumb-sep">/</span>
      <a href="${pageContext.request.contextPath}/admin/users">Người dùng</a>
      <span class="admin-breadcrumb-sep">/</span>
      <span>Tạo mới</span>
    </nav>

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Tạo tài khoản mới</h1>
        <p class="admin-page-subtitle">Chỉ tạo được tài khoản Staff hoặc Manager</p>
      </div>
    </div>

    <c:if test="${not empty errors}">
      <div class="admin-alert admin-alert--error" role="alert">
        <ul style="margin:0;padding-left:18px;">
          <c:forEach var="err" items="${errors}">
            <li><c:out value="${err}"/></li>
          </c:forEach>
        </ul>
      </div>
    </c:if>

    <div class="admin-card">
      <form class="admin-form" method="post"
            action="${pageContext.request.contextPath}/admin/users/create" novalidate>

        <div class="admin-field">
          <label class="admin-label" for="fullName">Họ và tên *</label>
          <input type="text" id="fullName" name="fullName" class="admin-input" required
                 value="<c:out value='${form.fullName}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="dateOfBirth">Ngày sinh *</label>
          <c:if test="${not empty form.dateOfBirth}">
            <fmt:formatDate value="${form.dateOfBirth}" pattern="yyyy-MM-dd" var="dobValue"/>
          </c:if>
          <input type="date" id="dateOfBirth" name="dateOfBirth" class="admin-input" required
                 value="<c:out value='${dobValue}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="roleName">Vai trò *</label>
          <select id="roleName" name="roleName" class="admin-select" required>
            <option value="">— Chọn vai trò —</option>
            <c:forEach var="role" items="${assignableRoles}">
              <option value="${role.roleName}"
                      <c:if test="${form.roleName == role.roleName}">selected</c:if>>
                <c:out value="${role.roleName}"/> — <c:out value="${role.description}"/>
              </option>
            </c:forEach>
          </select>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="email">Email</label>
          <input type="email" id="email" name="email" class="admin-input"
                 placeholder="email@example.com"
                 value="<c:out value='${form.email}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="username">Tên đăng nhập</label>
          <input type="text" id="username" name="username" class="admin-input"
                 placeholder="username"
                 value="<c:out value='${form.username}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="phoneNumber">Số điện thoại</label>
          <input type="text" id="phoneNumber" name="phoneNumber" class="admin-input"
                 placeholder="09xxxxxxxx"
                 value="<c:out value='${form.phoneNumber}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="password">Mật khẩu *</label>
          <input type="password" id="password" name="password" class="admin-input"
                 placeholder="Tối thiểu 8 ký tự" minlength="8" required/>
        </div>

        <p style="font-size:12px;color:var(--text-dim);margin-top:-8px;">
          * Cần ít nhất một trong: email, tên đăng nhập hoặc số điện thoại.
        </p>

        <div class="admin-form-actions">
          <button type="submit" class="admin-btn admin-btn--primary">Tạo tài khoản</button>
          <a href="${pageContext.request.contextPath}/admin/users" class="admin-btn admin-btn--ghost">Hủy</a>
        </div>
      </form>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
