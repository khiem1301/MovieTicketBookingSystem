<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quy tắc giá — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<c:set var="extraCss2" value="admin-pricing-rules"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="isEdit" value="${not empty editRule}"/>
<c:set var="formCondition" value="${not empty inputConditionType ? inputConditionType : (isEdit ? editRule.conditionType : 'DAY_OF_WEEK')}"/>
<c:set var="formAdjType" value="${not empty inputAdjustmentType ? inputAdjustmentType : (isEdit ? editRule.adjustmentType : 'FIXED_AMOUNT')}"/>
<c:set var="formStatus" value="${not empty inputStatus ? inputStatus : (isEdit ? editRule.status : 'ACTIVE')}"/>
<c:set var="formName" value="${not empty inputRuleName ? inputRuleName : (isEdit ? editRule.ruleName : '')}"/>
<c:set var="formAdjValue" value="${not empty inputAdjustmentValue ? inputAdjustmentValue : (isEdit ? editRule.adjustmentValue : '')}"/>
<c:set var="formTimeFrom" value="${not empty inputTimeFrom ? inputTimeFrom : (isEdit && editRule.timeFrom != null ? fn:substring(editRule.timeFrom, 0, 5) : '')}"/>
<c:set var="formTimeTo" value="${not empty inputTimeTo ? inputTimeTo : (isEdit && editRule.timeTo != null ? fn:substring(editRule.timeTo, 0, 5) : '')}"/>
<c:set var="formDateFrom" value="${not empty inputDateFrom ? inputDateFrom : (isEdit && editRule.dateFrom != null ? editRule.dateFrom : '')}"/>
<c:set var="formDateTo" value="${not empty inputDateTo ? inputDateTo : (isEdit && editRule.dateTo != null ? editRule.dateTo : '')}"/>
<c:set var="nameLen" value="${fn:length(formName)}"/>

<main class="admin-page mpr-page">
  <div class="container">

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Quy tắc giá động</h1>
        <p class="admin-page-subtitle">Tạo và quản lý quy tắc điều chỉnh giá suất chiếu</p>
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

    <div class="mpr-layout">

      <aside class="mpr-sidebar">
        <div class="admin-card" id="rule-form">
          <h2 class="mpr-section-title">
            <c:choose>
              <c:when test="${isEdit}">Sửa quy tắc</c:when>
              <c:otherwise>Tạo quy tắc mới</c:otherwise>
            </c:choose>
          </h2>

          <form method="post" action="${pageContext.request.contextPath}/admin/pricing-rules" class="mpr-form" id="pricingRuleForm">
            <input type="hidden" name="action" value="${isEdit ? 'update' : 'create'}"/>
            <c:if test="${isEdit}">
              <input type="hidden" name="id" value="${editRule.id}"/>
            </c:if>

            <div class="mpr-form-stack">
              <div class="admin-field mpr-field">
                <div class="mpr-label-row">
                  <label class="admin-label" for="ruleName">Tên quy tắc *</label>
                  <span class="mpr-char-count" id="ruleNameCount"><c:out value="${nameLen}"/>/100</span>
                </div>
                <input type="text" id="ruleName" name="ruleName" class="admin-input" maxlength="100" required
                       value="<c:out value='${formName}'/>"/>
                <p class="mpr-field-tip">Bắt buộc. Tối đa 100 ký tự. Nên đặt tên dễ hiểu (vd. Phụ thu cuối tuần).</p>
              </div>

              <div class="admin-field mpr-field">
                <label class="admin-label" for="conditionType">Loại điều kiện *</label>
                <select id="conditionType" name="conditionType" class="admin-select" required>
                  <option value="DAY_OF_WEEK" <c:if test="${formCondition == 'DAY_OF_WEEK'}">selected</c:if>>Ngày trong tuần</option>
                  <option value="TIME_RANGE" <c:if test="${formCondition == 'TIME_RANGE'}">selected</c:if>>Khung giờ</option>
                  <option value="DATE_RANGE" <c:if test="${formCondition == 'DATE_RANGE'}">selected</c:if>>Khoảng ngày</option>
                  <option value="SPECIFIC_DATE" <c:if test="${formCondition == 'SPECIFIC_DATE'}">selected</c:if>>Ngày cụ thể</option>
                </select>
                <p class="mpr-field-tip">Chọn khi nào rule áp dụng. Các field bên dưới đổi theo loại này.</p>
              </div>

              <div class="admin-field mpr-condition-block mpr-field" data-for="DAY_OF_WEEK" id="block-dow">
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
                <p class="mpr-field-tip">Chọn ít nhất 1 ngày (T2–CN). Có thể chọn nhiều ngày.</p>
              </div>

              <div class="admin-field mpr-condition-block mpr-field" data-for="TIME_RANGE" id="block-time">
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
                <p class="mpr-field-tip">Bắt buộc cả hai. Không được trùng nhau. Được phép qua đêm (vd. 22:00 → 02:00).</p>
              </div>

              <div class="admin-field mpr-condition-block mpr-field" data-for="DATE_RANGE" id="block-date-range">
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
                <p class="mpr-field-tip">Ngày kết thúc phải ≥ ngày bắt đầu.</p>
              </div>

              <div class="admin-field mpr-condition-block mpr-field" data-for="SPECIFIC_DATE" id="block-specific">
                <label class="admin-label" for="dateFromSpecific">Ngày áp dụng *</label>
                <input type="date" id="dateFromSpecific" name="dateFrom" class="admin-input"
                       value="<c:out value='${formDateFrom}'/>"/>
                <p class="mpr-field-tip">Chỉ một ngày (vd. ngày lễ / sự kiện).</p>
              </div>

              <div class="admin-field mpr-field">
                <label class="admin-label" for="adjustmentType">Loại điều chỉnh *</label>
                <select id="adjustmentType" name="adjustmentType" class="admin-select" required>
                  <option value="FIXED_AMOUNT" <c:if test="${formAdjType == 'FIXED_AMOUNT'}">selected</c:if>>Số tiền cố định (VND)</option>
                  <option value="PERCENTAGE" <c:if test="${formAdjType == 'PERCENTAGE'}">selected</c:if>>Phần trăm (%)</option>
                </select>
                <p class="mpr-field-tip">Đổi loại sẽ xóa ô giá trị để nhập lại.</p>
              </div>

              <div class="admin-field mpr-field">
                <label class="admin-label" for="adjustmentValue">Giá trị *</label>
                <input type="number" id="adjustmentValue" name="adjustmentValue" class="admin-input"
                       step="any" required
                       value="<c:out value='${formAdjValue}'/>"/>
                <p class="mpr-field-tip">Khác 0. %: từ -100 đến 100. Tiền: từ -5.000.000 đến 5.000.000đ.</p>
              </div>

              <div class="admin-field mpr-field">
                <label class="admin-label" for="statusForm">Trạng thái *</label>
                <select id="statusForm" name="status" class="admin-select" required>
                  <option value="ACTIVE" <c:if test="${formStatus == 'ACTIVE'}">selected</c:if>>ACTIVE</option>
                  <option value="INACTIVE" <c:if test="${formStatus == 'INACTIVE'}">selected</c:if>>INACTIVE</option>
                </select>
                <p class="mpr-field-tip">ACTIVE mới áp vào giá khách. INACTIVE = tắt tạm, không xóa.</p>
              </div>
            </div>

            <div class="admin-btn-group mpr-form-actions">
              <button type="submit" class="admin-btn admin-btn--primary">
                <c:out value="${isEdit ? 'Cập nhật' : 'Tạo quy tắc'}"/>
              </button>
              <c:if test="${isEdit}">
                <a href="${pageContext.request.contextPath}/admin/pricing-rules" class="admin-btn admin-btn--ghost">Hủy</a>
              </c:if>
            </div>
          </form>
        </div>
      </aside>

      <section class="mpr-main">
        <div class="admin-card">
          <form class="admin-filter" method="get" action="${pageContext.request.contextPath}/admin/pricing-rules"
                id="ruleFilterForm">
            <div class="admin-field admin-field--grow">
              <label class="admin-label" for="ruleKeyword">Tìm theo tên</label>
              <input type="text" id="ruleKeyword" name="keyword" class="admin-input"
                     placeholder="Gõ để lọc tên quy tắc..."
                     autocomplete="off"
                     value="<c:out value='${filterKeyword}'/>"/>
            </div>
            <div class="admin-field">
              <label class="admin-label" for="filterStatus">Trạng thái</label>
              <select id="filterStatus" name="status" class="admin-select">
                <option value="">Tất cả</option>
                <option value="ACTIVE" <c:if test="${filterStatus == 'ACTIVE'}">selected</c:if>>ACTIVE</option>
                <option value="INACTIVE" <c:if test="${filterStatus == 'INACTIVE'}">selected</c:if>>INACTIVE</option>
              </select>
            </div>
            <a href="${pageContext.request.contextPath}/admin/pricing-rules" class="admin-btn admin-btn--ghost">Xóa lọc</a>
          </form>

          <p class="admin-stats">Tổng: <strong><c:out value="${totalRules}"/></strong> quy tắc</p>

          <div id="pricingRuleListAjax" data-mgr-ajax-list>
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
                              <fmt:formatNumber value="${r.adjustmentValue}" maxFractionDigits="2" pattern="+#.##;-#.##"/>%
                            </c:when>
                            <c:otherwise>
                              <fmt:formatNumber value="${r.adjustmentValue}" type="number" maxFractionDigits="0" pattern="+#,##0;-#,##0"/>đ
                            </c:otherwise>
                          </c:choose>
                        </td>
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
                               href="${pageContext.request.contextPath}/admin/pricing-rules?action=edit&amp;id=${r.id}<c:if test='${not empty filterKeyword}'>&amp;keyword=<c:out value='${filterKeyword}'/></c:if><c:if test='${not empty filterStatus}'>&amp;status=<c:out value='${filterStatus}'/></c:if>">Sửa</a>
                            <form method="post" action="${pageContext.request.contextPath}/admin/pricing-rules" class="mpr-inline-form">
                              <input type="hidden" name="action" value="toggle-status"/>
                              <input type="hidden" name="id" value="${r.id}"/>
                              <c:if test="${not empty filterKeyword}"><input type="hidden" name="keyword" value="<c:out value='${filterKeyword}'/>"/></c:if>
                              <c:if test="${not empty filterStatus}"><input type="hidden" name="status" value="<c:out value='${filterStatus}'/>"/></c:if>
                              <c:if test="${not empty pgCurrent}"><input type="hidden" name="page" value="${pgCurrent}"/></c:if>
                              <button type="submit" class="admin-btn admin-btn--sm ${r.status == 'ACTIVE' ? 'admin-btn--ghost' : 'admin-btn--success'}">
                                <c:out value="${r.status == 'ACTIVE' ? 'Tắt' : 'Bật'}"/>
                              </button>
                            </form>
                            <form method="post" action="${pageContext.request.contextPath}/admin/pricing-rules" class="mpr-inline-form"
                                  onsubmit="return confirm('Xóa quy tắc này? Đơn đã đặt không bị ảnh hưởng.');">
                              <input type="hidden" name="action" value="delete"/>
                              <input type="hidden" name="id" value="${r.id}"/>
                              <c:if test="${not empty filterKeyword}"><input type="hidden" name="keyword" value="<c:out value='${filterKeyword}'/>"/></c:if>
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
              <%@ include file="/WEB-INF/views/common/pagination.jspf" %>
            </c:otherwise>
          </c:choose>
          </div>
        </div>
      </section>

    </div>
  </div>
</main>

<script>
(function () {
  var conditionSelect = document.getElementById('conditionType');
  var adjType = document.getElementById('adjustmentType');
  var adjValue = document.getElementById('adjustmentValue');
  var ruleName = document.getElementById('ruleName');
  var ruleNameCount = document.getElementById('ruleNameCount');
  var filterForm = document.getElementById('ruleFilterForm');
  var keywordInput = document.getElementById('ruleKeyword');
  var statusSelect = document.getElementById('filterStatus');

  function syncConditionBlocks() {
    if (!conditionSelect) return;
    var type = conditionSelect.value;
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

  if (conditionSelect) {
    conditionSelect.addEventListener('change', syncConditionBlocks);
    syncConditionBlocks();
  }

  if (adjType && adjValue) {
    adjType.addEventListener('change', function () {
      adjValue.value = '';
      adjValue.focus();
    });
  }

  if (ruleName && ruleNameCount) {
    function updateCount() {
      ruleNameCount.textContent = (ruleName.value || '').length + '/100';
    }
    ruleName.addEventListener('input', updateCount);
    updateCount();
  }

  if (filterForm && keywordInput) {
    var timer = null;
    function submitFilter() {
      var pageInput = filterForm.querySelector('input[name="page"]');
      if (pageInput) pageInput.remove();
      filterForm.submit();
    }
    keywordInput.addEventListener('input', function () {
      clearTimeout(timer);
      timer = setTimeout(submitFilter, 300);
    });
    if (statusSelect) {
      statusSelect.addEventListener('change', submitFilter);
    }
  }

  <c:if test="${isEdit || not empty errors}">
  var form = document.getElementById('rule-form');
  if (form) form.scrollIntoView({ behavior: 'smooth', block: 'start' });
  </c:if>
})();
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/mgr-ajax-pagination.js?v=1"></script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
