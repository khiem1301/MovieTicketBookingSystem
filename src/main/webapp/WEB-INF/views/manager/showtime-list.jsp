<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản Lý Suất Chiếu — ÉPCINE"/>
<c:set var="extraCss"  value="manager-movies"/>
<c:set var="extraCss2" value="manager-showtimes"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="isEdit" value="${not empty editShowtime}"/>
<c:set var="openCreateModal" value="${not empty error and empty editShowtime}"/>
<c:set var="openEditModal" value="${isEdit}"/>
<c:set var="openBulkModal" value="${openBulkModal == true}"/>
<c:set var="locked" value="${isEdit and editBookingCount != null and editBookingCount > 0}"/>

<div class="mm-page st-page"
     data-open-create="${openCreateModal}"
     data-open-edit="${openEditModal}"
     data-open-bulk="${openBulkModal}"
     data-today="<c:out value='${today}'/>"
     data-buffer="${cleanupBufferMinutes}"
     data-ctx="${pageContext.request.contextPath}">

  <c:if test="${param.success == 'created'}">
    <div class="mm-alert mm-alert--success">Thêm suất chiếu thành công.</div>
  </c:if>
  <c:if test="${param.success == 'updated' or param.success == 'status'}">
    <div class="mm-alert mm-alert--success">Cập nhật suất chiếu thành công.</div>
  </c:if>
  <c:if test="${param.success == 'cancelled'}">
    <div class="mm-alert mm-alert--success">
      <c:choose>
        <c:when test="${not empty param.msg}"><c:out value="${param.msg}"/></c:when>
        <c:otherwise>Đã hủy suất chiếu.</c:otherwise>
      </c:choose>
    </div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mm-alert mm-alert--success">Xóa suất chiếu thành công.</div>
  </c:if>
  <c:if test="${param.success == 'bulk'}">
    <div class="mm-alert mm-alert--success">Đã tạo hàng loạt <strong><c:out value="${param.count}"/></strong> suất chiếu.</div>
  </c:if>
  <c:if test="${param.success == 'copied'}">
    <div class="mm-alert mm-alert--success"><c:out value="${empty param.msg ? 'Đã copy lịch chiếu.' : param.msg}"/></div>
  </c:if>
  <c:if test="${param.error == 'has_bookings'}">
    <div class="mm-alert mm-alert--error">Không thể xóa — suất chiếu đã có đơn đặt vé. Hãy chuyển trạng thái sang Huỷ.</div>
  </c:if>
  <c:if test="${param.error == 'msg'}">
    <div class="mm-alert mm-alert--error"><c:out value="${param.msg}"/></div>
  </c:if>

  <div class="mm-header">
    <div>
      <h1 class="mm-title">Quản Lý Suất Chiếu</h1>
      <p class="mm-subtitle">Lập lịch theo ngày/phòng, tạo hàng loạt và theo dõi ghế đã bán.
        Buffer dọn phòng: <strong>${cleanupBufferMinutes} phút</strong>.</p>
    </div>
    <div class="st-header-actions">
      <button type="button" class="st-btn-secondary" onclick="openCopyModal()">Copy ngày</button>
      <button type="button" class="st-btn-secondary" onclick="openBulkModal()">+ Hàng loạt</button>
      <button type="button" class="mm-btn-add" id="stBtnAdd" onclick="openCreateModal()">+ Thêm Suất</button>
    </div>
  </div>

  <div class="mm-card">
    <div class="mm-toolbar st-toolbar">
      <div class="mm-search-wrap">
        <svg class="mm-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input type="text" id="stSearch" placeholder="Tìm theo tên phim…" oninput="applyFilters()"/>
      </div>
      <div class="mm-filter-wrap st-filter-wrap">
        <span class="mm-filter-label">LỌC:</span>
        <select id="stFilterMovie" class="st-filter-select" aria-label="Lọc theo phim" onchange="applyFilters()">
          <option value="">Tất cả phim</option>
          <c:forEach var="m" items="${movieList}">
            <option value="<c:out value='${m.id}'/>"><c:out value="${m.title}"/></option>
          </c:forEach>
        </select>
        <select id="stFilterRoom" class="st-filter-select" aria-label="Lọc theo phòng" onchange="applyFilters()">
          <option value="">Tất cả phòng</option>
          <c:forEach var="r" items="${roomList}">
            <option value="<c:out value='${r.id}'/>"><c:out value="${r.roomName}"/></option>
          </c:forEach>
        </select>
        <input id="stFilterDate" type="date" class="st-filter-date" aria-label="Lọc theo ngày" onchange="onDateFilterChange()"/>
        <div class="st-range-chips" role="group" aria-label="Khoảng ngày">
          <button type="button" class="st-chip active" data-range="7" onclick="setDateRange(this)">7 ngày tới</button>
          <button type="button" class="st-chip" data-range="today" onclick="setDateRange(this)">Hôm nay</button>
          <button type="button" class="st-chip" data-range="all" onclick="setDateRange(this)">Tất cả</button>
        </div>
        <div class="st-view-toggle" role="group" aria-label="Chế độ xem">
          <button type="button" class="st-view-btn active" data-view="list" onclick="setViewMode(this)">Danh sách</button>
          <button type="button" class="st-view-btn" data-view="calendar" onclick="setViewMode(this)">Lịch phòng</button>
        </div>
        <div class="mm-tabs" role="tablist">
          <button type="button" class="mm-tab active" data-filter="" onclick="setStatusTab(this)">Tất Cả</button>
          <button type="button" class="mm-tab" data-filter="SCHEDULED" onclick="setStatusTab(this)">Đã Lên Lịch</button>
          <button type="button" class="mm-tab" data-filter="SHOWING" onclick="setStatusTab(this)">Đang Chiếu</button>
          <button type="button" class="mm-tab" data-filter="FINISHED" onclick="setStatusTab(this)">Đã Kết Thúc</button>
          <button type="button" class="mm-tab" data-filter="CANCELLED" onclick="setStatusTab(this)">Huỷ</button>
        </div>
      </div>
    </div>

    <c:choose>
      <c:when test="${empty showtimeList}">
        <div class="mm-empty">Chưa có suất chiếu nào. Bấm <strong>+ Thêm Suất</strong> hoặc <strong>+ Hàng loạt</strong> để bắt đầu.</div>
      </c:when>
      <c:otherwise>
        <div id="stListView" class="st-list-view">
          <div class="mm-table-wrap">
            <table class="mm-table st-table">
              <thead>
                <tr>
                  <th>PHIM</th>
                  <th>PHÒNG</th>
                  <th>GIỜ CHIẾU</th>
                  <th>GHẾ</th>
                  <th>GIÁ GỐC</th>
                  <th>TRẠNG THÁI</th>
                  <th>THAO TÁC</th>
                </tr>
              </thead>
              <tbody id="stTableBody">
                <c:forEach var="st" items="${showtimeList}">
                  <c:set var="bc" value="${st.bookingCount}"/>
                  <c:set var="posterSrc" value=""/>
                  <c:if test="${not empty st.moviePosterUrl}">
                    <c:choose>
                      <c:when test="${fn:startsWith(st.moviePosterUrl,'http')}">
                        <c:set var="posterSrc" value="${st.moviePosterUrl}"/>
                      </c:when>
                      <c:otherwise>
                        <c:set var="posterSrc" value="${pageContext.request.contextPath}/${st.moviePosterUrl}"/>
                      </c:otherwise>
                    </c:choose>
                  </c:if>
                  <tr class="st-row"
                      data-id="<c:out value='${st.id}'/>"
                      data-movie-id="<c:out value='${st.movieId}'/>"
                      data-room-id="<c:out value='${st.roomId}'/>"
                      data-room-name="<c:out value='${st.roomName}'/>"
                      data-status="<c:out value='${st.status}'/>"
                      data-date="<fmt:formatDate value='${st.startTime}' pattern='yyyy-MM-dd'/>"
                      data-start-hour="<fmt:formatDate value='${st.startTime}' pattern='HH'/>"
                      data-start-hm="<fmt:formatDate value='${st.startTime}' pattern='HH:mm'/>"
                      data-end-hm="<fmt:formatDate value='${st.endTime}' pattern='HH:mm'/>"
                      data-title="<c:out value='${fn:toLowerCase(st.movieTitle)}'/>"
                      data-title-raw="<c:out value='${st.movieTitle}'/>"
                      data-sold="${st.soldSeats}"
                      data-capacity="${st.roomCapacity}"
                      data-remaining="${st.remainingSeats}">
                    <td class="mm-td-movie">
                      <c:choose>
                        <c:when test="${not empty posterSrc}">
                          <img class="mm-poster" src="<c:out value='${posterSrc}'/>" alt="" loading="lazy"/>
                        </c:when>
                        <c:otherwise>
                          <div class="mm-poster mm-poster--blank">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                              <rect x="3" y="3" width="18" height="18" rx="2"/>
                              <circle cx="8.5" cy="8.5" r="1.5"/>
                              <polyline points="21 15 16 10 5 21"/>
                            </svg>
                          </div>
                        </c:otherwise>
                      </c:choose>
                      <div>
                        <span class="mm-movie-title"><c:out value="${st.movieTitle}"/></span>
                        <div class="st-movie-meta"><c:out value="${st.movieDurationMinutes}"/> phút · <c:out value="${st.movieAgeRating}"/></div>
                      </div>
                    </td>
                    <td><c:out value="${st.roomName}"/></td>
                    <td class="st-time-cell">
                      <fmt:formatDate value="${st.startTime}" pattern="dd/MM/yyyy HH:mm"/>
                      <span class="st-time-sep">—</span>
                      <fmt:formatDate value="${st.endTime}" pattern="HH:mm"/>
                    </td>
                    <td class="st-seat-cell">
                      <span class="st-seat-sold">${st.soldSeats}</span>
                      <span class="st-seat-sep">/</span>
                      <span class="st-seat-cap">${st.roomCapacity}</span>
                      <div class="st-seat-remain ${st.remainingSeats == 0 ? 'is-full' : ''}">
                        còn ${st.remainingSeats}
                      </div>
                    </td>
                    <td><fmt:formatNumber value="${st.basePrice}" type="number" groupingUsed="true"/> ₫</td>
                    <td>
                      <c:choose>
                        <c:when test="${st.status == 'SCHEDULED'}">
                          <span class="st-badge st-badge--scheduled">Đã lên lịch</span>
                        </c:when>
                        <c:when test="${st.status == 'SHOWING'}">
                          <span class="st-badge st-badge--showing">Đang chiếu</span>
                        </c:when>
                        <c:when test="${st.status == 'CANCELLED'}">
                          <span class="st-badge st-badge--cancelled">Huỷ</span>
                        </c:when>
                        <c:otherwise>
                          <span class="st-badge st-badge--finished">Đã kết thúc</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="mm-td-actions">
                      <a href="${pageContext.request.contextPath}/manager/showtimes?action=edit&amp;id=<c:out value='${st.id}'/>"
                         class="mm-action-btn mm-action-btn--edit" title="Sửa">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                          <path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                        </svg>
                      </a>
                      <c:choose>
                        <c:when test="${bc != null && bc > 0}">
                          <button type="button" class="mm-action-btn mm-action-btn--delete" disabled
                                  title="Đã có ${bc} đơn — không xóa">
                            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                              <polyline points="3 6 5 6 21 6"/>
                              <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                              <path d="M10 11v6"/><path d="M14 11v6"/>
                              <path d="M9 6V4h6v2"/>
                            </svg>
                          </button>
                        </c:when>
                        <c:otherwise>
                          <form method="post" action="${pageContext.request.contextPath}/manager/showtimes"
                                style="display:inline"
                                onsubmit="return confirm('Xóa suất chiếu này?');">
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
        </div>

        <div id="stCalendarView" class="st-calendar-view" hidden>
          <div class="st-cal-toolbar">
            <button type="button" class="st-cal-nav" onclick="shiftCalendarDay(-1)" aria-label="Ngày trước">‹</button>
            <strong id="stCalDateLabel">—</strong>
            <button type="button" class="st-cal-nav" onclick="shiftCalendarDay(1)" aria-label="Ngày sau">›</button>
            <span class="st-cal-hint">Trục dọc: giờ · ngang: phòng · ô trống = slot khả dụng</span>
          </div>
          <div class="st-cal-scroll">
            <div id="stCalGrid" class="st-cal-grid"></div>
          </div>
        </div>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<%-- rooms for calendar --%>
<script type="application/json" id="stRoomsJson">[
<c:forEach var="r" items="${roomList}" varStatus="vs">
  {"id":"<c:out value='${r.id}'/>","name":"<c:out value='${r.roomName}'/>","capacity":${r.capacity}}<c:if test="${!vs.last}">,</c:if>
</c:forEach>
]</script>

<%-- ── Create Modal ─────────────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stCreateModal" aria-hidden="true">
  <div class="st-modal" role="dialog" aria-modal="true" aria-labelledby="stCreateTitle">
    <div class="st-modal-header">
      <h2 id="stCreateTitle">Thêm Suất Chiếu</h2>
      <button type="button" class="st-modal-close" onclick="closeCreateModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <c:if test="${not empty error and empty editShowtime}">
        <div class="mm-alert mm-alert--error" style="margin-bottom:16px"><c:out value="${error}"/></div>
      </c:if>
      <form method="post" action="${pageContext.request.contextPath}/manager/showtimes" class="st-modal-form" id="stCreateForm">
        <div class="st-form-group">
          <label for="createMovieId">Phim <span class="required">*</span></label>
          <select id="createMovieId" name="movieId" required>
            <option value="">— Chọn phim —</option>
            <c:forEach var="m" items="${movieList}">
              <option value="<c:out value='${m.id}'/>"
                      data-duration="${m.durationMinutes}"
                      ${!isEdit and inputMovieId == m.id ? 'selected' : ''}>
                <c:out value="${m.title}"/> (${m.durationMinutes} phút)
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="st-form-group">
          <label for="createRoomId">Phòng chiếu <span class="required">*</span></label>
          <select id="createRoomId" name="roomId" required>
            <option value="">— Chọn phòng —</option>
            <c:forEach var="r" items="${roomList}">
              <option value="<c:out value='${r.id}'/>"
                      ${!isEdit and inputRoomId == r.id ? 'selected' : ''}>
                <c:out value="${r.roomName}"/> (<c:out value="${r.capacity}"/> ghế)
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="st-form-group">
          <label for="createStartTime">Giờ bắt đầu <span class="required">*</span></label>
          <input id="createStartTime" type="datetime-local" name="startTime" required
                 value="<c:if test='${not isEdit}'><c:out value='${inputStartTime}'/></c:if>"/>
          <p class="st-duration-hint" id="createDurationHint"></p>
        </div>
        <div class="st-form-group">
          <label for="createBasePrice">Giá vé cơ bản (VNĐ) <span class="required">*</span></label>
          <input id="createBasePrice" type="number" name="basePrice" min="1000" max="999999999" step="1000" required
                 placeholder="80000"
                 value="<c:if test='${not isEdit}'><c:out value='${inputBasePrice}'/></c:if>"/>
          <small class="st-hint">Giờ kết thúc tự tính. Buffer dọn phòng ${cleanupBufferMinutes} phút giữa các suất. Trạng thái tự cập nhật theo thời gian.</small>
        </div>
        <div class="st-modal-actions">
          <button type="button" class="st-btn-cancel" onclick="closeCreateModal()">Hủy</button>
          <button type="submit" class="st-btn-primary">+ Thêm Suất Chiếu</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ── Bulk Create Modal ────────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stBulkModal" aria-hidden="true">
  <div class="st-modal st-modal--wide" role="dialog" aria-modal="true" aria-labelledby="stBulkTitle">
    <div class="st-modal-header">
      <h2 id="stBulkTitle">Tạo Hàng Loạt</h2>
      <button type="button" class="st-modal-close" onclick="closeBulkModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <c:if test="${not empty bulkError}">
        <div class="mm-alert mm-alert--error" style="margin-bottom:16px"><c:out value="${bulkError}"/></div>
      </c:if>
      <form method="post" action="${pageContext.request.contextPath}/manager/showtimes" class="st-modal-form" id="stBulkForm">
        <input type="hidden" name="action" value="bulkCreate"/>
        <div class="st-form-row">
          <div class="st-form-group">
            <label for="bulkMovieId">Phim <span class="required">*</span></label>
            <select id="bulkMovieId" name="movieId" required>
              <option value="">— Chọn phim —</option>
              <c:forEach var="m" items="${movieList}">
                <option value="<c:out value='${m.id}'/>"
                        data-duration="${m.durationMinutes}"
                        ${inputMovieId == m.id ? 'selected' : ''}>
                  <c:out value="${m.title}"/> (${m.durationMinutes} phút)
                </option>
              </c:forEach>
            </select>
          </div>
          <div class="st-form-group">
            <label for="bulkRoomId">Phòng <span class="required">*</span></label>
            <select id="bulkRoomId" name="roomId" required>
              <option value="">— Chọn phòng —</option>
              <c:forEach var="r" items="${roomList}">
                <option value="<c:out value='${r.id}'/>" ${inputRoomId == r.id ? 'selected' : ''}>
                  <c:out value="${r.roomName}"/>
                </option>
              </c:forEach>
            </select>
          </div>
        </div>
        <div class="st-form-row">
          <div class="st-form-group">
            <label for="bulkShowDate">Ngày chiếu <span class="required">*</span></label>
            <input id="bulkShowDate" type="date" name="showDate" required
                   value="<c:out value='${not empty inputShowDate ? inputShowDate : today}'/>"/>
          </div>
          <div class="st-form-group">
            <label for="bulkBasePrice">Giá vé (VNĐ) <span class="required">*</span></label>
            <input id="bulkBasePrice" type="number" name="basePrice" min="1000" max="999999999" step="1000" required
                   value="<c:out value='${inputBasePrice}'/>" placeholder="80000"/>
          </div>
        </div>
        <div class="st-form-group">
          <label>Các giờ bắt đầu <span class="required">*</span></label>
          <div id="bulkTimeList" class="st-bulk-times"></div>
          <button type="button" class="st-btn-secondary st-btn-add-time" onclick="addBulkTimeRow()">+ Thêm giờ</button>
          <small class="st-hint">Tối đa 12 suất. Trạng thái tự cập nhật theo thời gian (không chọn tay).</small>
        </div>
        <div class="st-modal-actions">
          <button type="button" class="st-btn-cancel" onclick="closeBulkModal()">Hủy</button>
          <button type="submit" class="st-btn-primary">Tạo tất cả</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ── Copy Day Modal ───────────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stCopyModal" aria-hidden="true">
  <div class="st-modal" role="dialog" aria-modal="true" aria-labelledby="stCopyTitle">
    <div class="st-modal-header">
      <h2 id="stCopyTitle">Copy Lịch Sang Ngày Khác</h2>
      <button type="button" class="st-modal-close" onclick="closeCopyModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <form method="post" action="${pageContext.request.contextPath}/manager/showtimes" class="st-modal-form">
        <input type="hidden" name="action" value="copyDay"/>
        <div class="st-form-group">
          <label for="copyFromDate">Từ ngày <span class="required">*</span></label>
          <input id="copyFromDate" type="date" name="fromDate" required value="<c:out value='${today}'/>"/>
        </div>
        <div class="st-form-group">
          <label for="copyToDate">Sang ngày <span class="required">*</span></label>
          <input id="copyToDate" type="date" name="toDate" required/>
        </div>
        <div class="st-form-group">
          <label for="copyRoomId">Phòng (tuỳ chọn)</label>
          <select id="copyRoomId" name="roomId">
            <option value="">Tất cả phòng</option>
            <c:forEach var="r" items="${roomList}">
              <option value="<c:out value='${r.id}'/>"><c:out value="${r.roomName}"/></option>
            </c:forEach>
          </select>
        </div>
        <small class="st-hint">Giữ nguyên khung giờ; suất trùng lịch hoặc đã quá giờ sẽ bị bỏ qua. Trạng thái tự cập nhật.</small>
        <div class="st-modal-actions">
          <button type="button" class="st-btn-cancel" onclick="closeCopyModal()">Hủy</button>
          <button type="submit" class="st-btn-primary">Copy lịch</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ── Edit Modal ───────────────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stEditModal" aria-hidden="true">
  <div class="st-modal" role="dialog" aria-modal="true" aria-labelledby="stEditTitle">
    <div class="st-modal-header">
      <h2 id="stEditTitle">Sửa Suất Chiếu</h2>
      <button type="button" class="st-modal-close" onclick="closeEditModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <c:if test="${isEdit}">
        <c:set var="editMovieSelected" value="${not empty inputMovieId ? inputMovieId : editShowtime.movieId}"/>
        <c:set var="editRoomSelected" value="${not empty inputRoomId ? inputRoomId : editShowtime.roomId}"/>
        <fmt:formatDate value="${editShowtime.startTime}" pattern="yyyy-MM-dd'T'HH:mm" var="editStartLocal"/>
        <c:set var="editStartValue" value="${not empty inputStartTime ? inputStartTime : editStartLocal}"/>
        <c:if test="${locked}">
          <div class="st-lock-note">
            Suất đã có <strong>${editBookingCount}</strong> đơn đặt vé — chỉ sửa giá vé hoặc trạng thái.
          </div>
        </c:if>
        <c:if test="${not empty error}">
          <div class="mm-alert mm-alert--error" style="margin-bottom:16px"><c:out value="${error}"/></div>
        </c:if>
        <form method="post" action="${pageContext.request.contextPath}/manager/showtimes" class="st-modal-form" id="stEditForm">
          <input type="hidden" name="action" value="update"/>
          <input type="hidden" name="id" value="<c:out value='${editShowtime.id}'/>"/>
          <div class="st-form-group">
            <label for="editMovieId">Phim <span class="required">*</span></label>
            <select id="editMovieId" name="movieId" required ${locked ? 'disabled' : ''}>
              <c:forEach var="m" items="${movieList}">
                <option value="<c:out value='${m.id}'/>"
                        data-duration="${m.durationMinutes}"
                        ${editMovieSelected == m.id ? 'selected' : ''}>
                  <c:out value="${m.title}"/> (${m.durationMinutes} phút)
                </option>
              </c:forEach>
            </select>
            <c:if test="${locked}">
              <input type="hidden" name="movieId" value="<c:out value='${editShowtime.movieId}'/>"/>
            </c:if>
          </div>
          <div class="st-form-group">
            <label for="editRoomId">Phòng chiếu <span class="required">*</span></label>
            <select id="editRoomId" name="roomId" required ${locked ? 'disabled' : ''}>
              <c:forEach var="r" items="${roomList}">
                <option value="<c:out value='${r.id}'/>"
                        ${editRoomSelected == r.id ? 'selected' : ''}>
                  <c:out value="${r.roomName}"/> (<c:out value="${r.capacity}"/> ghế)
                </option>
              </c:forEach>
            </select>
            <c:if test="${locked}">
              <input type="hidden" name="roomId" value="<c:out value='${editShowtime.roomId}'/>"/>
            </c:if>
          </div>
          <div class="st-form-group">
            <label for="editStartTime">Giờ bắt đầu <span class="required">*</span></label>
            <input id="editStartTime" type="datetime-local" name="startTime" required
                   ${locked ? 'disabled' : ''}
                   value="<c:out value='${editStartValue}'/>"/>
            <c:if test="${locked}">
              <input type="hidden" name="startTime" value="<c:out value='${editStartLocal}'/>"/>
            </c:if>
            <p class="st-duration-hint" id="editDurationHint"></p>
          </div>
          <div class="st-form-group">
            <label for="editBasePrice">Giá vé cơ bản (VNĐ) <span class="required">*</span></label>
            <input id="editBasePrice" type="number" name="basePrice" min="1000" max="999999999" step="1000" required
                   value="<c:out value='${not empty inputBasePrice ? inputBasePrice : editShowtime.basePrice}'/>"/>
          </div>
          <div class="st-form-group">
            <label>Trạng thái</label>
            <div class="st-status-readonly">
              <c:choose>
                <c:when test="${editShowtime.status == 'SCHEDULED'}">
                  <span class="st-badge st-badge--scheduled">Đã lên lịch</span>
                </c:when>
                <c:when test="${editShowtime.status == 'SHOWING'}">
                  <span class="st-badge st-badge--showing">Đang chiếu</span>
                </c:when>
                <c:when test="${editShowtime.status == 'CANCELLED'}">
                  <span class="st-badge st-badge--cancelled">Huỷ</span>
                </c:when>
                <c:otherwise>
                  <span class="st-badge st-badge--finished">Đã kết thúc</span>
                </c:otherwise>
              </c:choose>
              <small class="st-hint" style="margin-top:8px">Tự cập nhật theo giờ chiếu (trừ khi đã hủy).</small>
            </div>
          </div>
          <div class="st-modal-actions st-modal-actions--split">
            <div class="st-modal-actions-left">
              <c:if test="${editShowtime.status != 'CANCELLED' && editShowtime.status != 'FINISHED'}">
                <button type="button" class="st-btn-danger" onclick="openCancelReasonModal()">
                  Hủy suất chiếu
                </button>
              </c:if>
            </div>
            <div class="st-modal-actions-right">
              <button type="button" class="st-btn-cancel" onclick="closeEditModal()">Đóng</button>
              <button type="submit" class="st-btn-primary">Lưu Thay Đổi</button>
            </div>
          </div>
        </form>
      </c:if>
    </div>
  </div>
</div>

<%-- ── Cancel Reason Modal ──────────────────────────────────── --%>
<div class="st-modal-backdrop" id="stCancelModal" aria-hidden="true">
  <div class="st-modal" role="dialog" aria-modal="true" aria-labelledby="stCancelTitle">
    <div class="st-modal-header">
      <h2 id="stCancelTitle">Hủy suất chiếu</h2>
      <button type="button" class="st-modal-close" onclick="closeCancelReasonModal()" aria-label="Đóng">✕</button>
    </div>
    <div class="st-modal-body">
      <div class="st-lock-note">
        Hủy suất sẽ ảnh hưởng mọi khách đã đặt vé: gửi email lý do và
        <strong>cộng điểm thưởng tương đương giá trị vé</strong> cho thành viên.
      </div>
      <form method="post" action="${pageContext.request.contextPath}/manager/showtimes"
            class="st-modal-form" id="stCancelForm"
            onsubmit="return validateCancelReason();">
        <input type="hidden" name="action" value="cancel"/>
        <input type="hidden" name="id" id="stCancelShowtimeId"
               value="<c:if test='${isEdit}'><c:out value='${editShowtime.id}'/></c:if>"/>
        <div class="st-form-group">
          <label for="stCancelReason">Lý do hủy <span class="required">*</span></label>
          <textarea id="stCancelReason" name="reason" rows="5" required minlength="10" maxlength="1000"
                    placeholder="Ví dụ: Sự cố kỹ thuật phòng chiếu, bảo trì máy chiếu..."></textarea>
          <small class="st-hint">Tối thiểu 10 ký tự. Nội dung này sẽ gửi trong email tới khách đã đặt.</small>
        </div>
        <div class="st-modal-actions">
          <button type="button" class="st-btn-cancel" onclick="closeCancelReasonModal()">Đóng</button>
          <button type="submit" class="st-btn-danger">Xác nhận hủy suất</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-showtimes.js?v=5"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
