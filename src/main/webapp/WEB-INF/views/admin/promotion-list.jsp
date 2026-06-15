<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Promotions &amp; Vouchers — ÉPCINE"/>
<c:set var="extraCss"  value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<style>
/* ── Promo page overrides ───────────────────────────────────────── */
.promo-page { padding: 0 0 60px; }

/* Banner */
.promo-banner {
  background: linear-gradient(135deg, #0f0f0f 0%, #1a0808 100%);
  border-bottom: 1px solid rgba(229,57,53,0.18);
  padding: 36px 0 28px;
  margin-bottom: 0;
}
.promo-banner-top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 28px;
  flex-wrap: wrap;
}
.promo-banner h1 {
  font-size: 30px;
  font-weight: 800;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}
.promo-banner p {
  font-size: 14px;
  color: var(--text-muted);
}
.promo-create-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 10px 20px;
  background: var(--accent);
  color: #fff;
  border: none;
  border-radius: 8px;
  font-weight: 700;
  font-size: 14px;
  cursor: pointer;
  white-space: nowrap;
  transition: background .2s;
}
.promo-create-btn:hover { background: var(--accent-hover); }

/* Stat cards */
.promo-stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
}
.promo-stat-card {
  background: rgba(255,255,255,0.03);
  border: 1px solid rgba(229,57,53,0.22);
  border-left: 3px solid var(--accent);
  border-radius: 10px;
  padding: 18px 22px;
}
.promo-stat-label {
  display: block;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: .08em;
  color: var(--text-dim);
  text-transform: uppercase;
  margin-bottom: 8px;
}
.promo-stat-value {
  display: block;
  font-size: 28px;
  font-weight: 800;
  color: #fff;
  letter-spacing: -0.02em;
  margin-bottom: 4px;
}
.promo-stat-note {
  font-size: 12px;
  color: var(--text-muted);
}
.promo-stat-note.trend-up { color: #66bb6a; }

/* Content area */
.promo-content { padding: 28px 0 0; }

/* Alerts */
.promo-alert {
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 13px;
  margin-bottom: 20px;
  line-height: 1.5;
}
.promo-alert--success {
  background: rgba(76,175,80,.1);
  border: 1px solid rgba(76,175,80,.3);
  color: #a5d6a7;
}
.promo-alert--error {
  background: rgba(229,57,53,.1);
  border: 1px solid rgba(229,57,53,.3);
  color: #ff8a80;
}

/* Section card */
.promo-section {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
}
.promo-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 22px;
  border-bottom: 1px solid var(--border);
  flex-wrap: wrap;
  gap: 12px;
}
.promo-section-title {
  font-size: 16px;
  font-weight: 700;
}
.promo-section-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}
.promo-search-input {
  padding: 7px 14px;
  background: rgba(255,255,255,.05);
  border: 1px solid rgba(255,255,255,.1);
  border-radius: 7px;
  color: var(--text);
  font-size: 13px;
  width: 200px;
  outline: none;
  transition: border-color .2s;
}
.promo-search-input:focus { border-color: var(--accent); }
.promo-search-input::placeholder { color: var(--text-dim); }
.promo-filter-select {
  padding: 7px 12px;
  background: #1e1e1e;
  border: 1px solid rgba(255,255,255,.1);
  border-radius: 7px;
  color: #fff;
  font-size: 13px;
  cursor: pointer;
  outline: none;
}
.promo-filter-select option {
  background: #1e1e1e;
  color: #fff;
}
.promo-icon-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 7px 12px;
  background: rgba(255,255,255,.06);
  border: 1px solid rgba(255,255,255,.1);
  border-radius: 7px;
  color: var(--text-muted);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: background .2s, color .2s;
}
.promo-icon-btn:hover { background: rgba(255,255,255,.1); color: #fff; }

/* Table */
.promo-table { width: 100%; border-collapse: collapse; }
.promo-table thead tr {
  border-bottom: 1px solid var(--border);
}
.promo-table th {
  padding: 10px 18px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: .08em;
  text-transform: uppercase;
  color: var(--text-dim);
  text-align: left;
  white-space: nowrap;
}
.promo-table td { padding: 14px 18px; border-bottom: 1px solid rgba(255,255,255,.04); vertical-align: middle; }
.promo-table tbody tr:last-child td { border-bottom: none; }
.promo-table tbody tr:hover { background: rgba(255,255,255,.02); }
.promo-table tbody tr.is-expired { opacity: .45; }

/* Name cell */
.promo-name-cell { display: flex; align-items: center; gap: 12px; }
.promo-icon {
  width: 36px; height: 36px;
  border-radius: 8px;
  background: rgba(229,57,53,.15);
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.promo-icon svg { width: 18px; height: 18px; fill: var(--accent); }
.promo-name { font-weight: 600; font-size: 14px; line-height: 1.3; }
.promo-name-sub { font-size: 11px; color: var(--text-dim); margin-top: 2px; }

/* Code badge */
.promo-code {
  display: inline-block;
  padding: 4px 10px;
  background: rgba(255,255,255,.06);
  border: 1px solid rgba(255,255,255,.1);
  border-radius: 5px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: .5px;
  color: #e0e0e0;
  white-space: nowrap;
}

/* Value */
.promo-value { font-weight: 600; font-size: 14px; }
.promo-value--pct { color: #64b5f6; }
.promo-value--fixed { color: #81c784; }

/* Usage bar */
.promo-usage { min-width: 120px; }
.promo-bar {
  height: 3px;
  background: rgba(255,255,255,.1);
  border-radius: 2px;
  overflow: hidden;
  margin-bottom: 5px;
}
.promo-bar-fill {
  height: 100%;
  border-radius: 2px;
  background: var(--accent);
  transition: width .3s;
}
.promo-bar-fill.is-mid  { background: #ff9800; }
.promo-bar-fill.is-done { background: var(--text-dim); }
.promo-usage-text { font-size: 12px; color: var(--text-muted); }

/* Status badge */
.promo-status { display: inline-flex; align-items: center; gap: 5px; }
.promo-status-dot {
  width: 6px; height: 6px;
  border-radius: 50%;
  flex-shrink: 0;
}
.promo-status--active .promo-status-dot  { background: #4caf50; }
.promo-status--inactive .promo-status-dot { background: #616161; }
.promo-status--expired .promo-status-dot  { background: #9e9e9e; }
.promo-status-text {
  font-size: 11px;
  font-weight: 700;
  letter-spacing: .05em;
}
.promo-status--active .promo-status-text  { color: #66bb6a; }
.promo-status--inactive .promo-status-text { color: #757575; }
.promo-status--expired .promo-status-text  { color: #757575; }
.promo-expiry-date { font-size: 11px; color: var(--text-dim); margin-top: 3px; }

/* Action buttons */
.promo-actions { display: flex; gap: 6px; }
.promo-action-btn {
  padding: 5px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  border: 1px solid rgba(255,255,255,.12);
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  transition: all .2s;
  white-space: nowrap;
}
.promo-action-btn:hover { background: rgba(255,255,255,.08); color: #fff; }
.promo-action-btn.is-danger { border-color: rgba(229,57,53,.3); }
.promo-action-btn.is-danger:hover { background: rgba(229,57,53,.15); color: #ff8a80; }
.promo-action-btn.is-toggle-on  { border-color: rgba(76,175,80,.3); }
.promo-action-btn.is-toggle-on:hover  { background: rgba(76,175,80,.12); color: #81c784; }
.promo-action-btn.is-toggle-off { border-color: rgba(255,152,0,.3); }
.promo-action-btn.is-toggle-off:hover { background: rgba(255,152,0,.1); color: #ffa726; }

/* Footer */
.promo-table-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 22px;
  border-top: 1px solid var(--border);
  font-size: 13px;
  color: var(--text-dim);
  flex-wrap: wrap;
  gap: 10px;
}
.promo-pagination { display: flex; gap: 6px; align-items: center; }
.promo-page-btn {
  width: 30px; height: 30px;
  border-radius: 6px;
  border: 1px solid rgba(255,255,255,.1);
  background: transparent;
  color: var(--text-muted);
  font-size: 13px;
  cursor: pointer;
  transition: all .2s;
  display: flex; align-items: center; justify-content: center;
  text-decoration: none;
}
.promo-page-btn:hover, .promo-page-btn.is-active {
  background: var(--accent);
  border-color: var(--accent);
  color: #fff;
}

/* Modal */
.promo-modal {
  display: none;
  position: fixed;
  inset: 0;
  z-index: 8000;
  align-items: center;
  justify-content: center;
  padding: 20px;
}
.promo-modal.open { display: flex; }
.promo-modal-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(0,0,0,.72);
  cursor: pointer;
}
.promo-modal-panel {
  position: relative;
  z-index: 1;
  width: 620px;
  max-width: 100%;
  max-height: 90vh;
  background: #1a1a1a;
  border: 1px solid rgba(229,57,53,.2);
  border-radius: 14px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: fadeScaleIn .22s ease;
}
@keyframes fadeScaleIn {
  from { transform: scale(0.95); opacity: 0; }
  to   { transform: scale(1);    opacity: 1; }
}
.promo-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  border-bottom: 1px solid var(--border);
  flex-shrink: 0;
}
.promo-modal-heading { font-size: 16px; font-weight: 700; }
.promo-modal-close {
  width: 30px; height: 30px;
  border-radius: 6px;
  border: none;
  background: rgba(255,255,255,.06);
  color: var(--text-muted);
  font-size: 16px;
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: background .2s, color .2s;
}
.promo-modal-close:hover { background: rgba(255,255,255,.12); color: #fff; }
.promo-modal-panel > form {
  flex: 1;
  min-height: 0;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.promo-modal-body {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 24px;
}
.promo-modal-body::-webkit-scrollbar { width: 4px; }
.promo-modal-body::-webkit-scrollbar-track { background: transparent; }
.promo-modal-body::-webkit-scrollbar-thumb { background: rgba(255,255,255,.1); border-radius: 2px; }
.promo-modal-footer {
  padding: 16px 24px;
  border-top: 1px solid var(--border);
  display: flex;
  gap: 10px;
  flex-shrink: 0;
}
.promo-modal-submit {
  flex: 1;
  padding: 11px;
  background: var(--accent);
  color: #fff;
  border: none;
  border-radius: 8px;
  font-weight: 700;
  font-size: 14px;
  cursor: pointer;
  transition: background .2s;
}
.promo-modal-submit:hover { background: var(--accent-hover); }
.promo-modal-cancel {
  padding: 11px 18px;
  background: transparent;
  border: 1px solid rgba(255,255,255,.12);
  border-radius: 8px;
  color: var(--text-muted);
  font-size: 14px;
  cursor: pointer;
  transition: all .2s;
}
.promo-modal-cancel:hover { background: rgba(255,255,255,.06); color: #fff; }

/* Form inside modal */
.pm-field { margin-bottom: 16px; }
.pm-label {
  display: block;
  font-size: 11px;
  font-weight: 700;
  color: var(--text-dim);
  text-transform: uppercase;
  letter-spacing: .06em;
  margin-bottom: 6px;
}
.pm-input, .pm-select, .pm-textarea {
  width: 100%;
  padding: 9px 13px;
  background: #1e1e1e;
  border: 1px solid rgba(255,255,255,.1);
  border-radius: 7px;
  color: #fff;
  font-size: 13px;
  outline: none;
  transition: border-color .2s;
  font-family: inherit;
}
.pm-select option {
  background: #1e1e1e;
  color: #fff;
}
.pm-input:focus, .pm-select:focus, .pm-textarea:focus {
  border-color: var(--accent);
}
.pm-textarea { resize: vertical; min-height: 60px; }
.pm-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.pm-hint { font-size: 11px; color: var(--text-dim); margin-top: 4px; }
.pm-divider {
  border: none;
  border-top: 1px solid var(--border);
  margin: 18px 0;
}
</style>

<main class="admin-page promo-page">

  <%-- ══ BANNER ═══════════════════════════════════════════════════════════ --%>
  <div class="promo-banner">
    <div class="container">
      <div class="promo-banner-top">
        <div>
          <h1>Promotions &amp; Vouchers</h1>
          <p>Quản lý mã giảm giá, khuyến mãi và ưu đãi dành cho khách hàng</p>
        </div>
        <button class="promo-create-btn" onclick="openModal('create')">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M19 13H13v6h-2v-6H5v-2h6V5h2v6h6v2z"/></svg>
          Create Promotion
        </button>
      </div>

      <%-- Stat cards --%>
      <div class="promo-stats-row">
        <div class="promo-stat-card">
          <span class="promo-stat-label">Tổng giảm giá đã áp dụng</span>
          <span class="promo-stat-value">
            <fmt:formatNumber value="${statRevenue}" type="number" maxFractionDigits="0"/>₫
          </span>
          <span class="promo-stat-note">Tổng tiền đã giảm cho khách</span>
        </div>
        <div class="promo-stat-card">
          <span class="promo-stat-label">Tổng lượt sử dụng</span>
          <span class="promo-stat-value">
            <fmt:formatNumber value="${statRedemptions}" type="number" maxFractionDigits="0"/>
          </span>
          <span class="promo-stat-note">Tất cả mã giảm giá</span>
        </div>
        <div class="promo-stat-card">
          <span class="promo-stat-label">Chiến dịch đang hoạt động</span>
          <span class="promo-stat-value">${statActive}</span>
          <span class="promo-stat-note ${statEndingSoon > 0 ? 'trend-up' : ''}">
            <c:choose>
              <c:when test="${statEndingSoon > 0}">${statEndingSoon} mã hết hạn trong 7 ngày</c:when>
              <c:otherwise>Không có mã nào sắp hết hạn</c:otherwise>
            </c:choose>
          </span>
        </div>
      </div>
    </div>
  </div>

  <div class="container promo-content">

    <%-- Flash messages --%>
    <c:if test="${not empty flashSuccess}">
      <div class="promo-alert promo-alert--success"><c:out value="${flashSuccess}"/></div>
    </c:if>
    <c:if test="${not empty flashError}">
      <div class="promo-alert promo-alert--error"><c:out value="${flashError}"/></div>
    </c:if>

    <%-- ══ BẢNG DANH SÁCH ════════════════════════════════════════════════ --%>
    <div class="promo-section">

      <%-- Header section --%>
      <div class="promo-section-header">
        <span class="promo-section-title">All Promotions</span>
        <div class="promo-section-actions">
          <form method="get" action="${pageContext.request.contextPath}/admin/promotions"
                style="display:contents;">
            <input type="text" name="q" class="promo-search-input"
                   placeholder="Tìm mã hoặc tiêu đề..."
                   value="<c:out value='${keyword}'/>"/>
            <select name="status" class="promo-filter-select"
                    onchange="this.form.submit()">
              <option value="">Tất cả</option>
              <option value="ACTIVE"   ${statusFilter == 'ACTIVE'   ? 'selected' : ''}>ACTIVE</option>
              <option value="INACTIVE" ${statusFilter == 'INACTIVE' ? 'selected' : ''}>INACTIVE</option>
            </select>
            <button type="submit" class="promo-icon-btn">
              <svg viewBox="0 0 24 24" width="13" height="13" fill="currentColor"><path d="M3 18h6v-2H3v2zm0-5h12v-2H3v2zm0-7v2h18V6H3z"/></svg>
              Filter
            </button>
            <c:if test="${not empty keyword or not empty statusFilter}">
              <a href="${pageContext.request.contextPath}/admin/promotions"
                 class="promo-icon-btn">✕ Xóa lọc</a>
            </c:if>
          </form>
        </div>
      </div>

      <%-- Table --%>
      <c:choose>
        <c:when test="${not empty promotions}">
          <table class="promo-table">
            <thead>
              <tr>
                <th>Promotion Name</th>
                <th>Code</th>
                <th>Value</th>
                <th>Usage</th>
                <th>Status / Expiry</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="p" items="${promotions}">
                <fmt:formatDate value="${p.startDate}" pattern="yyyy-MM-dd" var="pStartFmt"/>
                <fmt:formatDate value="${p.endDate}"   pattern="yyyy-MM-dd" var="pEndFmt"/>
                <fmt:formatDate value="${p.endDate}"   pattern="dd/MM/yyyy" var="pEndDisp"/>
                <fmt:formatNumber value="${p.discountValue}" maxFractionDigits="2"
                                  groupingUsed="false" var="pValFmt"/>
                <c:set var="pMaxFmt" value=""/>
                <c:if test="${not empty p.maxDiscountAmount}">
                  <fmt:formatNumber value="${p.maxDiscountAmount}" maxFractionDigits="0"
                                    groupingUsed="false" var="pMaxFmt"/>
                </c:if>
                <c:set var="pMinFmt" value=""/>
                <c:if test="${not empty p.minOrderAmount}">
                  <fmt:formatNumber value="${p.minOrderAmount}" maxFractionDigits="0"
                                    groupingUsed="false" var="pMinFmt"/>
                </c:if>

                <tr class="${p.expired ? 'is-expired' : ''}">

                  <%-- Name --%>
                  <td>
                    <div class="promo-name-cell">
                      <div class="promo-icon">
                        <c:choose>
                          <c:when test="${p.discountType == 'PERCENTAGE'}">
                            <svg viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zM7.5 6C8.33 6 9 6.67 9 7.5S8.33 9 7.5 9 6 8.33 6 7.5 6.67 6 7.5 6zm9 12l-9-9 1.5-1.5 9 9-1.5 1.5zm-1-3.5c.83 0 1.5.67 1.5 1.5s-.67 1.5-1.5 1.5-1.5-.67-1.5-1.5.67-1.5 1.5-1.5z"/></svg>
                          </c:when>
                          <c:otherwise>
                            <svg viewBox="0 0 24 24"><path d="M20 12c0-1.1.9-2 2-2V6c0-1.1-.9-2-2-2H4c-1.1 0-2 .9-2 2v4c1.1 0 2 .9 2 2s-.9 2-2 2v4c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2v-4c-1.1 0-2-.9-2-2z"/></svg>
                          </c:otherwise>
                        </c:choose>
                      </div>
                      <div>
                        <div class="promo-name"><c:out value="${p.title}"/></div>
                        <div class="promo-name-sub">
                          <c:choose>
                            <c:when test="${p.discountType == 'PERCENTAGE'}">Giảm theo phần trăm</c:when>
                            <c:otherwise>Giảm cố định</c:otherwise>
                          </c:choose>
                        </div>
                      </div>
                    </div>
                  </td>

                  <%-- Code --%>
                  <td><span class="promo-code"><c:out value="${p.code}"/></span></td>

                  <%-- Value --%>
                  <td>
                    <c:choose>
                      <c:when test="${p.discountType == 'PERCENTAGE'}">
                        <span class="promo-value promo-value--pct">
                          <fmt:formatNumber value="${p.discountValue}" maxFractionDigits="0"/>% Off
                        </span>
                        <c:if test="${not empty p.maxDiscountAmount}">
                          <div style="font-size:11px;color:var(--text-dim);margin-top:2px;">
                            tối đa <fmt:formatNumber value="${p.maxDiscountAmount}" type="number" maxFractionDigits="0"/>₫
                          </div>
                        </c:if>
                      </c:when>
                      <c:otherwise>
                        <span class="promo-value promo-value--fixed">
                          <fmt:formatNumber value="${p.discountValue}" type="number" maxFractionDigits="0"/>₫ Off
                        </span>
                      </c:otherwise>
                    </c:choose>
                    <c:if test="${not empty p.minOrderAmount}">
                      <div style="font-size:11px;color:var(--text-dim);margin-top:2px;">
                        đơn từ <fmt:formatNumber value="${p.minOrderAmount}" type="number" maxFractionDigits="0"/>₫
                      </div>
                    </c:if>
                  </td>

                  <%-- Usage bar --%>
                  <td class="promo-usage">
                    <c:choose>
                      <c:when test="${not empty p.usageLimit and p.usageLimit > 0}">
                        <c:set var="pct" value="${p.usedCount * 100 / p.usageLimit}"/>
                        <c:set var="barCls" value=""/>
                        <c:if test="${pct >= 80}"><c:set var="barCls" value="is-mid"/></c:if>
                        <c:if test="${pct >= 100}"><c:set var="barCls" value="is-done"/></c:if>
                        <div class="promo-bar">
                          <div class="promo-bar-fill ${barCls}"
                               style="width:${pct > 100 ? 100 : pct}%"></div>
                        </div>
                        <span class="promo-usage-text">${p.usedCount}/${p.usageLimit}</span>
                      </c:when>
                      <c:otherwise>
                        <div class="promo-bar">
                          <c:if test="${p.usedCount > 0}">
                            <div class="promo-bar-fill" style="width:30%"></div>
                          </c:if>
                        </div>
                        <span class="promo-usage-text">${p.usedCount} / ∞</span>
                      </c:otherwise>
                    </c:choose>
                  </td>

                  <%-- Status / Expiry --%>
                  <td>
                    <c:choose>
                      <c:when test="${p.expired}">
                        <div class="promo-status promo-status--expired">
                          <span class="promo-status-dot"></span>
                          <span class="promo-status-text">EXPIRED</span>
                        </div>
                      </c:when>
                      <c:when test="${p.scheduled}">
                        <div class="promo-status promo-status--inactive">
                          <span class="promo-status-dot"></span>
                          <span class="promo-status-text">SCHEDULED</span>
                        </div>
                      </c:when>
                      <c:when test="${p.status == 'ACTIVE'}">
                        <div class="promo-status promo-status--active">
                          <span class="promo-status-dot"></span>
                          <span class="promo-status-text">ACTIVE</span>
                        </div>
                      </c:when>
                      <c:otherwise>
                        <div class="promo-status promo-status--inactive">
                          <span class="promo-status-dot"></span>
                          <span class="promo-status-text">INACTIVE</span>
                        </div>
                      </c:otherwise>
                    </c:choose>
                    <div class="promo-expiry-date"><c:out value="${pEndDisp}"/></div>
                  </td>

                  <%-- Actions --%>
                  <td>
                    <div class="promo-actions">
                      <%-- Edit --%>
                      <button class="promo-action-btn"
                              onclick="openEditModal(this)"
                              data-id="<c:out value='${p.id}'/>"
                              data-code="<c:out value='${p.code}'/>"
                              data-title="<c:out value='${p.title}'/>"
                              data-description="<c:out value='${p.description}'/>"
                              data-discount-type="<c:out value='${p.discountType}'/>"
                              data-discount-value="<c:out value='${pValFmt}'/>"
                              data-max-discount="<c:out value='${pMaxFmt}'/>"
                              data-min-order="<c:out value='${pMinFmt}'/>"
                              data-start-date="<c:out value='${pStartFmt}'/>"
                              data-end-date="<c:out value='${pEndFmt}'/>"
                              data-usage-limit="<c:out value='${p.usageLimit}'/>"
                              data-used-count="${p.usedCount}">
                        Edit
                      </button>

                      <%-- Toggle (không áp dụng khi đã hết hạn) --%>
                      <c:if test="${!p.expired}">
                        <form method="post"
                              action="${pageContext.request.contextPath}/admin/promotions/toggle"
                              style="display:inline;">
                          <input type="hidden" name="promotionId" value="${p.id}"/>
                          <button type="submit"
                                  class="promo-action-btn ${p.status == 'ACTIVE' ? 'is-toggle-off' : 'is-toggle-on'}">
                            <c:choose>
                              <c:when test="${p.status == 'ACTIVE'}">Tắt</c:when>
                              <c:otherwise>Bật</c:otherwise>
                            </c:choose>
                          </button>
                        </form>
                      </c:if>

                      <%-- Delete --%>
                      <c:choose>
                        <c:when test="${p.usedCount == 0}">
                          <form method="post"
                                action="${pageContext.request.contextPath}/admin/promotions/delete"
                                style="display:inline;"
                                onsubmit="return confirm('Xóa mã \'${p.code}\'?');">
                            <input type="hidden" name="promotionId" value="${p.id}"/>
                            <button type="submit" class="promo-action-btn is-danger">Xóa</button>
                          </form>
                        </c:when>
                        <c:otherwise>
                          <button class="promo-action-btn is-danger"
                                  disabled
                                  title="Không thể xóa: mã đã được dùng ${p.usedCount} lần"
                                  style="opacity:.35;cursor:not-allowed;">Xóa</button>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>

          <%-- Footer pagination --%>
          <div class="promo-table-footer">
            <span>
              Showing
              ${(pgCurrent - 1) * 10 + 1}–${pgCurrent * 10 < pgTotalItems ? pgCurrent * 10 : pgTotalItems}
              of <strong>${pgTotalItems}</strong> promotions
            </span>
            <c:if test="${pgTotal > 1}">
              <div class="promo-pagination">
                <c:if test="${pgCurrent > 1}">
                  <a href="${pgPath}?page=${pgCurrent - 1}${pgQueryExtra}"
                     class="promo-page-btn">‹</a>
                </c:if>
                <c:forEach begin="1" end="${pgTotal}" var="pg">
                  <a href="${pgPath}?page=${pg}${pgQueryExtra}"
                     class="promo-page-btn ${pg == pgCurrent ? 'is-active' : ''}">
                    ${pg}
                  </a>
                </c:forEach>
                <c:if test="${pgCurrent < pgTotal}">
                  <a href="${pgPath}?page=${pgCurrent + 1}${pgQueryExtra}"
                     class="promo-page-btn">›</a>
                </c:if>
              </div>
            </c:if>
          </div>
        </c:when>
        <c:otherwise>
          <div style="padding:48px 22px;text-align:center;color:var(--text-dim);font-size:14px;">
            <div style="font-size:36px;margin-bottom:12px;">🎟️</div>
            Chưa có mã giảm giá nào<c:if test="${not empty keyword or not empty statusFilter}">
              phù hợp với bộ lọc</c:if>.
          </div>
        </c:otherwise>
      </c:choose>
    </div><%-- /promo-section --%>
  </div><%-- /container --%>

  <%-- ══ MODAL TẠO / CHỈNH SỬA ════════════════════════════════════════════ --%>
  <div id="promoModal" class="promo-modal">
    <div class="promo-modal-backdrop" onclick="closeModal()"></div>
    <div class="promo-modal-panel">
      <div class="promo-modal-header">
        <span id="modalHeading" class="promo-modal-heading">Create Promotion</span>
        <button class="promo-modal-close" onclick="closeModal()">✕</button>
      </div>

      <form id="promoForm" method="post"
            action="${pageContext.request.contextPath}/admin/promotions/save" novalidate>
        <input type="hidden" id="modalPromotionId" name="promotionId" value=""/>

        <div class="promo-modal-body">

          <div class="pm-row">
            <div class="pm-field">
              <label class="pm-label" for="modalCode">Mã voucher *</label>
              <input type="text" id="modalCode" name="code" class="pm-input" required
                     maxlength="50" placeholder="SUMMER25"
                     style="text-transform:uppercase"
                     oninput="this.value=this.value.toUpperCase()"/>
              <span class="pm-hint">Chữ cái, số, gạch ngang, gạch dưới</span>
            </div>
            <div class="pm-field">
              <label class="pm-label" for="modalTitle">Tiêu đề *</label>
              <input type="text" id="modalTitle" name="title" class="pm-input" required
                     maxlength="255" placeholder="Giảm 25% mùa hè"/>
            </div>
          </div>

          <div class="pm-field">
            <label class="pm-label" for="modalDescription">Mô tả</label>
            <textarea id="modalDescription" name="description" class="pm-textarea"
                      placeholder="Điều kiện, đối tượng áp dụng..."></textarea>
          </div>

          <hr class="pm-divider"/>

          <div class="pm-row">
            <div class="pm-field">
              <label class="pm-label" for="modalDiscountType">Loại giảm giá *</label>
              <select id="modalDiscountType" name="discountType" class="pm-select"
                      onchange="onTypeChange(this.value)">
                <option value="PERCENTAGE">Phần trăm (%)</option>
                <option value="FIXED_AMOUNT">Số tiền cố định (₫)</option>
              </select>
            </div>
            <div class="pm-field">
              <label class="pm-label" for="modalDiscountValue">Giá trị giảm *</label>
              <input type="number" id="modalDiscountValue" name="discountValue" class="pm-input"
                     required min="0.01" step="0.01" placeholder="25"/>
            </div>
          </div>

          <div class="pm-row">
            <div class="pm-field" id="modalMaxDiscField">
              <label class="pm-label" for="modalMaxDiscount">Giảm tối đa (₫)</label>
              <input type="number" id="modalMaxDiscount" name="maxDiscountAmount"
                     class="pm-input" min="1" step="1000" placeholder="Không giới hạn"/>
              <span class="pm-hint">Chỉ với loại Phần trăm</span>
            </div>
            <div class="pm-field">
              <label class="pm-label" for="modalMinOrder">Đơn tối thiểu (₫)</label>
              <input type="number" id="modalMinOrder" name="minOrderAmount"
                     class="pm-input" min="1" step="1000" placeholder="Không yêu cầu"/>
            </div>
          </div>

          <hr class="pm-divider"/>

          <div class="pm-row">
            <div class="pm-field">
              <label class="pm-label" for="modalStartDate">Ngày bắt đầu *</label>
              <input type="date" id="modalStartDate" name="startDate" class="pm-input" required/>
            </div>
            <div class="pm-field">
              <label class="pm-label" for="modalEndDate">Ngày kết thúc *</label>
              <input type="date" id="modalEndDate" name="endDate" class="pm-input" required/>
            </div>
          </div>

          <div class="pm-field" style="max-width:50%;">
            <label class="pm-label" for="modalUsageLimit">Giới hạn lượt dùng</label>
            <input type="number" id="modalUsageLimit" name="usageLimit"
                   class="pm-input" min="1" step="1" placeholder="Không giới hạn"/>
          </div>

          <div id="modalUsedInfo" style="display:none;font-size:12px;color:var(--text-muted);
               background:rgba(255,255,255,.04);padding:10px 14px;border-radius:6px;margin-top:8px;">
            Mã này đã được sử dụng <strong id="modalUsedCount"></strong> lần.
            Không thể thay đổi mã voucher.
          </div>

        </div><%-- /modal-body --%>

        <div class="promo-modal-footer">
          <button type="button" class="promo-modal-cancel" onclick="closeModal()">Hủy</button>
          <button type="submit" class="promo-modal-submit" id="modalSubmitBtn">Tạo mã giảm giá</button>
        </div>
      </form>
    </div>
  </div>

</main>

<script>
var modal = document.getElementById('promoModal');

function openModal() {
  modal.classList.add('open');
  document.body.style.overflow = 'hidden';
}
function closeModal() {
  modal.classList.remove('open');
  document.body.style.overflow = '';
}
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') closeModal(); });

function formatIsoDate(d) {
  var y = d.getFullYear();
  var m = String(d.getMonth() + 1).padStart(2, '0');
  var day = String(d.getDate()).padStart(2, '0');
  return y + '-' + m + '-' + day;
}

function openCreateModal() {
  document.getElementById('modalHeading').textContent   = 'Create Promotion';
  document.getElementById('modalSubmitBtn').textContent = 'Tạo mã giảm giá';
  document.getElementById('modalPromotionId').value     = '';
  document.getElementById('promoForm').reset();
  document.getElementById('modalUsedInfo').style.display = 'none';
  document.getElementById('modalCode').removeAttribute('readonly');
  var today = new Date();
  var end = new Date();
  end.setDate(end.getDate() + 30);
  document.getElementById('modalStartDate').value = formatIsoDate(today);
  document.getElementById('modalEndDate').value   = formatIsoDate(end);
  onTypeChange('PERCENTAGE');
  openModal();
}

function openEditModal(btn) {
  var d = btn.dataset;
  document.getElementById('modalHeading').textContent   = 'Edit: ' + d.code;
  document.getElementById('modalSubmitBtn').textContent = 'Lưu thay đổi';
  document.getElementById('modalPromotionId').value     = d.id;
  document.getElementById('modalCode').value            = d.code;
  document.getElementById('modalTitle').value           = d.title;
  document.getElementById('modalDescription').value     = d.description || '';
  document.getElementById('modalDiscountType').value    = d.discountType;
  document.getElementById('modalDiscountValue').value   = d.discountValue;
  document.getElementById('modalMaxDiscount').value     = d.maxDiscount || '';
  document.getElementById('modalMinOrder').value        = d.minOrder || '';
  document.getElementById('modalStartDate').value       = d.startDate;
  document.getElementById('modalEndDate').value         = d.endDate;
  document.getElementById('modalUsageLimit').value      = d.usageLimit || '';

  var usedCount = parseInt(d.usedCount || '0');
  if (usedCount > 0) {
    document.getElementById('modalCode').setAttribute('readonly', 'readonly');
    document.getElementById('modalUsedInfo').style.display = '';
    document.getElementById('modalUsedCount').textContent = usedCount;
  } else {
    document.getElementById('modalCode').removeAttribute('readonly');
    document.getElementById('modalUsedInfo').style.display = 'none';
  }
  onTypeChange(d.discountType);
  openModal();
}

function onTypeChange(type) {
  document.getElementById('modalMaxDiscField').style.display =
    type === 'PERCENTAGE' ? '' : 'none';
}

// Khởi tạo
onTypeChange('PERCENTAGE');
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
