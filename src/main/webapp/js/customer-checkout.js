/* ============================================================
   FR-12 / FR-13 / FR-14 — Customer Checkout / Seat Selection
   ============================================================ */
(function () {
  'use strict';

  var pageEl = document.querySelector('.ck-page');
  if (!pageEl) return;

  var CTX = pageEl.dataset.ctx || '';
  var showtimeId = pageEl.dataset.showtimeId || '';
  var readOnly = pageEl.dataset.readOnly === 'true';
  var hasPendingBooking = pageEl.dataset.pendingBooking === 'true';
  var holdExpiresMs = parseInt(pageEl.dataset.holdExpires || '0', 10);

  var selectedSeats = [];
  var holdSyncing = false;
  var holdTimerId = null;
  var SEAT_REFRESH_MS = 2000;

  document.addEventListener('DOMContentLoaded', init);

  function init() {
    if (window.SeatTypeColors) {
      SeatTypeColors.applySwatchColors(document);
    }

    initHeldSeatsFromDom();

    if (!readOnly && !hasPendingBooking) {
      document.querySelectorAll('.ck-seat--available, .ck-seat--held, .ck-seat--selected').forEach(bindSeatClick);
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

  function bindSeatClick(btn) {
    if (btn.disabled || btn.dataset.ckBound === 'true') return;
    btn.dataset.ckBound = 'true';
    btn.addEventListener('click', function () { toggleSeat(btn); });
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
    if (readOnly || hasPendingBooking || holdSyncing) return;
    if (btn.classList.contains('ck-seat--sold') || btn.disabled) return;

    var snapshot = selectedSeats.map(function (s) {
      return { id: s.id, code: s.code, type: s.type, price: s.price };
    });

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
    syncHolds(snapshot);
  }

  function syncHolds(revertSnapshot) {
    if (!showtimeId) return;

    holdSyncing = true;
    var body = new URLSearchParams();
    body.append('action', 'hold');
    body.append('showtimeId', showtimeId);
    selectedSeats.forEach(function (s) {
      body.append('seatIds', s.id);
    });

    fetch(CTX + '/checkout', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
      body: body.toString()
    })
      .then(function (r) { return r.json().then(function (data) { return { ok: r.ok, data: data }; }); })
      .then(function (res) {
        holdSyncing = false;
        if (!res.data || !res.data.ok) {
          revertSelection(revertSnapshot, (res.data && res.data.error) || 'Kh\u00f4ng th\u1ec3 gi\u1eef gh\u1ebf');
          return;
        }
        if (res.data.expiresAt) {
          holdExpiresMs = res.data.expiresAt;
          startHoldTimer();
        } else {
          holdExpiresMs = 0;
          stopHoldTimer();
        }
      })
      .catch(function () {
        holdSyncing = false;
        revertSelection(revertSnapshot, 'L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.');
      });
  }

  function revertSelection(snapshot, message) {
    selectedSeats = snapshot.map(function (s) {
      return { id: s.id, code: s.code, type: s.type, price: s.price };
    });
    restoreSeatUiFromSelection();
    updateSummary();
    checkProceedBtn();
    if (message) showHoldError(message);
  }

  function restoreSeatUiFromSelection() {
    document.querySelectorAll('.ck-seat[data-seat-id]').forEach(function (btn) {
      if (btn.classList.contains('ck-seat--sold')) return;
      var isSelected = selectedSeats.some(function (s) { return s.id === btn.dataset.seatId; });
      btn.classList.remove('ck-seat--selected', 'ck-seat--held', 'ck-seat--available');
      if (isSelected) {
        btn.classList.add('ck-seat--selected');
      } else {
        btn.classList.add('ck-seat--available');
        delete btn.dataset.held;
      }
      btn.disabled = readOnly;
      var col = btn.querySelector('.ck-seat-num');
      if (!col && btn.dataset.seatCode) {
        var match = btn.dataset.seatCode.match(/\d+$/);
        if (match) btn.innerHTML = seatNumberHtml(parseInt(match[0], 10));
      }
      if (!readOnly && !hasPendingBooking) bindSeatClick(btn);
    });
  }

  function showHoldError(message) {
    var alertEl = document.getElementById('ckHoldError');
    if (!alertEl) {
      alertEl = document.createElement('div');
      alertEl.id = 'ckHoldError';
      alertEl.className = 'ck-alert ck-alert--error container';
      var layout = document.querySelector('.ck-layout');
      if (layout && layout.parentNode) {
        layout.parentNode.insertBefore(alertEl, layout);
      }
    }
    alertEl.textContent = message;
    alertEl.hidden = false;
    setTimeout(function () { alertEl.hidden = true; }, 5000);
  }

  function updateSummary() {
    var listEl = document.getElementById('ckSeatList');
    var emptyEl = document.getElementById('ckEmptyMsg');
    var totalEl = document.getElementById('ckTotal');
    if (!listEl || !totalEl) return;

    if (selectedSeats.length === 0) {
      listEl.innerHTML = '';
      listEl.hidden = true;
      if (emptyEl) emptyEl.hidden = false;
    } else {
      if (emptyEl) emptyEl.hidden = true;
      listEl.hidden = false;
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
      btn.disabled = readOnly || hasPendingBooking || holdSyncing || selectedSeats.length === 0;
    }
  }

  function onFormSubmit(e) {
    if (readOnly || hasPendingBooking || holdSyncing || selectedSeats.length === 0) {
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
    var wrap = document.getElementById('ckHoldTimer');
    if (!el || !holdExpiresMs) {
      stopHoldTimer();
      return;
    }
    if (wrap) wrap.hidden = false;

    function tick() {
      var remaining = holdExpiresMs - Date.now();
      if (remaining <= 0) {
        el.textContent = '00:00';
        clearInterval(holdTimerId);
        holdTimerId = null;
        selectedSeats = [];
        restoreSeatUiFromSelection();
        updateSummary();
        checkProceedBtn();
        if (wrap) wrap.hidden = true;
        return;
      }
      var totalSec = Math.floor(remaining / 1000);
      var min = Math.floor(totalSec / 60);
      var sec = totalSec % 60;
      el.textContent = String(min).padStart(2, '0') + ':' + String(sec).padStart(2, '0');
    }

    tick();
    if (holdTimerId) clearInterval(holdTimerId);
    holdTimerId = setInterval(tick, 1000);
  }

  function stopHoldTimer() {
    if (holdTimerId) {
      clearInterval(holdTimerId);
      holdTimerId = null;
    }
    var wrap = document.getElementById('ckHoldTimer');
    if (wrap) wrap.hidden = true;
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

      if (isSelected) {
        if (!info.available && !info.heldByMe) {
          markSold(btn, id);
        }
        return;
      }

      if (info.available) {
        markAvailable(btn, info);
      } else if (info.heldByMe) {
        markHeld(btn, info);
      } else {
        markSold(btn, id);
      }
    });

    updateSummary();
    checkProceedBtn();
  }

  function markAvailable(btn, info) {
    if (btn.classList.contains('ck-seat--available') && !btn.classList.contains('ck-seat--sold')) {
      return;
    }
    btn.classList.remove('ck-seat--sold', 'ck-seat--held', 'ck-seat--selected');
    btn.classList.add('ck-seat--available');
    btn.disabled = readOnly || hasPendingBooking;
    delete btn.dataset.held;
    btn.innerHTML = seatNumberHtml(info.seatColumn);
    btn.setAttribute('aria-label', 'Gh\u1ebf ' + (info.seatCode || ''));
    if (!readOnly && !hasPendingBooking) bindSeatClick(btn);
  }

  function markHeld(btn, info) {
    if (btn.classList.contains('ck-seat--sold')) {
      btn.classList.remove('ck-seat--sold', 'ck-seat--selected');
      btn.classList.add('ck-seat--available', 'ck-seat--held');
      btn.disabled = readOnly || hasPendingBooking;
      btn.dataset.held = 'true';
      btn.innerHTML = seatNumberHtml(info.seatColumn);
      if (!readOnly && !hasPendingBooking) bindSeatClick(btn);
    }
  }

  function seatNumberHtml(col) {
    if (col == null) return '';
    return '<span class="ck-seat-num">' + escHtml(String(col)) + '</span>';
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
