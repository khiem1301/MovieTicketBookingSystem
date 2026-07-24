<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Phòng chiếu — ÉPCINE"/>
<c:set var="extraCss" value="manager-auditoriums"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="mgr-page aud-list-page">

  <div class="mgr-breadcrumb">
    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
    <span>›</span>
    <span>Quản lý Phòng chiếu</span>
  </div>

  <div class="aud-list-header">
    <div>
      <h1 class="mgr-title">Quản lý Phòng chiếu</h1>
      <p class="aud-list-subtitle">Danh sách phòng chiếu theo dữ liệu hệ thống</p>
    </div>
    <form method="get" action="${pageContext.request.contextPath}/manager/rooms/create" class="aud-add-room-form">
      <button type="submit" class="aud-btn aud-btn--primary">
        <span class="material-symbols-outlined">add</span>
        Thêm phòng chiếu
      </button>
    </form>
  </div>

  <c:if test="${param.success == 'created'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã thêm phòng chiếu thành công!</div>
  </c:if>
  <c:if test="${param.success == 'status_updated'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã cập nhật trạng thái phòng chiếu!</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã xóa phòng chiếu (tạo nhầm) thành công!</div>
  </c:if>
  <c:if test="${not empty error}">
    <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
  </c:if>

  <div class="mgr-card">
    <div class="aud-list-toolbar">
      <h2 class="mgr-card-title" style="margin:0">
        Danh sách phòng
        <span class="mgr-count" id="audRoomCount">${fn:length(roomList)}</span>
      </h2>
      <div class="aud-filters" role="tablist">
        <button type="button" class="aud-filter aud-filter--active" data-filter="ALL">Tất cả</button>
        <button type="button" class="aud-filter" data-filter="ACTIVE">Hoạt động</button>
        <button type="button" class="aud-filter" data-filter="INACTIVE">Ngưng hoạt động</button>
      </div>
    </div>

    <c:choose>
      <c:when test="${empty roomList}">
        <p class="aud-list-empty">Chưa có phòng chiếu nào. Dùng form góc trên để tạo phòng mới.</p>
      </c:when>
      <c:otherwise>
        <div class="mgr-table-wrap">
          <table class="mgr-table aud-room-table" id="audRoomTable">
            <thead>
              <tr>
                <th>#</th>
                <th>Tên phòng</th>
                <th>Sức chứa</th>
                <th>Trạng thái</th>
                <th>Ngày tạo</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="room" items="${roomList}" varStatus="st">
                <c:set var="isInactive" value="${room.status != 'ACTIVE'}"/>
                <c:set var="displayStatus" value="${isInactive ? 'INACTIVE' : 'ACTIVE'}"/>
                <tr class="aud-room-row" data-status="<c:out value='${displayStatus}'/>">
                  <td class="mgr-td-num">${st.count}</td>
                  <td class="aud-room-name-cell">
                    <c:out value="${room.roomName}"/>
                  </td>
                  <td>
                    <c:out value="${room.capacity}"/> ghế
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${!isInactive}">
                        <span class="aud-status-pill aud-status-pill--live">Hoạt động</span>
                      </c:when>
                      <c:otherwise>
                        <span class="aud-status-pill aud-status-pill--off">Ngưng hoạt động</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td class="cell-muted">
                    <c:choose>
                      <c:when test="${not empty room.createdAt}">
                        <fmt:formatDate value="${room.createdAt}" pattern="dd/MM/yyyy HH:mm"/>
                      </c:when>
                      <c:otherwise>—</c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <div class="aud-row-actions">
                      <form method="post" action="${pageContext.request.contextPath}/manager/rooms/update"
                            class="aud-status-form">
                        <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
                        <input type="hidden" name="action" value="toggle"/>
                        <span class="aud-status-select-wrap">
                          <select name="status"
                                  class="aud-status-select aud-status-select--${displayStatus}"
                                  aria-label="Trạng thái phòng"
                                  onchange="this.form.submit()">
                            <option value="ACTIVE" ${!isInactive ? 'selected' : ''}>Hoạt động</option>
                            <option value="INACTIVE" ${isInactive ? 'selected' : ''}>Ngưng hoạt động</option>
                          </select>
                          <span class="material-symbols-outlined aud-status-select-icon" aria-hidden="true">expand_more</span>
                        </span>
                      </form>
                      <a href="${pageContext.request.contextPath}/manager/rooms/detail?id=<c:out value='${room.id}'/>"
                         class="aud-btn aud-btn--detail"
                         title="Chỉnh layout ghế">
                        Layout
                      </a>
                      <c:choose>
                        <c:when test="${deletableRoomIds.contains(room.id)}">
                          <form method="post" action="${pageContext.request.contextPath}/manager/rooms/delete"
                                class="aud-delete-form"
                                onsubmit="return confirm('Xóa phòng \'<c:out value="${room.roomName}"/>\'?\nChỉ dùng cho phòng tạo nhầm. Hành động này không thể hoàn tác.');">
                            <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
                            <button type="submit" class="aud-btn aud-btn--danger aud-btn--sm" title="Xóa phòng tạo nhầm">
                              Xóa
                            </button>
                          </form>
                        </c:when>
                        <c:otherwise>
                          <button type="button" class="aud-btn aud-btn--danger aud-btn--sm" disabled
                                  title="Không thể xóa — phòng đã có suất chiếu hoặc dữ liệu đặt ghế">
                            Xóa
                          </button>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/manager-auditoriums.js?v=2"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
