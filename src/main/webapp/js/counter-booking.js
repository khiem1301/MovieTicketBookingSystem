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
      syncHoldsWithServer(selectedShowtimeId, []);
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
    }
    updateSummarySeats();
    checkProceedBtn();

    const ids = selectedSeats.map(s => s.id);
    if (ids.length > 0) {
      // Khởi động đếm ngược ngay lập tức, không chờ server
      if (!holdExpiryMs) startCountdown(Date.now() + 1 * 60 * 1000);
      syncHoldsWithServer(selectedShowtimeId, ids);
    } else {
      stopCountdown();
      syncHoldsWithServer(selectedShowtimeId, []);
    }
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

          const isLocked  = data.status === 'LOCKED' || data.status === 'INACTIVE';
          memberLocked = isLocked;
          const statusBadge = isLocked
            ? `<span class="member-status-badge member-status-badge--locked">Tạm khóa</span>`
            : `<span class="member-status-badge member-status-badge--active">Hoạt động</span>`;

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
                  <strong>${data.loyaltyPoints.toLocaleString('vi-VN')}</strong>&nbsp;điểm tích luỹ
                </div>
                ${data.joinedDate ? `<div class="member-card-row member-card-joined">Tham gia: ${escHtml(data.joinedDate)}</div>` : ''}
              </div>
            </div>`;
        } else {
          memberLocked = false;
          document.getElementById('formMemberId').value = '';
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

  // ── Seat hold sync ──────────────────────────────────────────────
  function syncHoldsWithServer(showtimeId, seatIds) {
    if (!showtimeId) return;
    const fd = new FormData();
    fd.append('action', 'holdSeats');
    fd.append('showtimeId', showtimeId);
    seatIds.forEach(id => fd.append('seatIds', id));

    fetch(`${CTX}/staff/counter`, { method: 'POST', body: fd })
      .then(r => r.json())
      .then(data => {
        if (data && !data.ok && data.blocked) {
          loadSeats(showtimeId);
          stopCountdown();
          alert('Một ghế vừa bị người khác chọn. Sơ đồ ghế đã được cập nhật.');
        } else if (data && data.ok) {
          if (seatIds.length > 0 && data.expiredAt) {
            // Cập nhật lại thời gian chính xác từ server
            startCountdown(data.expiredAt);
          } else if (seatIds.length === 0) {
            stopCountdown();
          }
        }
      })
      .catch(() => { /* bỏ qua lỗi mạng khi giữ chỗ */ });
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
      // Hết giờ — xoá ghế đã chọn, reload sơ đồ
      selectedSeats = [];
      updateSummarySeats();
      checkProceedBtn();
      el.style.display = 'none';
      if (selectedShowtimeId) loadSeats(selectedShowtimeId);
      alert('Thời gian giữ ghế đã hết (1 phút). Vui lòng chọn lại ghế.');
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
