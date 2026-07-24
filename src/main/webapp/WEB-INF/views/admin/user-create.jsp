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
                 maxlength="255"
                 value="<c:out value='${form.fullName}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label">Ngày sinh *</label>
          <div class="admin-dob-row">
            <select id="dobDay" name="dobDay" class="admin-select" required aria-label="Ngày">
              <option value="">Ngày</option>
              <c:forEach begin="1" end="31" var="d">
                <option value="${d}" <c:if test="${form.dobDay == d}">selected</c:if>>${d}</option>
              </c:forEach>
            </select>
            <select id="dobMonth" name="dobMonth" class="admin-select" required aria-label="Tháng">
              <option value="">Tháng</option>
              <c:forEach begin="1" end="12" var="m">
                <option value="${m}" <c:if test="${form.dobMonth == m}">selected</c:if>>${m}</option>
              </c:forEach>
            </select>
            <select id="dobYear" name="dobYear" class="admin-select" required aria-label="Năm">
              <option value="">Năm</option>
              <c:forEach begin="0" end="100" var="i">
                <c:set var="y" value="${currentYear - i}"/>
                <option value="${y}" <c:if test="${form.dobYear == y}">selected</c:if>>${y}</option>
              </c:forEach>
            </select>
          </div>
          <p class="admin-field-hint">Định dạng ngày — tháng — năm</p>
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
          <label class="admin-label" for="email">Email *</label>
          <input type="email" id="email" name="email" class="admin-input" required
                 maxlength="255"
                 placeholder="email@example.com"
                 value="<c:out value='${form.email}'/>"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="username">Tên đăng nhập *</label>
          <input type="text" id="username" name="username" class="admin-input" required
                 maxlength="100" minlength="3"
                 pattern="[a-zA-Z0-9_]{3,100}"
                 placeholder="username"
                 value="<c:out value='${form.username}'/>"/>
          <p class="admin-field-hint">3–100 ký tự: chữ, số hoặc dấu gạch dưới</p>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="phoneNumber">Số điện thoại *</label>
          <input type="tel" id="phoneNumber" name="phoneNumber" class="admin-input" required
                 inputmode="numeric" maxlength="10" pattern="0[0-9]{9}"
                 placeholder="0901234567"
                 value="<c:out value='${form.phoneNumber}'/>"/>
          <p class="admin-field-hint">Đúng 10 chữ số, bắt đầu bằng 0</p>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="password">Mật khẩu *</label>
          <div class="admin-input-wrap">
            <input type="password" id="password" name="password"
                   class="admin-input admin-input--has-toggle" required
                   minlength="8" maxlength="16"
                   placeholder="<c:out value='${passwordHint}'/>"
                   autocomplete="new-password"/>
            <button type="button" class="admin-toggle-pw" data-target="password"
                    aria-label="Hiện hoặc ẩn mật khẩu">
              <svg class="icon-eye" width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                <circle cx="12" cy="12" r="3"/>
              </svg>
              <svg class="icon-eye-off" width="18" height="18" viewBox="0 0 24 24" fill="none"
                   stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                   style="display:none">
                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/>
                <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/>
                <line x1="1" y1="1" x2="23" y2="23"/>
              </svg>
            </button>
          </div>
          <p class="admin-field-hint"><c:out value="${passwordHint}"/></p>
        </div>

        <div class="admin-form-actions">
          <button type="submit" class="admin-btn admin-btn--primary">Tạo tài khoản</button>
          <a href="${pageContext.request.contextPath}/admin/users" class="admin-btn admin-btn--ghost">Hủy</a>
        </div>
      </form>
    </div>

  </div>
</main>

<script>
(function () {
  'use strict';

  var phone = document.getElementById('phoneNumber');
  if (phone) {
    phone.addEventListener('input', function () {
      this.value = this.value.replace(/\D/g, '').slice(0, 10);
    });
  }

  document.querySelectorAll('.admin-toggle-pw').forEach(function (btn) {
    btn.addEventListener('click', function (e) {
      e.preventDefault();
      var input = document.getElementById(btn.getAttribute('data-target') || 'password');
      if (!input) return;
      var show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      var eye = btn.querySelector('.icon-eye');
      var eyeOff = btn.querySelector('.icon-eye-off');
      if (eye) eye.style.display = show ? 'none' : '';
      if (eyeOff) eyeOff.style.display = show ? '' : 'none';
      input.focus();
    });
  });
}());
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
