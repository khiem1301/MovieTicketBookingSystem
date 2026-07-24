<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản Lý Loại Ghế — ÉPCINE"/>
<c:set var="extraCss"  value="manager-movies"/>
<c:set var="extraCss2" value="manager-seat-types"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="isEdit" value="${not empty editSeatType}"/>
<c:set var="openCreateModal" value="${not empty error and empty editSeatType}"/>
<c:set var="openEditModal" value="${isEdit}"/>
<c:set var="locked" value="${isEdit and seatTypeIdentityLocked}"/>

<div class="mm-page st-page"
     data-open-create="${openCreateModal}"
     data-open-edit="${openEditModal}">

  <c:if test="${param.success == 'created'}">
    <div class="mm-alert mm-alert--success">Thêm loại ghế thành công.</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mm-alert mm-alert--success">Cập nhật loại ghế thành công.</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mm-alert mm-alert--success">Xóa loại ghế thành công.</div>
  </c:if>
  <c:if test="${param.error == 'in_use'}">
    <div class="mm-alert mm-alert--error">Không thể xóa — loại ghế đang được sử dụng trong layout phòng chiếu.</div>
  </c:if>

  <div class="mm-header">
    <div>
      <h1 class="mm-title">Quản Lý Loại Ghế</h1>
      <p class="mm-subtitle">Định nghĩa loại ghế, hệ số giá và kích thước trên sơ đồ phòng chiếu.</p>
    </div>
    <button type="button" class="mm-btn-add" id="stBtnAdd" onclick="openCreateModal()">+ Thêm Loại Ghế</button>
  </div>

  <div class="mm-card">
    <div class="mm-toolbar">
      <div class="mm-search-wrap">
        <svg class="mm-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input type="text" id="stSearch" placeholder="Tìm theo tên hoặc mô tả…" oninput="applyFilters()"/>
      </div>
      <div class="mm-filter-wrap st-filter-wrap">
        <span class="mm-filter-label">LỌC:</span>
        <div class="mm-tabs" role="tablist">
          <button type="button" class="mm-tab active" data-filter="" onclick="setSpanTab(this)">Tất Cả</button>
          <button type="button" class="mm-tab" data-filter="1" onclick="setSpanTab(this)">Ghế Đơn</button>
          <button type="button" class="mm-tab" data-filter="2" onclick="setSpanTab(this)">Ghế Đôi</button>
        </div>
      </div>
    </div>

    <c:choose>
      <c:when test="${empty seatTypeList}">
        <div class="mm-empty">Chưa có loại ghế nào. Bấm <strong>+ Thêm Loại Ghế</strong> để thêm mới.</div>
      </c:when>
      <c:otherwise>
        <div class="mm-table-wrap">
          <table class="mm-table st-table">
            <thead>
              <tr>
                <th>LOẠI GHẾ</th>
                <th>KÍCH THƯỚC</th>
                <th>HỆ SỐ GIÁ</th>
                <th>ĐANG DÙNG</th>
                <th>THAO TÁC</th>
              </tr>
            </thead>
            <tbody id="stTableBody">
              <c:forEach var="st" items="${seatTypeList}">
                <c:set var="typeKey" value="${fn:toLowerCase(fn:trim(st.typeName))}"/>
                <c:if test="${typeKey == 'standard'}"><c:set var="typeKey" value="regular"/></c:if>
                <c:set var="usage" value="${usageMap[st.id] != null ? usageMap[st.id] : 0}"/>
                <tr class="st-row"
                    data-name="<c:out value='${fn:toLowerCase(st.typeName)}'/>"
                    data-desc="<c:out value='${fn:toLowerCase(st.description)}'/>"
                    data-span="<c:out value='${st.seatSpan >= 2 ? 2 : 1}'/>">
                  <td>
                    <div class="st-type-cell">
                      <span class="st-type-swatch slt-type-swatch"
                            data-type-key="<c:out value='${typeKey}'/>"
                            aria-hidden="true"></span>
                      <div>
                        <div class="st-type-name"><c:out value="${st.typeName}"/></div>
                        <c:if test="${not empty st.description}">
                          <div class="st-type-desc" title="<c:out value='${st.description}'/>">
                            <c:out value="${st.description}"/>
                          </div>
                        </c:if>
                      </div>
                    </div>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${st.seatSpan >= 2}">
                        <span class="st-badge st-badge--span2">2 ô — ghế đôi</span>
                      </c:when>
                      <c:otherwise>
                        <span class="st-badge st-badge--span1">1 ô — ghế đơn</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td>×<fmt:formatNumber value="${st.priceMultiplier}" minFractionDigits="2" maxFractionDigits="2"/></td>
                  <td>
                    <span class="st-usage ${usage > 0 ? 'st-usage--active' : ''}">
                      <c:out value="${usage}"/> ghế
                    </span>
                  </td>
                  <td class="mm-td-actions">
                    <a href="${pageContext.request.contextPath}/manager/seat-types?action=edit&amp;id=<c:out value='${st.id}'/>"
                       class="mm-action-btn mm-action-btn--edit" title="Sửa">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                      </svg>
                    </a>
                    <c:choose>
                      <c:when test="${usage > 0}">
                        <button type="button" class="mm-action-btn mm-action-btn--delete" disabled
                                title="Đang có ${usage} ghế sử dụng — không xóa"
                                data-type-name="<c:out value='${st.typeName}'/>"
                                data-usage-count="${usage}"
                                onclick="showSeatTypeDeleteBlocked(this)">
                          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="3 6 5 6 21 6"/>
                            <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                            <path d="M10 11v6"/><path d="M14 11v6"/>
                            <path d="M9 6V4h6v2"/>
                          </svg>
                        </button>
                      </c:when>
                      <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/manager/seat-types"
                              style="display:inline"
                              onsubmit="return confirm('Xóa loại ghế &quot;<c:out value='${st.typeName}'/>&quot;? Hành động này không thể hoàn tác.');">
                          <input type="hidden" name="action" value="delete"/>
                          <input type="hidden" name="id" value="<c:out value='${st.id}'/>"/>
                          <button type="submit" class="mm-action-btn mm-action-btn--delete" title="Xóa">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                              <polyline points="3 6 5 6 21 6"/>
                              <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                              <path d="M10 11v6"/><path d="M14 11v6"/>
                              <path d="M9 6V4h6v2"/>
                            </svg>
                          </button>
                        </form>
                      </c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <div class="mm-pagination">
          <span class="mm-pag-info" id="stPagInfo"></span>
          <div class="mm-pag-btns">
            <button type="button" class="mm-pag-btn" id="stPrevBtn" onclick="prevPage()">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
            </button>
            <button type="button" class="mm-pag-btn" id="stNextBtn" onclick="nextPage()">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
            </button>
          </div>
        </div>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<%-- ── Create Modal ─────────────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stCreateModal" aria-hidden="true">
  <div class="st-modal" role="dialog" aria-modal="true" aria-labelledby="stCreateTitle">
    <div class="st-modal-header">
      <h2 id="stCreateTitle">Thêm Loại Ghế</h2>
      <button type="button" class="st-modal-close" onclick="closeCreateModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <c:if test="${not empty error and empty editSeatType}">
        <div class="mm-alert mm-alert--error" style="margin-bottom:16px"><c:out value="${error}"/></div>
      </c:if>
      <c:set var="createTypeName" value="${not isEdit ? inputTypeName : ''}"/>
      <c:set var="createDesc" value="${not isEdit ? inputDescription : ''}"/>
      <c:set var="createTypeLen" value="${fn:length(createTypeName)}"/>
      <c:set var="createDescLen" value="${fn:length(createDesc)}"/>
      <form method="post" action="${pageContext.request.contextPath}/manager/seat-types" class="st-modal-form" id="stCreateForm">
        <div class="st-form-group">
          <div class="st-label-row">
            <label for="createTypeName">Tên loại ghế <span class="required">*</span></label>
            <span class="st-char-count" id="createTypeNameCount"><c:out value="${createTypeLen}"/>/50</span>
          </div>
          <input id="createTypeName" type="text" name="typeName" maxlength="50" required
                 placeholder="VD: PREMIUM"
                 data-char-count="createTypeNameCount" data-char-max="50"
                 value="<c:if test='${not isEdit}'><c:out value='${inputTypeName}'/></c:if>"/>
          <small class="st-hint">Bắt buộc. Tối đa 50 ký tự. Nên viết hoa (vd. PREMIUM, VIP).</small>
        </div>
        <div class="st-form-group">
          <label for="createMultiplier">Hệ số giá <span class="required">*</span></label>
          <input id="createMultiplier" type="number" name="priceMultiplier"
                 step="0.01" min="0.01" max="9.99" required
                 placeholder="1.00" inputmode="decimal"
                 value="<c:if test='${not isEdit}'><c:out value='${inputMultiplier}'/></c:if>"/>
          <small class="st-hint">Định dạng X.XX — từ 0.01 đến 9.99. Giá vé = giá suất × hệ số này.</small>
        </div>
        <div class="st-form-group">
          <label for="createSeatSpan">Kích thước trên layout <span class="required">*</span></label>
          <select id="createSeatSpan" name="seatSpan" required>
            <option value="1" ${!isEdit and inputSeatSpan == '2' ? '' : 'selected'}>1 ô — ghế đơn</option>
            <option value="2" ${!isEdit and inputSeatSpan == '2' ? 'selected' : ''}>2 ô — ghế đôi</option>
          </select>
          <small class="st-hint">2 ô = ghế đôi, hiển thị rộng gấp đôi trên sơ đồ (như COUPLE, SWEETBOX).</small>
        </div>
        <div class="st-form-group">
          <div class="st-label-row">
            <label for="createDescription">Mô tả</label>
            <span class="st-char-count" id="createDescriptionCount"><c:out value="${createDescLen}"/>/255</span>
          </div>
          <input id="createDescription" type="text" name="description" maxlength="255"
                 data-char-count="createDescriptionCount" data-char-max="255"
                 value="<c:if test='${not isEdit}'><c:out value='${inputDescription}'/></c:if>"/>
          <small class="st-hint">Tùy chọn. Tối đa 255 ký tự.</small>
        </div>
        <div class="st-modal-actions">
          <button type="button" class="st-btn-cancel" onclick="closeCreateModal()">Hủy</button>
          <button type="submit" class="st-btn-primary">+ Thêm Loại Ghế</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ── Edit Modal ───────────────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stEditModal" aria-hidden="true">
  <div class="st-modal" role="dialog" aria-modal="true" aria-labelledby="stEditTitle">
    <div class="st-modal-header">
      <h2 id="stEditTitle">Sửa Loại Ghế</h2>
      <button type="button" class="st-modal-close" onclick="closeEditModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <c:if test="${isEdit}">
        <c:set var="formTypeName" value="${not empty inputTypeName ? inputTypeName : editSeatType.typeName}"/>
        <c:set var="formDescription" value="${not empty inputDescription ? inputDescription : editSeatType.description}"/>
        <c:set var="formMultiplier" value="${not empty inputMultiplier ? inputMultiplier : editSeatType.priceMultiplier}"/>
        <c:set var="editSpan" value="${locked ? editSeatType.seatSpan : (not empty inputSeatSpan ? inputSeatSpan : editSeatType.seatSpan)}"/>
        <c:set var="editTypeLen" value="${fn:length(formTypeName)}"/>
        <c:set var="editDescLen" value="${fn:length(formDescription)}"/>

        <c:if test="${locked}">
          <div class="st-lock-note">
            Loại ghế đang có <strong>${editSeatTypeUsage}</strong> ghế trong layout phòng chiếu —
            không thể đổi <strong>tên</strong> hoặc <strong>kích thước</strong>.
            Vẫn có thể cập nhật hệ số giá và mô tả.
          </div>
        </c:if>
        <c:if test="${not empty error}">
          <div class="mm-alert mm-alert--error" style="margin-bottom:16px"><c:out value="${error}"/></div>
        </c:if>

        <form method="post" action="${pageContext.request.contextPath}/manager/seat-types" class="st-modal-form" id="stEditForm">
          <input type="hidden" name="action" value="update"/>
          <input type="hidden" name="id" value="<c:out value='${editSeatType.id}'/>"/>
          <c:if test="${locked}">
            <input type="hidden" name="typeName" value="<c:out value='${editSeatType.typeName}'/>"/>
            <input type="hidden" name="seatSpan" value="<c:out value='${editSeatType.seatSpan}'/>"/>
          </c:if>

          <div class="st-form-group">
            <div class="st-label-row">
              <label for="editTypeName">Tên loại ghế <span class="required">*</span></label>
              <span class="st-char-count" id="editTypeNameCount"><c:out value="${editTypeLen}"/>/50</span>
            </div>
            <input id="editTypeName" type="text" maxlength="50" required
                   data-char-count="editTypeNameCount" data-char-max="50"
                   <c:choose>
                     <c:when test="${locked}">
                       disabled
                       value="<c:out value='${editSeatType.typeName}'/>"
                     </c:when>
                     <c:otherwise>
                       name="typeName"
                       value="<c:out value='${formTypeName}'/>"
                     </c:otherwise>
                   </c:choose>/>
            <small class="st-hint">
              <c:choose>
                <c:when test="${locked}">Đã khóa vì loại ghế đang được dùng trong phòng chiếu.</c:when>
                <c:otherwise>Bắt buộc. Tối đa 50 ký tự. Nên viết hoa (vd. PREMIUM, VIP).</c:otherwise>
              </c:choose>
            </small>
          </div>

          <div class="st-form-group">
            <label for="editMultiplier">Hệ số giá <span class="required">*</span></label>
            <input id="editMultiplier" type="number" name="priceMultiplier"
                   step="0.01" min="0.01" max="9.99" required inputmode="decimal"
                   value="<c:out value='${formMultiplier}'/>"/>
            <small class="st-hint">Định dạng X.XX — từ 0.01 đến 9.99. Giá vé = giá suất × hệ số này.</small>
          </div>

          <div class="st-form-group">
            <label for="editSeatSpan">Kích thước trên layout <span class="required">*</span></label>
            <select id="editSeatSpan"
                    <c:choose>
                      <c:when test="${locked}">disabled</c:when>
                      <c:otherwise>name="seatSpan" required</c:otherwise>
                    </c:choose>>
              <option value="1" ${editSpan == 1 || editSpan == '1' ? 'selected' : ''}>1 ô — ghế đơn</option>
              <option value="2" ${editSpan == 2 || editSpan == '2' ? 'selected' : ''}>2 ô — ghế đôi</option>
            </select>
            <small class="st-hint">
              <c:choose>
                <c:when test="${locked}">Đã khóa vì loại ghế đang được dùng trong phòng chiếu.</c:when>
                <c:otherwise>1 ô = ghế đơn. 2 ô = ghế đôi trên sơ đồ.</c:otherwise>
              </c:choose>
            </small>
          </div>

          <div class="st-form-group">
            <div class="st-label-row">
              <label for="editDescription">Mô tả</label>
              <span class="st-char-count" id="editDescriptionCount"><c:out value="${editDescLen}"/>/255</span>
            </div>
            <input id="editDescription" type="text" name="description" maxlength="255"
                   data-char-count="editDescriptionCount" data-char-max="255"
                   value="<c:out value='${formDescription}'/>"/>
            <small class="st-hint">Tùy chọn. Tối đa 255 ký tự.</small>
          </div>

          <div class="st-modal-actions">
            <button type="button" class="st-btn-cancel" onclick="closeEditModal()">Hủy</button>
            <button type="submit" class="st-btn-primary">Lưu Thay Đổi</button>
          </div>
        </form>
      </c:if>
    </div>
  </div>
</div>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/seat-type-colors.js?v=6"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-seat-types.js?v=1"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
