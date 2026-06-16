<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions"  %>

<c:set var="pageTitle" value="Thanh toán — ${detail.movieTitle} | ÉPCINE"/>
<c:set var="extraCss" value="customer-checkout"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<c:set var="poster" value="${detail.moviePosterUrl}"/>
<c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
  <c:set var="poster" value="${ctx}/${poster}"/>
</c:if>

<c:set var="discount" value="${detail.discountAmount != null ? detail.discountAmount : 0}"/>
<c:set var="vatAmount" value="${detail.vatAmount != null ? detail.vatAmount : 0}"/>
<c:set var="vietqrActive" value="${vietqrActive == true}"/>

<div class="pay-page pay-page--checkout"
     data-ctx="${ctx}"
     data-booking-id="<c:out value='${detail.bookingId}'/>"
     data-expires="<c:out value='${detail.expiredAt.time}'/>"
     data-showtime-id="<c:out value='${detail.showtimeId}'/>">

  <header class="pay-header pay-header--secure">
    <div class="pay-header-inner container">
      <a href="${ctx}/checkout?showtimeId=${detail.showtimeId}" class="ck-back-btn" aria-label="Quay lại chọn ghế">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="15 18 9 12 15 6"/>
        </svg>
      </a>
      <div class="pay-header-text">
        <h1 class="pay-title">Thanh toán bảo mật</h1>
        <p class="pay-subtitle pay-subtitle--lock">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="11" width="18" height="11" rx="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
          Phiên thanh toán được mã hóa
        </p>
      </div>
    </div>
  </header>

  <c:if test="${not empty errorMessage}">
    <div class="ck-alert ck-alert--error container"><c:out value="${errorMessage}"/></div>
  </c:if>
  <c:if test="${not empty infoMessage}">
    <div class="ck-alert ck-alert--info container"><c:out value="${infoMessage}"/></div>
  </c:if>

  <div class="pay-checkout-grid container">

    <%-- Cột trái: VietQR --%>
    <section class="pay-momo-panel" aria-label="Thanh toán VietQR">
      <div class="pay-card pay-card--glass pay-momo-card">
        <div class="pay-momo-glow" aria-hidden="true"></div>
        <h2 class="pay-momo-heading">Phương thức thanh toán</h2>

        <div class="pay-momo-method pay-momo-method--selected pay-momo-method--vietqr">
          <div class="pay-momo-method-icon pay-momo-method-icon--vietqr">VQR</div>
          <span class="pay-momo-method-label">Chuyển khoản VietQR</span>
          <span class="pay-momo-method-check" aria-hidden="true">✓</span>
        </div>

        <c:choose>
          <c:when test="${vietqrActive}">
            <div class="pay-momo-qr-block">
              <div class="pay-momo-qr-wrap">
                <div class="pay-momo-qr-scanline" aria-hidden="true"></div>
                <c:if test="${not empty vietqrQrUrl}">
                  <img src="<c:out value='${vietqrQrUrl}'/>" alt="Mã QR VietQR thanh toán" class="pay-momo-qr-img"/>
                </c:if>
                <div class="pay-momo-qr-corner pay-momo-qr-corner--tl"></div>
                <div class="pay-momo-qr-corner pay-momo-qr-corner--tr"></div>
                <div class="pay-momo-qr-corner pay-momo-qr-corner--bl"></div>
                <div class="pay-momo-qr-corner pay-momo-qr-corner--br"></div>
              </div>
              <div class="pay-momo-instructions">
                <div class="pay-momo-instructions-head">
                  <span class="pay-momo-phone-icon">📱</span>
                  <h3>Quét mã VietQR để chuyển khoản</h3>
                </div>
                <ol class="pay-momo-steps">
                  <li><span class="pay-momo-step-num">1</span> Mở app ngân hàng hoặc ví điện tử hỗ trợ VietQR.</li>
                  <li><span class="pay-momo-step-num">2</span> Chọn <strong>Quét mã QR</strong> và quét mã bên trái.</li>
                  <li><span class="pay-momo-step-num">3</span> Kiểm tra số tiền và nội dung chuyển khoản, sau đó xác nhận.</li>
                </ol>

                <div class="pay-vqr-bank-details">
                  <div class="pay-vqr-bank-row">
                    <span class="pay-vqr-bank-label">Ngân hàng</span>
                    <span class="pay-vqr-bank-value"><c:out value="${vietqrBankName}"/></span>
                  </div>
                  <div class="pay-vqr-bank-row">
                    <span class="pay-vqr-bank-label">Số tài khoản</span>
                    <span class="pay-vqr-bank-value">
                      <code id="payVqrAccountNo"><c:out value="${vietqrAccountNo}"/></code>
                      <button type="button" class="pay-vqr-copy-btn" data-copy-target="payVqrAccountNo" title="Sao chép">📋</button>
                    </span>
                  </div>
                  <div class="pay-vqr-bank-row">
                    <span class="pay-vqr-bank-label">Chủ tài khoản</span>
                    <span class="pay-vqr-bank-value"><c:out value="${vietqrAccountName}"/></span>
                  </div>
                  <div class="pay-vqr-bank-row pay-vqr-bank-row--highlight">
                    <span class="pay-vqr-bank-label">Nội dung CK</span>
                    <span class="pay-vqr-bank-value">
                      <code id="payVqrTransferContent"><c:out value="${vietqrTransferContent}"/></code>
                      <button type="button" class="pay-vqr-copy-btn" data-copy-target="payVqrTransferContent" title="Sao chép">📋</button>
                    </span>
                  </div>
                </div>

                <div class="pay-momo-wait-note">
                  <span aria-hidden="true">ℹ</span>
                  Chuyển khoản đúng số tiền và nội dung ghi chú. Sau khi chuyển, nhấn nút bên dưới để hoàn tất đơn.
                </div>
              </div>
            </div>
            <form method="post" action="${ctx}/payment" class="pay-vqr-confirm-form"
                  onsubmit="return confirm('Bạn đã chuyển khoản thành công với đúng số tiền và nội dung?');">
              <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
              <input type="hidden" name="action" value="confirmVietQR"/>
              <button type="submit" class="pay-momo-pay-btn">Tôi đã chuyển khoản</button>
            </form>
          </c:when>
          <c:otherwise>
            <div class="pay-momo-start">
              <p class="pay-momo-start-text">
                Nhấn nút bên dưới để tạo mã QR VietQR cho đơn
                <strong><c:out value="${detail.bookingCode}"/></strong>.
              </p>
              <form method="post" action="${ctx}/payment" class="pay-momo-start-form">
                <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
                <input type="hidden" name="action" value="payVietQR"/>
                <button type="submit" class="pay-momo-pay-btn"
                        <c:if test="${not vietqrConfigured}">disabled title="Chưa cấu hình vietqr.properties"</c:if>>
                  Thanh toán bằng VietQR
                </button>
              </form>
              <c:if test="${not vietqrConfigured}">
                <p class="pay-stub-note">Sao chép <code>vietqr.properties.example</code> → <code>vietqr.properties</code> và điền STK ngân hàng.</p>
              </c:if>
            </div>
          </c:otherwise>
        </c:choose>
      </div>

      <div class="pay-trust-badges">
        <span>🛡 Mã hóa SSL</span>
        <span>✓ Thanh toán an toàn</span>
        <span>💬 Hỗ trợ 24/7</span>
      </div>
    </section>

    <%-- Cột phải: Tóm tắt đơn --%>
    <aside class="pay-summary pay-summary--sticky" aria-label="Tóm tắt đơn hàng">
      <div class="pay-card pay-card--summary pay-card--accent-top">
        <h2 class="pay-summary-heading">Tóm tắt đơn</h2>

        <div class="pay-movie-row pay-movie-row--compact">
          <div class="pay-movie-poster">
            <c:choose>
              <c:when test="${not empty poster}">
                <img src="<c:out value='${poster}'/>" alt="Poster phim" onerror="this.style.display='none'"/>
              </c:when>
              <c:otherwise><div class="pay-poster-fallback">🎬</div></c:otherwise>
            </c:choose>
          </div>
          <div class="pay-movie-info">
            <h3 class="pay-movie-title"><c:out value="${detail.movieTitle}"/></h3>
            <p class="pay-movie-meta">
              <fmt:formatDate value="${detail.startTime}" pattern="EEE, dd/MM/yyyy • HH:mm"/>
            </p>
            <p class="pay-movie-meta">Phòng: <c:out value="${detail.roomName}"/></p>
            <span class="pay-ref-inline">Mã: <c:out value="${detail.bookingCode}"/></span>
          </div>
        </div>

        <div class="pay-seats-block pay-seats-block--compact">
          <div class="pay-breakdown-row">
            <span>Ghế (<c:out value="${fn:length(detail.seats)}"/>)</span>
            <span class="pay-seat-codes">
              <c:forEach var="seat" items="${detail.seats}" varStatus="st">
                <c:out value="${seat.seatCode}"/><c:if test="${not st.last}">, </c:if>
              </c:forEach>
            </span>
          </div>
          <c:forEach var="seat" items="${detail.seats}">
            <div class="pay-breakdown-row pay-breakdown-row--sm">
              <span><c:out value="${seat.seatType}"/> — <c:out value="${seat.seatCode}"/></span>
              <span><fmt:formatNumber value="${seat.price}" type="number" groupingUsed="true"/> ₫</span>
            </div>
          </c:forEach>
        </div>

        <div class="pay-promo-block">
          <label class="pay-promo-label" for="payPromoCode">Mã giảm giá</label>
          <c:choose>
            <c:when test="${not empty detail.appliedPromoCode}">
              <div class="pay-promo-applied">
                <span class="pay-promo-applied-code"><c:out value="${detail.appliedPromoCode}"/></span>
                <span class="pay-promo-applied-title"><c:out value="${detail.appliedPromoTitle}"/></span>
              </div>
              <form method="post" action="${ctx}/payment" class="pay-promo-form">
                <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
                <input type="hidden" name="action" value="removePromo"/>
                <button type="submit" class="pay-promo-remove-btn">Gỡ mã</button>
              </form>
            </c:when>
            <c:otherwise>
              <form method="post" action="${ctx}/payment" class="pay-promo-form">
                <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
                <input type="hidden" name="action" value="applyPromo"/>
                <div class="pay-promo-row">
                  <input type="text" id="payPromoCode" name="promoCode" class="pay-promo-input"
                         placeholder="Nhập mã voucher" maxlength="50" autocomplete="off"/>
                  <button type="submit" class="pay-promo-apply-btn">Áp dụng</button>
                </div>
              </form>
            </c:otherwise>
          </c:choose>
        </div>

        <div class="pay-breakdown">
          <div class="pay-breakdown-row">
            <span>Tạm tính</span>
            <span><fmt:formatNumber value="${detail.totalAmount}" type="number" groupingUsed="true"/> ₫</span>
          </div>
          <c:if test="${discount gt 0}">
            <div class="pay-breakdown-row pay-breakdown-row--discount">
              <span>Giảm giá</span>
              <span>-<fmt:formatNumber value="${discount}" type="number" groupingUsed="true"/> ₫</span>
            </div>
          </c:if>
          <div class="pay-breakdown-row">
            <span>VAT (<fmt:formatNumber value="${detail.vatRate}" maxFractionDigits="1"/>%)</span>
            <span><fmt:formatNumber value="${vatAmount}" type="number" groupingUsed="true"/> ₫</span>
          </div>
          <div class="pay-breakdown-row pay-breakdown-row--total">
            <span>Tổng thanh toán</span>
            <span class="pay-final-amount">
              <fmt:formatNumber value="${detail.finalAmount}" type="number" groupingUsed="true"/> ₫
            </span>
          </div>
        </div>

        <div class="pay-expiry-box">
          <span class="pay-expiry-label">Thời gian còn lại</span>
          <div class="pay-expiry-timer" id="payCountdown">--:--</div>
        </div>

        <form method="post" action="${ctx}/payment" class="pay-cancel-form"
              onsubmit="return confirm('Hủy đơn này và giải phóng ghế ngay?');">
          <input type="hidden" name="bookingId" value="<c:out value='${detail.bookingId}'/>"/>
          <input type="hidden" name="action" value="cancel"/>
          <button type="submit" class="pay-cancel-btn">Hủy đơn</button>
        </form>
      </div>
    </aside>
  </div>
</div>

<script charset="UTF-8" src="${ctx}/js/customer-payment.js"></script>
<%@ include file="/WEB-INF/views/common/footer.jsp" %>
