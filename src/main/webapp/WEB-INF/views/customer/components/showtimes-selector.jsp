<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>

<%-- PHẦN DƯỚI — Chọn ngày & suất chiếu theo phòng (FR-11). Không chỉnh khi đồng nghiệp làm phần trên. --%>

<c:set var="ctx" value="${pageContext.request.contextPath}"/>

<section class="st-selector" id="showtimes-section">
  <div class="st-panel">
    <h2 class="st-heading">Chọn suất chiếu</h2>

    <%-- Thanh tab 7 ngày --%>
    <div class="st-date-tabs" id="stDateTabs" role="tablist">
      <c:forEach var="dateKey" items="${dateKeys}" varStatus="ds">
        <c:set var="parts" value="${fn:split(dateKey, '-')}"/>
        <button type="button"
                class="st-date-tab${ds.first ? ' st-date-tab--active' : ''}"
                role="tab"
                aria-selected="${ds.first}"
                data-date="<c:out value='${dateKey}'/>"
                id="st-tab-${ds.index}">
          <span class="st-date-tab-label"><c:out value="${dateLabels[ds.index]}"/></span>
          <span class="st-date-tab-day">${parts[2]}</span>
          <span class="st-date-tab-month">Th${parts[1]}</span>
        </button>
      </c:forEach>
    </div>

    <%-- Nội dung theo ngày --%>
    <div class="st-day-panels" id="stDayPanels">
      <c:forEach var="dateKey" items="${dateKeys}" varStatus="ds">
        <c:set var="rooms" value="${showtimeMap[dateKey]}"/>
        <div class="st-day-panel${ds.first ? ' st-day-panel--active' : ''}"
             id="st-panel-${ds.index}"
             data-date="<c:out value='${dateKey}'/>"
             role="tabpanel"
             aria-labelledby="st-tab-${ds.index}"
             <c:if test="${not ds.first}">hidden</c:if>>
          <c:choose>
            <c:when test="${empty rooms}">
              <div class="st-empty">
                <span class="st-empty-icon">🎟</span>
                <p>Không có suất chiếu trong ngày này.</p>
              </div>
            </c:when>
            <c:otherwise>
              <c:forEach var="roomEntry" items="${rooms}">
                <div class="st-room-block">
                  <h3 class="st-room-name">
                    <span class="st-room-icon">🎭</span>
                    <c:out value="${roomEntry.key}"/>
                  </h3>
                  <div class="st-time-chips">
                    <c:forEach var="st" items="${roomEntry.value}">
                      <c:set var="soldOut" value="${st.status == 'SOLD_OUT'}"/>
                      <c:set var="price" value="${st.effectivePrice != null ? st.effectivePrice : st.basePrice}"/>
                      <c:choose>
                        <c:when test="${soldOut}">
                          <span class="st-chip st-chip--disabled" title="Hết vé">
                            <fmt:formatDate value="${st.startTime}" pattern="HH:mm"/>
                            <span class="st-chip-sep">|</span>
                            <fmt:formatNumber value="${price}" pattern="#,##0"/> đ
                          </span>
                        </c:when>
                        <c:otherwise>
                          <a class="st-chip"
                             href="${ctx}/checkout?showtimeId=<c:out value='${st.id}'/>"
                             title="Đặt vé suất <fmt:formatDate value='${st.startTime}' pattern='HH:mm'/>">
                            <fmt:formatDate value="${st.startTime}" pattern="HH:mm"/>
                            <span class="st-chip-sep">|</span>
                            <fmt:formatNumber value="${price}" pattern="#,##0"/> đ
                          </a>
                        </c:otherwise>
                      </c:choose>
                    </c:forEach>
                  </div>
                </div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
      </c:forEach>
    </div>
  </div>
</section>

<script charset="UTF-8" src="${ctx}/js/showtimes-selector.js"></script>
