<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Cấu hình hệ thống — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <nav class="admin-breadcrumb">
      <a href="${pageContext.request.contextPath}/admin/dashboard">Bảng điều khiển</a>
      <span class="admin-breadcrumb-sep">/</span>
      <span>Cấu hình hệ thống</span>
    </nav>

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Cấu hình hệ thống</h1>
        <p class="admin-page-subtitle">Tham số tích điểm — dùng cho đặt vé online và quản lý loyalty</p>
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
      <h2 class="admin-section-title">Tích điểm (SystemConfig)</h2>
      <p style="font-size:13px;color:var(--text-muted);margin-bottom:20px;">
        Các tham số này được module booking/loyalty đọc qua <code>ConfigUtil</code>.
        Thay đổi có hiệu lực ngay sau khi lưu.
      </p>

      <form class="admin-form admin-form--wide" method="post"
            action="${pageContext.request.contextPath}/admin/config/update">

        <c:forEach var="config" items="${configs}">
          <div class="admin-field">
            <label class="admin-label" for="${config.configKey}">
              <c:choose>
                <c:when test="${config.configKey == 'loyalty_earn_rate'}">Tỷ lệ tích điểm (điểm / 1.000đ)</c:when>
                <c:when test="${config.configKey == 'loyalty_redeem_rate'}">Số điểm đổi 10.000đ giảm giá</c:when>
                <c:when test="${config.configKey == 'loyalty_min_redeem'}">Điểm tối thiểu mỗi đơn</c:when>
                <c:when test="${config.configKey == 'loyalty_max_redeem_per_order'}">Điểm tối đa mỗi đơn</c:when>
                <c:otherwise><c:out value="${config.configKey}"/></c:otherwise>
              </c:choose>
            </label>
            <c:if test="${not empty config.description}">
              <p class="admin-field-hint"><c:out value="${config.description}"/></p>
            </c:if>
            <input type="number" id="${config.configKey}" name="${config.configKey}"
                   class="admin-input" min="0" step="1" required
                   value="<c:out value='${config.configValue}'/>"/>
          </div>
        </c:forEach>

        <c:if test="${not empty lastUpdated}">
          <p class="admin-config-meta">
            Cập nhật lần cuối:
            <fmt:formatDate value="${lastUpdated.updatedAt}" pattern="dd/MM/yyyy HH:mm"/>
            <c:if test="${not empty lastUpdated.updatedByName}">
              — bởi <c:out value="${lastUpdated.updatedByName}"/>
            </c:if>
          </p>
        </c:if>

        <div class="admin-form-actions">
          <button type="submit" class="admin-btn admin-btn--primary">Lưu thay đổi</button>
          <a href="${pageContext.request.contextPath}/admin/dashboard" class="admin-btn admin-btn--ghost">Hủy</a>
        </div>
      </form>
    </div>

    <div class="admin-card">
      <h2 class="admin-section-title">Thuế VAT</h2>
      <p style="font-size:13px;color:var(--text-muted);">
        Quản lý quy tắc VAT (<code>VatRules</code>) sẽ được bổ sung ở phase tiếp theo.
        Hiện tại hệ thống lấy VAT từ rule ACTIVE trong database.
      </p>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
