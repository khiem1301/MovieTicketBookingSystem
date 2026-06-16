<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Chọn ghế — ${showtime.movieTitle} | ÉPCINE"/>
<c:set var="extraCss" value="customer-checkout"/>
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
    <div class="ck-alert ck-alert--warn container">
      Suất chiếu này đã hết vé. Bạn không thể chọn ghế.
    </div>
  </c:if>

  <div class="ck-layout container">
    <jsp:include page="components/seat-map.jsp"/>
    <jsp:include page="components/booking-summary.jsp"/>
  </div>
</div>

<script charset="UTF-8" src="${ctx}/js/seat-type-colors.js"></script>
<script charset="UTF-8" src="${ctx}/js/customer-checkout.js"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
