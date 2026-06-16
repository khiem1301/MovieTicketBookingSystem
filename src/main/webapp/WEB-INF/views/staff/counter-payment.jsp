<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Thanh Toán — ÉpCine POS</title>
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
      <span class="pos-title">Thanh Toán</span>
    </div>
    <div class="pos-header-right">
      <span class="pos-staff-name">
        Nhân viên: <strong><c:out value="${sessionScope.loggedUser.fullName}"/></strong>
      </span>
      <span class="pos-offline-badge">&#9679; OFFLINE</span>
    </div>
  </div>

  <c:if test="${not empty errorMessage}">
    <div class="pos-alert pos-alert--error"><c:out value="${errorMessage}"/></div>
  </c:if>

  <%-- Payment layout: 2 cột --%>
  <div class="payment-layout">

    <%-- ═══════════════════════════════
         TRÁI: Chi tiết đơn hàng
         ═══════════════════════════════ --%>
    <div class="payment-left">
      <div class="payment-card">
        <div class="payment-card-header">
          <span class="payment-section-title">Chi tiết đơn hàng</span>
          <span class="payment-offline-tag">OFFLINE WALK-IN</span>
        </div>

        <div class="payment-ref">
          Mã đơn: <strong><c:out value="${detail.bookingCode}"/></strong>
        </div>

        <%-- Thông tin phim --%>
        <div class="payment-movie-row">
          <div class="payment-movie-poster">
            <c:choose>
              <c:when test="${not empty detail.moviePosterUrl}">
                <img src="<c:out value='${detail.moviePosterUrl}'/>"
                     alt="poster"
                     onerror="this.style.display='none'"/>
              </c:when>
              <c:otherwise>
                <div class="poster-fallback">🎬</div>
              </c:otherwise>
            </c:choose>
          </div>
          <div class="payment-movie-info">
            <div class="payment-movie-title"><c:out value="${detail.movieTitle}"/></div>
            <div class="payment-movie-meta">
              <fmt:formatDate value="${detail.startTime}" pattern="dd/MM/yyyy HH:mm"/>
            </div>
            <div class="payment-movie-meta">Phòng: <c:out value="${detail.roomName}"/></div>
            <div class="payment-movie-meta">
              KH: <c:out value="${detail.customerName}"/>
              (<c:out value="${detail.customerPhone}"/>)
            </div>
          </div>
        </div>

        <%-- Danh sách vé --%>
        <div class="payment-items">
          <c:forEach var="seat" items="${detail.seats}">
            <div class="payment-item-row">
              <span>Vé <c:out value="${seat.seatType}"/> — Ghế <c:out value="${seat.seatCode}"/></span>
              <span>
                <fmt:formatNumber value="${seat.price}" type="number" groupingUsed="true"/> ₫
              </span>
            </div>
          </c:forEach>
          <div class="payment-item-row payment-item-row--total">
            <span>Tổng cộng</span>
            <span>
              <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
            </span>
          </div>
        </div>

        <%-- Phương thức thanh toán --%>
        <div class="payment-method-section">
          <div class="payment-section-title">Phương thức thanh toán</div>
          <div class="payment-method-tabs">
            <button class="pay-method-btn pay-method-btn--active" id="btnCash"
                    onclick="setPayMethod('CASH')">
              💵 Tiền mặt
            </button>
            <button class="pay-method-btn" id="btnCard"
                    onclick="setPayMethod('CARD')">
              💳 Thẻ / Chuyển khoản
            </button>
          </div>
        </div>

      </div>
    </div><%-- /payment-left --%>

    <%-- ═══════════════════════════════
         PHẢI: Nhập tiền + numpad
         ═══════════════════════════════ --%>
    <div class="payment-right">
      <div class="payment-card">

        <div class="payment-offline-booking-badge">OFFLINE BOOKING</div>

        <div class="numpad-total-section">
          <div class="numpad-total-label">Tổng cần thanh toán</div>
          <div class="numpad-total-amount" id="totalDue">
            <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
          </div>
        </div>

        <%-- Tiền nhận (chỉ hiện khi chọn tiền mặt) --%>
        <div id="cashSection">
          <div class="numpad-received-row">
            <div>
              <div class="numpad-label">Tiền nhận</div>
              <div class="numpad-received-display" id="receivedDisplay">0 ₫</div>
            </div>
            <div>
              <div class="numpad-label">Tiền thừa</div>
              <div class="numpad-change-display" id="changeDisplay">0 ₫</div>
            </div>
          </div>

          <%-- Quick amount buttons --%>
          <div class="numpad-quick-row">
            <button class="numpad-quick-btn" onclick="setExact()">Vừa đủ</button>
            <button class="numpad-quick-btn" onclick="addAmount(50000)">+50K</button>
            <button class="numpad-quick-btn" onclick="addAmount(100000)">+100K</button>
            <button class="numpad-quick-btn" onclick="addAmount(200000)">+200K</button>
            <button class="numpad-quick-btn" onclick="addAmount(500000)">+500K</button>
          </div>

          <%-- Numpad --%>
          <div class="numpad-grid">
            <button class="numpad-btn" onclick="numpadPress('1')">1</button>
            <button class="numpad-btn" onclick="numpadPress('2')">2</button>
            <button class="numpad-btn" onclick="numpadPress('3')">3</button>
            <button class="numpad-btn" onclick="numpadPress('4')">4</button>
            <button class="numpad-btn" onclick="numpadPress('5')">5</button>
            <button class="numpad-btn" onclick="numpadPress('6')">6</button>
            <button class="numpad-btn" onclick="numpadPress('7')">7</button>
            <button class="numpad-btn" onclick="numpadPress('8')">8</button>
            <button class="numpad-btn" onclick="numpadPress('9')">9</button>
            <button class="numpad-btn" onclick="numpadPress('000')">000</button>
            <button class="numpad-btn" onclick="numpadPress('0')">0</button>
            <button class="numpad-btn numpad-btn--del" onclick="numpadDel()">⌫</button>
          </div>
        </div>

        <%-- Nút xác nhận thanh toán --%>
        <form method="post" id="paymentForm"
              action="${pageContext.request.contextPath}/staff/counter?action=payment">
          <input type="hidden" name="bookingId"     value="${detail.bookingId}"/>
          <input type="hidden" name="paymentMethod" id="hiddenPayMethod"  value="CASH"/>
          <input type="hidden" name="cashReceived"  id="hiddenCashRecv"   value="0"/>
          <input type="hidden" name="changeAmount"  id="hiddenChangAmt"   value="0"/>
          <button type="button" class="pos-proceed-btn pos-proceed-btn--green"
                  id="markSuccessBtn" onclick="submitPayment()">
            ✓ Xác nhận thanh toán thành công
          </button>
        </form>

        <div style="margin-top:12px; text-align:center;">
          <a href="${pageContext.request.contextPath}/staff/counter?step=payment&bookingId=${detail.bookingId}"
             class="pos-link-btn">← Quay lại</a>
          &nbsp;|&nbsp;
          <a href="${pageContext.request.contextPath}/staff/counter"
             class="pos-link-btn">Tạo đơn mới</a>
        </div>

      </div>
    </div><%-- /payment-right --%>

  </div><%-- /payment-layout --%>
</div><%-- /pos-container --%>

<script>
  const TOTAL_DUE = <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="false"/>;
  let receivedRaw = '';
  let payMethod   = 'CASH';

  function setPayMethod(method) {
    payMethod = method;
    document.getElementById('btnCash').classList.toggle('pay-method-btn--active', method === 'CASH');
    document.getElementById('btnCard').classList.toggle('pay-method-btn--active', method === 'CARD');
    document.getElementById('cashSection').style.display = (method === 'CASH') ? 'block' : 'none';
  }

  function numpadPress(digit) {
    if (receivedRaw.length >= 12) return;
    receivedRaw += digit;
    updateCashDisplay();
  }

  function numpadDel() {
    receivedRaw = receivedRaw.slice(0, -1);
    updateCashDisplay();
  }

  function setExact() {
    receivedRaw = String(TOTAL_DUE);
    updateCashDisplay();
  }

  function addAmount(val) {
    const current = parseInt(receivedRaw || '0', 10);
    receivedRaw = String(current + val);
    updateCashDisplay();
  }

  function updateCashDisplay() {
    const received = parseInt(receivedRaw || '0', 10);
    const change   = received - TOTAL_DUE;
    document.getElementById('receivedDisplay').textContent = formatVnd(received);
    const changeEl = document.getElementById('changeDisplay');
    changeEl.textContent  = change >= 0 ? formatVnd(change) : '—';
    changeEl.style.color  = change >= 0 ? '#4fc3f7' : '#ef5350';
  }

  function submitPayment() {
    const received = parseInt(receivedRaw || '0', 10);
    const change   = Math.max(0, received - TOTAL_DUE);

    if (payMethod === 'CASH' && received < TOTAL_DUE) {
      alert('Tiền nhận chưa đủ. Vui lòng nhập đúng số tiền.');
      return;
    }

    document.getElementById('hiddenPayMethod').value = payMethod;
    document.getElementById('hiddenCashRecv').value  = payMethod === 'CASH' ? received : 0;
    document.getElementById('hiddenChangAmt').value  = payMethod === 'CASH' ? change   : 0;
    document.getElementById('paymentForm').submit();
  }

  function formatVnd(n) {
    return new Intl.NumberFormat('vi-VN').format(n) + ' ₫';
  }
</script>
</body>
</html>
