/* ============================================================
   Counter POS — FR-35 / FR-36 / FR-38
   3-panel layout: movie list → showtimes → seat map → summary
   ============================================================ */
(function () {
  'use strict';

  const CTX = document.querySelector('meta[name="ctx"]')?.content ?? '';

  // ── State ──────────────────────────────────────────────────────
  let selectedMovieEl  = null;
  let selectedMovieId  = null;
  let selectedMovieTitle = '';
  let showtimesAll     = [];   // all showtimes for the selected movie
  let selectedDate     = null;
  let selectedShowtimeId = null;
  let selectedRoomName = '';
  let selectedStartTime = '';
  let selectedSeats    = [];   // [{id, code, type, price}]

  // ── Movie tab / search ─────────────────────────────────────────
  window.switchTab = function (tab) {
    document.getElementById('tabNowShowing').classList.toggle('pos-tab--active', tab === 'now');
    document.getElementById('tabComingSoon').classList.toggle('pos-tab--active', tab === 'coming');
    filterMoviesByTab(tab);
  };

  window.filterMovies = function (query) {
    const q = query.toLowerCase();
    document.querySelectorAll('.pos-movie-item').forEach(el => {
      const title = el.dataset.movieTitle ?? '';
      el.style.display = title.includes(q) ? '' : 'none';
    });
  };

  function filterMoviesByTab(tab) {
    document.querySelectorAll('.pos-movie-item').forEach(el => {
      const status = (el.dataset.movieStatus ?? '').toUpperCase();
      if (tab === 'now') {
        el.style.display = status.includes('COMING') ? 'none' : '';
      } else {
        el.style.display = status.includes('COMING') ? '' : 'none';
      }
    });
  }

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
      document.getElementById('dateTabs').innerHTML =
        '<div class="pos-empty-small">Không có suất nào.</div>';
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
      .then(renderSeatMap)
      .catch(() => {
        area.innerHTML = '<div class="pos-seat-placeholder">Không tải được sơ đồ ghế.</div>';
      });
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

        const type = (seat.typeName ?? 'STANDARD').toUpperCase();
        const btn  = document.createElement('button');
        btn.className = `pos-seat-btn pos-seat--${type.toLowerCase()}`;
        btn.dataset.seatId   = seat.id;
        btn.dataset.seatCode = seat.seatCode;
        btn.dataset.seatType = type;
        btn.dataset.price    = seat.ticketPrice ?? 0;
        btn.textContent      = seat.seatCode;

        if (!seat.available) {
          btn.classList.add('pos-seat--sold');
          btn.disabled = true;
        } else {
          btn.addEventListener('click', () => toggleSeat(btn));
        }
        cells.appendChild(btn);
        expectedCol = col + 1;
      });

      rowDiv.appendChild(cells);
      area.appendChild(rowDiv);
    });
  }

  function toggleSeat(btn) {
    const idx = selectedSeats.findIndex(s => s.id === btn.dataset.seatId);
    if (idx >= 0) {
      selectedSeats.splice(idx, 1);
      btn.classList.remove('pos-seat--selected');
    } else {
      selectedSeats.push({
        id:    btn.dataset.seatId,
        code:  btn.dataset.seatCode,
        type:  btn.dataset.seatType,
        price: parseFloat(btn.dataset.price) || 0
      });
      btn.classList.add('pos-seat--selected');
    }
    updateSummarySeats();
    checkProceedBtn();
  }

  function clearSeats() {
    selectedSeats = [];
    document.getElementById('seatArea').innerHTML =
      '<div class="pos-seat-placeholder" id="seatPlaceholder">' +
      '<div class="placeholder-icon">🎬</div>' +
      '<div>Chọn suất chiếu để xem sơ đồ ghế</div></div>';
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

    const total = selectedSeats.reduce((sum, s) => sum + s.price, 0);
    document.getElementById('totalDisplay').textContent = formatVnd(total);
  }

  // ── Proceed to payment ─────────────────────────────────────────
  window.checkProceedBtn = function () {
    const name  = (document.getElementById('custName')?.value ?? '').trim();
    const phone = (document.getElementById('custPhone')?.value ?? '').trim();
    const ok    = selectedSeats.length > 0 && name && phone && selectedShowtimeId;
    document.getElementById('proceedBtn').disabled = !ok;
  };

  window.proceedToPayment = function () {
    const name  = (document.getElementById('custName')?.value ?? '').trim();
    const phone = (document.getElementById('custPhone')?.value ?? '').trim();
    if (!selectedShowtimeId || selectedSeats.length === 0 || !name || !phone) return;

    const form = document.getElementById('bookingForm');
    document.getElementById('formShowtimeId').value = selectedShowtimeId;
    document.getElementById('formCustName').value   = name;
    document.getElementById('formCustPhone').value  = phone;

    form.querySelectorAll('input[name="seatIds"], input[name="seatPrices"]')
        .forEach(el => el.remove());

    selectedSeats.forEach(seat => {
      append(form, 'seatIds',    seat.id);
      append(form, 'seatPrices', seat.price);
    });

    form.submit();
  };

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
