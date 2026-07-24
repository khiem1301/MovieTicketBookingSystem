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
<c:set var="locked" value="${isEdit and editBookingCount != null and editBookingCount > 0}"/>

<div class="mm-page st-page"
     data-open-create="${openCreateModal}"
     data-open-edit="${openEditModal}">

  <c:if test="${param.success == 'created'}">
    <div class="mm-alert mm-alert--success">Thêm suất chiếu thành công.</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mm-alert mm-alert--success">Cập nhật suất chiếu thành công.</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mm-alert mm-alert--success">Xóa suất chiếu thành công.</div>
  </c:if>
  <c:if test="${param.error == 'has_bookings'}">
    <div class="mm-alert mm-alert--error">Không thể xóa — suất chiếu đã có đơn đặt vé. Hãy chuyển trạng thái sang Huỷ.</div>
  </c:if>

  <div class="mm-header">
    <div>
      <h1 class="mm-title">Quản Lý Suất Chiếu</h1>
      <p class="mm-subtitle">Lập lịch chiếu, kiểm tra trùng phòng và quản lý trạng thái bán vé.</p>
    </div>
    <button type="button" class="mm-btn-add" id="stBtnAdd" onclick="openCreateModal()">+ Thêm Suất Chiếu</button>
  </div>

  <div class="mm-card">
    <div class="mm-toolbar">
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
        <input id="stFilterDate" type="date" class="st-filter-date" aria-label="Lọc theo ngày" onchange="applyFilters()"/>
        <div class="mm-tabs" role="tablist">
          <button type="button" class="mm-tab active" data-filter="" onclick="setStatusTab(this)">Tất Cả</button>
          <button type="button" class="mm-tab" data-filter="SCHEDULED" onclick="setStatusTab(this)">Đã Lên Lịch</button>
          <button type="button" class="mm-tab" data-filter="OPEN" onclick="setStatusTab(this)">Mở Bán</button>
          <button type="button" class="mm-tab" data-filter="SOLD_OUT" onclick="setStatusTab(this)">Hết Vé</button>
          <button type="button" class="mm-tab" data-filter="CANCELLED" onclick="setStatusTab(this)">Huỷ</button>
          <button type="button" class="mm-tab" data-filter="FINISHED" onclick="setStatusTab(this)">Kết Thúc</button>
        </div>
      </div>
    </div>

    <c:choose>
      <c:when test="${empty showtimeList}">
        <div class="mm-empty">Chưa có suất chiếu nào. Bấm <strong>+ Thêm Suất Chiếu</strong> để thêm mới.</div>
      </c:when>
      <c:otherwise>
        <div class="mm-table-wrap">
          <table class="mm-table st-table">
            <thead>
              <tr>
                <th>PHIM</th>
                <th>PHÒNG</th>
                <th>GIỜ CHIẾU</th>
                <th>GIÁ GỐC</th>
                <th>TRẠNG THÁI</th>
                <th>THAO TÁC</th>
              </tr>
            </thead>
            <tbody id="stTableBody">
              <c:forEach var="st" items="${showtimeList}">
                <c:set var="bc" value="${bookingCountMap[st.id]}"/>
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
                    data-movie-id="<c:out value='${st.movieId}'/>"
                    data-room-id="<c:out value='${st.roomId}'/>"
                    data-status="<c:out value='${st.status}'/>"
                    data-date="<fmt:formatDate value='${st.startTime}' pattern='yyyy-MM-dd'/>"
                    data-title="<c:out value='${fn:toLowerCase(st.movieTitle)}'/>">
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
                  <td><fmt:formatNumber value="${st.basePrice}" type="number" groupingUsed="true"/> ₫</td>
                  <td>
                    <c:choose>
                      <c:when test="${st.status == 'SCHEDULED'}">
                        <span class="st-badge st-badge--scheduled">Đã lên lịch</span>
                      </c:when>
                      <c:when test="${st.status == 'OPEN'}">
                        <span class="st-badge st-badge--open">Mở bán</span>
                      </c:when>
                      <c:when test="${st.status == 'SOLD_OUT'}">
                        <span class="st-badge st-badge--sold_out">Hết vé</span>
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
      </c:otherwise>
    </c:choose>
  </div>
</div>

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
          <small class="st-hint">Tối đa 9 chữ số (999.999.999 VNĐ). Giờ kết thúc tự tính theo thời lượng phim.</small>
        </div>
        <div class="st-modal-actions">
          <button type="button" class="st-btn-cancel" onclick="closeCreateModal()">Hủy</button>
          <button type="submit" class="st-btn-primary">+ Thêm Suất Chiếu</button>
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
            <label for="editStatus">Trạng thái</label>
            <select id="editStatus" name="status">
              <option value="SCHEDULED" ${editShowtime.status == 'SCHEDULED' ? 'selected' : ''}>Đã lên lịch</option>
              <option value="OPEN" ${editShowtime.status == 'OPEN' ? 'selected' : ''}>Mở bán</option>
              <option value="SOLD_OUT" ${editShowtime.status == 'SOLD_OUT' ? 'selected' : ''}>Hết vé</option>
              <option value="CANCELLED" ${editShowtime.status == 'CANCELLED' ? 'selected' : ''}>Huỷ</option>
              <option value="FINISHED" ${editShowtime.status == 'FINISHED' ? 'selected' : ''}>Đã kết thúc</option>
            </select>
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

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-showtimes.js?v=2"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
