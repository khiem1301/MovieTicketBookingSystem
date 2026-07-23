<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Vé điện tử — ÉPCINE"/>
<c:set var="extraCss"  value="counter-pos"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"
        integrity="sha512-CNgIRecGo7nphbeZ04Sc13ka07paqdeTu0WR1IM4kNcpmBAUSHSqX2tgqsBNn3k3oYQhK9CoMlLIMb5RYYT2A=="
        crossorigin="anonymous" referrerpolicy="no-referrer"></script>

<div class="e-ticket-page">
  <p class="e-ticket-hint">Xuất trình các vé bên dưới khi vào rạp</p>
  <p class="e-ticket-booking">
    Mã đơn <strong><c:out value="${detail.bookingCode}"/></strong>
    · ${fn:length(detail.tickets)} vé
  </p>

  <c:forEach var="ticket" items="${detail.tickets}" varStatus="st">
    <div class="ticket-preview" id="ticket-${st.index}">
      <div class="ticket-header">
        <div class="ticket-cinema">ÉPCINE PREMIUM</div>
        <div class="ticket-ref"><c:out value="${ticket.ticketCode}"/></div>
      </div>
      <div class="ticket-divider-dots"></div>
      <div class="ticket-movie-title"><c:out value="${detail.movieTitle}"/></div>

      <div class="ticket-info-grid">
        <div class="ticket-info-item">
          <div class="ticket-info-label">NGÀY</div>
          <div class="ticket-info-val">
            <fmt:formatDate value="${detail.startTime}" pattern="EEE, dd/MM"/>
          </div>
        </div>
        <div class="ticket-info-item">
          <div class="ticket-info-label">GIỜ</div>
          <div class="ticket-info-val ticket-info-val--accent">
            <fmt:formatDate value="${detail.startTime}" pattern="HH:mm"/>
          </div>
        </div>
        <div class="ticket-info-item">
          <div class="ticket-info-label">PHÒNG</div>
          <div class="ticket-info-val"><c:out value="${detail.roomName}"/></div>
        </div>
      </div>

      <div class="ticket-divider-dots"></div>

      <div class="ticket-seats-section">
        <div class="ticket-info-label">GHẾ</div>
        <div class="ticket-seats-list">
          <span class="ticket-seat-code"><c:out value="${ticket.seatCode}"/></span>
        </div>
        <div class="ticket-customer">
          <c:out value="${detail.customerName}"/>
        </div>
      </div>

      <div class="ticket-barcode-area">
        <div class="ticket-qr-placeholder">
          <div id="qr-${st.index}" class="qr-canvas"
               data-code="<c:out value='${ticket.qrCode}'/>"></div>
        </div>
        <div class="ticket-admit">ADMIT ONE</div>
      </div>
    </div>
    <c:if test="${!st.last}">
      <div class="e-ticket-sep"></div>
    </c:if>
  </c:forEach>

  <p class="e-ticket-meta">
    Trạng thái: <strong>ĐÃ THANH TOÁN</strong>
  </p>
</div>

<style>
  .e-ticket-page {
    max-width: 440px;
    margin: 24px auto 48px;
    padding: 0 16px;
  }
  .e-ticket-hint {
    text-align: center;
    color: #aaa;
    font-size: 14px;
    margin-bottom: 8px;
  }
  .e-ticket-booking {
    text-align: center;
    color: #ccc;
    font-size: 13px;
    margin-bottom: 20px;
  }
  .e-ticket-booking strong { color: #ffb4aa; }
  .e-ticket-sep {
    margin: 14px 0;
    border-top: 1px dashed #444;
  }
  .e-ticket-meta {
    text-align: center;
    color: #888;
    font-size: 13px;
    margin-top: 16px;
  }
  .e-ticket-meta strong { color: #4caf50; }
  .qr-canvas canvas, .qr-canvas img { display: block; margin: 0 auto; }
  @media print {
    .site-header, .site-footer, .e-ticket-hint, .e-ticket-booking, .e-ticket-meta, .e-ticket-sep {
      display: none !important;
    }
    .ticket-preview {
      page-break-after: always;
      background: #fff !important;
      color: #000 !important;
      border-color: #ccc !important;
      width: 80mm;
    }
    .ticket-movie-title, .ticket-info-val, .ticket-seats-list { color: #000 !important; }
    .ticket-cinema, .ticket-admit, .ticket-info-val--accent { color: #c62828 !important; }
  }
</style>

<script>
  document.querySelectorAll('.qr-canvas[data-code]').forEach(el => {
    const code = el.dataset.code;
    if (!code) return;
    new QRCode(el, {
      text: code,
      width: 120,
      height: 120,
      colorDark: '#000000',
      colorLight: '#ffffff',
      correctLevel: QRCode.CorrectLevel.M
    });
  });
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
