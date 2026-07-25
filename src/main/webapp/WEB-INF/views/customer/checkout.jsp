<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Chọn ghế — ${showtime.movieTitle} | ÉPCINE"/>
<c:set var="extraCss" value="customer-checkout"/>
<%-- Cache-bust theo request: tránh 1 trình duyệt giữ CSS/JS cũ dù Ctrl+F5 --%>
<c:set var="assetV" value="<%= Long.toString(System.currentTimeMillis()) %>"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="ck-page"
     data-ctx="${ctx}"
     data-showtime-id="<c:out value='${showtime.id}'/>"
     data-read-only="${readOnly ? 'true' : 'false'}"
     data-pending-booking="${not empty pendingBookingId ? 'true' : 'false'}"
     <c:if test="${not empty holdExpiresAt}">data-hold-expires="<c:out value='${holdExpiresAt}'/>"</c:if>>
  <jsp:include page="components/checkout-header.jsp"/>

  <c:if test="${not empty errorMessage}">
    <div class="ck-alert ck-alert--error container">
      <c:out value="${errorMessage}"/>
    </div>
  </c:if>

  <c:if test="${not empty infoMessage}">
    <div class="ck-alert ck-alert--info container">
      <c:out value="${infoMessage}"/>
    </div>
  </c:if>

  <c:if test="${soldOut}">
    <div class="ck-alert ck-alert--warn container" data-flash-persist="true">
      Suất chiếu này đã hết vé. Bạn không thể chọn ghế.
    </div>
  </c:if>

  <div class="ck-layout container">
    <jsp:include page="components/seat-map.jsp"/>
    <jsp:include page="components/booking-summary.jsp"/>
  </div>
</div>

<script charset="UTF-8" src="${ctx}/js/seat-type-colors.js?v=${assetV}"></script>
<script charset="UTF-8" src="${ctx}/js/customer-checkout.js?v=${assetV}"></script>
<script>
  // Sau khi load checkout.js: ép lại contrast (phòng JS cache lệch trình duyệt)
  if (typeof window.ckForceSeatLabelContrast === 'function') {
    window.ckForceSeatLabelContrast(document);
  }
</script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
