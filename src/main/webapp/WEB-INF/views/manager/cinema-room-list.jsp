<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Phòng chiếu — ÉPCINE"/>
<c:set var="extraCss" value="manager-auditoriums"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="aud-page">
  <div class="aud-bg-glow" aria-hidden="true"></div>

  <div class="aud-inner">

    <%-- Breadcrumb --%>
    <div class="mgr-breadcrumb aud-breadcrumb">
      <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
      <span>›</span>
      <span>Quản lý Phòng chiếu</span>
    </div>

    <%-- Page header --%>
    <header class="aud-header">
      <div class="aud-header-text">
        <h1 class="aud-title">Quản lý Phòng chiếu</h1>
        <p class="aud-subtitle">
          Theo dõi và điều phối các phòng chiếu. Giám sát trạng thái hoạt động,
          sức chứa và tình trạng kỹ thuật toàn bộ hệ thống rạp.
        </p>
      </div>
      <div class="aud-header-actions">
        <button type="button" class="aud-btn aud-btn--ghost" disabled title="Sắp ra mắt">
          <span class="material-symbols-outlined">tune</span>
          Cấu hình hệ thống
        </button>
        <button type="button" class="aud-btn aud-btn--primary" disabled title="Sắp ra mắt">
          <span class="material-symbols-outlined">add</span>
          Thêm phòng chiếu
        </button>
      </div>
    </header>

    <c:if test="${param.success == 'updated'}">
      <div class="mgr-alert mgr-alert--success aud-alert">✓ Đã cập nhật trạng thái phòng chiếu!</div>
    </c:if>

    <div class="aud-layout">

      <%-- Left: room cards --%>
      <div class="aud-main">

        <%-- Filter bar --%>
        <div class="aud-filter-bar glass-panel">
          <div class="aud-filters" role="tablist">
            <button type="button" class="aud-filter aud-filter--active" data-filter="ALL">Tất cả</button>
            <button type="button" class="aud-filter" data-filter="ACTIVE">Hoạt động</button>
            <button type="button" class="aud-filter" data-filter="MAINTENANCE">Bảo trì</button>
          </div>
          <div class="aud-view-toggle" aria-hidden="true">
            <span class="material-symbols-outlined aud-view-icon aud-view-icon--active">view_module</span>
            <span class="material-symbols-outlined aud-view-icon">view_list</span>
          </div>
        </div>

        <%-- Cards grid --%>
        <div class="aud-cards-grid" id="audRoomGrid">

          <c:choose>
            <c:when test="${empty roomList}">
              <div class="aud-empty glass-panel">
                <span class="material-symbols-outlined">meeting_room</span>
                <p>Chưa có phòng chiếu nào trong hệ thống.</p>
              </div>
            </c:when>
            <c:otherwise>
              <c:forEach var="room" items="${roomList}" varStatus="st">
                <c:set var="meta" value="${roomMetaMap[room.id]}"/>
                <c:set var="isSelected" value="${selectedRoom.id == room.id}"/>
                <c:set var="isMaintenance" value="${room.status == 'MAINTENANCE'}"/>
                <c:set var="isInactive" value="${room.status == 'INACTIVE'}"/>
                <c:set var="isLive" value="${room.status == 'ACTIVE'}"/>

                <article class="aud-room-card glass-panel${isSelected ? ' aud-room-card--selected' : ''}${isMaintenance or isInactive ? ' aud-room-card--offline' : ''}"
                         role="button" tabindex="0"
                         data-id="<c:out value='${room.id}'/>"
                         data-name="<c:out value='${room.roomName}'/>"
                         data-capacity="<c:out value='${room.capacity}'/>"
                         data-status="<c:out value='${room.status}'/>"
                         data-tag="<c:out value='${meta.tag}'/>"
                         data-projection="<c:out value='${meta.projection}'/>"
                         data-audio="<c:out value='${meta.audio}'/>"
                         data-chip-projection="<c:out value='${meta.chipProjection}'/>"
                         data-chip-audio="<c:out value='${meta.chipAudio}'/>"
                         data-screen-ratio="<c:out value='${meta.screenRatio}'/>"
                         data-current-show="<c:out value='${meta.currentShow}'/>"
                         data-occupancy="<c:out value='${meta.occupancy}'/>"
                         data-maintenance-note="<c:out value='${meta.maintenanceNote}'/>"
                         data-maintenance-eta="<c:out value='${meta.maintenanceEta}'/>">

                  <div class="aud-room-card__glow" aria-hidden="true"></div>

                  <div class="aud-room-card__head">
                    <div>
                      <div class="aud-room-card__title-row">
                        <h3 class="aud-room-card__name"><c:out value="${room.roomName}"/></h3>
                        <c:if test="${not empty meta.tag}">
                          <span class="aud-room-tag"><c:out value="${meta.tag}"/></span>
                        </c:if>
                      </div>
                      <span class="aud-room-seats">
                        <span class="material-symbols-outlined">weekend</span>
                        <c:out value="${room.capacity}"/> ghế
                      </span>
                    </div>

                    <div class="aud-room-toggle-wrap">
                      <label class="aud-toggle${isMaintenance or isInactive ? ' aud-toggle--disabled' : ''}">
                        <input type="checkbox"
                               class="aud-toggle-input"
                               ${isLive ? 'checked' : ''}
                               ${isMaintenance or isInactive ? 'disabled' : ''}
                               aria-label="Trạng thái phòng"/>
                        <span class="aud-toggle-track"></span>
                      </label>
                      <span class="aud-room-status-label${isLive ? ' aud-room-status-label--live' : ''}">
                        <c:choose>
                          <c:when test="${isLive}">Hoạt động</c:when>
                          <c:when test="${isMaintenance}">Bảo trì</c:when>
                          <c:otherwise>Ngưng</c:otherwise>
                        </c:choose>
                      </span>
                    </div>
                  </div>

                  <div class="aud-room-card__body">
                    <c:choose>
                      <c:when test="${isMaintenance}">
                        <div class="aud-room-chips">
                          <span class="aud-chip aud-chip--muted">
                            <span class="material-symbols-outlined">build</span>
                            <c:out value="${not empty meta.maintenanceNote ? meta.maintenanceNote : 'Đang bảo trì'}"/>
                          </span>
                        </div>
                        <div class="aud-occupancy">
                          <div class="aud-occupancy__labels">
                            <span>Trạng thái: Bảo trì thiết bị</span>
                            <span><c:out value="${not empty meta.maintenanceEta ? meta.maintenanceEta : '—'}"/></span>
                          </div>
                          <div class="aud-progress">
                            <div class="aud-progress__bar aud-progress__bar--muted" style="width:100%"></div>
                          </div>
                        </div>
                      </c:when>
                      <c:otherwise>
                        <div class="aud-room-chips">
                          <span class="aud-chip">
                            <span class="material-symbols-outlined">video_camera_front</span>
                            <c:out value="${meta.chipProjection}"/>
                          </span>
                          <span class="aud-chip">
                            <span class="material-symbols-outlined">volume_up</span>
                            <c:out value="${meta.chipAudio}"/>
                          </span>
                        </div>
                        <div class="aud-occupancy">
                          <div class="aud-occupancy__labels">
                            <span>Suất hiện tại: <c:out value="${meta.currentShow}"/></span>
                            <span><c:out value="${meta.occupancy}"/>% đầy</span>
                          </div>
                          <div class="aud-progress">
                            <div class="aud-progress__bar" style="width:${meta.occupancy}%"></div>
                          </div>
                        </div>
                      </c:otherwise>
                    </c:choose>
                  </div>
                </article>
              </c:forEach>

              <%-- Add new placeholder --%>
              <article class="aud-room-card aud-room-card--add glass-panel" tabindex="0" role="button"
                       aria-label="Thêm phòng chiếu mới" title="Sắp ra mắt">
                <div class="aud-add-icon">
                  <span class="material-symbols-outlined">add</span>
                </div>
                <h3 class="aud-add-title">Thêm phòng mới</h3>
                <p class="aud-add-desc">Cấu hình phòng chiếu và sơ đồ ghế mới.</p>
              </article>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <%-- Right: detail panel --%>
      <aside class="aud-detail-col">
        <div class="aud-detail glass-panel-heavy" id="audDetailPanel">

          <c:if test="${not empty selectedRoom}">
            <c:set var="selMeta" value="${roomMetaMap[selectedRoom.id]}"/>
            <c:set var="selLive" value="${selectedRoom.status == 'ACTIVE'}"/>
            <c:set var="selMaint" value="${selectedRoom.status == 'MAINTENANCE'}"/>

            <div class="aud-detail__hero">
              <div class="aud-detail__hero-img" aria-hidden="true"></div>
              <div class="aud-detail__hero-overlay"></div>
              <div class="aud-detail__hero-content">
                <div>
                  <span class="aud-detail__badge">Đang chọn</span>
                  <h2 class="aud-detail__name" id="audDetailName"><c:out value="${selectedRoom.roomName}"/></h2>
                </div>
                <button type="button" class="aud-detail__edit" disabled title="Sắp ra mắt">
                  <span class="material-symbols-outlined">edit</span>
                </button>
              </div>
            </div>

            <div class="aud-detail__body">
              <div class="aud-detail__stats">
                <div class="aud-stat-box">
                  <span class="aud-stat-label">Tổng sức chứa</span>
                  <span class="aud-stat-value" id="audDetailCapacity"><c:out value="${selectedRoom.capacity}"/></span>
                </div>
                <div class="aud-stat-box">
                  <span class="aud-stat-label">Ghế hỗ trợ</span>
                  <span class="aud-stat-value" id="audDetailAccessible">
                    <c:out value="${accessibleSeatCount}"/>
                    <span class="aud-stat-unit">ghế</span>
                  </span>
                </div>
              </div>

              <section class="aud-detail__section">
                <h4 class="aud-section-title">Thông số kỹ thuật</h4>
                <ul class="aud-spec-list">
                  <li>
                    <span class="aud-spec-key">
                      <span class="material-symbols-outlined">videocam</span> Hình chiếu
                    </span>
                    <span class="aud-spec-val" id="audDetailProjection"><c:out value="${selMeta.projection}"/></span>
                  </li>
                  <li>
                    <span class="aud-spec-key">
                      <span class="material-symbols-outlined">speaker</span> Âm thanh
                    </span>
                    <span class="aud-spec-val" id="audDetailAudio"><c:out value="${selMeta.audio}"/></span>
                  </li>
                  <li>
                    <span class="aud-spec-key">
                      <span class="material-symbols-outlined">aspect_ratio</span> Tỷ lệ màn
                    </span>
                    <span class="aud-spec-val" id="audDetailRatio"><c:out value="${selMeta.screenRatio}"/></span>
                  </li>
                </ul>
              </section>

              <section class="aud-detail__section">
                <h4 class="aud-section-title">Khu vực ghế</h4>
                <div class="aud-zones" id="audDetailZones">
                  <div class="aud-zone">
                    <div class="aud-zone__left">
                      <span class="aud-zone-dot aud-zone-dot--vip"></span>
                      <span>VIP</span>
                    </div>
                    <span class="aud-zone-count">—</span>
                  </div>
                  <div class="aud-zone">
                    <div class="aud-zone__left">
                      <span class="aud-zone-dot aud-zone-dot--premium"></span>
                      <span>Premium</span>
                    </div>
                    <span class="aud-zone-count">—</span>
                  </div>
                  <div class="aud-zone">
                    <div class="aud-zone__left">
                      <span class="aud-zone-dot aud-zone-dot--standard"></span>
                      <span>Thường</span>
                    </div>
                    <span class="aud-zone-count" id="audZoneStandard"><c:out value="${selectedRoom.capacity}"/> ghế</span>
                  </div>
                </div>
                <p class="aud-zones-hint">Chi tiết khu vực ghế sẽ hiển thị khi cấu hình layout.</p>
              </section>
            </div>

            <div class="aud-detail__footer">
              <button type="button" class="aud-btn aud-btn--outline aud-btn--block" disabled title="Sắp ra mắt">
                <span class="material-symbols-outlined">calendar_month</span>
                Xem lịch chiếu
              </button>
              <button type="button" class="aud-btn aud-btn--secondary aud-btn--block" disabled title="Sắp ra mắt">
                <span class="material-symbols-outlined">build</span>
                Ghi nhận bảo trì
              </button>
            </div>
          </c:if>

          <c:if test="${empty selectedRoom}">
            <div class="aud-detail__empty">
              <span class="material-symbols-outlined">meeting_room</span>
              <p>Chọn một phòng chiếu để xem chi tiết.</p>
            </div>
          </c:if>
        </div>
      </aside>
    </div>
  </div>
</div>

<script src="${pageContext.request.contextPath}/js/manager-auditoriums.js"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
