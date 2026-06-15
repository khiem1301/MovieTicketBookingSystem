/* FR-14 — Customer payment page countdown */
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
    if (!countdownEl || !expiresMs) return;

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
  });
}());
