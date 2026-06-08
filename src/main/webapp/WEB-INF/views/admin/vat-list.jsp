<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Quản lý thuế VAT — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <nav class="admin-breadcrumb">
      <a href="${pageContext.request.contextPath}/admin/dashboard">Bảng điều khiển</a>
      <span class="admin-breadcrumb-sep">/</span>
      <a href="${pageContext.request.contextPath}/admin/config">Cấu hình hệ thống</a>
      <span class="admin-breadcrumb-sep">/</span>
      <span>Thuế VAT</span>
    </nav>

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Quản lý thuế VAT</h1>
        <p class="admin-page-subtitle">
          Tạo quy tắc mới để đổi thuế suất — đơn đặt vé lưu snapshot, không ảnh hưởng đơn cũ
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
      <h2 class="admin-section-title">Đang áp dụng</h2>
      <c:choose>
        <c:when test="${not empty currentRule}">
          <div class="admin-stats-grid" style="margin-bottom:0;">
            <div class="admin-stat-card">
              <span class="admin-stat-value">
                <fmt:formatNumber value="${currentRule.vatRate}" minFractionDigits="0" maxFractionDigits="2"/>%
              </span>
              <span class="admin-stat-label">Thuế suất hiện tại</span>
            </div>
            <div class="admin-stat-card">
              <span class="admin-stat-value" style="font-size:18px;">
                <c:out value="${currentRule.ruleName}"/>
              </span>
              <span class="admin-stat-label">Tên quy tắc</span>
            </div>
            <div class="admin-stat-card">
              <span class="admin-stat-value" style="font-size:18px;">
                <fmt:formatDate value="${currentRule.startDate}" pattern="dd/MM/yyyy"/>
              </span>
              <span class="admin-stat-label">Ngày bắt đầu</span>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <p style="font-size:13px;color:var(--text-muted);margin:0;">
            Chưa có quy tắc ACTIVE — hệ thống dùng mặc định <strong>8%</strong> khi đặt vé.
          </p>
        </c:otherwise>
      </c:choose>
    </div>

    <div class="admin-card">
      <h2 class="admin-section-title">Áp dụng thuế suất mới</h2>
      <p style="font-size:13px;color:var(--text-muted);margin-bottom:20px;">
        Quy tắc ACTIVE hiện tại sẽ chuyển sang <code>INACTIVE</code> và lưu vào lịch sử.
      </p>

      <form class="admin-form admin-form--wide" method="post"
            action="${pageContext.request.contextPath}/admin/vat/create" novalidate>

        <div class="admin-field">
          <label class="admin-label" for="ruleName">Tên quy tắc *</label>
          <input type="text" id="ruleName" name="ruleName" class="admin-input" required
                 maxlength="100" placeholder="VD: VAT giảm 8% theo NQ..."
                 value=""/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="vatRate">Thuế suất VAT (%) *</label>
          <input type="number" id="vatRate" name="vatRate" class="admin-input" required
                 min="0" max="100" step="0.01" placeholder="VD: 10 hoặc 8.00"/>
        </div>

        <div class="admin-field">
          <label class="admin-label" for="startDate">Ngày bắt đầu áp dụng *</label>
          <input type="date" id="startDate" name="startDate" class="admin-input" required
                 value="<c:out value='${defaultStartDate}'/>"/>
        </div>

        <div class="admin-form-actions">
          <button type="submit" class="admin-btn admin-btn--primary">Áp dụng quy tắc mới</button>
          <a href="${pageContext.request.contextPath}/admin/config" class="admin-btn admin-btn--ghost">Quay lại</a>
        </div>
      </form>
    </div>

    <div class="admin-card">
      <h2 class="admin-section-title">Lịch sử quy tắc</h2>
      <c:choose>
        <c:when test="${not empty history}">
          <div class="admin-table-wrap">
            <table class="admin-table">
              <thead>
                <tr>
                  <th>Tên quy tắc</th>
                  <th>Thuế suất</th>
                  <th>Bắt đầu</th>
                  <th>Kết thúc</th>
                  <th>Trạng thái</th>
                  <th>Ngày tạo</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="rule" items="${history}">
                  <tr>
                    <td><c:out value="${rule.ruleName}"/></td>
                    <td>
                      <fmt:formatNumber value="${rule.vatRate}" minFractionDigits="0" maxFractionDigits="2"/>%
                    </td>
                    <td class="cell-muted">
                      <fmt:formatDate value="${rule.startDate}" pattern="dd/MM/yyyy"/>
                    </td>
                    <td class="cell-muted">
                      <c:choose>
                        <c:when test="${not empty rule.endDate}">
                          <fmt:formatDate value="${rule.endDate}" pattern="dd/MM/yyyy"/>
                        </c:when>
                        <c:otherwise>—</c:otherwise>
                      </c:choose>
                    </td>
                    <td>
                      <span class="admin-badge admin-badge--inactive">
                        <c:out value="${rule.status}"/>
                      </span>
                    </td>
                    <td class="cell-muted">
                      <fmt:formatDate value="${rule.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:when>
        <c:otherwise>
          <p style="font-size:13px;color:var(--text-muted);margin:0;">
            Chưa có quy tắc nào trong lịch sử.
          </p>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
