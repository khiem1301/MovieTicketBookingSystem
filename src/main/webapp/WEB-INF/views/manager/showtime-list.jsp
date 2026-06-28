<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Suất chiếu — ÉPCINE"/>
<c:set var="extraCss" value="manager-showtimes"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="mgr-page st-page">

  <div class="mgr-breadcrumb">
    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
    <span>›</span>
    <span>Quản lý Suất chiếu</span>
  </div>

  <div class="st-page-header">
    <div>
      <h1 class="st-title">Quản lý Suất chiếu</h1>
      <p class="st-subtitle">Lập lịch chiếu, kiểm tra trùng phòng và quản lý trạng thái bán vé.</p>
    </div>
  </div>

  <c:if test="${param.success == 'created'}">
    <div class="mgr-alert mgr-alert--success">&#10003; Đã tạo suất chiếu mới!</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mgr-alert mgr-alert--success">&#10003; Đã cập nhật suất chiếu!</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mgr-alert mgr-alert--success">&#10003; Đã xóa suất chiếu!</div>
  </c:if>
  <c:if test="${param.error == 'has_bookings'}">
    <div class="mgr-alert mgr-alert--error">Không thể xóa — suất chiếu đã có đơn đặt vé. Hãy chuyển trạng thái sang <strong>Huỷ (CANCELLED)</strong>.</div>
  </c:if>

  <div class="mgr-grid">

    <%-- Form trái --%>
    <div class="mgr-card">
      <c:choose>
        <c:when test="${not empty editShowtime}">
          <c:set var="locked" value="${editBookingCount != null && editBookingCount > 0}"/>
          <h2 class="mgr-card-title"><span class="mgr-card-title-icon">&#9998;</span> Sửa suất chiếu</h2>
          <c:if test="${locked}">
            <div class="st-lock-note">
              <span class="material-symbols-outlined">lock</span>
              Suất đã có <strong>${editBookingCount}</strong> đơn đặt vé — chỉ sửa giá vé hoặc trạng thái.
            </div>
          </c:if>
          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>
          <form method="post" action="${pageContext.request.contextPath}/manager/showtimes" class="mgr-form" id="stForm">
            <input type="hidden" name="action" value="update"/>
            <input type="hidden" name="id" value="<c:out value='${editShowtime.id}'/>"/>
            <div class="mgr-form-group">
              <label for="movieId">Phim <span class="required">*</span></label>
              <select id="movieId" name="movieId" required ${locked ? 'disabled' : ''}>
                <c:forEach var="m" items="${movieList}">
                  <option value="<c:out value='${m.id}'/>"
                          data-duration="${m.durationMinutes}"
                          ${(not empty inputMovieId ? inputMovieId : editShowtime.movieId) == m.id ? 'selected' : ''}>
                    <c:out value="${m.title}"/> (${m.durationMinutes} phút)
                  </option>
                </c:forEach>
              </select>
              <c:if test="${locked}">
                <input type="hidden" name="movieId" value="<c:out value='${editShowtime.movieId}'/>"/>
              </c:if>
            </div>
            <div class="mgr-form-group">
              <label for="roomId">Phòng chiếu <span class="required">*</span></label>
              <select id="roomId" name="roomId" required ${locked ? 'disabled' : ''}>
                <c:forEach var="r" items="${roomList}">
                  <option value="<c:out value='${r.id}'/>"
                          ${(not empty inputRoomId ? inputRoomId : editShowtime.roomId) == r.id ? 'selected' : ''}>
                    <c:out value="${r.roomName}"/> (<c:out value="${r.capacity}"/> ghế)
                  </option>
                </c:forEach>
              </select>
              <c:if test="${locked}">
                <input type="hidden" name="roomId" value="<c:out value='${editShowtime.roomId}'/>"/>
              </c:if>
            </div>
            <div class="mgr-form-group">
              <label for="startTime">Giờ bắt đầu <span class="required">*</span></label>
              <input id="startTime" type="datetime-local" name="startTime" required
                     ${locked ? 'disabled' : ''}
                     value="<c:choose><c:when test='${not empty inputStartTime}'><c:out value='${inputStartTime}'/></c:when><c:otherwise><fmt:formatDate value='${editShowtime.startTime}' pattern="yyyy-MM-dd'T'HH:mm"/></c:otherwise></c:choose>"/>
              <c:if test="${locked}">
                <input type="hidden" name="startTime"
                       value="<fmt:formatDate value='${editShowtime.startTime}' pattern='yyyy-MM-dd\'T\'HH:mm'/>"/>
              </c:if>
              <p class="st-duration-hint" id="stDurationHint"></p>
            </div>
            <div class="mgr-form-group">
              <label for="basePrice">Giá vé cơ bản (VNĐ) <span class="required">*</span></label>
              <input id="basePrice" type="number" name="basePrice" min="1000" max="999999999" step="1000" required
                     aria-describedby="basePriceHint"
                     value="<c:out value='${not empty inputBasePrice ? inputBasePrice : editShowtime.basePrice}'/>"/>
              <small id="basePriceHint" class="mgr-hint">Tối đa 9 chữ số (tối đa 999.999.999 VNĐ)</small>
            </div>
            <div class="mgr-form-group">
              <label for="status">Trạng thái</label>
              <select id="status" name="status">
                <option value="SCHEDULED" ${editShowtime.status == 'SCHEDULED' ? 'selected' : ''}>Đã lên lịch</option>
                <option value="OPEN" ${editShowtime.status == 'OPEN' ? 'selected' : ''}>Mở bán</option>
                <option value="SOLD_OUT" ${editShowtime.status == 'SOLD_OUT' ? 'selected' : ''}>Hết vé</option>
                <option value="CANCELLED" ${editShowtime.status == 'CANCELLED' ? 'selected' : ''}>Huỷ</option>
                <option value="FINISHED" ${editShowtime.status == 'FINISHED' ? 'selected' : ''}>Đã kết thúc</option>
              </select>
            </div>
            <div class="mgr-form-actions">
              <button type="submit" class="btn btn-primary mgr-submit">&#128190; Lưu thay đổi</button>
              <a href="${pageContext.request.contextPath}/manager/showtimes" class="btn btn-ghost mgr-submit">Huỷ</a>
            </div>
          </form>
        </c:when>
        <c:otherwise>
          <h2 class="mgr-card-title"><span class="mgr-card-title-icon">＋</span> Thêm suất chiếu</h2>
          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>
          <form method="post" action="${pageContext.request.contextPath}/manager/showtimes" class="mgr-form" id="stForm">
            <div class="mgr-form-group">
              <label for="movieId">Phim <span class="required">*</span></label>
              <select id="movieId" name="movieId" required>
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
            <div class="mgr-form-group">
              <label for="roomId">Phòng chiếu <span class="required">*</span></label>
              <select id="roomId" name="roomId" required>
                <option value="">— Chọn phòng —</option>
                <c:forEach var="r" items="${roomList}">
                  <option value="<c:out value='${r.id}'/>"
                          ${inputRoomId == r.id ? 'selected' : ''}>
                    <c:out value="${r.roomName}"/> (<c:out value="${r.capacity}"/> ghế)
                  </option>
                </c:forEach>
              </select>
            </div>
            <div class="mgr-form-group">
              <label for="startTime">Giờ bắt đầu <span class="required">*</span></label>
              <input id="startTime" type="datetime-local" name="startTime" required
                     value="<c:out value='${inputStartTime}'/>"/>
              <p class="st-duration-hint" id="stDurationHint"></p>
            </div>
            <div class="mgr-form-group">
              <label for="basePrice">Giá vé cơ bản (VNĐ) <span class="required">*</span></label>
              <input id="basePrice" type="number" name="basePrice" min="1000" max="999999999" step="1000" required
                     placeholder="80000"
                     aria-describedby="basePriceHint"
                     value="<c:out value='${inputBasePrice}'/>"/>
              <small id="basePriceHint" class="mgr-hint">Tối đa 9 chữ số (tối đa 999.999.999 VNĐ)</small>
            </div>
            <p class="st-form-note">Giờ kết thúc tự tính theo thời lượng phim. Chưa áp dụng thời gian dọn phòng giữa các suất.</p>
            <button type="submit" class="btn btn-primary mgr-submit">+ Thêm suất chiếu</button>
          </form>
        </c:otherwise>
      </c:choose>
    </div>

    <%-- Bảng phải --%>
    <div class="mgr-card st-list-card">
      <h2 class="mgr-card-title">
        Danh sách suất chiếu
        <span class="mgr-count" id="stVisibleCount">${fn:length(showtimeList)}</span>
      </h2>

      <div class="st-filters">
        <select id="stFilterMovie" class="st-filter-select" aria-label="Lọc theo phim">
          <option value="">Tất cả phim</option>
          <c:forEach var="m" items="${movieList}">
            <option value="<c:out value='${m.id}'/>"><c:out value="${m.title}"/></option>
          </c:forEach>
        </select>
        <select id="stFilterRoom" class="st-filter-select" aria-label="Lọc theo phòng">
          <option value="">Tất cả phòng</option>
          <c:forEach var="r" items="${roomList}">
            <option value="<c:out value='${r.id}'/>"><c:out value="${r.roomName}"/></option>
          </c:forEach>
        </select>
        <input id="stFilterDate" type="date" class="st-filter-date" aria-label="Lọc theo ngày"/>
        <select id="stFilterStatus" class="st-filter-select" aria-label="Lọc theo trạng thái">
          <option value="">Tất cả trạng thái</option>
          <option value="SCHEDULED">Đã lên lịch</option>
          <option value="OPEN">Mở bán</option>
          <option value="SOLD_OUT">Hết vé</option>
          <option value="CANCELLED">Huỷ</option>
          <option value="FINISHED">Đã kết thúc</option>
        </select>
      </div>

      <div class="mgr-table-wrap">
        <table class="mgr-table st-table" id="stTable">
          <thead>
            <tr>
              <th>Phim</th>
              <th>Phòng</th>
              <th>Giờ chiếu</th>
              <th>Giá gốc</th>
              <th>Trạng thái</th>
              <th>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="st" items="${showtimeList}">
              <c:set var="bc" value="${bookingCountMap[st.id]}"/>
              <tr class="st-row"
                  data-movie-id="<c:out value='${st.movieId}'/>"
                  data-room-id="<c:out value='${st.roomId}'/>"
                  data-status="<c:out value='${st.status}'/>"
                  data-date="<fmt:formatDate value='${st.startTime}' pattern='yyyy-MM-dd'/>">
                <td>
                  <div class="st-movie-cell">
                    <c:if test="${not empty st.moviePosterUrl}">
                      <img src="${pageContext.request.contextPath}/<c:out value='${st.moviePosterUrl}'/>"
                           alt="" class="st-poster-thumb"/>
                    </c:if>
                    <div>
                      <div class="st-movie-title"><c:out value="${st.movieTitle}"/></div>
                      <div class="st-movie-meta"><c:out value="${st.movieDurationMinutes}"/> phút · <c:out value="${st.movieAgeRating}"/></div>
                    </div>
                  </div>
                </td>
                <td><c:out value="${st.roomName}"/></td>
                <td class="st-time-cell">
                  <fmt:formatDate value="${st.startTime}" pattern="dd/MM/yyyy HH:mm"/>
                  <span class="st-time-sep">—</span>
                  <fmt:formatDate value="${st.endTime}" pattern="HH:mm"/>
                </td>
                <td><fmt:formatNumber value="${st.basePrice}" type="number" groupingUsed="true"/> &#8363;</td>
                <td>
                  <span class="st-badge st-badge--${fn:toLowerCase(st.status)}">
                    <c:choose>
                      <c:when test="${st.status == 'SCHEDULED'}">Đã lên lịch</c:when>
                      <c:when test="${st.status == 'OPEN'}">Mở bán</c:when>
                      <c:when test="${st.status == 'SOLD_OUT'}">Hết vé</c:when>
                      <c:when test="${st.status == 'CANCELLED'}">Huỷ</c:when>
                      <c:otherwise>Đã kết thúc</c:otherwise>
                    </c:choose>
                  </span>
                </td>
                <td class="st-actions">
                  <a href="${pageContext.request.contextPath}/manager/showtimes?action=edit&amp;id=<c:out value='${st.id}'/>"
                     class="st-action-btn" title="Sửa">
                    <span class="material-symbols-outlined">edit</span>
                  </a>
                  <c:choose>
                    <c:when test="${bc != null && bc > 0}">
                      <span class="st-action-btn st-action-btn--muted" title="Đã có ${bc} đơn — không xóa">
                        <span class="material-symbols-outlined">block</span>
                      </span>
                    </c:when>
                    <c:otherwise>
                      <form method="post" action="${pageContext.request.contextPath}/manager/showtimes"
                            class="st-delete-form"
                            onsubmit="return confirm('Xóa suất chiếu này?');">
                        <input type="hidden" name="action" value="delete"/>
                        <input type="hidden" name="id" value="<c:out value='${st.id}'/>"/>
                        <button type="submit" class="st-action-btn st-action-btn--danger" title="Xóa">
                          <span class="material-symbols-outlined">delete</span>
                        </button>
                      </form>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty showtimeList}">
              <tr id="stEmptyRow">
                <td colspan="6" class="st-empty">Chưa có suất chiếu nào. Thêm suất mới ở form bên trái.</td>
              </tr>
            </c:if>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-showtimes.js"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
