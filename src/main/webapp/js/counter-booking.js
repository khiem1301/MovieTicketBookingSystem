/* ============================================================
   Counter POS — FR-35 / FR-36 / FR-38
   3-panel layout: movie list → showtimes → seat map → summary
   ============================================================ */
(function () {
  'use strict';

  const CTX = document.querySelector('meta[name="ctx"]')?.content ?? '';

  // ── State ──────────────────────────────────────────────────────
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
  let appliedPoints    = 0;    // điểm đã áp dụng để trừ tiền
  let memberPointsBalance = 0; // số dư điểm của thành viên
  let appliedVoucherCode   = '';  // mã voucher đang áp dụng
  let voucherDiscountAmount = 0;  // số tiền giảm từ voucher (VND)
  let holdSyncing          = false;
  const SEAT_REFRESH_MS    = 2000;
  let seatRefreshTimer     = null;

  // ── Movie tab / search ─────────────────────────────────────────
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
      const tabName = activeTab === 'coming' ? 'Sắp chiếu' : 'Đang chiếu';
      emptyEl.textContent = q ? 'Không tìm thấy phim phù hợp.' : `Không có phim ${tabName}.`;
      emptyEl.style.display = '';
    } else {
      emptyEl.style.display = 'none';
    }
  };

  // ── Movie selection ────────────────────────────────────────────
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
        loading.textContent = 'Không tải được suất chiếu.';
      });
  }

  // ── Showtime / Date selection ──────────────────────────────────
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
        '<div class="placeholder-icon">📅</div>' +
        '<div>Phim này chưa có lịch chiếu.<br/>' +
        '<small>Quản lý cần tạo lịch chiếu trước.</small></div></div>';
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
        <div class="date-tab-day">${isToday ? 'HÔM NAY' : weekday(d)}</div>
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
      grid.innerHTML = '<div class="pos-empty-small">Không có suất cho ngày này.</div>';
    }
  }

  function selectShowtime(st) {
    if (st.status === 'CANCELLED') {
      alert(`Suất chiếu ${st.time} đã bị hủy, không thể đặt vé.`);
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
    loadSeats(st.id);
  }

  // ── Seat map ────────────────────────────────────────────────────
  function loadSeats(showtimeId) {
    const area = document.getElementById('seatArea');
    area.innerHTML = '<div class="pos-loading-seats">Đang tải sơ đồ ghế...</div>';

    fetch(`${CTX}/staff/counter?action=seats&showtimeId=${encodeURIComponent(showtimeId)}`)
      .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
      .then(rows => {
        renderSeatMap(rows);
        startSeatRefresh(showtimeId);
      })
      .catch(() => {
        stopSeatRefresh();
        area.innerHTML = '<div class="pos-seat-placeholder">Không tải được sơ đồ ghế.</div>';
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
      area.innerHTML = '<div class="pos-seat-placeholder">Phòng chưa có ghế nào.</div>';
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
    // Bỏ ghế đã bán khỏi selection nếu map vừa refresh
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
      '<span class="legend-item"><span class="leg-dot leg-selected"></span>Đang chọn</span>' +
      '<span class="legend-item"><span class="leg-dot leg-sold"></span>Đã bán</span>';
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
        alert(`Tối đa ${MAX_SEATS} ghế mỗi lần đặt.`);
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
      '<div class="placeholder-icon">🎬</div>' +
      '<div>Chọn suất chiếu để xem sơ đồ ghế</div></div>';
    const legend = document.getElementById('posSeatLegend');
    if (legend) {
      legend.innerHTML =
        '<span class="legend-item"><span class="leg-dot leg-selected"></span>Đang chọn</span>' +
        '<span class="legend-item"><span class="leg-dot leg-sold"></span>Đã bán</span>';
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

  // ── Summary panel ───────────────────────────────────────────────
  function updateSummaryMovie() {
    const el = document.getElementById('summaryMovie');
    if (!selectedMovieId) {
      el.innerHTML = '<div class="pos-summary-placeholder">Chưa chọn phim</div>';
      return;
    }
    el.innerHTML = `
      <div class="summary-movie-box">
        <div class="summary-movie-title">${escHtml(selectedMovieTitle)}</div>
        ${selectedShowtimeId ? `
          <div class="summary-show-info">
            <span>${escHtml(selectedStartTime)}</span>
            <span>${escHtml(selectedRoomName)}</span>
          </div>` : '<div class="summary-show-info text-dim">Chưa chọn suất</div>'}
      </div>`;
  }

  function updateSummarySeats() {
    const listEl = document.getElementById('seatSummaryList');
    if (selectedSeats.length === 0) {
      listEl.innerHTML = '<span class="pos-empty-small">Chưa có ghế nào</span>';
    } else {
      listEl.innerHTML = selectedSeats.map(s => `
        <div class="pos-seat-summary-row">
          <span>${escHtml(s.type)} — ${escHtml(s.code)}</span>
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
      if (discLabel)   discLabel.textContent   = `Giảm (${appliedPoints.toLocaleString('vi-VN')} điểm)`;
    }

    document.getElementById('totalDisplay').textContent = formatVnd(finalTotal);
  }

  // ── Voucher / Khuyến mãi ───────────────────────────────────────────────
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
      res.textContent   = 'Vui lòng nhập mã voucher.';
      return;
    }
    if (selectedSeats.length === 0) {
      res.style.display = 'block';
      res.style.color   = '#ef9a9a';
      res.textContent   = 'Vui lòng chọn ghế trước khi áp dụng voucher.';
      return;
    }
    var rawTotal = selectedSeats.reduce(function (s, seat) { return s + seat.price; }, 0);
    res.style.display  = 'block';
    res.style.color    = '#aaa';
    res.textContent    = 'Đang kiểm tra...';

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
          res.textContent = '✓ ' + data.code + ' — ' + escHtml(data.title)
                          + ': −' + formatVnd(data.discount);
          updateSummarySeats();
        } else {
          appliedVoucherCode    = '';
          voucherDiscountAmount = 0;
          res.style.color = '#ef9a9a';
          res.textContent = data.error || 'Mã voucher không hợp lệ.';
          updateSummarySeats();
        }
      })
      .catch(function (err) {
        appliedVoucherCode    = '';
        voucherDiscountAmount = 0;
        res.style.color = '#ef9a9a';
        if (err && err.message === 'not-json') {
          res.textContent = 'Ứng dụng cần được rebuild để dùng tính năng voucher.';
        } else {
          res.textContent = 'Lỗi kết nối. Vui lòng thử lại.';
        }
      });
  };

  // ── FR-42: Member Lookup ────────────────────────────────────────
  window.lookupMember = function () {
    const phone = (document.getElementById('lookupPhone')?.value ?? '').trim();
    const resultEl = document.getElementById('memberResult');
    if (!phone) return;

    resultEl.style.display = 'block';
    resultEl.className = 'pos-member-result pos-member-result--loading';
    resultEl.textContent = 'Đang tra cứu...';

    fetch(`${CTX}/staff/counter?action=lookup&phone=${encodeURIComponent(phone)}`)
      .then(r => r.json())
      .then(data => {
        if (data.found) {
          document.getElementById('custName').value     = data.fullName;
          document.getElementById('custPhone').value    = data.phone || phone;
          document.getElementById('formMemberId').value = data.userId;

          // Backend khóa tài khoản bằng status=BANNED (UserStatusServlet), không dùng LOCKED
          const isLocked  = data.status === 'BANNED' || data.status === 'INACTIVE';
          memberLocked = isLocked;
          const statusBadge = data.status === 'BANNED'
            ? `<span class="member-status-badge member-status-badge--locked">Đã khóa</span>`
            : data.status === 'INACTIVE'
            ? `<span class="member-status-badge member-status-badge--locked">Ngừng hoạt động</span>`
            : `<span class="member-status-badge member-status-badge--active">Hoạt động</span>`;

          memberPointsBalance = data.loyaltyPoints || 0;
          resultEl.className = 'pos-member-result pos-member-result--found';
          resultEl.innerHTML = `
            <div class="member-card">
              <div class="member-card-avatar">${escHtml(data.fullName.charAt(0).toUpperCase())}</div>
              <div class="member-card-info">
                <div class="member-card-name">
                  <span class="member-badge">&#9733; THÀNH VIÊN</span>
                  <strong>${escHtml(data.fullName)}</strong>
                  ${statusBadge}
                </div>
                ${data.email ? `<div class="member-card-row" style="word-break:break-all"><span class="member-card-icon">✉</span>${escHtml(data.email)}</div>` : ''}
                <div class="member-card-row"><span class="member-card-icon">📱</span>${escHtml(data.phone || phone)}</div>
                <div class="member-card-row member-card-points">
                  <span class="member-card-icon">★</span>
                  <strong>${memberPointsBalance.toLocaleString('vi-VN')}</strong>&nbsp;điểm tích luỹ
                </div>
                ${data.joinedDate ? `<div class="member-card-row member-card-joined">Tham gia: ${escHtml(data.joinedDate)}</div>` : ''}
              </div>
            </div>`;

          // Show loyalty section (chỉ hiện khi không bị khóa)
          if (!isLocked) {
            const loyaltySection = document.getElementById('loyaltySection');
            if (loyaltySection) loyaltySection.style.display = '';
            const balanceEl = document.getElementById('loyaltyBalanceInfo');
            if (balanceEl) balanceEl.textContent = `Số dư: ${memberPointsBalance.toLocaleString('vi-VN')} điểm`;
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
                <div style="font-weight:600;color:#ef9a9a">Không tìm thấy thành viên</div>
                <div style="font-size:12px;color:#888;margin-top:2px">SĐT <strong>${escHtml(phone)}</strong> chưa đăng ký tài khoản</div>
              </div>
            </div>`;
          document.getElementById('custPhone').value = phone;
        }
        checkProceedBtn();
      })
      .catch(() => {
        resultEl.className = 'pos-member-result pos-member-result--notfound';
        resultEl.textContent = 'Lỗi tra cứu. Vui lòng nhập tay thông tin khách.';
      });
  };

  // ── Proceed to payment ─────────────────────────────────────────
  window.checkProceedBtn = function () {
    const seatsOk = selectedSeats.length > 0 && selectedShowtimeId;
    const btn = document.getElementById('proceedBtn');
    btn.disabled = !seatsOk || memberLocked;

    const warn = document.getElementById('memberLockedWarn');
    if (warn) warn.style.display = memberLocked ? 'block' : 'none';
  };

  window.proceedToPayment = function () {
    const name  = (document.getElementById('custName')?.value ?? '').trim() || 'Khách vãng lai';
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

  // ── Loyalty Points ──────────────────────────────────────────
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
      preview.textContent = `→ Giảm ${formatVnd(disc)} (${effective.toLocaleString('vi-VN')} điểm)`;
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
      alert('Điểm tối thiểu để đổi là 100 điểm.');
      return;
    }
    if (effective > memberPointsBalance) {
      alert(`Số điểm nhập (${effective.toLocaleString('vi-VN')}) vượt quá số dư (${memberPointsBalance.toLocaleString('vi-VN')} điểm).`);
      return;
    }
    if (effective > 5000) {
      alert('Tối đa 5.000 điểm mỗi đơn hàng.');
      inp.value = 5000;
      return;
    }

    appliedPoints = effective;
    updateSummarySeats();

    const preview = document.getElementById('loyaltyDiscountPreview');
    if (preview) {
      if (appliedPoints > 0) {
        preview.style.color = '#66bb6a';
        preview.textContent = `✓ Đã áp dụng: -${formatVnd((appliedPoints / 100) * 10000)}`;
      } else {
        preview.textContent = 'Không áp dụng điểm.';
        preview.style.color = '#aaa';
      }
    }
  };

  // ── Seat hold sync (giống customer checkout) ─────────────────────
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
        data: { ok: false, error: 'Phản hồi không hợp lệ từ máy chủ' }
      })))
      .then(res => {
        holdSyncing = false;
        if (!res.data || !res.data.ok) {
          if (revertSnapshot) {
            const msg = (res.data && res.data.error) || 'Không thể giữ ghế';
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
          revertSelection(revertSnapshot, 'Lỗi kết nối. Vui lòng thử lại.');
        }
      });
  }

  // ── Seat hold countdown ─────────────────────────────────────────
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

  // ── Utils ───────────────────────────────────────────────────────
  function append(form, name, value) {
    const inp = document.createElement('input');
    inp.type  = 'hidden';
    inp.name  = name;
    inp.value = value;
    form.appendChild(inp);
  }

  function formatVnd(n) {
    return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + ' ₫';
  }

  function escHtml(str) {
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

}());
