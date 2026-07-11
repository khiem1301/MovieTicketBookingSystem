/* FR-14 / FR-16 — Customer payment page countdown + VietQR copy */
(function () {
  'use strict';

  var pageEl = document.querySelector('.pay-page');
  if (!pageEl) return;

  var expiresMs = parseInt(pageEl.dataset.expires || '0', 10);
  var showtimeId = pageEl.dataset.showtimeId || '';
  var bookingId = pageEl.dataset.bookingId || '';
  var ctx = pageEl.dataset.ctx || '';
  var countdownEl = document.getElementById('payCountdown');
  var timerId = null;

  document.addEventListener('DOMContentLoaded', function () {
    startVietqrSepayPoll();

    var promoInput = document.getElementById('payPromoCode');
    if (promoInput) {
      promoInput.addEventListener('input', function () {
        promoInput.value = promoInput.value.toUpperCase();
      });
    }

    document.querySelectorAll('.pay-vqr-copy-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var targetId = btn.getAttribute('data-copy-target');
        var el = targetId ? document.getElementById(targetId) : null;
        if (!el) return;
        var text = el.textContent || '';
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(function () {
            btn.textContent = '✓';
            setTimeout(function () { btn.textContent = '📋'; }, 1500);
          }).catch(function () { fallbackCopy(text, btn); });
        } else {
          fallbackCopy(text, btn);
        }
      });
    });

    if (countdownEl && expiresMs) {
      function tick() {
        var remaining = expiresMs - Date.now();
        if (remaining <= 0) {
          countdownEl.textContent = '00:00';
          countdownEl.classList.add('pay-expiry-value--expired');
          clearInterval(timerId);
          redirectAfterPaymentExpired();
          return;
        }
        var totalSec = Math.floor(remaining / 1000);
        var min = Math.floor(totalSec / 60);
        var sec = totalSec % 60;
        countdownEl.textContent = String(min).padStart(2, '0') + ':' + String(sec).padStart(2, '0');
      }
      tick();
      timerId = setInterval(tick, 1000);
    }
  });

  function redirectAfterPaymentExpired() {
    var errorMsg = '\u0110\u01A1n \u0111\u1EB7t v\u00E9 \u0111\u00E3 h\u1EBFt h\u1EA1n. Vui l\u00F2ng ch\u1ECDn gh\u1EBF l\u1EA1i.';
    var checkoutUrl = (showtimeId && ctx)
      ? (ctx + '/checkout?showtimeId=' + encodeURIComponent(showtimeId)
          + '&error=' + encodeURIComponent(errorMsg))
      : (ctx + '/movies');

    function go() {
      window.location.href = checkoutUrl;
    }

    if (!bookingId || !ctx) {
      go();
      return;
    }

    // Đánh EXPIRED trên server trước khi về checkout — ghế được giải phóng ngay
    var body = new URLSearchParams();
    body.append('bookingId', bookingId);
    body.append('action', 'expire');

    fetch(ctx + '/payment', {
      method: 'POST',
      credentials: 'same-origin',
      keepalive: true,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
      },
      body: body.toString()
    }).catch(function () { /* ignore */ }).then(go);
  }

  function fallbackCopy(text, btn) {
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.left = '-9999px';
    document.body.appendChild(ta);
    ta.select();
    try {
      document.execCommand('copy');
      btn.textContent = '✓';
      setTimeout(function () { btn.textContent = '📋'; }, 1500);
    } catch (e) { /* ignore */ }
    document.body.removeChild(ta);
  }

  /** SePay webhook: poll /payment/status trên trang VietQR đang chờ. */
  function startVietqrSepayPoll() {
    var waitBox = document.querySelector('[data-vietqr-waiting="true"]');
    if (!waitBox) return;

    var ctx = waitBox.dataset.ctx || '';
    var bookingId = waitBox.dataset.bookingId || '';
    var msgEl = document.getElementById('payVietqrWaitMsg');
    var attempts = 0;
    var maxAttempts = 90; // ~3 phút

    function poll() {
      attempts += 1;
      if (!bookingId || !ctx) return;

      fetch(ctx + '/payment/status?bookingId=' + encodeURIComponent(bookingId), {
        credentials: 'same-origin',
        headers: { 'Accept': 'application/json' }
      })
        .then(function (res) {
          if (res.status === 401) {
            if (msgEl) {
              msgEl.textContent = 'Phi\u00EAn \u0111\u0103ng nh\u1EADp h\u1EBFt h\u1EA1n. Vui l\u00F2ng \u0111\u0103ng nh\u1EADp l\u1EA1i.';
            }
            return null;
          }
          if (!res.ok) return null;
          return res.json();
        })
        .then(function (data) {
          if (data && data.paid && data.successUrl) {
            window.location.href = data.successUrl;
            return;
          }
          if (attempts >= maxAttempts) {
            if (msgEl) {
              msgEl.textContent = 'Ch\u01B0a nh\u1EADn \u0111\u01B0\u1EE3c x\u00E1c nh\u1EADn SePay. Ki\u1EC3m tra n\u1ED9i dung CK / d\u00F9ng x\u00E1c nh\u1EADn th\u1EE7 c\u00F4ng n\u1EBFu c\u1EA7n.';
            }
            return;
          }
          if (msgEl) {
            msgEl.textContent = '\u0110ang ch\u1EDD SePay x\u00E1c nh\u1EADn... (' + attempts + '/' + maxAttempts + ')';
          }
          setTimeout(poll, 2000);
        })
        .catch(function () {
          if (attempts < maxAttempts) {
            setTimeout(poll, 2000);
          }
        });
    }

    poll();
  }
}());
