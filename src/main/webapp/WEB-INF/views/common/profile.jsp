<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<c:set var="pageTitle" value="Tài khoản — ÉPCINE"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<link rel="stylesheet" href="${ctx}/css/profile.css"/>

<main class="profile-page container">
  <c:if test="${param.saved == '1'}">
    <div class="profile-alert profile-alert--success" role="status">
      Đã cập nhật thông tin tài khoản thành công.
    </div>
  </c:if>
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
  <c:if test="${not empty profileErrors}">
    <div class="profile-alert profile-alert--error" role="alert">
      <c:forEach var="err" items="${profileErrors}">
        <div><c:out value="${err}"/></div>
      </c:forEach>
    </div>
  </c:if>
  <c:if test="${not empty passwordChangeErrors}">
    <div class="profile-alert profile-alert--error" role="alert">
      <c:forEach var="err" items="${passwordChangeErrors}">
        <div><c:out value="${err}"/></div>
      </c:forEach>
    </div>
  </c:if>

  <div class="profile-layout">
    <aside class="profile-sidebar">
      <div class="profile-avatar-wrap" id="profile-avatar-wrap"
           data-msg-type="Ảnh đại diện phải là JPG hoặc PNG."
           data-msg-size="Ảnh đại diện không được vượt quá 1 MB.">
        <label class="profile-avatar-upload" title="Chọn ảnh đại diện">
          <c:choose>
            <c:when test="${not empty avatarPublicUrl}">
              <img id="profile-avatar-preview" class="profile-avatar-lg" src="<c:out value='${avatarPublicUrl}'/>" alt="Avatar"/>
            </c:when>
            <c:otherwise>
              <div id="profile-avatar-preview" class="profile-avatar-lg profile-avatar-lg--placeholder" aria-hidden="true">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
                  <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                  <circle cx="12" cy="7" r="4"/>
                </svg>
              </div>
            </c:otherwise>
          </c:choose>
          <input type="file" id="avatar" name="avatar" form="profileForm"
                 class="profile-avatar-input" accept=".jpg,.jpeg,.png,image/jpeg,image/png"/>
        </label>
        <p class="profile-avatar-hint">JPG hoặc PNG, tối đa 1 MB</p>
        <p id="profile-avatar-error" class="profile-avatar-error" role="alert" hidden></p>
      </div>

      <h1 class="profile-sidebar-name"><c:out value="${user.fullName}"/></h1>

      <p class="profile-sidebar-badge">
        <c:choose>
          <c:when test="${user.roleName == 'CUSTOMER' && user.loyaltyPoints >= 10000}">THÀNH VIÊN VIP</c:when>
          <c:when test="${user.roleName == 'CUSTOMER'}">THÀNH VIÊN ÉPCINE</c:when>
          <c:when test="${user.roleName == 'MANAGER'}">QUẢN LÝ RẠP</c:when>
          <c:when test="${user.roleName == 'STAFF'}">NHÂN VIÊN</c:when>
          <c:when test="${user.roleName == 'ADMIN'}">QUẢN TRỊ</c:when>
          <c:otherwise><c:out value="${user.roleName}"/></c:otherwise>
        </c:choose>
      </p>

      <div class="profile-stats-grid">
        <a href="${ctx}/booking-history" class="profile-stat profile-stat--link">
          <span class="profile-stat-value"><c:out value="${bookingCount}"/></span>
          <span class="profile-stat-label">Tổng vé đã đặt</span>
        </a>
        <a href="${ctx}/loyalty" class="profile-stat profile-stat--link">
          <c:choose>
            <c:when test="${user.roleName == 'CUSTOMER'}">
              <span class="profile-stat-value profile-stat-value--accent">
                <c:choose>
                  <c:when test="${user.loyaltyPoints >= 1000}">
                    <fmt:formatNumber value="${user.loyaltyPoints / 1000}" maxFractionDigits="1"/>K
                  </c:when>
                  <c:otherwise><c:out value="${user.loyaltyPoints}"/></c:otherwise>
                </c:choose>
              </span>
            </c:when>
            <c:otherwise>
              <span class="profile-stat-value profile-stat-value--accent">—</span>
            </c:otherwise>
          </c:choose>
          <span class="profile-stat-label">Điểm thưởng</span>
        </a>
      </div>
    </aside>

    <div class="profile-content">
      <section class="profile-card profile-card--details">
        <header class="profile-card-header">
          <span class="profile-card-icon" aria-hidden="true">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
              <circle cx="12" cy="7" r="4"/>
            </svg>
          </span>
          <h2 class="profile-card-title">Thông tin cá nhân</h2>
        </header>

        <form id="profileForm" class="profile-form profile-form--grid" action="${ctx}/profile" method="post" enctype="multipart/form-data" novalidate>
          <div class="profile-field">
            <label for="fullName">Họ và tên</label>
            <input type="text" id="fullName" name="fullName" required
                   value="<c:out value='${user.fullName}'/>" autocomplete="name"/>
          </div>
          <div class="profile-field">
            <label for="email">Email</label>
            <input type="email" id="email" class="profile-input--readonly" readonly
                   value="<c:out value='${user.email}'/>" aria-readonly="true"/>
          </div>
          <div class="profile-field profile-field--full">
            <label for="phoneNumber">Số điện thoại</label>
            <input type="tel" id="phoneNumber" name="phoneNumber" required
                   value="<c:out value='${user.phoneNumber}'/>" autocomplete="tel"
                   placeholder="0901234567" inputmode="numeric"
                   pattern="(\+84|0)[0-9]{9}" title="10 chữ số, VD: 0901234567"/>
          </div>
          <div class="profile-field">
            <label for="username">Tên đăng nhập</label>
            <input type="text" id="username" name="username" required
                   value="<c:out value='${user.username}'/>" autocomplete="username"
                   pattern="[a-zA-Z0-9_]{3,100}" title="3–100 ký tự chữ, số hoặc dấu gạch dưới"/>
            <p class="profile-field-hint">Chỉ chữ, số và dấu gạch dưới (3–100 ký tự).</p>
          </div>
          <div class="profile-field">
            <label for="dateOfBirth">Ngày sinh</label>
            <input type="text" id="dateOfBirth" class="profile-input--readonly" readonly
                   value="<fmt:formatDate value='${user.dateOfBirth}' pattern='dd/MM/yyyy'/>"
                   aria-readonly="true"/>
            <p class="profile-field-hint">Ngày sinh không thể thay đổi tại đây.</p>
          </div>
          <div class="profile-form-actions profile-field--full">
            <button type="submit" class="profile-btn profile-btn--primary">Lưu thay đổi</button>
          </div>
        </form>
      </section>

      <div class="profile-cards-row">
        <%@ include file="/WEB-INF/views/common/profile-security.jspf" %>

        <section class="profile-card profile-card--preferences" aria-labelledby="preferences-heading">
          <header class="profile-card-header">
            <span class="profile-card-icon" aria-hidden="true">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
              </svg>
            </span>
            <h2 class="profile-card-title" id="preferences-heading">Sở thích</h2>
          </header>
          <p class="profile-preferences-lead">
            Chọn thể loại phim yêu thích để nhận gợi ý phù hợp hơn.
          </p>
          <div class="profile-tag-cloud" aria-hidden="true">
            <span class="profile-tag profile-tag--active">Hành động</span>
            <span class="profile-tag profile-tag--active">Khoa học viễn tưởng</span>
            <span class="profile-tag profile-tag--active">Giật gân</span>
            <span class="profile-tag">Tâm lý</span>
            <span class="profile-tag">Hài</span>
            <span class="profile-tag profile-tag--disabled">+ Thêm</span>
          </div>
          <p class="profile-coming-soon">Tính năng sắp ra mắt</p>
        </section>
      </div>
    </div>
  </div>
</main>

<script charset="UTF-8" src="${ctx}/js/profile.js"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>

