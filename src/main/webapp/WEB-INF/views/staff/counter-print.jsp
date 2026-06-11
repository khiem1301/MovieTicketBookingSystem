<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>In Vé — ÉpCine POS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/staff.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/counter-pos.css"/>
</head>
<body class="pos-body">

<div class="pos-container">

  <%-- Header --%>
  <div class="pos-header">
    <div class="pos-header-left">
      <a href="${pageContext.request.contextPath}/staff/counter" class="pos-logo">
        <img src="${pageContext.request.contextPath}/images/logorapchieuphim.png"
             alt="ÉpCine" class="pos-logo-img"
             onerror="this.style.display='none';this.nextElementSibling.style.display='inline'"/>
        <span class="pos-logo-fallback" style="display:none">ÉpCine</span>
      </a>
      <span class="pos-title">In Vé</span>
    </div>
    <div class="pos-header-right">
      <span class="pos-staff-name">
        Nhân viên: <strong><c:out value="${sessionScope.loggedUser.fullName}"/></strong>
      </span>
      <span class="pos-offline-badge">&#9679; OFFLINE</span>
    </div>
  </div>

  <div class="print-layout">

    <%-- ═══════════════════════════════
         TRÁI: Xem trước vé
         ═══════════════════════════════ --%>
    <div class="print-left">
      <div class="payment-card">
        <div class="payment-section-title" style="margin-bottom:16px">Xem trước vé</div>

        <%-- Visual ticket preview --%>
        <div class="ticket-preview" id="ticketPreview">
          <div class="ticket-header">
            <div class="ticket-cinema">ÉPCINE PREMIUM</div>
            <div class="ticket-ref"><c:out value="${detail.bookingCode}"/></div>
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
              <c:forEach var="seat" items="${detail.seats}" varStatus="st">
                <span class="ticket-seat-code">
                  <c:out value="${seat.seatCode}"/>
                  <c:if test="${!st.last}">, </c:if>
                </span>
              </c:forEach>
            </div>
            <div class="ticket-customer">
              <c:out value="${detail.customerName}"/>
            </div>
          </div>

          <div class="ticket-barcode-area">
            <div class="ticket-qr-placeholder">
              <div class="qr-mock"></div>
            </div>
            <div class="ticket-admit">ADMIT ONE × ${fn:length(detail.seats)}</div>
          </div>
        </div>

        <p style="text-align:center;font-size:12px;color:#888;margin-top:8px">
          Vé thực tế sẽ in trên giấy nhiệt 80mm
        </p>
      </div>
    </div>

    <%-- ═══════════════════════════════
         PHẢI: Cài đặt in
         ═══════════════════════════════ --%>
    <div class="print-right">
      <div class="payment-card">

        <div class="print-status-row">
          <div class="print-printer-status">
            <span class="print-dot-green">&#9679;</span> Máy in: Kết nối
          </div>
          <span class="pos-offline-badge">OFFLINE</span>
        </div>

        <div class="payment-section-title" style="margin-top:12px">Cài đặt in</div>

        <%-- Số bản in --%>
        <div class="print-setting-row">
          <span class="print-setting-label">Số bản in</span>
          <div class="print-copies-ctrl">
            <button class="copies-btn" onclick="changeCopies(-1)">−</button>
            <span id="copiesDisplay">1</span>
            <button class="copies-btn" onclick="changeCopies(1)">+</button>
          </div>
        </div>

        <%-- Loại in --%>
        <div class="print-setting-row">
          <span class="print-setting-label">Loại giấy</span>
        </div>
        <label class="print-radio-row">
          <input type="radio" name="outputType" value="thermal" checked/>
          <div>
            <div class="print-radio-title">Giấy nhiệt (80mm)</div>
            <div class="print-radio-sub">Cuộn giấy nhiệt tiêu chuẩn</div>
          </div>
        </label>
        <label class="print-radio-row">
          <input type="radio" name="outputType" value="card"/>
          <div>
            <div class="print-radio-title">Thẻ lưu niệm</div>
            <div class="print-radio-sub">Giấy dày cao cấp</div>
          </div>
        </label>

        <%-- Include receipt --%>
        <label class="print-check-row">
          <input type="checkbox" id="includeReceipt" checked/>
          <span>In kèm biên lai thanh toán</span>
        </label>

        <%-- Action buttons --%>
        <button class="pos-proceed-btn" style="margin-top:20px" onclick="printTickets()">
          🖨 In vé
        </button>
        <button class="pos-secondary-btn" onclick="window.print()">
          🔁 In lại lần cuối
        </button>

        <div style="margin-top:16px; text-align:center;">
          <a href="${pageContext.request.contextPath}/staff/counter"
             class="pos-link-btn">✚ Tạo đơn mới</a>
        </div>

      </div>

      <%-- Tóm tắt xác nhận --%>
      <div class="payment-card" style="margin-top:16px">
        <div class="confirm-success-icon">✓</div>
        <div class="confirm-success-text">Đặt vé thành công!</div>
        <div class="confirm-detail-row">
          <span>Mã đơn</span>
          <strong><c:out value="${detail.bookingCode}"/></strong>
        </div>
        <div class="confirm-detail-row">
          <span>Khách hàng</span>
          <span><c:out value="${detail.customerName}"/></span>
        </div>
        <div class="confirm-detail-row">
          <span>Trạng thái</span>
          <span class="badge-confirmed">ĐÃ THANH TOÁN</span>
        </div>
        <div class="confirm-detail-row">
          <span>Tổng tiền</span>
          <strong>
            <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
          </strong>
        </div>
      </div>

    </div><%-- /print-right --%>
  </div><%-- /print-layout --%>
</div>

<%-- Print styles --%>
<style>
  @media print {
    body > *:not(#ticketPreview) { display: none !important; }
    #ticketPreview {
      position: fixed; top: 0; left: 0;
      width: 80mm; background: #fff; color: #000;
    }
  }
</style>

<script>
  let copies = 1;
  function changeCopies(delta) {
    copies = Math.max(1, Math.min(10, copies + delta));
    document.getElementById('copiesDisplay').textContent = copies;
  }
  function printTickets() {
    window.print();
  }
</script>

</body>
</html>
