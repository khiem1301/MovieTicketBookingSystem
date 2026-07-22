<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%-- Same palette as manager seat types (REGULAR/VIP/COUPLE/SWEETBOX + custom e.g. AA) --%>
<style id="ckSeatTypeColorRules">
<c:forEach var="legend" items="${seatTypeLegend}">
  .ck-seat.ck-seat--available.ck-seat--${legend.typeKey} {
    background: ${legend.color} !important;
    border: 1px solid ${legend.color} !important;
    color: ${legend.textColor} !important;
  }
  .ck-legend-swatch.ck-legend-swatch--type[data-type-key="${legend.typeKey}"] {
    background: ${legend.color} !important;
  }
</c:forEach>
  .ck-seat.ck-seat--available.ck-seat--vip {
    box-shadow: 0 0 10px rgba(255, 215, 0, 0.25);
  }
  .ck-legend-swatch.ck-legend-swatch--type[data-type-key="vip"] {
    box-shadow: 0 0 10px rgba(255, 215, 0, 0.25);
  }
</style>

<section class="ck-map-section" aria-label="Sơ đồ ghế">
  <div class="ck-screen-wrap">
    <div class="ck-screen-glow"></div>
    <div class="ck-screen-bar"></div>
    <span class="ck-screen-label">Màn hình</span>
  </div>

  <div class="ck-seat-scroll">
    <div class="ck-seat-area" id="ckSeatArea">
      <c:choose>
        <c:when test="${empty seatsByRow}">
          <div class="ck-seat-empty">Phòng chưa có ghế nào.</div>
        </c:when>
        <c:otherwise>
          <c:forEach var="rowEntry" items="${seatsByRow}">
            <div class="ck-seat-row">
              <span class="ck-row-label"><c:out value="${rowEntry.key}"/></span>
              <div class="ck-row-cells">
                <c:set var="expectedCol" value="1"/>
                <c:forEach var="seat" items="${rowEntry.value}">
                  <c:if test="${seat.seatColumn > expectedCol}">
                    <c:forEach begin="${expectedCol}" end="${seat.seatColumn - 1}">
                      <span class="ck-seat-gap" aria-hidden="true"></span>
                    </c:forEach>
                  </c:if>
                  <c:set var="typeName" value="${seat.seatTypeName != null ? seat.seatTypeName : 'REGULAR'}"/>
                  <c:set var="typeKey" value="${fn:toLowerCase(typeName)}"/>
                  <c:set var="seatColor" value="${seatTypeColorByKey[typeKey]}"/>
                  <c:set var="seatTextColor" value="${seatTypeTextByKey[typeKey]}"/>
                  <c:choose>
                    <c:when test="${!seat.available}">
                      <button type="button"
                              class="ck-seat ck-seat--sold ck-seat--${typeKey}"
                              data-seat-id="<c:out value='${seat.id}'/>"
                              data-seat-code="<c:out value='${seat.seatCode}'/>"
                              data-price="<c:out value='${seat.ticketPrice}'/>"
                              data-type="<c:out value='${typeName}'/>"
                              data-type-color="<c:out value='${seatColor}'/>"
                              data-type-text="<c:out value='${seatTextColor}'/>"
                              disabled
                              aria-label="Ghế <c:out value='${seat.seatCode}'/> đã được đặt">
                        <span class="ck-seat-num"><c:out value="${seat.seatCode}"/></span>
                      </button>
                    </c:when>
                    <c:when test="${seat.heldByCurrentUser}">
                      <button type="button"
                              class="ck-seat ck-seat--selected ck-seat--held ck-seat--${typeKey}"
                              data-seat-id="<c:out value='${seat.id}'/>"
                              data-seat-code="<c:out value='${seat.seatCode}'/>"
                              data-price="<c:out value='${seat.ticketPrice}'/>"
                              data-type="<c:out value='${typeName}'/>"
                              data-type-color="<c:out value='${seatColor}'/>"
                              data-type-text="<c:out value='${seatTextColor}'/>"
                              data-held="true"
                              aria-label="Ghế <c:out value='${seat.seatCode}'/> đang được giữ">
                        <span class="ck-seat-num"><c:out value="${seat.seatCode}"/></span>
                      </button>
                    </c:when>
                    <c:otherwise>
                      <button type="button"
                              class="ck-seat ck-seat--available ck-seat--${typeKey}"
                              data-seat-id="<c:out value='${seat.id}'/>"
                              data-seat-code="<c:out value='${seat.seatCode}'/>"
                              data-price="<c:out value='${seat.ticketPrice}'/>"
                              data-type="<c:out value='${typeName}'/>"
                              data-type-color="<c:out value='${seatColor}'/>"
                              data-type-text="<c:out value='${seatTextColor}'/>"
                              style="background:<c:out value='${seatColor}'/>;border-color:<c:out value='${seatColor}'/>;color:<c:out value='${seatTextColor}'/>"
                              <c:if test="${readOnly}">disabled</c:if>
                              aria-label="Ghế <c:out value='${seat.seatCode}'/>">
                        <span class="ck-seat-num"><c:out value="${seat.seatCode}"/></span>
                      </button>
                    </c:otherwise>
                  </c:choose>
                  <c:set var="expectedCol" value="${seat.seatColumn + 1}"/>
                </c:forEach>
              </div>
              <span class="ck-row-label"><c:out value="${rowEntry.key}"/></span>
            </div>
          </c:forEach>
        </c:otherwise>
      </c:choose>
    </div>
  </div>

  <div class="ck-legend">
    <div class="ck-legend-item">
      <span class="ck-legend-swatch ck-legend-swatch--available"></span>
      <span>Còn trống</span>
    </div>
    <div class="ck-legend-item">
      <span class="ck-legend-swatch ck-legend-swatch--selected"></span>
      <span>Đang chọn</span>
    </div>
    <div class="ck-legend-item">
      <span class="ck-legend-swatch ck-legend-swatch--sold"></span>
      <span>Đã đặt</span>
    </div>
    <c:forEach var="legend" items="${seatTypeLegend}">
      <div class="ck-legend-item">
        <span class="ck-legend-swatch ck-legend-swatch--type"
              data-type-key="<c:out value='${legend.typeKey}'/>"
              style="background:<c:out value='${legend.color}'/>"></span>
        <span>
          <c:out value="${legend.typeName}"/>
          <c:if test="${legend.samplePrice != null}">
            (<fmt:formatNumber value="${legend.samplePrice}" pattern="#,##0"/> đ)
          </c:if>
        </span>
      </div>
    </c:forEach>
  </div>
</section>
