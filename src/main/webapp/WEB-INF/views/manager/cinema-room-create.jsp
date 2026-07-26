<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Thêm phòng chiếu — ÉPCINE"/>
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
      <span>Thêm phòng chiếu</span>
    </div>

    <c:if test="${not empty error}">
      <div class="mgr-alert mgr-alert--error aud-alert"><c:out value="${error}"/></div>
    </c:if>

    <form id="sltSaveForm" method="post" action="${pageContext.request.contextPath}/manager/rooms/create">
      <input type="hidden" id="sltLayoutJsonInput" name="layoutJson" value=""/>

      <div class="aud-detail-summary glass-panel">
        <div class="aud-detail-summary__main">
          <a href="${pageContext.request.contextPath}/manager/rooms" class="aud-back-link">
            <span class="material-symbols-outlined">arrow_back</span>
            Quay lại danh sách
          </a>
          <div class="aud-detail-summary__title-row">
            <h1 class="aud-detail-summary__title">Thêm phòng chiếu</h1>
          </div>
          <p class="aud-detail-summary__meta">
            Nhập tên phòng và thiết kế layout ghế. Chỉ lưu khi đã có ít nhất 1 ghế.
          </p>
          <label class="aud-create-name-field">
            <span class="aud-create-name-label">Tên phòng <span class="required">*</span></span>
            <input type="text" id="createRoomName" name="roomName" maxlength="100" required
                   placeholder="VD: Phòng 5, IMAX 1..."
                   value="<c:out value='${inputRoomName}'/>"
                   class="aud-rename-input aud-create-name-input"/>
          </label>
        </div>
        <div class="aud-detail-summary__actions">
          <div class="slt-capacity-display">
            <span class="slt-capacity-label">Tổng ghế</span>
            <span class="slt-capacity-value" id="sltCapacityDisplay">0</span>
          </div>
        </div>
      </div>
    </form>

    <div class="slt-editor glass-panel-heavy" id="sltEditor">
      <div class="slt-editor__header">
        <div class="slt-editor__header-left">
          <div class="slt-editor__icon">
            <span class="material-symbols-outlined">event_seat</span>
          </div>
          <div>
            <h2 class="slt-editor__title">Thiết kế layout ghế</h2>
            <p class="slt-editor__subtitle">Thêm hàng, đặt ghế / lối đi rồi lưu để tạo phòng</p>
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
          <button type="button" class="aud-btn aud-btn--primary slt-save-btn" id="sltSave">
            <span class="material-symbols-outlined">save</span>
            Lưu &amp; tạo phòng
          </button>
        </div>
      </div>

      <div class="slt-editor__body">
        <aside class="slt-sidebar">
          <section class="slt-sidebar__section">
            <h3 class="slt-sidebar__title">Loại ghế</h3>
            <p class="slt-active-type-hint" id="sltActiveTypeHint"
               data-hint-add="Đang chọn: {label} — click lên layout để đặt ghế"
               data-hint-delete="Chế độ Xóa — click ghế hoặc lối đi để xóa">Chọn loại ghế bên dưới trước khi đặt lên layout</p>
            <div class="slt-seat-types" id="sltSeatTypes">
              <c:forEach var="st" items="${seatTypeList}">
                <c:set var="typeKey" value="${fn:toLowerCase(st.typeName)}"/>
                <c:set var="typeSpan" value="${st.seatSpan >= 2 ? 2 : 1}"/>
                <button type="button"
                        class="slt-type-card slt-type-card--${typeKey}"
                        data-type-id="<c:out value='${st.id}'/>"
                        data-type-key="${typeKey}"
                        data-seat-span="${typeSpan}"
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

          <button type="button" class="slt-discard-btn" id="sltDiscard">Đặt lại layout</button>
        </aside>

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
        Phòng chỉ được tạo sau khi bạn lưu layout có ít nhất 1 ghế.
        Mỗi hàng tối đa <strong>17 ô</strong> (tính cả lối đi).
      </p>
    </div>
  </div>
</div>

<script>
  window.SLT_CONFIG = {
    mode: 'create',
    startEmpty: true,
    requireSeats: true,
    roomId: 'new',
    roomName: '',
    dbSeatCount: 0,
    ctx: '<c:out value="${pageContext.request.contextPath}"/>',
    layoutJson: null,
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
      maxCellsPerRow: 'H\u00e0ng {label} \u0111\u00e3 \u0111\u1ea1t t\u1ed1i \u0111a {max} \u00f4 (t\u00ednh c\u1ea3 l\u1ed1i \u0111i).',
      minRows: 'Ph\u1ea3i gi\u1eef \u00edt nh\u1ea5t m\u1ed9t h\u00e0ng gh\u1ebf.',
      confirmRemoveRow: 'H\u00e0ng {label} c\u00f2n gh\u1ebf. X\u00f3a h\u00e0ng s\u1ebd x\u00f3a to\u00e0n b\u1ed9 n\u1ed9i dung h\u00e0ng n\u00e0y. Ti\u1ebfp t\u1ee5c?',
      confirmSaveEmpty: 'Ph\u1ea3i \u0111\u1eb7t \u00edt nh\u1ea5t 1 gh\u1ebf tr\u01b0\u1edbc khi t\u1ea1o ph\u00f2ng.',
      confirmSave: 'T\u1ea1o ph\u00f2ng chi\u1ebfu v\u1edbi {n} gh\u1ebf?',
      confirmClear: 'X\u00f3a to\u00e0n b\u1ed9 gh\u1ebf tr\u00ean layout?',
      confirmDiscard: 'Đ\u1eb7t l\u1ea1i layout tr\u1ed1ng?',
      placedMeta: '{n} gh\u1ebf \u0111\u00e3 \u0111\u1eb7t layout',
      alertSelectTypeSidebar: 'Ch\u1ecdn lo\u1ea1i gh\u1ebf \u1edf sidebar tr\u01b0\u1edbc khi th\u00eam gh\u1ebf.',
      alertNoSeatType: 'Ch\u01b0a c\u00f3 lo\u1ea1i gh\u1ebf n\u00e0o. Th\u00eam lo\u1ea1i gh\u1ebf trong Qu\u1ea3n l\u00fd lo\u1ea1i gh\u1ebf tr\u01b0\u1edbc.',
      alertRoomName: 'Vui l\u00f2ng nh\u1eadp t\u00ean ph\u00f2ng tr\u01b0\u1edbc khi l\u01b0u.'
    }
  };
</script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/seat-type-colors.js"></script>
<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-seat-layout.js?v=6"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
