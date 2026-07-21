<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Thanh Toán — ÉpCine POS"/>
<c:set var="extraCss"  value="staff"/>
<c:set var="extraCss2" value="counter-pos"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<script>document.body.classList.add('pos-body');</script>

<div class="pos-container">

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
                <c:choose>
                  <c:when test="${fn:startsWith(detail.moviePosterUrl, 'http://') or fn:startsWith(detail.moviePosterUrl, 'https://')}">
                    <c:set var="posterSrc" value="${detail.moviePosterUrl}"/>
                  </c:when>
                  <c:otherwise>
                    <c:set var="posterSrc" value="${pageContext.request.contextPath}/${detail.moviePosterUrl}"/>
                  </c:otherwise>
                </c:choose>
                <img src="<c:out value='${posterSrc}'/>"
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
            <button class="pay-method-btn <c:if test="${not vietqrActive}">pay-method-btn--active</c:if>"
                    id="btnCash" onclick="setPayMethod('CASH')">
              💵 Tiền mặt
            </button>
            <button class="pay-method-btn <c:if test="${vietqrActive}">pay-method-btn--active</c:if>"
                    id="btnVietqr" onclick="setPayMethod('VIETQR')">
              📱 Chuyển khoản
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

        <%-- VietQR / Chuyển khoản --%>
        <div id="vietqrSection" style="display:<c:choose><c:when test="${vietqrActive}">block</c:when><c:otherwise>none</c:otherwise></c:choose>">
          <c:choose>
            <c:when test="${vietqrActive}">
              <div class="vietqr-qr-block">
                <div style="text-align:center;margin-bottom:10px">
                  <img src="<c:out value='${vietqrQrUrl}'/>" alt="Mã QR VietQR"
                       style="width:200px;height:200px;border-radius:8px;border:2px solid #444"/>
                </div>
                <div class="vietqr-bank-info">
                  <div class="vietqr-bank-row">
                    <span class="vietqr-bank-label">Ngân hàng</span>
                    <span class="vietqr-bank-val"><c:out value="${vietqrBankName}"/></span>
                  </div>
                  <div class="vietqr-bank-row">
                    <span class="vietqr-bank-label">Số tài khoản</span>
                    <strong class="vietqr-bank-val"><c:out value="${vietqrAccountNo}"/></strong>
                  </div>
                  <div class="vietqr-bank-row">
                    <span class="vietqr-bank-label">Chủ tài khoản</span>
                    <span class="vietqr-bank-val"><c:out value="${vietqrAccountName}"/></span>
                  </div>
                  <div class="vietqr-bank-row vietqr-bank-row--hl">
                    <span class="vietqr-bank-label">Nội dung CK</span>
                    <strong class="vietqr-bank-val"><c:out value="${vietqrTransferContent}"/></strong>
                  </div>
                  <div class="vietqr-bank-row vietqr-bank-row--hl">
                    <span class="vietqr-bank-label">Số tiền</span>
                    <strong class="vietqr-bank-val">
                      <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
                    </strong>
                  </div>
                </div>
                <c:choose>
                  <c:when test="${sepayEnabled}">
                    <div class="pay-momo-wait-note" id="vietqrWaitBox"
                         data-vietqr-waiting="true"
                         data-booking-id="<c:out value='${detail.bookingId}'/>"
                         data-ctx="${pageContext.request.contextPath}"
                         style="margin-top:12px;padding:10px 12px;background:#1a1a2e;border:1px solid rgba(255,255,255,0.12);border-radius:8px;font-size:13px;color:#b0b0c0">
                      ℹ SePay tự xác nhận khi tiền vào — trang sẽ tự chuyển.
                      <span id="vietqrWaitMsg" style="display:block;margin-top:4px;color:#90caf9">
                        Đang chờ xác nhận...
                      </span>
                    </div>
                    <form method="post"
                          action="${pageContext.request.contextPath}/staff/counter?action=confirmVietQR"
                          style="margin-top:8px;text-align:center">
                      <input type="hidden" name="bookingId" value="${detail.bookingId}"/>
                      <button type="submit" class="pos-link-btn"
                              style="border:1px solid rgba(255,255,255,0.2);border-radius:6px;padding:8px 16px">
                        Xác nhận thủ công (nếu SePay chậm)
                      </button>
                    </form>
                  </c:when>
                  <c:otherwise>
                    <p style="font-size:12px;color:#aaa;margin-top:8px;text-align:center">
                      Hướng màn hình QR về phía khách → khách quét app ngân hàng → tiền vào thì bấm nút bên dưới.
                    </p>
                    <form method="post"
                          action="${pageContext.request.contextPath}/staff/counter?action=confirmVietQR"
                          style="margin-top:8px">
                      <input type="hidden" name="bookingId" value="${detail.bookingId}"/>
                      <button type="submit" class="pos-proceed-btn pos-proceed-btn--green">
                        ✓ Tiền đã vào — tiếp tục in vé
                      </button>
                    </form>
                  </c:otherwise>
                </c:choose>
              </div>
            </c:when>
            <c:when test="${vietqrConfigured}">
              <div style="text-align:center;padding:20px 0">
                <div style="font-size:36px;margin-bottom:8px">📱</div>
                <p style="color:#ccc;font-size:14px;margin-bottom:16px">
                  Nhấn để tạo mã QR chuyển khoản cho đơn này.
                </p>
                <form method="post"
                      action="${pageContext.request.contextPath}/staff/counter?action=initVietQR">
                  <input type="hidden" name="bookingId" value="${detail.bookingId}"/>
                  <button type="submit" class="pos-proceed-btn" style="margin:0 auto;display:block">
                    📲 Tạo mã QR chuyển khoản
                  </button>
                </form>
              </div>
            </c:when>
            <c:otherwise>
              <div style="padding:16px;text-align:center;color:#aaa">
                <div style="font-size:32px;margin-bottom:8px">🏦</div>
                <p style="font-size:13px">Chưa cấu hình VietQR.<br/>
                  Sao chép <code>vietqr.properties.example</code> → <code>vietqr.properties</code>
                  và điền thông tin ngân hàng.</p>
              </div>
            </c:otherwise>
          </c:choose>
        </div>

        <%-- Nút xác nhận tiền mặt --%>
        <div id="cashConfirmSection" style="display:<c:choose><c:when test="${vietqrActive}">none</c:when><c:otherwise>block</c:otherwise></c:choose>">
          <form method="post" id="paymentForm"
                action="${pageContext.request.contextPath}/staff/counter?action=payment">
            <input type="hidden" name="bookingId"    value="${detail.bookingId}"/>
            <input type="hidden" name="cashReceived" id="hiddenCashRecv" value="0"/>
            <input type="hidden" name="changeAmount" id="hiddenChangAmt" value="0"/>
            <button type="button" class="pos-proceed-btn pos-proceed-btn--green"
                    id="markSuccessBtn" onclick="submitPayment()">
              ✓ Xác nhận thanh toán thành công
            </button>
          </form>
        </div>

        <div style="margin-top:12px; text-align:center;">
          <a href="${pageContext.request.contextPath}/staff/counter"
             class="pos-link-btn">← Quay lại quầy vé</a>
          &nbsp;|&nbsp;
          <a href="${pageContext.request.contextPath}/staff/history"
             class="pos-link-btn">Lịch sử</a>
        </div>

      </div>
    </div><%-- /payment-right --%>

  </div><%-- /payment-layout --%>
</div><%-- /pos-container --%>

<script>
  const TOTAL_DUE = ${detail.finalAmount};
  const MAX_CASH  = 999999999; // ~999 triệu VND
  let receivedRaw = '';
  let payMethod   = '${vietqrActive ? "VIETQR" : "CASH"}';

  function setPayMethod(method) {
    payMethod = method;
    const isCash   = method === 'CASH';
    document.getElementById('btnCash').classList.toggle('pay-method-btn--active', isCash);
    document.getElementById('btnVietqr').classList.toggle('pay-method-btn--active', !isCash);
    document.getElementById('cashSection').style.display        = isCash ? '' : 'none';
    document.getElementById('cashConfirmSection').style.display = isCash ? '' : 'none';
    document.getElementById('vietqrSection').style.display      = isCash ? 'none' : '';
  }

  (function () {
    if ('${vietqrActive}' === 'true') setPayMethod('VIETQR');
  })();

  function numpadPress(digit) {
    const next = receivedRaw + digit;
    if (next.length > 9 || parseInt(next, 10) > MAX_CASH) return;
    receivedRaw = next;
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
    const next = current + val;
    if (next > MAX_CASH) return;
    receivedRaw = String(next);
    updateCashDisplay();
  }

  function updateCashDisplay() {
    const received = parseInt(receivedRaw || '0', 10);
    const change   = received - TOTAL_DUE;
    document.getElementById('receivedDisplay').textContent = formatVnd(received);
    const changeEl = document.getElementById('changeDisplay');
    changeEl.textContent = change >= 0 ? formatVnd(change) : '—';
    changeEl.style.color = change >= 0 ? '#4fc3f7' : '#ef5350';
  }

  function submitPayment() {
    const received = parseInt(receivedRaw || '0', 10);
    const change   = Math.max(0, received - TOTAL_DUE);
    if (received < TOTAL_DUE) {
      alert('Tiền nhận chưa đủ. Vui lòng nhập đúng số tiền.');
      return;
    }
    document.getElementById('hiddenCashRecv').value = received;
    document.getElementById('hiddenChangAmt').value = change;
    document.getElementById('paymentForm').submit();
  }

  function formatVnd(n) {
    return new Intl.NumberFormat('vi-VN').format(n) + ' ₫';
  }
</script>

<%-- SePay polling — chỉ chạy khi QR đang hiển thị --%>
<script>
(function () {
  var waitBox = document.querySelector('[data-vietqr-waiting="true"]');
  if (!waitBox) return;

  var ctx         = waitBox.dataset.ctx;
  var bookingId   = waitBox.dataset.bookingId;
  var msgEl       = document.getElementById('vietqrWaitMsg');
  var attempts    = 0;
  var maxAttempts = 90;

  function poll() {
    attempts++;
    fetch(ctx + '/staff/counter?action=paymentStatus&bookingId=' + encodeURIComponent(bookingId), {
      credentials: 'same-origin',
      headers: { 'Accept': 'application/json' }
    })
    .then(function (res) { return res.ok ? res.json() : null; })
    .then(function (data) {
      if (data && data.paid && data.successUrl) {
        window.location.href = data.successUrl;
        return;
      }
      if (attempts >= maxAttempts) {
        if (msgEl) msgEl.textContent = 'Chưa nhận được xác nhận SePay. Dùng nút xác nhận thủ công nếu cần.';
        return;
      }
      if (msgEl) msgEl.textContent = 'Đang chờ SePay xác nhận... (' + attempts + '/' + maxAttempts + ')';
      setTimeout(poll, 2000);
    })
    .catch(function () { if (attempts < maxAttempts) setTimeout(poll, 2000); });
  }

  poll();
})();
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>