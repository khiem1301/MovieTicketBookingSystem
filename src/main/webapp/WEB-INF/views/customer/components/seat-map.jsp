<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<%-- Palette + contrast: luôn !important (kể cả -webkit-text-fill) để thắng button{color:inherit} --%>
<style id="ckSeatTypeColorRules">
<c:forEach var="legend" items="${seatTypeLegend}">
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--${legend.typeKey} {
    background: ${legend.color} !important;
    border: 1px solid ${legend.color} !important;
    color: ${legend.textColor} !important;
    -webkit-text-fill-color: ${legend.textColor} !important;
  }
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--${legend.typeKey} .ck-seat-code {
    color: ${legend.textColor} !important;
    -webkit-text-fill-color: ${legend.textColor} !important;
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
  /* Fallback cứng: ghế sáng (regular/vip) luôn chữ tối */
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--regular,
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--standard,
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--vip,
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--regular .ck-seat-code,
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--standard .ck-seat-code,
  .ck-seat-area button.ck-seat.ck-seat--available.ck-seat--vip .ck-seat-code {
    color: #1a1a1a !important;
    -webkit-text-fill-color: #1a1a1a !important;
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
                  <%-- Khớp SeatTypeColorUtil.normalizeType / staff POS --%>
                  <c:set var="typeKey" value="${fn:toLowerCase(fn:trim(typeName))}"/>
                  <c:if test="${typeKey == 'standard'}">
                    <c:set var="typeKey" value="regular"/>
                  </c:if>
                  <c:set var="seatColor" value="${seatTypeColorByKey[typeKey]}"/>
                  <c:set var="seatTextColor" value="${seatTypeTextByKey[typeKey]}"/>
                  <c:if test="${empty seatColor}">
                    <c:choose>
                      <c:when test="${typeKey == 'vip'}"><c:set var="seatColor" value="#ffd700"/></c:when>
                      <c:when test="${typeKey == 'couple'}"><c:set var="seatColor" value="#ff4d94"/></c:when>
                      <c:when test="${typeKey == 'sweetbox'}"><c:set var="seatColor" value="#0072d7"/></c:when>
                      <c:otherwise><c:set var="seatColor" value="#cccccc"/></c:otherwise>
                    </c:choose>
                  </c:if>
                  <%-- Ghế sáng (regular/vip) luôn chữ tối — không phụ thuộc map/JS --%>
                  <c:choose>
                    <c:when test="${typeKey == 'couple' || typeKey == 'sweetbox'}">
                      <c:set var="seatTextColor" value="#ffffff"/>
                    </c:when>
                    <c:when test="${typeKey == 'regular' || typeKey == 'standard' || typeKey == 'vip' || empty seatTextColor}">
                      <c:set var="seatTextColor" value="#1a1a1a"/>
                    </c:when>
                  </c:choose>
                  <c:choose>
                    <c:when test="${!seat.available}">
                      <button type="button"
                              class="ck-seat ck-seat--sold ck-seat--${typeKey}"
                              data-seat-id="<c:out value='${seat.id}'/>"
                              data-seat-code="<c:out value='${seat.seatCode}'/>"
                              data-price="<c:out value='${seat.ticketPrice}'/>"
                              data-type="<c:out value='${typeKey}'/>"
                              data-type-color="<c:out value='${seatColor}'/>"
                              data-type-text="<c:out value='${seatTextColor}'/>"
                              disabled
                              aria-label="Ghế <c:out value='${seat.seatCode}'/> đã được đặt"><span class="ck-seat-code"><c:out value="${seat.seatCode}"/></span></button>
                    </c:when>
                    <c:when test="${seat.heldByCurrentUser}">
                      <button type="button"
                              class="ck-seat ck-seat--selected ck-seat--held ck-seat--${typeKey}"
                              data-seat-id="<c:out value='${seat.id}'/>"
                              data-seat-code="<c:out value='${seat.seatCode}'/>"
                              data-price="<c:out value='${seat.ticketPrice}'/>"
                              data-type="<c:out value='${typeKey}'/>"
                              data-type-color="<c:out value='${seatColor}'/>"
                              data-type-text="<c:out value='${seatTextColor}'/>"
                              data-held="true"
                              aria-label="Ghế <c:out value='${seat.seatCode}'/> đang được giữ"><span class="ck-seat-code"><c:out value="${seat.seatCode}"/></span></button>
                    </c:when>
                    <c:otherwise>
                      <button type="button"
                              class="ck-seat ck-seat--available ck-seat--${typeKey}"
                              data-seat-id="<c:out value='${seat.id}'/>"
                              data-seat-code="<c:out value='${seat.seatCode}'/>"
                              data-price="<c:out value='${seat.ticketPrice}'/>"
                              data-type="<c:out value='${typeKey}'/>"
                              data-type-color="<c:out value='${seatColor}'/>"
                              data-type-text="<c:out value='${seatTextColor}'/>"
                              style="background:<c:out value='${seatColor}'/> !important;border-color:<c:out value='${seatColor}'/> !important;color:<c:out value='${seatTextColor}'/> !important;-webkit-text-fill-color:<c:out value='${seatTextColor}'/> !important"
                              <c:if test="${readOnly}">disabled</c:if>
                              aria-label="Ghế <c:out value='${seat.seatCode}'/>"><span class="ck-seat-code" style="color:<c:out value='${seatTextColor}'/> !important;-webkit-text-fill-color:<c:out value='${seatTextColor}'/> !important"><c:out value="${seat.seatCode}"/></span></button>
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

<%-- Inline: không phụ thuộc CSS/JS cache của trình duyệt --%>
<script>
(function () {
  function forceSeatLabelContrast(root) {
    var scope = root || document;
    scope.querySelectorAll('.ck-seat.ck-seat--available[data-type]').forEach(function (btn) {
      var key = String(btn.getAttribute('data-type') || 'regular').toLowerCase().trim();
      var bg = (btn.getAttribute('data-type-color') || '').trim();
      var text = '#1a1a1a';
      if (key === 'couple' || key === 'sweetbox') text = '#ffffff';
      if (!bg) {
        if (key === 'vip') bg = '#ffd700';
        else if (key === 'couple') bg = '#ff4d94';
        else if (key === 'sweetbox') bg = '#0072d7';
        else bg = '#cccccc';
      }
      btn.style.setProperty('background', bg, 'important');
      btn.style.setProperty('background-color', bg, 'important');
      btn.style.setProperty('border-color', bg, 'important');
      btn.style.setProperty('color', text, 'important');
      btn.style.setProperty('-webkit-text-fill-color', text, 'important');
      var code = btn.querySelector('.ck-seat-code');
      if (code) {
        code.style.setProperty('color', text, 'important');
        code.style.setProperty('-webkit-text-fill-color', text, 'important');
      }
    });
  }
  forceSeatLabelContrast(document);
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { forceSeatLabelContrast(document); });
  }
  window.addEventListener('load', function () { forceSeatLabelContrast(document); });
  // Chạy lại sau script checkout (có thể bị cache cũ) để ghi đè màu sai
  setTimeout(function () { forceSeatLabelContrast(document); }, 0);
  setTimeout(function () { forceSeatLabelContrast(document); }, 300);
  window.ckForceSeatLabelContrast = forceSeatLabelContrast;
})();
</script>
