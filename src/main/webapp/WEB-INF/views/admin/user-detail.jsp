<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Chi tiết người dùng — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <nav class="admin-breadcrumb">
      <a href="${pageContext.request.contextPath}/admin/dashboard">Bảng điều khiển</a>
      <span class="admin-breadcrumb-sep">/</span>
      <a href="${pageContext.request.contextPath}/admin/users">Người dùng</a>
      <span class="admin-breadcrumb-sep">/</span>
      <span>Chi tiết</span>
    </nav>

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title"><c:out value="${user.fullName}"/></h1>
        <p class="admin-page-subtitle">
          <span class="admin-badge admin-badge--role"><c:out value="${user.roleName}"/></span>
          &nbsp;
          <c:choose>
            <c:when test="${user.status == 'ACTIVE'}">
              <span class="admin-badge admin-badge--active">Active</span>
            </c:when>
            <c:when test="${user.status == 'BANNED'}">
              <span class="admin-badge admin-badge--banned">Banned</span>
            </c:when>
            <c:otherwise>
              <span class="admin-badge admin-badge--inactive">Inactive</span>
            </c:otherwise>
          </c:choose>
        </p>
      </div>
    </div>

    <c:if test="${not empty flashSuccess}">
      <div class="admin-alert admin-alert--success" role="status">
        <c:out value="${flashSuccess}"/>
      </div>
    </c:if>
    <c:if test="${not empty flashError}">
      <div class="admin-alert admin-alert--error" role="alert">
        <c:out value="${flashError}"/>
      </div>
    </c:if>

    <div class="admin-card">
      <h2 class="admin-section-title">Thông tin tài khoản</h2>
      <div class="admin-detail-grid">
        <div class="admin-detail-item">
          <span class="admin-detail-label">Email</span>
          <span class="admin-detail-value"><c:out value="${not empty user.email ? user.email : '—'}"/></span>
        </div>
        <div class="admin-detail-item">
          <span class="admin-detail-label">Tên đăng nhập</span>
          <span class="admin-detail-value"><c:out value="${not empty user.username ? user.username : '—'}"/></span>
        </div>
        <div class="admin-detail-item">
          <span class="admin-detail-label">Số điện thoại</span>
          <span class="admin-detail-value"><c:out value="${not empty user.phoneNumber ? user.phoneNumber : '—'}"/></span>
        </div>
        <div class="admin-detail-item">
          <span class="admin-detail-label">Ngày sinh</span>
          <span class="admin-detail-value">
            <fmt:formatDate value="${user.dateOfBirth}" pattern="dd/MM/yyyy"/>
          </span>
        </div>
        <div class="admin-detail-item">
          <span class="admin-detail-label">Điểm tích lũy</span>
          <span class="admin-detail-value"><c:out value="${user.loyaltyPoints}"/></span>
        </div>
        <div class="admin-detail-item">
          <span class="admin-detail-label">Đăng nhập lần cuối</span>
          <span class="admin-detail-value">
            <c:choose>
              <c:when test="${not empty user.lastLoginAt}">
                <fmt:formatDate value="${user.lastLoginAt}" pattern="dd/MM/yyyy HH:mm"/>
              </c:when>
              <c:otherwise>—</c:otherwise>
            </c:choose>
          </span>
        </div>
        <div class="admin-detail-item">
          <span class="admin-detail-label">Ngày tạo</span>
          <span class="admin-detail-value">
            <fmt:formatDate value="${user.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
          </span>
        </div>
      </div>
    </div>

    <c:if test="${!isSelf && user.roleName != 'ADMIN'}">
      <div class="admin-card">
        <h2 class="admin-section-title">Thao tác quản trị</h2>

        <c:if test="${user.status == 'BANNED' && not empty latestLock}">
          <div class="admin-alert" style="margin-bottom:20px;border:1px solid var(--border);background:var(--bg-elevated);">
            <p style="margin:0 0 6px;font-size:13px;color:var(--text-muted);">Lý do khóa gần nhất</p>
            <p style="margin:0;font-size:14px;"><c:out value="${latestLock.reason}"/></p>
            <p style="margin:8px 0 0;font-size:12px;color:var(--text-muted);">
              <fmt:formatDate value="${latestLock.performedAt}" pattern="dd/MM/yyyy HH:mm"/>
              <c:if test="${not empty latestLock.performedByName}">
                — bởi <c:out value="${latestLock.performedByName}"/>
              </c:if>
              <c:if test="${latestLock.emailSent}"> · Đã gửi email</c:if>
            </p>
          </div>
        </c:if>

        <c:if test="${user.status != 'BANNED'}">
          <h3 class="admin-section-title" style="font-size:15px;border:none;padding:0;margin-bottom:12px;">
            Khóa tài khoản
          </h3>
          <form class="admin-form admin-form--wide" method="post"
                action="${pageContext.request.contextPath}/admin/users/status"
                onsubmit="return confirm('Khóa tài khoản này? Người dùng sẽ không thể đăng nhập.');"
                style="margin-bottom:24px;">
            <input type="hidden" name="userId" value="${user.id}"/>
            <input type="hidden" name="action" value="lock"/>

            <div class="admin-field">
              <label class="admin-label" for="lockReason">Lý do khóa *</label>
              <p class="admin-field-hint">Tối thiểu 10 ký tự. Lý do được lưu vào hệ thống; có thể gửi cho user qua email.</p>
              <textarea id="lockReason" name="reason" class="admin-input admin-textarea" rows="4"
                        maxlength="500" required
                        placeholder="VD: Vi phạm chính sách đặt vé / hành vi gian lận..."></textarea>
            </div>

            <div class="admin-field">
              <label class="admin-checkbox">
                <input type="checkbox" name="sendEmail" value="on"
                       <c:if test="${canSendLockEmail}">checked</c:if>
                       <c:if test="${!canSendLockEmail}">disabled</c:if>/>
                Gửi email thông báo đến người dùng
              </label>
              <c:choose>
                <c:when test="${!userHasEmail}">
                  <p class="admin-field-hint">Tài khoản không có email — không thể gửi thông báo.</p>
                </c:when>
                <c:when test="${!emailConfigured}">
                  <p class="admin-field-hint">Chưa cấu hình <code>email.properties</code> — chỉ lưu lý do, không gửi mail.</p>
                </c:when>
                <c:otherwise>
                  <p class="admin-field-hint">Email gửi tới: <c:out value="${user.email}"/></p>
                </c:otherwise>
              </c:choose>
            </div>

            <div class="admin-form-actions">
              <button type="submit" class="admin-btn admin-btn--danger">Khóa tài khoản</button>
            </div>
          </form>
        </c:if>

        <div class="admin-btn-group" style="margin-bottom:24px;">
          <c:if test="${user.status == 'BANNED' || user.status == 'INACTIVE'}">
            <form method="post" action="${pageContext.request.contextPath}/admin/users/status">
              <input type="hidden" name="userId" value="${user.id}"/>
              <input type="hidden" name="action" value="unlock"/>
              <button type="submit" class="admin-btn admin-btn--success">Kích hoạt lại</button>
            </form>
          </c:if>
          <c:if test="${user.status == 'ACTIVE'}">
            <form method="post" action="${pageContext.request.contextPath}/admin/users/status"
                  onsubmit="return confirm('Vô hiệu hóa tài khoản? Người dùng cần xác thực lại trước khi đăng nhập.');">
              <input type="hidden" name="userId" value="${user.id}"/>
              <input type="hidden" name="action" value="deactivate"/>
              <button type="submit" class="admin-btn admin-btn--ghost">Vô hiệu hóa</button>
            </form>
          </c:if>
        </div>

        <h2 class="admin-section-title">Đặt lại mật khẩu</h2>
        <form class="admin-form" method="post"
              action="${pageContext.request.contextPath}/admin/users/reset-password"
              onsubmit="return confirm('Đặt lại mật khẩu cho người dùng này?');">
          <input type="hidden" name="userId" value="${user.id}"/>
          <div class="admin-field">
            <label class="admin-label" for="newPassword">Mật khẩu mới</label>
            <input type="password" id="newPassword" name="newPassword" class="admin-input"
                   placeholder="Tối thiểu 8 ký tự" minlength="8" required/>
          </div>
          <div class="admin-form-actions">
            <button type="submit" class="admin-btn admin-btn--primary">Đặt lại mật khẩu</button>
          </div>
        </form>
      </div>
    </c:if>

    <c:if test="${isSelf}">
      <div class="admin-card">
        <p style="color:var(--text-muted);font-size:14px;">
          Đây là tài khoản của bạn. Không thể khóa hoặc đặt lại mật khẩu tại đây.
        </p>
      </div>
    </c:if>

    <c:if test="${user.roleName == 'ADMIN' && !isSelf}">
      <div class="admin-card">
        <p style="color:var(--text-muted);font-size:14px;">
          Tài khoản Admin không thể bị khóa hoặc đặt lại mật khẩu qua trang này.
        </p>
      </div>
    </c:if>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
