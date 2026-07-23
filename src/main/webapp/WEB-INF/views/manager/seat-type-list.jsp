<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Loại ghế — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="mgr-page">

  <div class="mgr-breadcrumb">
    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
    <span>›</span>
    <span>Quản lý Loại ghế</span>
  </div>

  <h1 class="mgr-title">Quản lý Loại ghế</h1>

  <c:if test="${param.success == 'created'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã thêm loại ghế thành công!</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã cập nhật loại ghế thành công!</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã xóa loại ghế thành công!</div>
  </c:if>
  <c:if test="${param.error == 'in_use'}">
    <div class="mgr-alert mgr-alert--error">Không thể xóa — loại ghế đang được sử dụng trong layout phòng chiếu.</div>
  </c:if>

  <div class="mgr-grid">

    <div class="mgr-card" id="seat-type-form">
      <c:choose>
        <c:when test="${not empty editSeatType}">
          <c:set var="formTypeName" value="${not empty inputTypeName ? inputTypeName : editSeatType.typeName}"/>
          <c:set var="formDescription" value="${not empty inputDescription ? inputDescription : editSeatType.description}"/>
          <c:set var="formMultiplier" value="${not empty inputMultiplier ? inputMultiplier : editSeatType.priceMultiplier}"/>
          <c:set var="typeNameLen" value="${fn:length(formTypeName)}"/>
          <c:set var="descLen" value="${fn:length(formDescription)}"/>

          <h2 class="mgr-card-title"><span class="mgr-card-title-icon">✏️</span> Sửa loại ghế</h2>
          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>
          <c:if test="${seatTypeIdentityLocked}">
            <div class="mgr-alert mgr-alert--error" style="background:rgba(255,193,7,0.12);border-color:rgba(255,193,7,0.35);color:#ffd54f">
              Loại ghế đang có <strong>${editSeatTypeUsage}</strong> ghế trong layout phòng chiếu —
              không thể đổi <strong>tên</strong> hoặc <strong>kích thước</strong>.
              Vẫn có thể cập nhật hệ số giá và mô tả.
            </div>
          </c:if>
          <form method="post" action="${pageContext.request.contextPath}/manager/seat-types" class="mgr-form" id="seatTypeForm">
            <input type="hidden" name="action" value="update"/>
            <input type="hidden" name="id" value="<c:out value='${editSeatType.id}'/>"/>
            <c:if test="${seatTypeIdentityLocked}">
              <input type="hidden" name="typeName" value="<c:out value='${editSeatType.typeName}'/>"/>
              <input type="hidden" name="seatSpan" value="<c:out value='${editSeatType.seatSpan}'/>"/>
            </c:if>

            <div class="mgr-form-group">
              <div class="mgr-label-row">
                <label for="typeName">Tên loại ghế <span class="required">*</span></label>
                <span class="mgr-char-count" id="typeNameCount"><c:out value="${typeNameLen}"/>/50</span>
              </div>
              <input id="typeName" type="text" maxlength="50" required
                     data-char-count="typeNameCount" data-char-max="50"
                     <c:choose>
                       <c:when test="${seatTypeIdentityLocked}">
                         disabled
                         value="<c:out value='${editSeatType.typeName}'/>"
                       </c:when>
                       <c:otherwise>
                         name="typeName"
                         aria-describedby="typeNameTip"
                         value="<c:out value='${formTypeName}'/>"
                       </c:otherwise>
                     </c:choose>/>
              <p id="typeNameTip" class="mgr-field-tip">
                <c:choose>
                  <c:when test="${seatTypeIdentityLocked}">Đã khóa vì loại ghế đang được dùng trong phòng chiếu.</c:when>
                  <c:otherwise>Bắt buộc. Tối đa 50 ký tự. Nên viết hoa (vd. PREMIUM, VIP).</c:otherwise>
                </c:choose>
              </p>
            </div>

            <div class="mgr-form-group">
              <label for="priceMultiplier">Hệ số giá <span class="required">*</span></label>
              <input id="priceMultiplier" type="number" name="priceMultiplier"
                     step="0.01" min="0.01" max="9.99" required
                     inputmode="decimal"
                     aria-describedby="multiplierTip"
                     value="<c:out value='${formMultiplier}'/>"/>
              <p id="multiplierTip" class="mgr-field-tip">
                Bắt buộc. Định dạng X.XX — từ 0.01 đến 9.99 (vd. 1.00, 1.50). Giá vé = giá suất × hệ số này.
              </p>
            </div>

            <div class="mgr-form-group">
              <label for="seatSpan">Kích thước trên layout <span class="required">*</span></label>
              <c:set var="editSpan" value="${seatTypeIdentityLocked ? editSeatType.seatSpan : (not empty inputSeatSpan ? inputSeatSpan : editSeatType.seatSpan)}"/>
              <select id="seatSpan"
                      aria-describedby="seatSpanTip"
                      <c:choose>
                        <c:when test="${seatTypeIdentityLocked}">disabled</c:when>
                        <c:otherwise>name="seatSpan" required</c:otherwise>
                      </c:choose>>
                <option value="1" ${editSpan == 1 || editSpan == '1' ? 'selected' : ''}>1 ô — ghế đơn</option>
                <option value="2" ${editSpan == 2 || editSpan == '2' ? 'selected' : ''}>2 ô — ghế đôi</option>
              </select>
              <p id="seatSpanTip" class="mgr-field-tip">
                <c:choose>
                  <c:when test="${seatTypeIdentityLocked}">Đã khóa vì loại ghế đang được dùng trong phòng chiếu.</c:when>
                  <c:otherwise>1 ô = ghế đơn. 2 ô = ghế đôi, hiển thị rộng gấp đôi trên sơ đồ (như COUPLE, SWEETBOX).</c:otherwise>
                </c:choose>
              </p>
            </div>

            <div class="mgr-form-group">
              <div class="mgr-label-row">
                <label for="description">Mô tả</label>
                <span class="mgr-char-count" id="descriptionCount"><c:out value="${descLen}"/>/255</span>
              </div>
              <input id="description" type="text" name="description" maxlength="255"
                     data-char-count="descriptionCount" data-char-max="255"
                     aria-describedby="descriptionTip"
                     value="<c:out value='${formDescription}'/>"/>
              <p id="descriptionTip" class="mgr-field-tip">Tùy chọn. Tối đa 255 ký tự — mô tả ngắn giúp phân biệt loại ghế.</p>
            </div>

            <div class="mgr-form-actions">
              <button type="submit" class="btn btn-primary mgr-submit">💾 Lưu thay đổi</button>
              <a href="${pageContext.request.contextPath}/manager/seat-types" class="btn btn-ghost mgr-submit">Hủy</a>
            </div>
          </form>
        </c:when>
        <c:otherwise>
          <c:set var="formTypeName" value="${inputTypeName}"/>
          <c:set var="formDescription" value="${inputDescription}"/>
          <c:set var="typeNameLen" value="${fn:length(formTypeName)}"/>
          <c:set var="descLen" value="${fn:length(formDescription)}"/>

          <h2 class="mgr-card-title"><span class="mgr-card-title-icon">＋</span> Thêm loại ghế</h2>
          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>
          <form method="post" action="${pageContext.request.contextPath}/manager/seat-types" class="mgr-form" id="seatTypeForm">
            <div class="mgr-form-group">
              <div class="mgr-label-row">
                <label for="typeName">Tên loại ghế <span class="required">*</span></label>
                <span class="mgr-char-count" id="typeNameCount"><c:out value="${typeNameLen}"/>/50</span>
              </div>
              <input id="typeName" type="text" name="typeName" maxlength="50" required
                     placeholder="VD: PREMIUM"
                     data-char-count="typeNameCount" data-char-max="50"
                     aria-describedby="typeNameTip"
                     value="<c:out value='${formTypeName}'/>"/>
              <p id="typeNameTip" class="mgr-field-tip">Bắt buộc. Tối đa 50 ký tự. Nên viết hoa (vd. PREMIUM, VIP).</p>
            </div>

            <div class="mgr-form-group">
              <label for="priceMultiplier">Hệ số giá <span class="required">*</span></label>
              <input id="priceMultiplier" type="number" name="priceMultiplier"
                     step="0.01" min="0.01" max="9.99" required
                     placeholder="1.00"
                     inputmode="decimal"
                     aria-describedby="multiplierTip"
                     value="<c:out value='${inputMultiplier}'/>"/>
              <p id="multiplierTip" class="mgr-field-tip">
                Bắt buộc. Định dạng X.XX — từ 0.01 đến 9.99 (vd. 1.00, 1.50). Giá vé = giá suất × hệ số này.
              </p>
            </div>

            <div class="mgr-form-group">
              <label for="seatSpan">Kích thước trên layout <span class="required">*</span></label>
              <select id="seatSpan" name="seatSpan" required aria-describedby="seatSpanTip">
                <option value="1" ${inputSeatSpan == '2' ? '' : 'selected'}>1 ô — ghế đơn</option>
                <option value="2" ${inputSeatSpan == '2' ? 'selected' : ''}>2 ô — ghế đôi</option>
              </select>
              <p id="seatSpanTip" class="mgr-field-tip">
                1 ô = ghế đơn. 2 ô = ghế đôi, hiển thị rộng gấp đôi trên sơ đồ (như COUPLE, SWEETBOX).
              </p>
            </div>

            <div class="mgr-form-group">
              <div class="mgr-label-row">
                <label for="description">Mô tả</label>
                <span class="mgr-char-count" id="descriptionCount"><c:out value="${descLen}"/>/255</span>
              </div>
              <input id="description" type="text" name="description" maxlength="255"
                     data-char-count="descriptionCount" data-char-max="255"
                     aria-describedby="descriptionTip"
                     value="<c:out value='${formDescription}'/>"/>
              <p id="descriptionTip" class="mgr-field-tip">Tùy chọn. Tối đa 255 ký tự — mô tả ngắn giúp phân biệt loại ghế.</p>
            </div>

            <button type="submit" class="btn btn-primary mgr-submit">+ Thêm loại ghế</button>
          </form>
        </c:otherwise>
      </c:choose>
    </div>

    <div class="mgr-card">
      <h2 class="mgr-card-title">
        Danh sách loại ghế
        <span class="mgr-count">${fn:length(seatTypeList)}</span>
      </h2>
      <table class="mgr-table">
        <thead>
          <tr>
            <th>#</th>
            <th>Tên loại</th>
            <th>Kích thước</th>
            <th>Hệ số</th>
            <th>Ghế đang dùng</th>
            <th>Thao tác</th>
          </tr>
        </thead>
        <tbody>
          <c:forEach var="st" items="${seatTypeList}" varStatus="stIdx">
            <c:set var="typeKey" value="${fn:toLowerCase(st.typeName)}"/>
            <tr class="${editSeatType.id == st.id ? 'mgr-row--editing' : ''}">
              <td class="mgr-td-num">${stIdx.count}</td>
              <td>
                <span class="slt-type-swatch slt-type-swatch--${typeKey}"
                      data-type-key="${typeKey}"
                      style="display:inline-block;vertical-align:middle;margin-right:8px;width:14px;height:14px;border-radius:3px;"></span>
                <c:out value="${st.typeName}"/>
              </td>
              <td><c:out value="${st.seatSpan >= 2 ? '2 ô' : '1 ô'}"/></td>
              <td>×<fmt:formatNumber value="${st.priceMultiplier}" minFractionDigits="2" maxFractionDigits="2"/></td>
              <td class="mgr-td-date">${usageMap[st.id] != null ? usageMap[st.id] : 0}</td>
              <td>
                <a href="${pageContext.request.contextPath}/manager/seat-types?action=edit&id=<c:out value='${st.id}'/>"
                   class="mgr-btn mgr-btn--edit" title="Sửa">✏️</a>
                <c:choose>
                  <c:when test="${usageMap[st.id] > 0}">
                    <button type="button"
                            class="mgr-btn mgr-btn--invalid mgr-btn--blocked"
                            title="Đang có ${usageMap[st.id]} ghế sử dụng — không thể xóa"
                            data-type-name="<c:out value='${st.typeName}'/>"
                            data-usage-count="${usageMap[st.id]}"
                            onclick="showSeatTypeDeleteBlocked(this)">🗑️</button>
                  </c:when>
                  <c:otherwise>
                    <form method="post" action="${pageContext.request.contextPath}/manager/seat-types"
                          style="display:inline"
                          onsubmit="return confirm('Xóa loại ghế &quot;<c:out value='${st.typeName}'/>&quot;? Hành động này không thể hoàn tác.');">
                      <input type="hidden" name="action" value="delete"/>
                      <input type="hidden" name="id" value="<c:out value='${st.id}'/>"/>
                      <button type="submit" class="mgr-btn mgr-btn--invalid" title="Xóa">🗑️</button>
                    </form>
                  </c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/manager-seat-layout.css"/>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/seat-type-colors.js"></script>
<script charset="UTF-8">
  function showSeatTypeDeleteBlocked(btn) {
    var name = btn.dataset.typeName || 'loại ghế này';
    var count = btn.dataset.usageCount || '0';
    alert('Không thể xóa "' + name + '" — đang có ' + count + ' ghế sử dụng trong layout phòng chiếu.');
  }

  document.addEventListener('DOMContentLoaded', function () {
    if (window.SeatTypeColors) SeatTypeColors.applySwatchColors();

    document.querySelectorAll('[data-char-count]').forEach(function (input) {
      var countEl = document.getElementById(input.getAttribute('data-char-count'));
      var max = parseInt(input.getAttribute('data-char-max') || input.maxLength || '0', 10);
      if (!countEl || !max) return;
      function updateCount() {
        countEl.textContent = (input.value || '').length + '/' + max;
      }
      input.addEventListener('input', updateCount);
      updateCount();
    });

    var multiplier = document.getElementById('priceMultiplier');
    if (multiplier) {
      multiplier.addEventListener('blur', function () {
        var raw = (multiplier.value || '').trim();
        if (!raw) return;
        var n = Number(raw);
        if (!isFinite(n) || n < 0.01 || n > 9.99) return;
        multiplier.value = n.toFixed(2);
      });
    }

    <c:if test="${not empty editSeatType || not empty error}">
    var formCard = document.getElementById('seat-type-form');
    if (formCard) formCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
    </c:if>
  });
</script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
