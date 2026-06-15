<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Bảng điều khiển — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Bảng điều khiển</h1>
        <p class="admin-page-subtitle">
          Xin chào, <c:out value="${adminName}"/> — chào mừng bạn quay trở lại hệ thống ÉpCine
        </p>
      </div>
      <a href="${pageContext.request.contextPath}/home" class="admin-btn admin-btn--ghost">
        ← Về trang chủ
      </a>
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

    <%-- Thống kê tài khoản --%>
    <h2 class="admin-section-title" style="border:none;padding:0;margin-bottom:12px;">
      Thống kê tài khoản
    </h2>
    <div class="admin-stats-grid">
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${totalUsers}"/></span>
        <span class="admin-stat-label">Tổng tài khoản</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${activeUsers}"/></span>
        <span class="admin-stat-label">Đang hoạt động</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${staffCount}"/></span>
        <span class="admin-stat-label">Nhân viên (Staff)</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${managerCount}"/></span>
        <span class="admin-stat-label">Quản lý (Manager)</span>
      </div>
    </div>

    <%-- Thống kê đặt vé tháng này --%>
    <h2 class="admin-section-title" style="margin-top:28px;border:none;padding:0;margin-bottom:12px;">
      Thống kê đặt vé
      <span style="font-size:13px;font-weight:500;color:var(--text-muted);margin-left:8px;">(tháng hiện tại)</span>
    </h2>
    <div class="admin-stats-grid admin-stats-grid--3">
      <div class="admin-stat-card">
        <span class="admin-stat-value admin-stat-value--money">
          <fmt:formatNumber value="${monthStats.revenue}" type="number" groupingUsed="true" maxFractionDigits="0"/>đ
        </span>
        <span class="admin-stat-label">Doanh thu</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${monthStats.ticketCount}"/></span>
        <span class="admin-stat-label">Vé đã bán</span>
      </div>
      <div class="admin-stat-card">
        <span class="admin-stat-value"><c:out value="${monthStats.bookingCount}"/></span>
        <span class="admin-stat-label">Đơn đã thanh toán</span>
      </div>
    </div>
    <p style="font-size:13px;color:var(--text-muted);margin:8px 0 0;">
      <a href="${pageContext.request.contextPath}/admin/reports" style="color:var(--accent);font-weight:600;">
        Xem báo cáo chi tiết →
      </a>
    </p>

    <%-- Module cards --%>
    <h2 class="admin-section-title" style="margin-top:32px;border:none;padding:0;">
      Chức năng quản trị
    </h2>
    <p style="font-size:13px;color:var(--text-muted);margin-bottom:20px;">
      Chọn mục bên dưới hoặc mở menu tài khoản góc phải trên header.
    </p>

    <div class="admin-module-grid">
      <a href="${pageContext.request.contextPath}/admin/users" class="admin-module-card admin-module-card--active">
        <div class="admin-module-icon">👥</div>
        <h3 class="admin-module-title">Quản lý người dùng</h3>
        <p class="admin-module-desc">
          Tạo tài khoản Staff/Manager, khóa tài khoản và đặt lại mật khẩu.
        </p>
        <span class="admin-module-link">Truy cập →</span>
      </a>

      <a href="${pageContext.request.contextPath}/admin/config" class="admin-module-card admin-module-card--active">
        <div class="admin-module-icon">⚙️</div>
        <h3 class="admin-module-title">Cấu hình hệ thống</h3>
        <p class="admin-module-desc">
          Tham số tích điểm loyalty — earn/redeem rate, min/max mỗi đơn.
        </p>
        <span class="admin-module-link">Truy cập →</span>
      </a>

      <a href="${pageContext.request.contextPath}/admin/reports" class="admin-module-card admin-module-card--active">
        <div class="admin-module-icon">📊</div>
        <h3 class="admin-module-title">Báo cáo &amp; thống kê</h3>
        <p class="admin-module-desc">
          Doanh thu, số vé bán và top phim được đặt nhiều nhất.
        </p>
        <span class="admin-module-link">Truy cập →</span>
      </a>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
