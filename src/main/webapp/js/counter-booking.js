/* ============================================================
   Counter POS \u2014 FR-35 / FR-36 / FR-38
   3-panel layout: movie list \u2192 showtimes \u2192 seat map \u2192 summary
   ============================================================ */
(function () {
  'use strict';

  const CTX = document.querySelector('meta[name="ctx"]')?.content ?? '';

  // Back t\u1eeb m\u00e0n thanh to\u00e1n: bfcache c\u00f3 th\u1ec3 tr\u1ea3 POS c\u0169 (gh\u1ebf kh\u00f3a, thi\u1ebfu banner \u0111\u01a1n ch\u1edd)
  window.addEventListener('pageshow', function (e) {
    if (e.persisted) {
      window.location.reload();
    }
  });

  // \u2500\u2500 State \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  const MAX_SEATS = 8;

  let selectedMovieEl  = null;
  let selectedMovieId  = null;
  let selectedMovieTitle = '';
  let showtimesAll     = [];   // all showtimes for the selected movie
  let selectedDate     = null;
  let selectedShowtimeId = null;
  let selectedRoomName = '';
  let selectedStartTime = '';
  let selectedSeats    = [];   // [{id, code, type, price}]
  let memberLocked     = false;
  let appliedPoints    = 0;    // \u0111i\u1ec3m \u0111\u00e3 \u00e1p d\u1ee5ng \u0111\u1ec3 tr\u1eeb ti\u1ec1n
  let memberPointsBalance = 0; // s\u1ed1 d\u01b0 \u0111i\u1ec3m c\u1ee7a th\u00e0nh vi\u00ean
  let appliedVoucherCode   = '';  // m\u00e3 voucher \u0111ang \u00e1p d\u1ee5ng
  let voucherDiscountAmount = 0;  // s\u1ed1 ti\u1ec1n gi\u1ea3m t\u1eeb voucher (VND)
  let holdSyncing          = false;
  const SEAT_REFRESH_MS    = 2000;
  let seatRefreshTimer     = null;

  // \u2500\u2500 Movie tab / search \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  window.switchTab = function (tab) {
    document.getElementById('tabNowShowing').classList.toggle('pos-tab--active', tab === 'now');
    document.getElementById('tabComingSoon').classList.toggle('pos-tab--active', tab === 'coming');
    const q = document.getElementById('movieSearch')?.value ?? '';
    filterMovies(q);
  };

  window.filterMovies = function (query) {
    const q = query.toLowerCase().trim();
    const activeTab = document.querySelector('.pos-tab--active')?.dataset?.tab ?? 'now';
    let visibleCount = 0;
    document.querySelectorAll('.pos-movie-item').forEach(el => {
      const title  = (el.dataset.movieTitle ?? '').toLowerCase();
      const status = (el.dataset.movieStatus ?? '').toUpperCase();
      const tabOk  = activeTab === 'coming' ? status.includes('COMING') : !status.includes('COMING');
      const show   = tabOk && (q === '' || title.includes(q));
      el.style.display = show ? '' : 'none';
      if (show) visibleCount++;
    });

    let emptyEl = document.getElementById('movieListEmpty');
    if (!emptyEl) {
      emptyEl = document.createElement('div');
      emptyEl.id = 'movieListEmpty';
      emptyEl.className = 'pos-empty';
      document.getElementById('movieList').appendChild(emptyEl);
    }
    if (visibleCount === 0) {
      const tabName = activeTab === 'coming' ? 'S\u1eafp chi\u1ebfu' : '\u0110ang chi\u1ebfu';
      emptyEl.textContent = q ? 'Kh\u00f4ng t\u00ecm th\u1ea5y phim ph\u00f9 h\u1ee3p.' : `Kh\u00f4ng c\u00f3 phim ${tabName}.`;
      emptyEl.style.display = '';
    } else {
      emptyEl.style.display = 'none';
    }
  };

  // \u2500\u2500 Movie selection \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  window.selectMovie = function (el) {
    if (selectedMovieEl) selectedMovieEl.classList.remove('pos-movie-item--active');
    selectedMovieEl = el;
    el.classList.add('pos-movie-item--active');

    selectedMovieId    = el.dataset.movieId;
    selectedMovieTitle = el.querySelector('.pos-movie-title')?.textContent ?? '';

    // Reset downstream state
    clearShowtimes();
    clearSeats();
    updateSummaryMovie();
    loadShowtimes(selectedMovieId);
  };

  function loadShowtimes(movieId) {
    const picker  = document.getElementById('showtimePicker');
    const loading = document.getElementById('showtimeLoading');
    picker.style.display = 'block';
    loading.classList.remove('hidden');
    document.getElementById('dateTabs').innerHTML  = '';
    document.getElementById('timeGrid').innerHTML  = '';

    fetch(`${CTX}/staff/counter?action=showtimes&movieId=${encodeURIComponent(movieId)}`)
      .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(data => {
        loading.classList.add('hidden');
        showtimesAll = data;
        renderDateTabs(data);
      })
      .catch(() => {
        loading.textContent = 'Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c su\u1ea5t chi\u1ebfu.';
      });
  }

  // \u2500\u2500 Showtime / Date selection \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function renderDateTabs(showtimes) {
    const dateMap = {};
    showtimes.forEach(st => {
      if (!dateMap[st.date]) dateMap[st.date] = [];
      dateMap[st.date].push(st);
    });

    const dates = Object.keys(dateMap).sort();
    if (dates.length === 0) {
      document.getElementById('showtimePicker').style.display = 'none';
      const area = document.getElementById('seatArea');
      area.innerHTML =
        '<div class="pos-seat-placeholder">' +
        '<div class="placeholder-icon">\ud83d\udcc5</div>' +
        '<div>Phim n\u00e0y ch\u01b0a c\u00f3 l\u1ecbch chi\u1ebfu.<br/>' +
        '<small>Qu\u1ea3n l\u00fd c\u1ea7n t\u1ea1o l\u1ecbch chi\u1ebfu tr\u01b0\u1edbc.</small></div></div>';
      return;
    }

    const container = document.getElementById('dateTabs');
    container.innerHTML = '';
    dates.forEach((date, idx) => {
      const d   = new Date(date + 'T00:00:00');
      const now = new Date();
      const isToday = d.toDateString() === now.toDateString();

      const btn = document.createElement('button');
      btn.className = 'pos-date-tab' + (idx === 0 ? ' pos-date-tab--active' : '');
      btn.dataset.date = date;
      btn.innerHTML = `
        <div class="date-tab-day">${isToday ? 'H\u00d4M NAY' : weekday(d)}</div>
        <div class="date-tab-num">${d.getDate()}</div>`;
      btn.addEventListener('click', () => selectDate(date));
      container.appendChild(btn);
    });

    selectDate(dates[0]);
  }

  function weekday(d) {
    return ['CN','T2','T3','T4','T5','T6','T7'][d.getDay()];
  }

  function selectDate(date) {
    selectedDate = date;
    document.querySelectorAll('.pos-date-tab').forEach(b => {
      b.classList.toggle('pos-date-tab--active', b.dataset.date === date);
    });

    const filtered = showtimesAll.filter(st => st.date === date);
    const grid = document.getElementById('timeGrid');
    grid.innerHTML = '';

    filtered.forEach(st => {
      const btn = document.createElement('button');
      btn.className = 'pos-time-btn' + (st.status === 'OPEN' ? '' : ' pos-time-btn--dim');
      btn.dataset.showtimeId = st.id;
      btn.textContent = st.time;
      btn.addEventListener('click', () => selectShowtime(st));
      grid.appendChild(btn);
    });

    if (filtered.length === 0) {
      grid.innerHTML = '<div class="pos-empty-small">Kh\u00f4ng c\u00f3 su\u1ea5t cho ng\u00e0y n\u00e0y.</div>';
    }
  }

  function selectShowtime(st) {
    if (st.status === 'CANCELLED') {
      alert(`Su\u1ea5t chi\u1ebfu ${st.time} \u0111\u00e3 b\u1ecb h\u1ee7y, kh\u00f4ng th\u1ec3 \u0111\u1eb7t v\u00e9.`);
      return;
    }
    if (selectedShowtimeId && selectedShowtimeId !== st.id) {
      syncHoldsWithServer(selectedShowtimeId, null, []);
    }
    selectedShowtimeId = st.id;
    selectedRoomName   = st.roomName;
    selectedStartTime  = st.date + ' ' + st.time;

    document.querySelectorAll('.pos-time-btn').forEach(b => {
      b.classList.toggle('pos-time-btn--active', b.dataset.showtimeId === st.id);
    });

    clearSeats();
    updateSummaryMovie();
    updatePendingShowtimeUi(st.id);
    loadSeats(st.id); // poll gh\u1ebf li\u00ean t\u1ee5c b\u00ean trong startSeatRefresh
  }

  /** Highlight \u0111\u01a1n PENDING c\u1ee7a su\u1ea5t \u0111ang ch\u1ecdn + c\u1ea3nh b\u00e1o / kh\u00f3a n\u00fat t\u1ea1o \u0111\u01a1n m\u1edbi */
  function updatePendingShowtimeUi(showtimeId) {
    const warn = document.getElementById('posShowtimePendingWarn');
    let hasPending = false;
    document.querySelectorAll('.pos-pending-card[data-showtime-id]').forEach(card => {
      const match = showtimeId && card.dataset.showtimeId === showtimeId;
      card.classList.toggle('pos-pending-card--active', !!match);
      if (match) hasPending = true;
    });
    if (warn) warn.style.display = hasPending ? '' : 'none';
    window.__posShowtimeHasPending = hasPending;
    checkProceedBtn();
  }

  function showtimeHasPendingBooking(showtimeId) {
    if (!showtimeId) return false;
    var found = false;
    document.querySelectorAll('.pos-pending-card[data-showtime-id]').forEach(function (card) {
      if (card.dataset.showtimeId === showtimeId) found = true;
    });
    return found;
  }

  // \u2500\u2500 Seat map \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function loadSeats(showtimeId) {
    const area = document.getElementById('seatArea');
    area.innerHTML = '<div class="pos-loading-seats">\u0110ang t\u1ea3i s\u01a1 \u0111\u1ed3 gh\u1ebf...</div>';

    fetch(`${CTX}/staff/counter?action=seats&showtimeId=${encodeURIComponent(showtimeId)}`)
      .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(rows => {
        renderSeatMap(rows);
        startSeatRefresh(showtimeId);
      })
      .catch(() => {
        stopSeatRefresh();
        area.innerHTML = '<div class="pos-seat-placeholder">Kh\u00f4ng t\u1ea3i \u0111\u01b0\u1ee3c s\u01a1 \u0111\u1ed3 gh\u1ebf.</div>';
      });
  }

  function startSeatRefresh(showtimeId) {
    stopSeatRefresh();
    if (!showtimeId) return;
    seatRefreshTimer = setInterval(() => refreshSeats(showtimeId), SEAT_REFRESH_MS);
  }

  function stopSeatRefresh() {
    if (seatRefreshTimer) {
      clearInterval(seatRefreshTimer);
      seatRefreshTimer = null;
    }
  }

  function refreshSeats(showtimeId) {
    if (!showtimeId || showtimeId !== selectedShowtimeId || holdSyncing) return;
    fetch(`${CTX}/staff/counter?action=seats&showtimeId=${encodeURIComponent(showtimeId)}`)
      .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(applySeatRefresh)
      .catch(() => { /* silent */ });
  }

  function applySeatRefresh(rows) {
    if (!Array.isArray(rows)) return;

    const seatState = {};
    rows.forEach(row => {
      (row.seats || []).forEach(seat => {
        seatState[seat.id] = seat;
      });
    });

    let removedFromSelection = false;
    document.querySelectorAll('.pos-seat-btn[data-seat-id]').forEach(btn => {
      const id = btn.dataset.seatId;
      const info = seatState[id];
      if (!info) return;

      const isSelected = selectedSeats.some(s => s.id === id);

      if (isSelected) {
        if (!info.available && !info.heldByMe) {
          if (markSold(btn, id)) removedFromSelection = true;
        }
        return;
      }

      if (info.available || info.heldByMe) {
        markAvailable(btn, info);
        if (info.heldByMe) {
          btn.classList.add('pos-seat--selected');
        }
      } else {
        markSold(btn, id);
      }
    });

    if (removedFromSelection) {
      updateSummarySeats();
      checkProceedBtn();
      if (selectedShowtimeId) {
        syncHoldsWithServer(selectedShowtimeId, null);
      }
    }

    if (window.SeatTypeColors && SeatTypeColors.applyAll) {
      SeatTypeColors.applyAll(document);
    }
  }

  function bindSeatClick(btn) {
    if (btn.dataset.posBound === 'true') return;
    btn.dataset.posBound = 'true';
    btn.addEventListener('click', () => toggleSeat(btn));
  }

  function markAvailable(btn, info) {
    const wasSold = btn.classList.contains('pos-seat--sold');
    btn.classList.remove('pos-seat--sold');
    btn.disabled = false;
    if (info && info.ticketPrice != null) btn.dataset.price = info.ticketPrice;
    if (!btn.classList.contains('pos-seat--selected')) {
      if (window.SeatTypeColors && SeatTypeColors.applyPosSeatColors) {
        SeatTypeColors.applyPosSeatColors(btn.parentElement || document);
      }
    }
    if (wasSold || btn.dataset.posBound !== 'true') {
      bindSeatClick(btn);
    }
  }

  function markSold(btn, id) {
    let removed = false;
    if (!btn.classList.contains('pos-seat--sold')) {
      btn.classList.remove('pos-seat--selected');
      btn.classList.add('pos-seat--sold');
      btn.disabled = true;
      if (window.SeatTypeColors && SeatTypeColors.clearSeatInlineStyle) {
        SeatTypeColors.clearSeatInlineStyle(btn);
      }
    }
    const idx = selectedSeats.findIndex(s => s.id === id);
    if (idx >= 0) {
      selectedSeats.splice(idx, 1);
      removed = true;
    }
    return removed;
  }

  function renderSeatMap(rows) {
    const area = document.getElementById('seatArea');
    area.innerHTML = '';

    if (!rows || rows.length === 0) {
      area.innerHTML = '<div class="pos-seat-placeholder">Ph\u00f2ng ch\u01b0a c\u00f3 gh\u1ebf n\u00e0o.</div>';
      return;
    }

    rows.forEach(row => {
      const rowDiv = document.createElement('div');
      rowDiv.className = 'pos-seat-row';

      const label = document.createElement('span');
      label.className = 'pos-row-label';
      label.textContent = row.rowName;
      rowDiv.appendChild(label);

      const cells = document.createElement('div');
      cells.className = 'pos-row-cells';

      let expectedCol = 1;
      row.seats.forEach(seat => {
        const col = seat.seatColumn ?? expectedCol;
        while (expectedCol < col) {
          const gap = document.createElement('span');
          gap.className = 'pos-seat-gap';
          gap.setAttribute('aria-hidden', 'true');
          cells.appendChild(gap);
          expectedCol++;
        }

        const rawType = seat.typeName ?? 'REGULAR';
        const typeKey = (window.SeatTypeColors
          ? SeatTypeColors.normalizeType(rawType)
          : String(rawType).toLowerCase()) || 'regular';
        const btn  = document.createElement('button');
        btn.type = 'button';
        btn.className = `pos-seat-btn pos-seat--${typeKey}`;
        btn.dataset.seatId   = seat.id;
        btn.dataset.seatCode = seat.seatCode;
        btn.dataset.seatType = typeKey;
        btn.dataset.type     = typeKey;
        btn.dataset.price    = seat.ticketPrice ?? 0;
        btn.textContent      = seat.seatCode;

        if (window.SeatTypeColors && SeatTypeColors.isWideType(typeKey)) {
          btn.classList.add('pos-seat--wide');
        }

        const selected = selectedSeats.some(s => s.id === seat.id);
        if (!seat.available && !seat.heldByMe) {
          btn.classList.add('pos-seat--sold');
          btn.disabled = true;
        } else {
          if (selected || seat.heldByMe) {
            btn.classList.add('pos-seat--selected');
            if (seat.heldByMe && !selected) {
              selectedSeats.push({
                id: seat.id,
                code: seat.seatCode,
                type: typeKey,
                price: parseFloat(seat.ticketPrice) || 0
              });
            }
          }
          bindSeatClick(btn);
        }
        cells.appendChild(btn);
        expectedCol = col + 1;
      });

      rowDiv.appendChild(cells);
      area.appendChild(rowDiv);
    });

    updateSeatLegend(rows);
    // B\u1ecf gh\u1ebf \u0111\u00e3 b\u00e1n kh\u1ecfi selection n\u1ebfu map v\u1eeba refresh
    selectedSeats = selectedSeats.filter(s => {
      for (const row of rows || []) {
        for (const seat of row.seats || []) {
          if (seat.id === s.id) return seat.available || seat.heldByMe;
        }
      }
      return false;
    });
    updateSummarySeats();
    checkProceedBtn();
    if (window.SeatTypeColors && SeatTypeColors.applyAll) {
      SeatTypeColors.applyAll(document);
    }
  }

  function updateSeatLegend(rows) {
    const legend = document.getElementById('posSeatLegend');
    if (!legend) return;

    const types = new Map();
    (rows || []).forEach(row => {
      (row.seats || []).forEach(seat => {
        const raw = seat.typeName || 'REGULAR';
        const key = window.SeatTypeColors
          ? SeatTypeColors.normalizeType(raw)
          : String(raw).toLowerCase();
        if (!types.has(key)) {
          types.set(key, String(raw).toUpperCase());
        }
      });
    });

    let html = '';
    types.forEach((label, key) => {
      html += `<span class="legend-item">` +
        `<span class="leg-dot leg-type" data-type-key="${escHtml(key)}"></span>` +
        `${escHtml(label)}</span>`;
    });
    html +=
      '<span class="legend-item"><span class="leg-dot leg-selected"></span>\u0110ang ch\u1ecdn</span>' +
      '<span class="legend-item"><span class="leg-dot leg-sold"></span>\u0110\u00e3 b\u00e1n</span>';
    legend.innerHTML = html;
  }

  function toggleSeat(btn) {
    if (holdSyncing) return;
    if (btn.classList.contains('pos-seat--sold') || btn.disabled) return;

    const snapshot = selectedSeats.map(s => ({
      id: s.id, code: s.code, type: s.type, price: s.price
    }));

    const idx = selectedSeats.findIndex(s => s.id === btn.dataset.seatId);
    if (idx >= 0) {
      selectedSeats.splice(idx, 1);
      btn.classList.remove('pos-seat--selected');
      if (window.SeatTypeColors && SeatTypeColors.applyPosSeatColors) {
        SeatTypeColors.applyPosSeatColors(btn.parentElement || document);
      }
    } else {
      if (selectedSeats.length >= MAX_SEATS) {
        alert(`T\u1ed1i \u0111a ${MAX_SEATS} gh\u1ebf m\u1ed7i l\u1ea7n \u0111\u1eb7t.`);
        return;
      }
      selectedSeats.push({
        id:    btn.dataset.seatId,
        code:  btn.dataset.seatCode,
        type:  btn.dataset.seatType,
        price: parseFloat(btn.dataset.price) || 0
      });
      btn.classList.add('pos-seat--selected');
      if (window.SeatTypeColors && SeatTypeColors.clearSeatInlineStyle) {
        SeatTypeColors.clearSeatInlineStyle(btn);
      }
    }
    resetVoucherSection();
    updateSummarySeats();
    checkProceedBtn();
    syncHoldsWithServer(selectedShowtimeId, snapshot);
  }

  function restoreSeatUiFromSelection() {
    document.querySelectorAll('.pos-seat-btn[data-seat-id]').forEach(btn => {
      if (btn.classList.contains('pos-seat--sold')) return;
      const isSelected = selectedSeats.some(s => s.id === btn.dataset.seatId);
      btn.classList.toggle('pos-seat--selected', isSelected);
      if (isSelected) {
        if (window.SeatTypeColors && SeatTypeColors.clearSeatInlineStyle) {
          SeatTypeColors.clearSeatInlineStyle(btn);
        }
      } else if (window.SeatTypeColors && SeatTypeColors.applyPosSeatColors) {
        SeatTypeColors.applyPosSeatColors(btn.parentElement || document);
      }
    });
  }

  function revertSelection(snapshot, message) {
    selectedSeats = snapshot.map(s => ({
      id: s.id, code: s.code, type: s.type, price: s.price
    }));
    restoreSeatUiFromSelection();
    updateSummarySeats();
    checkProceedBtn();
    if (message) alert(message);
  }

  function clearSeats() {
    stopSeatRefresh();
    stopCountdown();
    selectedSeats = [];
    document.getElementById('seatArea').innerHTML =
      '<div class="pos-seat-placeholder" id="seatPlaceholder">' +
      '<div class="placeholder-icon">\ud83c\udfac</div>' +
      '<div>Ch\u1ecdn su\u1ea5t chi\u1ebfu \u0111\u1ec3 xem s\u01a1 \u0111\u1ed3 gh\u1ebf</div></div>';
    const legend = document.getElementById('posSeatLegend');
    if (legend) {
      legend.innerHTML =
        '<span class="legend-item"><span class="leg-dot leg-selected"></span>\u0110ang ch\u1ecdn</span>' +
        '<span class="legend-item"><span class="leg-dot leg-sold"></span>\u0110\u00e3 b\u00e1n</span>';
    }
    updateSummarySeats();
  }

  function clearShowtimes() {
    selectedShowtimeId = null;
    selectedDate = null;
    showtimesAll = [];
    document.getElementById('showtimePicker').style.display = 'none';
    document.getElementById('dateTabs').innerHTML = '';
    document.getElementById('timeGrid').innerHTML = '';
  }

  // \u2500\u2500 Summary panel \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function updateSummaryMovie() {
    const el = document.getElementById('summaryMovie');
    if (!selectedMovieId) {
      el.innerHTML = '<div class="pos-summary-placeholder">Ch\u01b0a ch\u1ecdn phim</div>';
      return;
    }
    el.innerHTML = `
      <div class="summary-movie-box">
        <div class="summary-movie-title">${escHtml(selectedMovieTitle)}</div>
        ${selectedShowtimeId ? `
          <div class="summary-show-info">
            <span>${escHtml(selectedStartTime)}</span>
            <span>${escHtml(selectedRoomName)}</span>
          </div>` : '<div class="summary-show-info text-dim">Ch\u01b0a ch\u1ecdn su\u1ea5t</div>'}
      </div>`;
  }

  function updateSummarySeats() {
    const listEl = document.getElementById('seatSummaryList');
    if (selectedSeats.length === 0) {
      listEl.innerHTML = '<span class="pos-empty-small">Ch\u01b0a c\u00f3 gh\u1ebf n\u00e0o</span>';
    } else {
      listEl.innerHTML = selectedSeats.map(s => `
        <div class="pos-seat-summary-row">
          <span>${escHtml(s.type)} \u2014 ${escHtml(s.code)}</span>
          <span>${formatVnd(s.price)}</span>
        </div>`).join('');
    }

    const rawTotal   = selectedSeats.reduce((sum, s) => sum + s.price, 0);
    const discount   = appliedPoints > 0 ? (appliedPoints / 100) * 10000 : 0;
    const finalTotal = Math.max(0, rawTotal - discount);

    const discRow     = document.getElementById('pointsDiscountRow');
    const discDisplay = document.getElementById('pointsDiscountDisplay');
    const discLabel   = document.getElementById('pointsDiscountLabel');
    if (discRow) discRow.style.display = discount > 0 ? '' : 'none';
    if (discount > 0) {
      if (discDisplay) discDisplay.textContent = '-' + formatVnd(discount);
      if (discLabel)   discLabel.textContent   = `Gi\u1ea3m (${appliedPoints.toLocaleString('vi-VN')} \u0111i\u1ec3m)`;
    }

    document.getElementById('totalDisplay').textContent = formatVnd(finalTotal);
  }

  // \u2500\u2500 Voucher / Khuy\u1ebfn m\u00e3i \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function resetVoucherSection() {
    appliedVoucherCode    = '';
    voucherDiscountAmount = 0;
    var inp = document.getElementById('voucherCodeInput');
    if (inp) inp.value = '';
    var res = document.getElementById('voucherResult');
    if (res) { res.textContent = ''; res.style.display = 'none'; }
    var row = document.getElementById('voucherDiscountRow');
    if (row) row.style.display = 'none';
    updateSummarySeats();
  }

  window.checkVoucher = function () {
    var inp = document.getElementById('voucherCodeInput');
    var res = document.getElementById('voucherResult');
    if (!inp || !res) return;
    var code = inp.value.trim().toUpperCase();
    if (!code) {
      res.style.display = 'block';
      res.style.color   = '#ef9a9a';
      res.textContent   = 'Vui l\u00f2ng nh\u1eadp m\u00e3 voucher.';
      return;
    }
    if (selectedSeats.length === 0) {
      res.style.display = 'block';
      res.style.color   = '#ef9a9a';
      res.textContent   = 'Vui l\u00f2ng ch\u1ecdn gh\u1ebf tr\u01b0\u1edbc khi \u00e1p d\u1ee5ng voucher.';
      return;
    }
    var rawTotal = selectedSeats.reduce(function (s, seat) { return s + seat.price; }, 0);
    res.style.display  = 'block';
    res.style.color    = '#aaa';
    res.textContent    = '\u0110ang ki\u1ec3m tra...';

    fetch(CTX + '/staff/counter?action=checkVoucher&code=' + encodeURIComponent(code)
                + '&total=' + rawTotal)
      .then(function (r) {
        var ct = r.headers.get('content-type') || '';
        if (!ct.includes('application/json')) {
          throw new Error('not-json');
        }
        return r.json();
      })
      .then(function (data) {
        if (data.valid) {
          appliedVoucherCode    = data.code;
          voucherDiscountAmount = data.discount;
          res.style.color = '#66bb6a';
          res.textContent = '\u2713 ' + data.code + ' \u2014 ' + escHtml(data.title)
                          + ': \u2212' + formatVnd(data.discount);
          updateSummarySeats();
        } else {
          appliedVoucherCode    = '';
          voucherDiscountAmount = 0;
          res.style.color = '#ef9a9a';
          res.textContent = data.error || 'M\u00e3 voucher kh\u00f4ng h\u1ee3p l\u1ec7.';
          updateSummarySeats();
        }
      })
      .catch(function (err) {
        appliedVoucherCode    = '';
        voucherDiscountAmount = 0;
        res.style.color = '#ef9a9a';
        if (err && err.message === 'not-json') {
          res.textContent = '\u1ee8ng d\u1ee5ng c\u1ea7n \u0111\u01b0\u1ee3c rebuild \u0111\u1ec3 d\u00f9ng t\u00ednh n\u0103ng voucher.';
        } else {
          res.textContent = 'L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.';
        }
      });
  };

  // \u2500\u2500 FR-42: Member Lookup \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  window.lookupMember = function () {
    const phone = (document.getElementById('lookupPhone')?.value ?? '').trim();
    const resultEl = document.getElementById('memberResult');
    if (!phone) return;

    resultEl.style.display = 'block';
    resultEl.className = 'pos-member-result pos-member-result--loading';
    resultEl.textContent = '\u0110ang tra c\u1ee9u...';

    fetch(`${CTX}/staff/counter?action=lookup&phone=${encodeURIComponent(phone)}`)
      .then(r => r.json())
      .then(data => {
        if (data.found) {
          document.getElementById('custName').value     = data.fullName;
          document.getElementById('custPhone').value    = data.phone || phone;
          document.getElementById('formMemberId').value = data.userId;

          // Backend kh\u00f3a t\u00e0i kho\u1ea3n b\u1eb1ng status=BANNED (UserStatusServlet), kh\u00f4ng d\u00f9ng LOCKED
          const isLocked  = data.status === 'BANNED' || data.status === 'INACTIVE';
          memberLocked = isLocked;
          const statusBadge = data.status === 'BANNED'
            ? `<span class="member-status-badge member-status-badge--locked">\u0110\u00e3 kh\u00f3a</span>`
            : data.status === 'INACTIVE'
            ? `<span class="member-status-badge member-status-badge--locked">Ng\u1eebng ho\u1ea1t \u0111\u1ed9ng</span>`
            : `<span class="member-status-badge member-status-badge--active">Ho\u1ea1t \u0111\u1ed9ng</span>`;

          memberPointsBalance = data.loyaltyPoints || 0;
          resultEl.className = 'pos-member-result pos-member-result--found';
          resultEl.innerHTML = `
            <div class="member-card">
              <div class="member-card-avatar">${escHtml(data.fullName.charAt(0).toUpperCase())}</div>
              <div class="member-card-info">
                <div class="member-card-name">
                  <span class="member-badge">&#9733; TH\u00c0NH VI\u00caN</span>
                  <strong>${escHtml(data.fullName)}</strong>
                  ${statusBadge}
                </div>
                ${data.email ? `<div class="member-card-row" style="word-break:break-all"><span class="member-card-icon">\u2709</span>${escHtml(data.email)}</div>` : ''}
                <div class="member-card-row"><span class="member-card-icon">\ud83d\udcf1</span>${escHtml(data.phone || phone)}</div>
                <div class="member-card-row member-card-points">
                  <span class="member-card-icon">\u2605</span>
                  <strong>${memberPointsBalance.toLocaleString('vi-VN')}</strong>&nbsp;\u0111i\u1ec3m t\u00edch lu\u1ef9
                </div>
                ${data.joinedDate ? `<div class="member-card-row member-card-joined">Tham gia: ${escHtml(data.joinedDate)}</div>` : ''}
              </div>
            </div>`;

          // Show loyalty section (ch\u1ec9 hi\u1ec7n khi kh\u00f4ng b\u1ecb kh\u00f3a)
          if (!isLocked) {
            const loyaltySection = document.getElementById('loyaltySection');
            if (loyaltySection) loyaltySection.style.display = '';
            const balanceEl = document.getElementById('loyaltyBalanceInfo');
            if (balanceEl) balanceEl.textContent = `S\u1ed1 d\u01b0: ${memberPointsBalance.toLocaleString('vi-VN')} \u0111i\u1ec3m`;
            document.getElementById('loyaltyPointsInput').value = '';
            document.getElementById('loyaltyDiscountPreview').textContent = '';
          }
        } else {
          memberLocked = false;
          document.getElementById('formMemberId').value = '';
          resetLoyaltySection();
          resultEl.className = 'pos-member-result pos-member-result--notfound';
          resultEl.innerHTML = `
            <div class="member-notfound">
              <span class="member-notfound-icon">?</span>
              <div>
                <div style="font-weight:600;color:#ef9a9a">Kh\u00f4ng t\u00ecm th\u1ea5y th\u00e0nh vi\u00ean</div>
                <div style="font-size:12px;color:#888;margin-top:2px">S\u0110T <strong>${escHtml(phone)}</strong> ch\u01b0a \u0111\u0103ng k\u00fd t\u00e0i kho\u1ea3n</div>
              </div>
            </div>`;
          document.getElementById('custPhone').value = phone;
        }
        checkProceedBtn();
      })
      .catch(() => {
        resultEl.className = 'pos-member-result pos-member-result--notfound';
        resultEl.textContent = 'L\u1ed7i tra c\u1ee9u. Vui l\u00f2ng nh\u1eadp tay th\u00f4ng tin kh\u00e1ch.';
      });
  };

  // \u2500\u2500 Proceed to payment \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  window.checkProceedBtn = function () {
    const pendingBlock = showtimeHasPendingBooking(selectedShowtimeId);
    const seatsOk = selectedSeats.length > 0 && selectedShowtimeId && !pendingBlock;
    const btn = document.getElementById('proceedBtn');
    if (btn) btn.disabled = !seatsOk || memberLocked;

    const warn = document.getElementById('memberLockedWarn');
    if (warn) warn.style.display = memberLocked ? 'block' : 'none';
  };

  window.proceedToPayment = function () {
    if (showtimeHasPendingBooking(selectedShowtimeId)) {
      alert('Su\u1ea5t n\u00e0y \u0111\u00e3 c\u00f3 \u0111\u01a1n \u0111ang ch\u1edd thanh to\u00e1n. H\u00e3y Ti\u1ebfp t\u1ee5c ho\u1eb7c H\u1ee7y \u0111\u01a1n \u0111\u00f3 tr\u01b0\u1edbc.');
      return;
    }
    const name  = (document.getElementById('custName')?.value ?? '').trim() || 'Kh\u00e1ch v\u00e3ng lai';
    const phone = (document.getElementById('custPhone')?.value ?? '').trim();
    if (!selectedShowtimeId || selectedSeats.length === 0) return;

    const form = document.getElementById('bookingForm');
    document.getElementById('formShowtimeId').value    = selectedShowtimeId;
    document.getElementById('formCustName').value      = name;
    document.getElementById('formCustPhone').value     = phone;
    document.getElementById('formPointsToRedeem').value = appliedPoints;
    document.getElementById('formVoucherCode').value     = appliedVoucherCode;

    form.querySelectorAll('input[name="seatIds"], input[name="seatPrices"]')
        .forEach(el => el.remove());

    selectedSeats.forEach(seat => {
      append(form, 'seatIds',    seat.id);
      append(form, 'seatPrices', seat.price);
    });

    form.submit();
  };

  // \u2500\u2500 Loyalty Points \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function resetLoyaltySection() {
    appliedPoints = 0;
    memberPointsBalance = 0;
    const section = document.getElementById('loyaltySection');
    if (section) section.style.display = 'none';
    const inp = document.getElementById('loyaltyPointsInput');
    if (inp) inp.value = '';
    const preview = document.getElementById('loyaltyDiscountPreview');
    if (preview) preview.textContent = '';
    updateSummarySeats();
  }

  window.updateLoyaltyDiscount = function () {
    const inp = document.getElementById('loyaltyPointsInput');
    const preview = document.getElementById('loyaltyDiscountPreview');
    if (!inp || !preview) return;
    const pts = Math.max(0, parseInt(inp.value) || 0);
    const effective = Math.floor(pts / 100) * 100;
    if (effective >= 100) {
      const disc = (effective / 100) * 10000;
      preview.style.color = '#aaa';
      preview.textContent = `\u2192 Gi\u1ea3m ${formatVnd(disc)} (${effective.toLocaleString('vi-VN')} \u0111i\u1ec3m)`;
    } else {
      preview.textContent = '';
    }
  };

  window.applyLoyaltyPoints = function () {
    const inp = document.getElementById('loyaltyPointsInput');
    if (!inp) return;
    const pts = Math.max(0, parseInt(inp.value) || 0);
    const effective = Math.floor(pts / 100) * 100;

    if (pts > 0 && effective < 100) {
      alert('\u0110i\u1ec3m t\u1ed1i thi\u1ec3u \u0111\u1ec3 \u0111\u1ed5i l\u00e0 100 \u0111i\u1ec3m.');
      return;
    }
    if (effective > memberPointsBalance) {
      alert(`S\u1ed1 \u0111i\u1ec3m nh\u1eadp (${effective.toLocaleString('vi-VN')}) v\u01b0\u1ee3t qu\u00e1 s\u1ed1 d\u01b0 (${memberPointsBalance.toLocaleString('vi-VN')} \u0111i\u1ec3m).`);
      return;
    }
    if (effective > 5000) {
      alert('T\u1ed1i \u0111a 5.000 \u0111i\u1ec3m m\u1ed7i \u0111\u01a1n h\u00e0ng.');
      inp.value = 5000;
      return;
    }

    appliedPoints = effective;
    updateSummarySeats();

    const preview = document.getElementById('loyaltyDiscountPreview');
    if (preview) {
      if (appliedPoints > 0) {
        preview.style.color = '#66bb6a';
        preview.textContent = `\u2713 \u0110\u00e3 \u00e1p d\u1ee5ng: -${formatVnd((appliedPoints / 100) * 10000)}`;
      } else {
        preview.textContent = 'Kh\u00f4ng \u00e1p d\u1ee5ng \u0111i\u1ec3m.';
        preview.style.color = '#aaa';
      }
    }
  };

  // \u2500\u2500 Seat hold sync (gi\u1ed1ng customer checkout) \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function syncHoldsWithServer(showtimeId, revertSnapshot, seatIdsOverride) {
    if (!showtimeId) return;

    const seatIds = seatIdsOverride !== undefined
      ? seatIdsOverride
      : selectedSeats.map(s => s.id);

    holdSyncing = true;
    const body = new URLSearchParams();
    body.append('action', 'holdSeats');
    body.append('showtimeId', showtimeId);
    seatIds.forEach(id => body.append('seatIds', id));

    fetch(`${CTX}/staff/counter`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8' },
      body: body.toString()
    })
      .then(r => r.json().then(data => ({ httpOk: r.ok, data })).catch(() => ({
        httpOk: r.ok,
        data: { ok: false, error: 'Ph\u1ea3n h\u1ed3i kh\u00f4ng h\u1ee3p l\u1ec7 t\u1eeb m\u00e1y ch\u1ee7' }
      })))
      .then(res => {
        holdSyncing = false;
        if (!res.data || !res.data.ok) {
          if (revertSnapshot) {
            const msg = (res.data && res.data.error) || 'Kh\u00f4ng th\u1ec3 gi\u1eef gh\u1ebf';
            revertSelection(revertSnapshot, msg);
          }
          if (res.data && res.data.blocked && selectedShowtimeId === showtimeId) {
            loadSeats(showtimeId);
          }
          return;
        }
        if (res.data.expiresAt) {
          startCountdown(res.data.expiresAt);
        } else {
          stopCountdown();
        }
      })
      .catch(() => {
        holdSyncing = false;
        if (revertSnapshot) {
          revertSelection(revertSnapshot, 'L\u1ed7i k\u1ebft n\u1ed1i. Vui l\u00f2ng th\u1eed l\u1ea1i.');
        }
      });
  }

  // \u2500\u2500 Seat hold countdown \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  let holdExpiryMs  = null;
  let countdownTimer = null;

  function startCountdown(expiryMs) {
    holdExpiryMs = expiryMs;
    clearInterval(countdownTimer);
    tickCountdown();
    countdownTimer = setInterval(tickCountdown, 1000);
  }

  function stopCountdown() {
    holdExpiryMs = null;
    clearInterval(countdownTimer);
    countdownTimer = null;
    var el = document.getElementById('holdCountdown');
    if (el) el.style.display = 'none';
  }

  function tickCountdown() {
    var el = document.getElementById('holdCountdown');
    var timeEl = document.getElementById('holdTime');
    if (!el || !timeEl || !holdExpiryMs) return;

    var remaining = Math.max(0, holdExpiryMs - Date.now());
    var totalSecs = Math.floor(remaining / 1000);
    var mins = Math.floor(totalSecs / 60);
    var secs = totalSecs % 60;

    timeEl.textContent = String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0');
    el.style.display = 'flex';
    el.classList.toggle('hold-countdown--warn', totalSecs < 60);

    if (remaining === 0) {
      clearInterval(countdownTimer);
      countdownTimer = null;
      holdExpiryMs = null;
      selectedSeats = [];
      restoreSeatUiFromSelection();
      updateSummarySeats();
      checkProceedBtn();
      el.style.display = 'none';
      if (selectedShowtimeId) loadSeats(selectedShowtimeId);
    }
  }

  // \u2500\u2500 Utils \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
  function append(form, name, value) {
    const inp = document.createElement('input');
    inp.type  = 'hidden';
    inp.name  = name;
    inp.value = value;
    form.appendChild(inp);
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
