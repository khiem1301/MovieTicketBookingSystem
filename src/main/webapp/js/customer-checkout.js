/* ============================================================
   FR-12 / FR-13 — Customer Checkout / Seat Selection
   ============================================================ */
(function () {
  'use strict';

  var pageEl = document.querySelector('.ck-page');
  if (!pageEl) return;

  var CTX = pageEl.dataset.ctx || '';
  var showtimeId = pageEl.dataset.showtimeId || '';
  var readOnly = pageEl.dataset.readOnly === 'true';
  var holdExpiresMs = parseInt(pageEl.dataset.holdExpires || '0', 10);

  var selectedSeats = [];
  var holdTimerId = null;
  var SEAT_REFRESH_MS = 2000;

  document.addEventListener('DOMContentLoaded', init);

  function init() {
    if (window.SeatTypeColors) {
      SeatTypeColors.applySwatchColors(document);
    }

    initHeldSeatsFromDom();

    if (!readOnly) {
      document.querySelectorAll('.ck-seat--available, .ck-seat--held, .ck-seat--selected').forEach(function (btn) {
        if (!btn.disabled) {
          btn.addEventListener('click', function () { toggleSeat(btn); });
        }
      });
    }

    var form = document.getElementById('ckCheckoutForm');
    if (form) {
      form.addEventListener('submit', onFormSubmit);
    }

    updateSummary();
    checkProceedBtn();
    startHoldTimer();

    if (!readOnly && showtimeId) {
      refreshSeats();
      setInterval(refreshSeats, SEAT_REFRESH_MS);
    }
  }

  function initHeldSeatsFromDom() {
    document.querySelectorAll('.ck-seat[data-seat-id]').forEach(function (btn) {
      if (btn.classList.contains('ck-seat--held') || btn.dataset.held === 'true') {
        addSeatFromBtn(btn);
      }
    });
  }

  function addSeatFromBtn(btn) {
    if (selectedSeats.some(function (s) { return s.id === btn.dataset.seatId; })) return;
    selectedSeats.push({
      id: btn.dataset.seatId,
      code: btn.dataset.seatCode,
      type: btn.dataset.type || 'STANDARD',
      price: parseFloat(btn.dataset.price) || 0
    });
    btn.classList.remove('ck-seat--available', 'ck-seat--held');
    btn.classList.add('ck-seat--selected');
    delete btn.dataset.held;
  }

  function toggleSeat(btn) {
    if (btn.classList.contains('ck-seat--sold') || btn.disabled) return;

    var idx = selectedSeats.findIndex(function (s) { return s.id === btn.dataset.seatId; });
    if (idx >= 0) {
      selectedSeats.splice(idx, 1);
      btn.classList.remove('ck-seat--selected', 'ck-seat--held');
      btn.classList.add('ck-seat--available');
    } else {
      selectedSeats.push({
        id: btn.dataset.seatId,
        code: btn.dataset.seatCode,
        type: btn.dataset.type || 'STANDARD',
        price: parseFloat(btn.dataset.price) || 0
      });
      btn.classList.remove('ck-seat--available', 'ck-seat--held');
      btn.classList.add('ck-seat--selected');
    }
    updateSummary();
    checkProceedBtn();
  }

  function updateSummary() {
    var listEl = document.getElementById('ckSeatList');
    var totalEl = document.getElementById('ckTotal');
    if (!listEl || !totalEl) return;

    if (selectedSeats.length === 0) {
      listEl.innerHTML = '<p class="ck-empty-msg">Chưa chọn ghế nào</p>';
    } else {
      listEl.innerHTML = selectedSeats.map(function (s) {
        return '<div class="ck-seat-chip">' +
          '<span class="ck-seat-chip-code">' + escHtml(s.code) + '</span>' +
          '<span class="ck-seat-chip-price">' + formatVnd(s.price) + '</span>' +
          '</div>';
      }).join('');
    }

    var total = selectedSeats.reduce(function (sum, s) { return sum + s.price; }, 0);
    totalEl.textContent = formatVnd(total);
  }

  function checkProceedBtn() {
    var btn = document.getElementById('ckProceedBtn');
    if (btn) {
      btn.disabled = readOnly || selectedSeats.length === 0;
    }
  }

  function onFormSubmit(e) {
    if (readOnly || selectedSeats.length === 0) {
      e.preventDefault();
      return;
    }

    var hidden = document.getElementById('ckHiddenSeats');
    if (!hidden) return;

    hidden.innerHTML = '';
    selectedSeats.forEach(function (seat) {
      var inp = document.createElement('input');
      inp.type = 'hidden';
      inp.name = 'seatIds';
      inp.value = seat.id;
      hidden.appendChild(inp);
    });
  }

  function startHoldTimer() {
    var el = document.getElementById('ckHoldCountdown');
    if (!el || !holdExpiresMs) return;

    function tick() {
      var remaining = holdExpiresMs - Date.now();
      if (remaining <= 0) {
        el.textContent = '00:00';
        clearInterval(holdTimerId);
        return;
      }
      var totalSec = Math.floor(remaining / 1000);
      var min = Math.floor(totalSec / 60);
      var sec = totalSec % 60;
      el.textContent = String(min).padStart(2, '0') + ':' + String(sec).padStart(2, '0');
    }

    tick();
    holdTimerId = setInterval(tick, 1000);
  }

  function refreshSeats() {
    if (!showtimeId) return;

    fetch(CTX + '/checkout?action=seats&showtimeId=' + encodeURIComponent(showtimeId))
      .then(function (r) { return r.json(); })
      .then(function (rows) { applySeatRefresh(rows); })
      .catch(function () { /* silent */ });
  }

  function applySeatRefresh(rows) {
    if (!Array.isArray(rows)) return;

    var seatState = {};
    rows.forEach(function (row) {
      (row.seats || []).forEach(function (seat) {
        seatState[seat.id] = seat;
      });
    });

    document.querySelectorAll('.ck-seat[data-seat-id]').forEach(function (btn) {
      var id = btn.dataset.seatId;
      var info = seatState[id];
      if (!info) return;

      var isSelected = selectedSeats.some(function (s) { return s.id === id; });

      if (info.heldByMe && isSelected) {
        return;
      }

      if (!info.available && !info.heldByMe) {
        markSold(btn, id);
      }
    });

    updateSummary();
    checkProceedBtn();
  }

  function markSold(btn, id) {
    if (!btn.classList.contains('ck-seat--sold')) {
      btn.classList.remove('ck-seat--available', 'ck-seat--selected', 'ck-seat--held');
      btn.classList.add('ck-seat--sold');
      btn.disabled = true;
      btn.innerHTML = '<svg class="ck-seat-icon" width="14" height="14" viewBox="0 0 24 24" fill="none"' +
        ' stroke="currentColor" stroke-width="2.5" stroke-linecap="round">' +
        '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>';
    }

    var idx = selectedSeats.findIndex(function (s) { return s.id === id; });
    if (idx >= 0) selectedSeats.splice(idx, 1);
  }

  function formatVnd(n) {
    return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + ' \u20ab';
  }

  function escHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }
}());
