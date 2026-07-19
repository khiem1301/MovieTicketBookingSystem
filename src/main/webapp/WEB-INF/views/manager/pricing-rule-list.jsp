<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quy tắc giá — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<c:set var="extraCss2" value="manager-pricing-rules"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="isEdit" value="${not empty editRule}"/>
<c:set var="formCondition" value="${not empty inputConditionType ? inputConditionType : (isEdit ? editRule.conditionType : 'DAY_OF_WEEK')}"/>
<c:set var="formAdjType" value="${not empty inputAdjustmentType ? inputAdjustmentType : (isEdit ? editRule.adjustmentType : 'FIXED_AMOUNT')}"/>
<c:set var="formStatus" value="${not empty inputStatus ? inputStatus : (isEdit ? editRule.status : 'ACTIVE')}"/>
<c:set var="formName" value="${not empty inputRuleName ? inputRuleName : (isEdit ? editRule.ruleName : '')}"/>
<c:set var="formPriority" value="${not empty inputPriority ? inputPriority : (isEdit ? editRule.priority : '0')}"/>
<c:set var="formAdjValue" value="${not empty inputAdjustmentValue ? inputAdjustmentValue : (isEdit ? editRule.adjustmentValue : '')}"/>
<c:set var="formTimeFrom" value="${not empty inputTimeFrom ? inputTimeFrom : (isEdit && editRule.timeFrom != null ? fn:substring(editRule.timeFrom, 0, 5) : '')}"/>
<c:set var="formTimeTo" value="${not empty inputTimeTo ? inputTimeTo : (isEdit && editRule.timeTo != null ? fn:substring(editRule.timeTo, 0, 5) : '')}"/>
<c:set var="formDateFrom" value="${not empty inputDateFrom ? inputDateFrom : (isEdit && editRule.dateFrom != null ? editRule.dateFrom : '')}"/>
<c:set var="formDateTo" value="${not empty inputDateTo ? inputDateTo : (isEdit && editRule.dateTo != null ? editRule.dateTo : '')}"/>

<main class="admin-page mpr-page">
  <div class="container">

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Quy tắc giá động</h1>
        <p class="admin-page-subtitle">Tạo và quản lý quy tắc điều chỉnh giá suất chiếu (FR-49)</p>
      </div>
    </div>

    <c:if test="${param.success == 'created'}">
      <div class="admin-alert admin-alert--success" role="status">Đã tạo quy tắc giá mới.</div>
    </c:if>
    <c:if test="${param.success == 'updated'}">
      <div class="admin-alert admin-alert--success" role="status">Đã cập nhật quy tắc giá.</div>
    </c:if>
    <c:if test="${param.success == 'deleted'}">
      <div class="admin-alert admin-alert--success" role="status">Đã xóa quy tắc giá.</div>
    </c:if>
    <c:if test="${param.success == 'status-updated'}">
      <div class="admin-alert admin-alert--success" role="status">Đã cập nhật trạng thái quy tắc.</div>
    </c:if>
    <c:if test="${not empty errors}">
      <div class="admin-alert admin-alert--error" role="alert">
        <ul class="mpr-error-list">
          <c:forEach var="err" items="${errors}">
            <li><c:out value="${err}"/></li>
          </c:forEach>
        </ul>
      </div>
    </c:if>
    <c:if test="${not empty previewError}">
      <div class="admin-alert admin-alert--error" role="alert"><c:out value="${previewError}"/></div>
    </c:if>
    <c:if test="${previewSuccess}">
      <div class="admin-alert admin-alert--success" role="status">
        Giá hiệu quả (sau rule ACTIVE):
        <strong><fmt:formatNumber value="${previewPrice}" type="number" maxFractionDigits="0"/>đ</strong>
      </div>
    </c:if>

    <div class="mpr-layout">

      <%-- LEFT: create / edit + preview --%>
      <aside class="mpr-sidebar">
        <div class="admin-card" id="rule-form">
          <h2 class="mpr-section-title">
            <c:choose>
              <c:when test="${isEdit}">Sửa quy tắc</c:when>
              <c:otherwise>Tạo quy tắc mới</c:otherwise>
            </c:choose>
          </h2>

          <form method="post" action="${pageContext.request.contextPath}/manager/pricing-rules" class="mpr-form">
            <input type="hidden" name="action" value="${isEdit ? 'update' : 'create'}"/>
            <c:if test="${isEdit}">
              <input type="hidden" name="id" value="${editRule.id}"/>
            </c:if>

            <div class="mpr-form-stack">
              <div class="admin-field">
                <label class="admin-label" for="ruleName">Tên quy tắc *</label>
                <input type="text" id="ruleName" name="ruleName" class="admin-input" maxlength="100" required
                       value="<c:out value='${formName}'/>"/>
              </div>

              <div class="admin-field">
                <label class="admin-label" for="conditionType">Loại điều kiện *</label>
                <select id="conditionType" name="conditionType" class="admin-select" required>
                  <option value="DAY_OF_WEEK" <c:if test="${formCondition == 'DAY_OF_WEEK'}">selected</c:if>>Ngày trong tuần</option>
                  <option value="TIME_RANGE" <c:if test="${formCondition == 'TIME_RANGE'}">selected</c:if>>Khung giờ</option>
                  <option value="DATE_RANGE" <c:if test="${formCondition == 'DATE_RANGE'}">selected</c:if>>Khoảng ngày</option>
                  <option value="SPECIFIC_DATE" <c:if test="${formCondition == 'SPECIFIC_DATE'}">selected</c:if>>Ngày cụ thể</option>
                </select>
              </div>

              <div class="admin-field mpr-condition-block" data-for="DAY_OF_WEEK" id="block-dow">
                <span class="admin-label">Ngày trong tuần *</span>
                <div class="mpr-day-checks">
                  <c:forTokens items="1,2,3,4,5,6,7" delims="," var="d">
                    <label class="mpr-day-check">
                      <input type="checkbox" name="days" value="${d}"
                             <c:if test="${selectedDays != null && selectedDays.contains(d)}">checked</c:if>/>
                      <c:choose>
                        <c:when test="${d == '1'}">T2</c:when>
                        <c:when test="${d == '2'}">T3</c:when>
                        <c:when test="${d == '3'}">T4</c:when>
                        <c:when test="${d == '4'}">T5</c:when>
                        <c:when test="${d == '5'}">T6</c:when>
                        <c:when test="${d == '6'}">T7</c:when>
                        <c:otherwise>CN</c:otherwise>
                      </c:choose>
                    </label>
                  </c:forTokens>
                </div>
                <p class="mpr-hint">1 = Thứ 2 … 7 = Chủ nhật</p>
              </div>

              <div class="admin-field mpr-condition-block" data-for="TIME_RANGE" id="block-time">
                <div class="mpr-inline-pair">
                  <div class="admin-field">
                    <label class="admin-label" for="timeFrom">Từ giờ *</label>
                    <input type="time" id="timeFrom" name="timeFrom" class="admin-input"
                           value="<c:out value='${formTimeFrom}'/>"/>
                  </div>
                  <div class="admin-field">
                    <label class="admin-label" for="timeTo">Đến giờ *</label>
                    <input type="time" id="timeTo" name="timeTo" class="admin-input"
                           value="<c:out value='${formTimeTo}'/>"/>
                  </div>
                </div>
                <p class="mpr-hint">Cho phép qua đêm (vd. 22:00 → 02:00)</p>
              </div>

              <div class="admin-field mpr-condition-block" data-for="DATE_RANGE" id="block-date-range">
                <div class="mpr-inline-pair">
                  <div class="admin-field">
                    <label class="admin-label" for="dateFrom">Từ ngày *</label>
                    <input type="date" id="dateFrom" name="dateFrom" class="admin-input"
                           value="<c:out value='${formDateFrom}'/>"/>
                  </div>
                  <div class="admin-field">
                    <label class="admin-label" for="dateTo">Đến ngày *</label>
                    <input type="date" id="dateTo" name="dateTo" class="admin-input"
                           value="<c:out value='${formDateTo}'/>"/>
                  </div>
                </div>
              </div>

              <div class="admin-field mpr-condition-block" data-for="SPECIFIC_DATE" id="block-specific">
                <label class="admin-label" for="dateFromSpecific">Ngày áp dụng *</label>
                <input type="date" id="dateFromSpecific" name="dateFrom" class="admin-input"
                       value="<c:out value='${formDateFrom}'/>"/>
              </div>

              <div class="admin-field">
                <label class="admin-label" for="adjustmentType">Loại điều chỉnh *</label>
                <select id="adjustmentType" name="adjustmentType" class="admin-select" required>
                  <option value="FIXED_AMOUNT" <c:if test="${formAdjType == 'FIXED_AMOUNT'}">selected</c:if>>Số tiền cố định (VND)</option>
                  <option value="PERCENTAGE" <c:if test="${formAdjType == 'PERCENTAGE'}">selected</c:if>>Phần trăm (%)</option>
                </select>
              </div>

              <div class="admin-field">
                <label class="admin-label" for="adjustmentValue">Giá trị *</label>
                <input type="number" id="adjustmentValue" name="adjustmentValue" class="admin-input"
                       step="any" min="0" required
                       value="<c:out value='${formAdjValue}'/>"/>
              </div>

              <div class="admin-field">
                <label class="admin-label" for="priority">Độ ưu tiên *</label>
                <input type="number" id="priority" name="priority" class="admin-input"
                       min="0" max="9999" required
                       value="<c:out value='${formPriority}'/>"/>
                <p class="mpr-hint">Cao hơn sắp trước (rule khớp vẫn cộng dồn)</p>
              </div>

              <div class="admin-field">
                <label class="admin-label" for="statusForm">Trạng thái *</label>
                <select id="statusForm" name="status" class="admin-select" required>
                  <option value="ACTIVE" <c:if test="${formStatus == 'ACTIVE'}">selected</c:if>>ACTIVE</option>
                  <option value="INACTIVE" <c:if test="${formStatus == 'INACTIVE'}">selected</c:if>>INACTIVE</option>
                </select>
              </div>
            </div>

            <div class="admin-btn-group mpr-form-actions">
              <button type="submit" class="admin-btn admin-btn--primary">
                <c:out value="${isEdit ? 'Cập nhật' : 'Tạo quy tắc'}"/>
              </button>
              <c:if test="${isEdit}">
                <a href="${pageContext.request.contextPath}/manager/pricing-rules" class="admin-btn admin-btn--ghost">Hủy</a>
              </c:if>
            </div>
          </form>
        </div>

        <div class="admin-card mpr-preview-card">
          <h2 class="mpr-section-title">Xem trước giá</h2>
          <p class="mpr-hint mpr-hint--block">Áp toàn bộ rule <strong>ACTIVE</strong> lên giá gốc + ngày giờ suất mẫu.</p>
          <form method="post" action="${pageContext.request.contextPath}/manager/pricing-rules" class="mpr-form-stack">
            <input type="hidden" name="action" value="preview"/>
            <div class="admin-field">
              <label class="admin-label" for="previewBasePrice">Giá gốc (VND)</label>
              <input type="number" id="previewBasePrice" name="previewBasePrice" class="admin-input"
                     min="1" step="1000" required
                     value="<c:out value='${previewBasePrice}'/>" placeholder="100000"/>
            </div>
            <div class="admin-field">
              <label class="admin-label" for="previewDateTime">Ngày giờ suất</label>
              <input type="datetime-local" id="previewDateTime" name="previewDateTime" class="admin-input"
                     required value="<c:out value='${previewDateTime}'/>"/>
            </div>
            <button type="submit" class="admin-btn admin-btn--primary mpr-preview-btn">Xem giá hiệu quả</button>
          </form>
        </div>
      </aside>

      <%-- RIGHT: list --%>
      <section class="mpr-main">
        <div class="admin-card">
          <form class="admin-filter" method="get" action="${pageContext.request.contextPath}/manager/pricing-rules">
            <div class="admin-field admin-field--grow">
              <label class="admin-label" for="q">Tìm theo tên</label>
              <input type="text" id="q" name="q" class="admin-input"
                     placeholder="Tên quy tắc..."
                     value="<c:out value='${filterQ}'/>"/>
            </div>
            <div class="admin-field">
              <label class="admin-label" for="status">Trạng thái</label>
              <select id="status" name="status" class="admin-select">
                <option value="">Tất cả</option>
                <option value="ACTIVE" <c:if test="${filterStatus == 'ACTIVE'}">selected</c:if>>ACTIVE</option>
                <option value="INACTIVE" <c:if test="${filterStatus == 'INACTIVE'}">selected</c:if>>INACTIVE</option>
              </select>
            </div>
            <button type="submit" class="admin-btn admin-btn--ghost">Lọc</button>
            <a href="${pageContext.request.contextPath}/manager/pricing-rules" class="admin-btn admin-btn--ghost">Xóa lọc</a>
          </form>

          <p class="admin-stats">Tổng: <strong><c:out value="${totalRules}"/></strong> quy tắc</p>

          <c:choose>
            <c:when test="${empty rules}">
              <p class="mpr-empty">Chưa có quy tắc nào.</p>
            </c:when>
            <c:otherwise>
              <div class="admin-table-wrap">
                <table class="admin-table">
                  <thead>
                    <tr>
                      <th>Tên</th>
                      <th>Điều kiện</th>
                      <th>Chi tiết</th>
                      <th>Điều chỉnh</th>
                      <th>Ưu tiên</th>
                      <th>Trạng thái</th>
                      <th>Ngày tạo</th>
                      <th>Thao tác</th>
                    </tr>
                  </thead>
                  <tbody>
                    <c:forEach var="r" items="${rules}">
                      <tr>
                        <td><strong><c:out value="${r.ruleName}"/></strong></td>
                        <td>
                          <c:choose>
                            <c:when test="${r.conditionType == 'DAY_OF_WEEK'}">Ngày trong tuần</c:when>
                            <c:when test="${r.conditionType == 'TIME_RANGE'}">Khung giờ</c:when>
                            <c:when test="${r.conditionType == 'DATE_RANGE'}">Khoảng ngày</c:when>
                            <c:when test="${r.conditionType == 'SPECIFIC_DATE'}">Ngày cụ thể</c:when>
                            <c:otherwise><c:out value="${r.conditionType}"/></c:otherwise>
                          </c:choose>
                        </td>
                        <td class="cell-muted">
                          <c:choose>
                            <c:when test="${r.conditionType == 'DAY_OF_WEEK'}">
                              <c:out value="${r.dayOfWeek}"/>
                            </c:when>
                            <c:when test="${r.conditionType == 'TIME_RANGE'}">
                              <c:out value="${fn:substring(r.timeFrom, 0, 5)}"/> – <c:out value="${fn:substring(r.timeTo, 0, 5)}"/>
                            </c:when>
                            <c:when test="${r.conditionType == 'DATE_RANGE'}">
                              <c:out value="${r.dateFrom}"/> → <c:out value="${r.dateTo}"/>
                            </c:when>
                            <c:when test="${r.conditionType == 'SPECIFIC_DATE'}">
                              <c:out value="${r.dateFrom}"/>
                            </c:when>
                          </c:choose>
                        </td>
                        <td>
                          <c:choose>
                            <c:when test="${r.adjustmentType == 'PERCENTAGE'}">
                              +<fmt:formatNumber value="${r.adjustmentValue}" maxFractionDigits="2"/>%
                            </c:when>
                            <c:otherwise>
                              +<fmt:formatNumber value="${r.adjustmentValue}" type="number" maxFractionDigits="0"/>đ
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td><c:out value="${r.priority}"/></td>
                        <td>
                          <c:choose>
                            <c:when test="${r.status == 'ACTIVE'}">
                              <span class="admin-badge admin-badge--active">ACTIVE</span>
                            </c:when>
                            <c:otherwise>
                              <span class="admin-badge admin-badge--inactive">INACTIVE</span>
                            </c:otherwise>
                          </c:choose>
                        </td>
                        <td class="cell-muted">
                          <c:if test="${r.createdAt != null}">
                            <fmt:formatDate value="${r.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                          </c:if>
                        </td>
                        <td>
                          <div class="admin-btn-group">
                            <a class="admin-btn admin-btn--ghost admin-btn--sm"
                               href="${pageContext.request.contextPath}/manager/pricing-rules?action=edit&amp;id=${r.id}<c:if test='${not empty filterQ}'>&amp;q=<c:out value='${filterQ}'/></c:if><c:if test='${not empty filterStatus}'>&amp;status=<c:out value='${filterStatus}'/></c:if>">Sửa</a>
                            <form method="post" action="${pageContext.request.contextPath}/manager/pricing-rules" class="mpr-inline-form">
                              <input type="hidden" name="action" value="toggle-status"/>
                              <input type="hidden" name="id" value="${r.id}"/>
                              <c:if test="${not empty filterQ}"><input type="hidden" name="q" value="<c:out value='${filterQ}'/>"/></c:if>
                              <c:if test="${not empty filterStatus}"><input type="hidden" name="status" value="<c:out value='${filterStatus}'/>"/></c:if>
                              <c:if test="${not empty pgCurrent}"><input type="hidden" name="page" value="${pgCurrent}"/></c:if>
                              <button type="submit" class="admin-btn admin-btn--sm ${r.status == 'ACTIVE' ? 'admin-btn--ghost' : 'admin-btn--success'}">
                                <c:out value="${r.status == 'ACTIVE' ? 'Tắt' : 'Bật'}"/>
                              </button>
                            </form>
                            <form method="post" action="${pageContext.request.contextPath}/manager/pricing-rules" class="mpr-inline-form"
                                  onsubmit="return confirm('Xóa quy tắc này? Đơn đã đặt không bị ảnh hưởng.');">
                              <input type="hidden" name="action" value="delete"/>
                              <input type="hidden" name="id" value="${r.id}"/>
                              <c:if test="${not empty filterQ}"><input type="hidden" name="q" value="<c:out value='${filterQ}'/>"/></c:if>
                              <c:if test="${not empty filterStatus}"><input type="hidden" name="status" value="<c:out value='${filterStatus}'/>"/></c:if>
                              <c:if test="${not empty pgCurrent}"><input type="hidden" name="page" value="${pgCurrent}"/></c:if>
                              <button type="submit" class="admin-btn admin-btn--danger admin-btn--sm">Xóa</button>
                            </form>
                          </div>
                        </td>
                      </tr>
                    </c:forEach>
                  </tbody>
                </table>
              </div>
              <%@ include file="/WEB-INF/views/admin/pagination.jspf" %>
            </c:otherwise>
          </c:choose>
        </div>
      </section>

    </div>
  </div>
</main>

<script>
(function () {
  var select = document.getElementById('conditionType');
  if (!select) return;

  function syncConditionBlocks() {
    var type = select.value;
    document.querySelectorAll('.mpr-condition-block').forEach(function (block) {
      var match = block.getAttribute('data-for') === type;
      block.style.display = match ? '' : 'none';
      block.querySelectorAll('input, select').forEach(function (el) {
        if (el.type === 'checkbox') {
          el.disabled = !match;
        } else if (el.name === 'dateFrom' || el.name === 'dateTo'
            || el.name === 'timeFrom' || el.name === 'timeTo') {
          el.disabled = !match;
        }
      });
    });
  }

  select.addEventListener('change', syncConditionBlocks);
  syncConditionBlocks();

  <c:if test="${isEdit || not empty errors}">
  var form = document.getElementById('rule-form');
  if (form) form.scrollIntoView({ behavior: 'smooth', block: 'start' });
  </c:if>
})();
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
