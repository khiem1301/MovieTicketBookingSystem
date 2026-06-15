/* FR-14 / FR-16 — Customer payment page countdown + VietQR copy */
(function () {
  'use strict';

  var pageEl = document.querySelector('.pay-page');
  if (!pageEl) return;

  var expiresMs = parseInt(pageEl.dataset.expires || '0', 10);
  var showtimeId = pageEl.dataset.showtimeId || '';
  var ctx = pageEl.dataset.ctx || '';
  var countdownEl = document.getElementById('payCountdown');
  var timerId = null;

  document.addEventListener('DOMContentLoaded', function () {
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
          if (showtimeId && ctx) {
            window.location.href = ctx + '/checkout?showtimeId='
              + encodeURIComponent(showtimeId)
              + '&error=' + encodeURIComponent('Đơn đặt vé đã hết hạn. Vui lòng chọn ghế lại.');
          }
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
}());
