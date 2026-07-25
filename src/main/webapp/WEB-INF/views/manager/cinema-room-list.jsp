<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Phòng chiếu — ÉPCINE"/>
<c:set var="extraCss" value="manager-auditoriums"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="mgr-page aud-list-page">

  <div class="mgr-breadcrumb">
    <a href="${ctx}/home">Trang chủ</a>
    <span>›</span>
    <span>Quản lý Phòng chiếu</span>
  </div>

  <div class="aud-list-header">
    <div>
      <h1 class="mgr-title">Quản lý Phòng chiếu</h1>
      <p class="aud-list-subtitle">Danh sách phòng chiếu theo dữ liệu hệ thống</p>
    </div>
    <form method="get" action="${ctx}/manager/rooms/create" class="aud-add-room-form">
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
        <span class="mgr-count" id="audRoomCount"><c:out value="${pgTotalItems}"/></span>
      </h2>
      <div class="aud-filters" role="tablist">
        <a href="${ctx}/manager/rooms"
           class="aud-filter ${statusFilter == 'ALL' ? 'aud-filter--active' : ''}">Tất cả</a>
        <a href="${ctx}/manager/rooms?status=ACTIVE"
           class="aud-filter ${statusFilter == 'ACTIVE' ? 'aud-filter--active' : ''}">Hoạt động</a>
        <a href="${ctx}/manager/rooms?status=INACTIVE"
           class="aud-filter ${statusFilter == 'INACTIVE' ? 'aud-filter--active' : ''}">Ngưng hoạt động</a>
      </div>
    </div>

    <c:choose>
      <c:when test="${empty roomList}">
        <p class="aud-list-empty">
          <c:choose>
            <c:when test="${statusFilter != 'ALL'}">Không có phòng nào với bộ lọc hiện tại.</c:when>
            <c:otherwise>Chưa có phòng chiếu nào. Dùng form góc trên để tạo phòng mới.</c:otherwise>
          </c:choose>
        </p>
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
                  <td class="mgr-td-num">${pgRankStart + st.index}</td>
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
                      <form method="post" action="${ctx}/manager/rooms/update"
                            class="aud-status-form">
                        <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
                        <input type="hidden" name="action" value="toggle"/>
                        <input type="hidden" name="returnPage" value="<c:out value='${pgCurrent}'/>"/>
                        <input type="hidden" name="returnStatus" value="<c:out value='${statusFilter}'/>"/>
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
                      <a href="${ctx}/manager/rooms/detail?id=<c:out value='${room.id}'/>"
                         class="aud-btn aud-btn--detail"
                         title="Chỉnh layout ghế">
                        Layout
                      </a>
                      <c:choose>
                        <c:when test="${deletableRoomIds.contains(room.id)}">
                          <form method="post" action="${ctx}/manager/rooms/delete"
                                class="aud-delete-form"
                                onsubmit="return confirm('Xóa phòng \'<c:out value="${room.roomName}"/>\'?\nChỉ dùng cho phòng tạo nhầm. Hành động này không thể hoàn tác.');">
                            <input type="hidden" name="roomId" value="<c:out value='${room.id}'/>"/>
                            <input type="hidden" name="returnPage" value="<c:out value='${pgCurrent}'/>"/>
                            <input type="hidden" name="returnStatus" value="<c:out value='${statusFilter}'/>"/>
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

        <c:if test="${pgTotal > 1}">
          <div class="aud-pagination">
            <span class="aud-pag-info">
              Trang <strong><c:out value="${pgCurrent}"/></strong> / <c:out value="${pgTotal}"/>
              &mdash; Tổng <strong><c:out value="${pgTotalItems}"/></strong> phòng
            </span>
            <div class="aud-pag-btns">
              <c:if test="${pgCurrent > 1}">
                <a class="aud-pag-btn" href="${ctx}/manager/rooms?page=${pgCurrent - 1}${pgQueryExtra}" aria-label="Trang trước">‹</a>
              </c:if>
              <c:forEach begin="1" end="${pgTotal}" var="pg">
                <a class="aud-pag-btn ${pg == pgCurrent ? 'is-active' : ''}"
                   href="${ctx}/manager/rooms?page=${pg}${pgQueryExtra}">${pg}</a>
              </c:forEach>
              <c:if test="${pgCurrent < pgTotal}">
                <a class="aud-pag-btn" href="${ctx}/manager/rooms?page=${pgCurrent + 1}${pgQueryExtra}" aria-label="Trang sau">›</a>
              </c:if>
            </div>
          </div>
        </c:if>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
