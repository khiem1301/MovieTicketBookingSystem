<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <meta name="ctx" content="${pageContext.request.contextPath}"/>
  <meta name="bookingId" content="${detail.bookingId}"/>
  <title>In Vé — ÉpCine POS</title>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/main.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/staff.css"/>
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/counter-pos.css"/>
  <%-- FR-18: Thư viện tạo QR code phía client --%>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/qrcodejs/1.0.0/qrcode.min.js"
          integrity="sha512-CNgIRecGo7nphbeZ04Sc13ka07paqdeTu0WR1IM4kNcpmBAUSHSqX2tgqsBNn3k3oYQhK9CoMlLIMb5RYYT2A=="
          crossorigin="anonymous" referrerpolicy="no-referrer"></script>
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

        <%-- Render một ticket preview cho mỗi vé (FR-18) --%>
        <c:choose>
          <c:when test="${not empty detail.tickets}">
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

                <%-- FR-18: QR code được tạo bởi JavaScript --%>
                <div class="ticket-barcode-area">
                  <div class="ticket-qr-placeholder">
                    <div id="qr-${st.index}" class="qr-canvas"
                         data-code="<c:out value='${ticket.qrCode}'/>"></div>
                  </div>
                  <div class="ticket-admit">ADMIT ONE</div>
                </div>
              </div>
              <c:if test="${!st.last}">
                <div style="margin:12px 0; border-top:1px dashed #444;"></div>
              </c:if>
            </c:forEach>
          </c:when>
          <c:otherwise>
            <%-- Fallback: hiển thị như cũ nếu tickets chưa load --%>
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
                <div class="ticket-customer"><c:out value="${detail.customerName}"/></div>
              </div>
              <div class="ticket-barcode-area">
                <div class="ticket-qr-placeholder">
                  <div id="qr-fallback" class="qr-canvas"
                       data-code="<c:out value='${detail.bookingCode}'/>"></div>
                </div>
                <div class="ticket-admit">ADMIT ONE × ${fn:length(detail.seats)}</div>
              </div>
            </div>
          </c:otherwise>
        </c:choose>

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

        <%-- FR-37: Đánh dấu đã in --%>
        <button class="pos-secondary-btn" id="markPrintedBtn" onclick="markPrinted()">
          ✓ Xác nhận đã in xong
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
          <span>Số vé</span>
          <span>
            <c:choose>
              <c:when test="${not empty detail.tickets}">${fn:length(detail.tickets)}</c:when>
              <c:otherwise>${fn:length(detail.seats)}</c:otherwise>
            </c:choose>
            vé
          </span>
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

<%-- Print styles — chỉ in các ticket-preview --%>
<style>
  .qr-canvas canvas, .qr-canvas img { display:block; margin:0 auto; }
  @media print {
    body > *:not(.pos-container) { display: none !important; }
    .print-right, .pos-header    { display: none !important; }
    .print-left  { width: 100% !important; }
    .ticket-preview {
      page-break-after: always;
      background: #fff; color: #000;
      width: 80mm;
    }
  }
</style>

<script>
  const CTX        = document.querySelector('meta[name="ctx"]').content;
  const BOOKING_ID = document.querySelector('meta[name="bookingId"]').content;
  let copies = 1;
  let printed = false;

  // FR-18 — Tạo QR code cho từng vé
  document.querySelectorAll('.qr-canvas[data-code]').forEach(el => {
    const code = el.dataset.code;
    if (!code) return;
    new QRCode(el, {
      text:   code,
      width:  120,
      height: 120,
      colorDark:  '#000000',
      colorLight: '#ffffff',
      correctLevel: QRCode.CorrectLevel.M
    });
  });

  function changeCopies(delta) {
    copies = Math.max(1, Math.min(10, copies + delta));
    document.getElementById('copiesDisplay').textContent = copies;
  }

  function printTickets() {
    window.print();
  }

  // FR-37 — Gọi API đánh dấu vé đã in
  function markPrinted() {
    const btn = document.getElementById('markPrintedBtn');
    btn.disabled = true;
    btn.textContent = 'Đang lưu...';

    fetch(`${CTX}/staff/counter?action=markPrinted`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: 'action=markPrinted&bookingId=' + encodeURIComponent(BOOKING_ID)
    })
    .then(r => r.json())
    .then(data => {
      if (data.ok) {
        btn.textContent = '✓ Đã lưu trạng thái in';
        btn.style.background = '#2e7d32';
        printed = true;
      } else {
        btn.disabled = false;
        btn.textContent = '✓ Xác nhận đã in xong';
        alert('Lỗi cập nhật: ' + (data.error || 'Không xác định'));
      }
    })
    .catch(() => {
      btn.disabled = false;
      btn.textContent = '✓ Xác nhận đã in xong';
      alert('Không thể kết nối máy chủ.');
    });
  }
</script>

</body>
</html>
