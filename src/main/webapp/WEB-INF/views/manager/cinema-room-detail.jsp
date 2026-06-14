<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="${room.roomName} — Layout ghế — ÉPCINE"/>
<c:set var="extraCss" value="manager-auditoriums"/>
<c:set var="extraCss2" value="manager-seat-layout"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="aud-page aud-page--detail">
  <div class="aud-bg-glow" aria-hidden="true"></div>

  <div class="aud-inner aud-inner--detail">

    <div class="mgr-breadcrumb aud-breadcrumb">
      <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
      <span>›</span>
      <a href="${pageContext.request.contextPath}/manager/rooms">Quản lý Phòng chiếu</a>
      <span>›</span>
      <span><c:out value="${room.roomName}"/></span>
    </div>

    <c:if test="${param.success == 'created'}">
      <div class="mgr-alert mgr-alert--success aud-alert">✓ Đã tạo phòng chiếu mới! Hãy thiết lập layout ghế bên dưới.</div>
    </c:if>
    <c:if test="${param.success == 'updated'}">
      <div class="mgr-alert mgr-alert--success aud-alert">✓ Đã cập nhật tên phòng!</div>
    </c:if>
    <c:if test="${param.success == 'status_updated'}">
      <div class="mgr-alert mgr-alert--success aud-alert">✓ Đã cập nhật trạng thái phòng!</div>
    </c:if>
    <c:if test="${param.success == 'layout_saved'}">
      <div class="mgr-alert mgr-alert--success aud-alert">✓ Đã lưu layout ghế vào database!</div>
    </c:if>
    <c:if test="${not empty error}">
      <div class="mgr-alert mgr-alert--error aud-alert"><c:out value="${error}"/></div>
    </c:if>

    <%-- Hidden form lưu layout --%>
    <form id="sltSaveForm" method="post" action="${pageContext.request.contextPath}/manager/rooms/save-layout" style="display:none">
      <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
      <input type="hidden" id="sltLayoutJsonInput" name="layoutJson" value=""/>
    </form>

    <%-- Thông tin phòng (tóm tắt) --%>
    <div class="aud-detail-summary glass-panel">
      <div class="aud-detail-summary__main">
        <a href="${pageContext.request.contextPath}/manager/rooms?room=<c:out value='${room.id}'/>"
           class="aud-back-link">
          <span class="material-symbols-outlined">arrow_back</span>
          Quay lại danh sách
        </a>
        <div class="aud-detail-summary__title-row">
          <h1 class="aud-detail-summary__title"><c:out value="${room.roomName}"/></h1>
          <c:if test="${not empty roomMeta.tag}">
            <span class="aud-room-tag"><c:out value="${roomMeta.tag}"/></span>
          </c:if>
          <c:choose>
            <c:when test="${room.status == 'ACTIVE'}">
              <span class="aud-status-pill aud-status-pill--live">Hoạt động</span>
            </c:when>
            <c:when test="${room.status == 'MAINTENANCE'}">
              <span class="aud-status-pill aud-status-pill--maint">Bảo trì</span>
            </c:when>
            <c:otherwise>
              <span class="aud-status-pill aud-status-pill--off">Ngưng hoạt động</span>
            </c:otherwise>
          </c:choose>
        </div>
        <p class="aud-detail-summary__meta">
          <span><c:out value="${room.capacity}"/> ghế (DB)</span>
          <span class="aud-meta-sep">·</span>
          <span id="sltPlacedMeta"><c:out value="${activeSeatCount}"/> ghế đã đặt layout</span>
          <c:if test="${not empty room.createdAt}">
            <span class="aud-meta-sep">·</span>
            <span>Tạo <fmt:formatDate value="${room.createdAt}" pattern="dd/MM/yyyy"/></span>
          </c:if>
        </p>
      </div>
      <div class="aud-detail-summary__actions">
        <form method="post" action="${pageContext.request.contextPath}/manager/rooms/update" class="aud-rename-form">
          <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
          <input type="hidden" name="action" value="rename"/>
          <input type="hidden" name="from" value="detail"/>
          <input type="text" name="roomName" maxlength="100" required
                 value="<c:out value='${room.roomName}'/>"
                 class="aud-rename-input"/>
          <button type="submit" class="aud-btn aud-btn--ghost">
            <span class="material-symbols-outlined">save</span>
            Lưu tên
          </button>
        </form>
        <form method="post" action="${pageContext.request.contextPath}/manager/rooms/update" class="aud-status-form aud-status-form--detail">
          <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
          <input type="hidden" name="action" value="toggle"/>
          <input type="hidden" name="from" value="detail"/>
          <label class="aud-status-field">
            <span class="aud-status-field-label">Trạng thái</span>
            <span class="aud-status-select-wrap">
              <select name="status"
                      class="aud-status-select aud-status-select--${room.status}"
                      onchange="this.form.submit()">
                <option value="ACTIVE" ${room.status == 'ACTIVE' ? 'selected' : ''}>Hoạt động</option>
                <option value="MAINTENANCE" ${room.status == 'MAINTENANCE' ? 'selected' : ''}>Bảo trì</option>
                <option value="INACTIVE" ${room.status == 'INACTIVE' ? 'selected' : ''}>Ngưng hoạt động</option>
              </select>
              <span class="material-symbols-outlined aud-status-select-icon" aria-hidden="true">expand_more</span>
            </span>
          </label>
        </form>
      </div>
    </div>

    <%-- Layout Editor (design Seat Layout) --%>
    <div class="slt-editor glass-panel-heavy" id="sltEditor">

      <div class="slt-editor__header">
        <div class="slt-editor__header-left">
          <div class="slt-editor__icon">
            <span class="material-symbols-outlined">event_seat</span>
          </div>
          <div>
            <h2 class="slt-editor__title"><c:out value="${room.roomName}"/></h2>
            <p class="slt-editor__subtitle">Trình chỉnh sửa layout ghế</p>
          </div>
          <div class="slt-editor__divider" aria-hidden="true"></div>
          <div class="slt-editor__history">
            <button type="button" class="slt-icon-btn" id="sltUndo" title="Hoàn tác" disabled>
              <span class="material-symbols-outlined">undo</span>
            </button>
            <button type="button" class="slt-icon-btn" id="sltRedo" title="Làm lại" disabled>
              <span class="material-symbols-outlined">redo</span>
            </button>
            <div class="slt-editor__divider slt-editor__divider--sm" aria-hidden="true"></div>
            <button type="button" class="slt-icon-btn slt-icon-btn--danger" id="sltClear" title="Xóa toàn bộ">
              <span class="material-symbols-outlined">delete_sweep</span>
            </button>
          </div>
        </div>
        <div class="slt-editor__header-right">
          <div class="slt-capacity-display">
            <span class="slt-capacity-label">Tổng ghế</span>
            <span class="slt-capacity-value" id="sltCapacityDisplay">0</span>
          </div>
          <button type="button" class="aud-btn aud-btn--primary slt-save-btn" id="sltSave">
            <span class="material-symbols-outlined">save</span>
            Lưu layout
          </button>
        </div>
      </div>

      <div class="slt-editor__body">
        <%-- Sidebar --%>
        <aside class="slt-sidebar">
          <section class="slt-sidebar__section">
            <h3 class="slt-sidebar__title">Loại ghế</h3>
            <p class="slt-active-type-hint" id="sltActiveTypeHint"
               data-hint-add="Đang chọn: {label} — click lên layout để đặt ghế"
               data-hint-delete="Chế độ Xóa — click ghế hoặc lối đi để xóa">Chọn loại ghế bên dưới trước khi đặt lên layout</p>
            <div class="slt-seat-types" id="sltSeatTypes">
              <c:forEach var="st" items="${seatTypeList}">
                <c:set var="typeKey" value="${fn:toLowerCase(st.typeName)}"/>
                <c:set var="isWide" value="${st.typeName == 'COUPLE' or st.typeName == 'SWEETBOX'}"/>
                <button type="button"
                        class="slt-type-card slt-type-card--${typeKey}"
                        data-type-id="<c:out value='${st.id}'/>"
                        data-type-key="${typeKey}"
                        data-wide="${isWide ? 'true' : 'false'}"
                        data-multiplier="<c:out value='${st.priceMultiplier}'/>">
                  <span class="slt-type-swatch slt-type-swatch--${typeKey}" data-type-key="${typeKey}"></span>
                  <span class="slt-type-info">
                    <span class="slt-type-name">
                      <c:choose>
                        <c:when test="${st.typeName == 'REGULAR'}">Ghế thường</c:when>
                        <c:when test="${st.typeName == 'VIP'}">Ghế VIP</c:when>
                        <c:when test="${st.typeName == 'COUPLE'}">Ghế đôi</c:when>
                        <c:when test="${st.typeName == 'SWEETBOX'}">Sweetbox</c:when>
                        <c:otherwise><c:out value="${st.typeName}"/></c:otherwise>
                      </c:choose>
                    </span>
                    <span class="slt-type-price">×<fmt:formatNumber value="${st.priceMultiplier}" minFractionDigits="2" maxFractionDigits="2"/></span>
                  </span>
                  <span class="material-symbols-outlined slt-type-drag">drag_indicator</span>
                </button>
              </c:forEach>
            </div>
          </section>

          <section class="slt-sidebar__section">
            <h3 class="slt-sidebar__title">Cấu hình</h3>
            <div class="slt-config">
              <label class="slt-field">
                <span class="slt-field-label">Tên layout</span>
                <input type="text" class="slt-field-input" id="sltLayoutTitle"
                       value="Layout <c:out value='${room.roomName}'/>"/>
              </label>
              <label class="slt-toggle-row">
                <input type="checkbox" class="slt-toggle-check" id="sltSnapGrid" checked/>
                <span class="slt-toggle-ui"></span>
                <span>Snap to Grid</span>
              </label>
              <label class="slt-toggle-row">
                <input type="checkbox" class="slt-toggle-check" id="sltAutoNumber" checked/>
                <span class="slt-toggle-ui"></span>
                <span>Tự đánh số ghế</span>
              </label>
            </div>
          </section>

          <button type="button" class="slt-discard-btn" id="sltDiscard">Hủy thay đổi</button>
        </aside>

        <%-- Workspace --%>
        <div class="slt-workspace">
          <div class="slt-screen">
            <div class="slt-screen__curve"></div>
            <span class="slt-screen__label">MÀN HÌNH</span>
          </div>

          <div class="slt-grid-wrap">
            <div class="slt-grid-panel" id="sltGridPanel">
              <div id="sltGrid" class="slt-grid" aria-label="Sơ đồ ghế"></div>
              <button type="button" class="slt-add-row-btn" id="sltAddRowFooter" title="Thêm hàng ghế mới">
                <span class="material-symbols-outlined">add_row_below</span>
                Thêm hàng ghế
              </button>
            </div>
          </div>

          <div class="slt-toolbar" id="sltToolbar">
            <button type="button" class="slt-tool slt-tool--active" data-tool="select">
              <span class="material-symbols-outlined">ads_click</span>
              Chọn
            </button>
            <button type="button" class="slt-tool" data-tool="add">
              <span class="material-symbols-outlined">add_box</span>
              Thêm ghế
            </button>
            <button type="button" class="slt-tool" data-tool="gap">
              <span class="material-symbols-outlined">space_bar</span>
              Lối đi
            </button>
            <button type="button" class="slt-tool slt-tool--danger" data-tool="delete">
              <span class="material-symbols-outlined">delete</span>
              Xóa
            </button>
            <div class="slt-toolbar__divider"></div>
            <span class="slt-toolbar__count">
              <strong id="sltRowCount">0</strong> hàng ·
              <strong id="sltSeatCount">0</strong> ghế
            </span>
          </div>
        </div>
      </div>

      <p class="slt-backend-note">
        <span class="material-symbols-outlined">info</span>
        Lối đi được lưu theo vị trí cột trong layout. Dùng <strong>Thêm hàng</strong> để thêm hàng D, E, … (tối đa A–Z).
      </p>
    </div>
  </div>
</div>

<script>
  window.SLT_CONFIG = {
    roomId: '<c:out value="${room.id}"/>',
    roomName: '<c:out value="${room.roomName}"/>',
    dbSeatCount: ${dbSeatCount != null ? dbSeatCount : 0},
    ctx: '<c:out value="${pageContext.request.contextPath}"/>',
    layoutJson: <c:choose><c:when test="${not empty layoutJson}"><c:out value="${layoutJson}" escapeXml="false"/></c:when><c:otherwise>null</c:otherwise></c:choose>,
    i18n: {
      emptyGap: 'Click \u0111\u1ec3 th\u00eam l\u1ed1i \u0111i',
      emptyAdd: 'Click \u0111\u1ec3 th\u00eam gh\u1ebf',
      emptySelect: 'H\u00e0ng tr\u1ed1ng \u2014 ch\u1ecdn c\u00f4ng c\u1ee5 L\u1ed1i \u0111i ho\u1eb7c Th\u00eam gh\u1ebf',
      appendGap: 'Th\u00eam l\u1ed1i \u0111i cu\u1ed1i h\u00e0ng',
      appendSeat: 'Th\u00eam gh\u1ebf cu\u1ed1i h\u00e0ng',
      gapTitle: 'L\u1ed1i \u0111i \u2014 d\u00f9ng c\u00f4ng c\u1ee5 X\u00f3a \u0111\u1ec3 g\u1ee1 b\u1ecf',
      deleteSeat: 'Click \u0111\u1ec3 x\u00f3a gh\u1ebf',
      deleteGap: 'Click \u0111\u1ec3 x\u00f3a l\u1ed1i \u0111i',
      emptyDelete: 'H\u00e0ng tr\u1ed1ng',
      removeRow: 'X\u00f3a h\u00e0ng {label}',
      maxRows: '\u0110\u00e3 \u0111\u1ea1t t\u1ed1i \u0111a 26 h\u00e0ng (A\u2013Z).',
      minRows: 'Ph\u1ea3i gi\u1eef \u00edt nh\u1ea5t m\u1ed9t h\u00e0ng gh\u1ebf.',
      confirmRemoveRow: 'H\u00e0ng {label} c\u00f2n gh\u1ebf. X\u00f3a h\u00e0ng s\u1ebd x\u00f3a to\u00e0n b\u1ed9 n\u1ed9i dung h\u00e0ng n\u00e0y. Ti\u1ebfp t\u1ee5c?',
      confirmSaveEmpty: 'Layout kh\u00f4ng c\u00f3 gh\u1ebf n\u00e0o. L\u01b0u s\u1ebd x\u00f3a to\u00e0n b\u1ed9 gh\u1ebf hi\u1ec7n t\u1ea1i trong ph\u00f2ng. Ti\u1ebfp t\u1ee5c?',
      confirmSave: 'L\u01b0u layout gh\u1ebf v\u00e0o database? ({n} gh\u1ebf)',
      confirmClear: 'X\u00f3a to\u00e0n b\u1ed9 gh\u1ebf tr\u00ean layout?',
      confirmDiscard: 'H\u1ee7y thay \u0111\u1ed5i v\u00e0 t\u1ea3i l\u1ea1i layout?',
      placedMeta: '{n} gh\u1ebf \u0111\u00e3 \u0111\u1eb7t layout',
      alertSelectTypeSidebar: 'Ch\u1ecdn lo\u1ea1i gh\u1ebf \u1edf sidebar tr\u01b0\u1edbc khi th\u00eam gh\u1ebf.',
      alertNoSeatType: 'Ch\u01b0a c\u00f3 lo\u1ea1i gh\u1ebf n\u00e0o. Th\u00eam lo\u1ea1i gh\u1ebf trong Qu\u1ea3n l\u00fd lo\u1ea1i gh\u1ebf tr\u01b0\u1edbc.'
    }
  };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/seat-type-colors.js"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-seat-layout.js?v=2"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
