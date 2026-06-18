<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Xác minh bảo mật — ÉPCINE"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<link rel="stylesheet" href="${ctx}/css/profile.css"/>

<main class="profile-page container profile-page--narrow">
  <h1 class="profile-title">Xác minh tài khoản</h1>
  <p class="profile-lead">
    Chọn một trong hai cách để xác minh danh tính trước khi đổi mật khẩu.
    Tài khoản đăng ký bằng Google nên dùng xác minh qua email.
  </p>

  <c:if test="${param.error == 'invalid'}">
    <div class="profile-alert profile-alert--error" role="alert">
      Liên kết xác minh không hợp lệ hoặc đã hết hạn.
    </div>
  </c:if>
  <c:if test="${param.error == 'mismatch'}">
    <div class="profile-alert profile-alert--error" role="alert">
      Liên kết không khớp với tài khoản đang đăng nhập. Vui lòng đăng nhập đúng tài khoản.
    </div>
  </c:if>
  <c:if test="${param.error == 'server'}">
    <div class="profile-alert profile-alert--error" role="alert">
      Không thể xác minh. Vui lòng thử lại sau.
    </div>
  </c:if>
  <c:if test="${not empty errorMessage}">
    <div class="profile-alert profile-alert--error" role="alert">
      <c:out value="${errorMessage}"/>
    </div>
  </c:if>
  <c:if test="${not empty infoMessage}">
    <div class="profile-alert profile-alert--success" role="status">
      <c:out value="${infoMessage}"/>
    </div>
  </c:if>

  <div class="profile-tabs" role="tablist">
    <a href="#tab-password"
       class="profile-tab ${activeTab == 'password' ? 'profile-tab--active' : ''}"
       data-tab="password">Mật khẩu hiện tại</a>
    <a href="#tab-email"
       class="profile-tab ${activeTab == 'email' ? 'profile-tab--active' : ''}"
       data-tab="email">Xác minh qua email</a>
  </div>

  <section id="tab-password"
           class="profile-card profile-tab-panel ${activeTab == 'password' ? 'profile-tab-panel--active' : ''}">
    <h2 class="profile-card-title">Nhập mật khẩu hiện tại</h2>
    <form class="profile-form" action="${ctx}/profile/security-verify" method="post" novalidate>
      <input type="hidden" name="method" value="password"/>
      <div class="profile-field">
        <label for="currentPassword">Mật khẩu hiện tại</label>
        <input type="password" id="currentPassword" name="currentPassword"
               autocomplete="current-password" required/>
      </div>
      <button type="submit" class="profile-btn profile-btn--primary">Xác minh</button>
    </form>
  </section>

  <section id="tab-email"
           class="profile-card profile-tab-panel ${activeTab == 'email' ? 'profile-tab-panel--active' : ''}">
    <h2 class="profile-card-title">Gửi link xác minh</h2>
    <p class="profile-security-hint">
      Chúng tôi sẽ gửi link xác minh đến
      <strong><c:out value="${userEmail}"/></strong>
      (hiệu lực 15 phút). Mở link trên cùng trình duyệt đang đăng nhập.
    </p>
    <form class="profile-form" action="${ctx}/profile/security-verify" method="post">
      <input type="hidden" name="method" value="email"/>
      <button type="submit" class="profile-btn profile-btn--primary">Gửi email xác minh</button>
    </form>
  </section>

  <p class="profile-back">
    <a href="${ctx}/profile">← Quay lại tài khoản</a>
  </p>
</main>

<script charset="UTF-8">
  (function () {
    var tabs = document.querySelectorAll('.profile-tab');
    var panels = document.querySelectorAll('.profile-tab-panel');
    tabs.forEach(function (tab) {
      tab.addEventListener('click', function (e) {
        e.preventDefault();
        var name = tab.getAttribute('data-tab');
        tabs.forEach(function (t) { t.classList.remove('profile-tab--active'); });
        panels.forEach(function (p) { p.classList.remove('profile-tab-panel--active'); });
        tab.classList.add('profile-tab--active');
        var panel = document.getElementById('tab-' + name);
        if (panel) panel.classList.add('profile-tab-panel--active');
      });
    });
  })();
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
