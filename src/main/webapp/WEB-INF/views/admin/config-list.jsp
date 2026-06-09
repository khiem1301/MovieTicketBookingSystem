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
      <h2 class="admin-section-title">Lịch sử chỉnh sửa tích điểm</h2>
      <p style="font-size:13px;color:var(--text-muted);margin-bottom:16px;">
        Ghi lại mỗi lần admin lưu thay đổi — hiển thị giá trị mới và giá trị trước đó (nếu có).
      </p>
      <c:choose>
        <c:when test="${not empty loyaltyHistory}">
          <div class="admin-table-wrap">
            <table class="admin-table">
              <thead>
                <tr>
                  <th>Thời gian</th>
                  <th>Người sửa</th>
                  <th>Tích điểm<br/><span style="font-weight:400;font-size:11px;">điểm/1.000đ</span></th>
                  <th>Đổi điểm<br/><span style="font-weight:400;font-size:11px;">điểm/10.000đ</span></th>
                  <th>Min/đơn</th>
                  <th>Max/đơn</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="log" items="${loyaltyHistory}">
                  <tr>
                    <td class="cell-muted" style="white-space:nowrap;">
                      <fmt:formatDate value="${log.updatedAt}" pattern="dd/MM/yyyy HH:mm"/>
                    </td>
                    <td>
                      <c:choose>
                        <c:when test="${not empty log.updatedByName}">
                          <c:out value="${log.updatedByName}"/>
                        </c:when>
                        <c:otherwise>—</c:otherwise>
                      </c:choose>
                    </td>
                    <td>
                      <c:out value="${log.earnRate}"/>
                      <c:if test="${not empty log.previousEarnRate and log.previousEarnRate != log.earnRate}">
                        <span class="cell-muted" style="display:block;font-size:11px;">
                          trước: <c:out value="${log.previousEarnRate}"/>
                        </span>
                      </c:if>
                    </td>
                    <td>
                      <c:out value="${log.redeemRate}"/>
                      <c:if test="${not empty log.previousRedeemRate and log.previousRedeemRate != log.redeemRate}">
                        <span class="cell-muted" style="display:block;font-size:11px;">
                          trước: <c:out value="${log.previousRedeemRate}"/>
                        </span>
                      </c:if>
                    </td>
                    <td>
                      <c:out value="${log.minRedeem}"/>
                      <c:if test="${not empty log.previousMinRedeem and log.previousMinRedeem != log.minRedeem}">
                        <span class="cell-muted" style="display:block;font-size:11px;">
                          trước: <c:out value="${log.previousMinRedeem}"/>
                        </span>
                      </c:if>
                    </td>
                    <td>
                      <c:out value="${log.maxRedeemPerOrder}"/>
                      <c:if test="${not empty log.previousMaxRedeemPerOrder and log.previousMaxRedeemPerOrder != log.maxRedeemPerOrder}">
                        <span class="cell-muted" style="display:block;font-size:11px;">
                          trước: <c:out value="${log.previousMaxRedeemPerOrder}"/>
                        </span>
                      </c:if>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:when>
        <c:otherwise>
          <c:choose>
            <c:when test="${historyTableMissing}">
              <p style="font-size:13px;color:var(--text-muted);margin:0;">
                Chưa có bảng lịch sử. Chạy script
                <code>Database/migrations/add_system_config_log.sql</code> trên SQL Server rồi tải lại trang.
              </p>
            </c:when>
            <c:otherwise>
              <p style="font-size:13px;color:var(--text-muted);margin:0;">
                Chưa có lịch sử chỉnh sửa. Lịch sử sẽ được ghi sau lần lưu thay đổi đầu tiên.
              </p>
            </c:otherwise>
          </c:choose>
        </c:otherwise>
      </c:choose>
    </div>

    <div class="admin-card">
      <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:16px;flex-wrap:wrap;">
        <div>
          <h2 class="admin-section-title">Thuế VAT</h2>
          <p style="font-size:13px;color:var(--text-muted);margin-bottom:8px;">
            Quản lý quy tắc thuế suất (<code>VatRules</code>) — áp dụng cho đơn đặt vé mới.
          </p>
          <c:choose>
            <c:when test="${not empty currentVatRule}">
              <p style="font-size:14px;margin:0;">
                Đang áp dụng:
                <strong>
                  <fmt:formatNumber value="${currentVatRule.vatRate}" minFractionDigits="0" maxFractionDigits="2"/>%
                </strong>
                — <c:out value="${currentVatRule.ruleName}"/>
              </p>
            </c:when>
            <c:otherwise>
              <p style="font-size:14px;margin:0;">Chưa cấu hình — mặc định <strong>8%</strong></p>
            </c:otherwise>
          </c:choose>
        </div>
        <a href="${pageContext.request.contextPath}/admin/vat" class="admin-btn admin-btn--primary">
          Quản lý VAT →
        </a>
      </div>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
