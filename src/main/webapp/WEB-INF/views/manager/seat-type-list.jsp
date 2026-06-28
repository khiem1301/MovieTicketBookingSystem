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

    <div class="mgr-card">
      <c:choose>
        <c:when test="${not empty editSeatType}">
          <h2 class="mgr-card-title"><span class="mgr-card-title-icon">✏️</span> Sửa loại ghế</h2>
          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>
          <form method="post" action="${pageContext.request.contextPath}/manager/seat-types" class="mgr-form">
            <input type="hidden" name="action" value="update"/>
            <input type="hidden" name="id" value="<c:out value='${editSeatType.id}'/>"/>
            <div class="mgr-form-group">
              <label for="typeName">Tên loại ghế <span class="required">*</span></label>
              <input id="typeName" type="text" name="typeName" maxlength="50" required
                     aria-describedby="typeNameHint"
                     value="<c:out value='${not empty inputTypeName ? inputTypeName : editSeatType.typeName}'/>"/>
              <small id="typeNameHint" class="mgr-hint">Tối đa 50 ký tự</small>
            </div>
            <div class="mgr-form-group">
              <label for="priceMultiplier">Hệ số giá <span class="required">*</span></label>
              <input id="priceMultiplier" type="number" name="priceMultiplier" step="0.01" min="0.01" max="9.99" required
                     title="1 chữ số phần nguyên, 2 chữ số phần thập phân (VD: 1.50)"
                     value="<c:out value='${not empty inputMultiplier ? inputMultiplier : editSeatType.priceMultiplier}'/>"/>
              <small class="mgr-hint">Định dạng X.XX — từ 0.01 đến 9.99</small>
            </div>
            <div class="mgr-form-group">
              <label for="seatSpan">Kích thước trên layout <span class="required">*</span></label>
              <select id="seatSpan" name="seatSpan" required>
                <c:set var="editSpan" value="${not empty inputSeatSpan ? inputSeatSpan : editSeatType.seatSpan}"/>
                <option value="1" ${editSpan == 1 || editSpan == '1' ? 'selected' : ''}>1 ô — ghế đơn</option>
                <option value="2" ${editSpan == 2 || editSpan == '2' ? 'selected' : ''}>2 ô — ghế đôi</option>
              </select>
              <small class="mgr-hint">Ghế 2 ô hiển thị rộng gấp đôi trên sơ đồ (như COUPLE, SWEETBOX)</small>
            </div>
            <div class="mgr-form-group">
              <label for="description">Mô tả</label>
              <input id="description" type="text" name="description" maxlength="255"
                     aria-describedby="descriptionHint"
                     value="<c:out value='${not empty inputDescription ? inputDescription : editSeatType.description}'/>"/>
              <small id="descriptionHint" class="mgr-hint">Tối đa 255 ký tự</small>
            </div>
            <div class="mgr-form-actions">
              <button type="submit" class="btn btn-primary mgr-submit">💾 Lưu thay đổi</button>
              <a href="${pageContext.request.contextPath}/manager/seat-types" class="btn btn-ghost mgr-submit">Hủy</a>
            </div>
          </form>
        </c:when>
        <c:otherwise>
          <h2 class="mgr-card-title"><span class="mgr-card-title-icon">＋</span> Thêm loại ghế</h2>
          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>
          <form method="post" action="${pageContext.request.contextPath}/manager/seat-types" class="mgr-form">
            <div class="mgr-form-group">
              <label for="typeName">Tên loại ghế <span class="required">*</span></label>
              <input id="typeName" type="text" name="typeName" maxlength="50" required
                     placeholder="VD: PREMIUM"
                     aria-describedby="typeNameHint"
                     value="<c:out value='${inputTypeName}'/>"/>
              <small id="typeNameHint" class="mgr-hint">Tối đa 50 ký tự</small>
            </div>
            <div class="mgr-form-group">
              <label for="priceMultiplier">Hệ số giá <span class="required">*</span></label>
              <input id="priceMultiplier" type="number" name="priceMultiplier" step="0.01" min="0.01" max="9.99" required
                     placeholder="1.00"
                     title="1 chữ số phần nguyên, 2 chữ số phần thập phân (VD: 1.50)"
                     value="<c:out value='${inputMultiplier}'/>"/>
              <small class="mgr-hint">Định dạng X.XX — từ 0.01 đến 9.99</small>
            </div>
            <div class="mgr-form-group">
              <label for="seatSpan">Kích thước trên layout <span class="required">*</span></label>
              <select id="seatSpan" name="seatSpan" required>
                <option value="1" ${inputSeatSpan == '2' ? '' : 'selected'}>1 ô — ghế đơn</option>
                <option value="2" ${inputSeatSpan == '2' ? 'selected' : ''}>2 ô — ghế đôi</option>
              </select>
              <small class="mgr-hint">Ghế 2 ô hiển thị rộng gấp đôi trên sơ đồ (như COUPLE, SWEETBOX)</small>
            </div>
            <div class="mgr-form-group">
              <label for="description">Mô tả</label>
              <input id="description" type="text" name="description" maxlength="255"
                     aria-describedby="descriptionHint"
                     value="<c:out value='${inputDescription}'/>"/>
              <small id="descriptionHint" class="mgr-hint">Tối đa 255 ký tự</small>
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
  });
</script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
