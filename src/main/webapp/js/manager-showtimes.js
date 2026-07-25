(function () {
  'use strict';

  var ROWS_PER_PAGE = 8;
  var CAL_START_HOUR = 8;
  var CAL_END_HOUR = 23;
  var UI_STATE_KEY = 'epcine.manager.showtimes.ui';

  var currentPage = 1;
  var statusFilter = '';
  var dateRange = '7'; // '7' | 'today' | 'all' | 'custom'
  var viewMode = 'list';
  var calendarDate = '';
  var filteredRows = [];
  var restoringUi = false;

  var pageRoot = document.querySelector('.st-page');
  var createModal = document.getElementById('stCreateModal');
  var editModal = document.getElementById('stEditModal');
  var copyModal = document.getElementById('stCopyModal');
  var cancelModal = document.getElementById('stCancelModal');
  var today = pageRoot ? (pageRoot.getAttribute('data-today') || isoToday()) : isoToday();
  var ctx = pageRoot ? (pageRoot.getAttribute('data-ctx') || '') : '';

  function saveUiState() {
    if (restoringUi) return;
    try {
      var searchEl = document.getElementById('stSearch');
      var movieEl = document.getElementById('stFilterMovie');
      var roomEl = document.getElementById('stFilterRoom');
      var dateEl = document.getElementById('stFilterDate');
      sessionStorage.setItem(UI_STATE_KEY, JSON.stringify({
        statusFilter: statusFilter,
        dateRange: dateRange,
        viewMode: viewMode,
        calendarDate: calendarDate,
        currentPage: currentPage,
        search: searchEl ? searchEl.value : '',
        movieId: movieEl ? movieEl.value : '',
        roomId: roomEl ? roomEl.value : '',
        filterDate: dateEl ? dateEl.value : ''
      }));
    } catch (e) { /* ignore quota / private mode */ }
  }

  function readUiState() {
    try {
      var raw = sessionStorage.getItem(UI_STATE_KEY);
      return raw ? JSON.parse(raw) : null;
    } catch (e) {
      return null;
    }
  }

  function setActiveByAttr(selector, attr, value) {
    document.querySelectorAll(selector).forEach(function (el) {
      var match = (el.getAttribute(attr) || '') === (value || '');
      el.classList.toggle('active', match);
    });
  }

  function restoreUiState() {
    var state = readUiState();
    if (!state) return null;

    restoringUi = true;
    try {
      var searchEl = document.getElementById('stSearch');
      var movieEl = document.getElementById('stFilterMovie');
      var roomEl = document.getElementById('stFilterRoom');
      var dateEl = document.getElementById('stFilterDate');

      if (searchEl && typeof state.search === 'string') searchEl.value = state.search;
      if (movieEl && typeof state.movieId === 'string') movieEl.value = state.movieId;
      if (roomEl && typeof state.roomId === 'string') roomEl.value = state.roomId;
      if (dateEl && typeof state.filterDate === 'string') dateEl.value = state.filterDate;

      statusFilter = typeof state.statusFilter === 'string' ? state.statusFilter : '';
      dateRange = state.dateRange || '7';
      viewMode = state.viewMode === 'calendar' ? 'calendar' : 'list';
      calendarDate = state.calendarDate || today;
      currentPage = Math.max(1, parseInt(state.currentPage, 10) || 1);

      setActiveByAttr('.mm-tabs .mm-tab', 'data-filter', statusFilter);
      setActiveByAttr('.st-range-chips .st-chip', 'data-range', dateRange === 'custom' ? '' : dateRange);
      if (dateRange === 'custom') {
        document.querySelectorAll('.st-range-chips .st-chip').forEach(function (c) {
          c.classList.remove('active');
        });
      }
      setActiveByAttr('.st-view-btn', 'data-view', viewMode);

      var listView = document.getElementById('stListView');
      var calView = document.getElementById('stCalendarView');
      if (listView) listView.hidden = viewMode !== 'list';
      if (calView) calView.hidden = viewMode !== 'calendar';
    } finally {
      restoringUi = false;
    }
    return state;
  }

  var rooms = [];
  try {
    var roomsEl = document.getElementById('stRoomsJson');
    if (roomsEl) rooms = JSON.parse(roomsEl.textContent || '[]');
  } catch (e) {
    rooms = [];
  }

  function isoToday() {
    var d = new Date();
    return toIsoDate(d);
  }

  function toIsoDate(d) {
    var m = (d.getMonth() + 1);
    var day = d.getDate();
    return d.getFullYear() + '-' + pad(m) + '-' + pad(day);
  }

  function pad(n) {
    return n < 10 ? '0' + n : String(n);
  }

  function addDays(iso, days) {
    var p = iso.split('-').map(Number);
    var d = new Date(p[0], p[1] - 1, p[2]);
    d.setDate(d.getDate() + days);
    return toIsoDate(d);
  }

  function parseIso(iso) {
    var p = iso.split('-').map(Number);
    return new Date(p[0], p[1] - 1, p[2]);
  }

  function formatViDate(iso) {
    var p = iso.split('-');
    if (p.length !== 3) return iso;
    return p[2] + '/' + p[1] + '/' + p[0];
  }

  function anyModalOpen() {
    return [createModal, editModal, copyModal, cancelModal].some(function (m) {
      return m && m.classList.contains('open');
    });
  }

  function bindDurationHint(selectId, hintId) {
    var select = document.getElementById(selectId);
    var hint = document.getElementById(hintId);
    if (!select || !hint) return;

    function update() {
      var opt = select.options[select.selectedIndex];
      var dur = opt && opt.dataset.duration ? parseInt(opt.dataset.duration, 10) : 0;
      hint.textContent = dur > 0
        ? ('Thời lượng phim: ' + dur + ' phút — giờ kết thúc tự tính.')
        : '';
    }

    select.addEventListener('change', update);
    update();
  }

  function openModal(el) {
    if (!el) return;
    el.classList.add('open');
    el.setAttribute('aria-hidden', 'false');
    document.body.classList.add('st-modal-open');
  }

  function closeModal(el) {
    if (!el) return;
    el.classList.remove('open');
    el.setAttribute('aria-hidden', 'true');
    if (!anyModalOpen()) document.body.classList.remove('st-modal-open');
  }

  window.openCreateModal = function () {
    closeModal(editModal);
    closeModal(copyModal);
    openModal(createModal);
  };

  window.closeCreateModal = function () {
    closeModal(createModal);
  };

  window.closeEditModal = function () {
    closeModal(editModal);
  };

  function setEditLocked(locked, bookingCount) {
    var movieSel = document.getElementById('editMovieId');
    var roomSel = document.getElementById('editRoomId');
    var startEl = document.getElementById('editStartTime');
    var movieHid = document.getElementById('editMovieIdHidden');
    var roomHid = document.getElementById('editRoomIdHidden');
    var startHid = document.getElementById('editStartTimeHidden');
    var lockNote = document.getElementById('editLockNote');
    var lockCount = document.getElementById('editLockCount');

    if (movieSel) movieSel.disabled = !!locked;
    if (roomSel) roomSel.disabled = !!locked;
    if (startEl) startEl.disabled = !!locked;

    if (movieHid) {
      movieHid.disabled = !locked;
      if (movieSel) movieHid.value = movieSel.value;
    }
    if (roomHid) {
      roomHid.disabled = !locked;
      if (roomSel) roomHid.value = roomSel.value;
    }
    if (startHid) {
      startHid.disabled = !locked;
      if (startEl) startHid.value = startEl.value;
    }

    if (lockNote) {
      if (locked) lockNote.removeAttribute('hidden');
      else lockNote.setAttribute('hidden', '');
    }
    if (lockCount) lockCount.textContent = String(bookingCount || 0);
  }

  function setEditStatusBadge(status) {
    var badge = document.getElementById('editStatusBadge');
    if (!badge) return;
    var map = {
      SCHEDULED: { cls: 'st-badge st-badge--scheduled', text: 'Đã lên lịch' },
      SHOWING: { cls: 'st-badge st-badge--showing', text: 'Đang chiếu' },
      CANCELLED: { cls: 'st-badge st-badge--cancelled', text: 'Huỷ' },
      FINISHED: { cls: 'st-badge st-badge--finished', text: 'Đã kết thúc' }
    };
    var info = map[status] || map.FINISHED;
    badge.className = info.cls;
    badge.textContent = info.text;

    var cancelBtn = document.getElementById('editCancelBtn');
    if (cancelBtn) {
      // Chỉ suất chưa chiếu (SCHEDULED) mới được hủy
      var canCancel = status === 'SCHEDULED';
      if (canCancel) cancelBtn.removeAttribute('hidden');
      else cancelBtn.setAttribute('hidden', '');
    }
  }

  function syncEditDurationHint() {
    var select = document.getElementById('editMovieId');
    var hint = document.getElementById('editDurationHint');
    if (!select || !hint) return;
    var opt = select.options[select.selectedIndex];
    var dur = opt && opt.dataset.duration ? parseInt(opt.dataset.duration, 10) : 0;
    hint.textContent = dur > 0
      ? ('Thời lượng phim: ' + dur + ' phút — giờ kết thúc tự tính.')
      : '';
  }

  window.openEditShowtime = function (row) {
    if (!row) return;
    var id = row.dataset.id || '';
    var movieId = row.dataset.movieId || '';
    var roomId = row.dataset.roomId || '';
    var startLocal = row.dataset.startLocal || '';
    var basePrice = row.dataset.basePrice || '';
    var status = row.dataset.status || 'SCHEDULED';
    var bookingCount = parseInt(row.dataset.bookingCount || '0', 10) || 0;
    var locked = bookingCount > 0;

    var idEl = document.getElementById('editShowtimeId');
    var movieSel = document.getElementById('editMovieId');
    var roomSel = document.getElementById('editRoomId');
    var startEl = document.getElementById('editStartTime');
    var priceEl = document.getElementById('editBasePrice');
    var cancelId = document.getElementById('stCancelShowtimeId');

    if (idEl) idEl.value = id;
    if (movieSel) movieSel.value = movieId;
    if (roomSel) roomSel.value = roomId;
    if (startEl) startEl.value = startLocal;
    if (priceEl) priceEl.value = basePrice;
    if (cancelId) cancelId.value = id;

    setEditStatusBadge(status);
    setEditLocked(locked, bookingCount);
    syncEditDurationHint();

    closeModal(createModal);
    closeModal(copyModal);
    openModal(editModal);
  };

  window.openEditShowtimeById = function (id) {
    if (!id) return;
    var row = document.querySelector('#stTableBody .st-row[data-id="' + id.replace(/"/g, '') + '"]');
    openEditShowtime(row);
  };

  window.openCopyModal = function () {
    closeModal(createModal);
    closeModal(editModal);
    var to = document.getElementById('copyToDate');
    if (to && !to.value) to.value = addDays(today, 1);
    openModal(copyModal);
  };

  window.closeCopyModal = function () {
    closeModal(copyModal);
  };

  window.openCancelReasonModal = function () {
    var idEl = document.getElementById('editShowtimeId');
    var row = idEl && idEl.value
      ? document.querySelector('#stTableBody .st-row[data-id="' + idEl.value + '"]')
      : null;
    var status = row ? resolveLiveStatus(row) : 'SCHEDULED';
    if (status !== 'SCHEDULED') {
      alert('Không thể hủy suất đã bắt đầu chiếu hoặc đã kết thúc.');
      return;
    }
    if (!cancelModal) return;
    openModal(cancelModal);
    var reason = document.getElementById('stCancelReason');
    if (reason) {
      reason.value = '';
      reason.focus();
    }
  };

  window.closeCancelReasonModal = function () {
    closeModal(cancelModal);
  };

  window.validateCancelReason = function () {
    var reason = (document.getElementById('stCancelReason')?.value || '').trim();
    if (reason.length < 10) {
      alert('Lý do hủy phải có ít nhất 10 ký tự.');
      return false;
    }
    return confirm('Xác nhận hủy suất chiếu?\n\nKhách đã đặt sẽ nhận email lý do và được cộng điểm thưởng tương đương giá trị vé.');
  };

  window.setStatusTab = function (btn) {
    document.querySelectorAll('.mm-tabs .mm-tab').forEach(function (t) {
      t.classList.remove('active');
    });
    btn.classList.add('active');
    statusFilter = btn.getAttribute('data-filter') || '';
    currentPage = 1;
    applyFilters();
  };

  window.setDateRange = function (btn) {
    document.querySelectorAll('.st-range-chips .st-chip').forEach(function (c) {
      c.classList.remove('active');
    });
    btn.classList.add('active');
    dateRange = btn.getAttribute('data-range') || 'all';
    var dateEl = document.getElementById('stFilterDate');
    if (dateEl) {
      if (dateRange === 'today') {
        dateEl.value = today;
        calendarDate = today;
      } else {
        dateEl.value = '';
        if (dateRange === '7') calendarDate = today;
      }
    }
    currentPage = 1;
    applyFilters();
  };

  window.onDateFilterChange = function () {
    var dateEl = document.getElementById('stFilterDate');
    if (dateEl && dateEl.value) {
      dateRange = 'custom';
      calendarDate = dateEl.value;
      document.querySelectorAll('.st-range-chips .st-chip').forEach(function (c) {
        c.classList.remove('active');
      });
    } else if (dateRange === 'custom') {
      dateRange = 'all';
      document.querySelectorAll('.st-range-chips .st-chip').forEach(function (c) {
        if (c.getAttribute('data-range') === 'all') c.classList.add('active');
      });
    }
    currentPage = 1;
    applyFilters();
  };

  window.setViewMode = function (btn) {
    document.querySelectorAll('.st-view-btn').forEach(function (b) {
      b.classList.remove('active');
    });
    btn.classList.add('active');
    viewMode = btn.getAttribute('data-view') || 'list';
    var listView = document.getElementById('stListView');
    var calView = document.getElementById('stCalendarView');
    if (listView) listView.hidden = viewMode !== 'list';
    if (calView) calView.hidden = viewMode !== 'calendar';
    if (viewMode === 'calendar') {
      if (!calendarDate) calendarDate = today;
      renderCalendar();
    } else {
      renderPage();
    }
    saveUiState();
  };

  window.shiftCalendarDay = function (delta) {
    if (!calendarDate) calendarDate = today;
    calendarDate = addDays(calendarDate, delta);
    var dateEl = document.getElementById('stFilterDate');
    if (dateEl) dateEl.value = calendarDate;
    dateRange = 'custom';
    document.querySelectorAll('.st-range-chips .st-chip').forEach(function (c) {
      c.classList.remove('active');
    });
    applyFilters();
  };

  function inDateRange(rowDate) {
    if (!rowDate) return false;
    if (dateRange === 'all') return true;
    if (dateRange === 'today' || dateRange === 'custom') {
      var dateEl = document.getElementById('stFilterDate');
      var selected = (dateEl && dateEl.value) ? dateEl.value : (calendarDate || today);
      return rowDate === selected;
    }
    if (dateRange === '7') {
      var end = addDays(today, 6);
      return rowDate >= today && rowDate <= end;
    }
    return true;
  }

  window.applyFilters = function () {
    var searchEl = document.getElementById('stSearch');
    var movieEl = document.getElementById('stFilterMovie');
    var roomEl = document.getElementById('stFilterRoom');

    var q = searchEl ? searchEl.value.trim().toLowerCase() : '';
    var movieId = movieEl ? movieEl.value : '';
    var roomId = roomEl ? roomEl.value : '';

    var rows = Array.prototype.slice.call(document.querySelectorAll('#stTableBody .st-row'));
    filteredRows = rows.filter(function (row) {
      if (q && (row.dataset.title || '').indexOf(q) < 0) return false;
      if (movieId && row.dataset.movieId !== movieId) return false;
      if (roomId && row.dataset.roomId !== roomId) return false;
      if (!inDateRange(row.dataset.date)) return false;
      if (statusFilter && row.dataset.status !== statusFilter) return false;
      return true;
    });

    if (!restoringUi) currentPage = 1;
    if (viewMode === 'calendar') renderCalendar();
    else renderPage();
    saveUiState();
  };

  function renderPage() {
    var rows = Array.prototype.slice.call(document.querySelectorAll('#stTableBody .st-row'));
    rows.forEach(function (row) {
      row.classList.add('st-row--hidden');
    });

    var total = filteredRows.length;
    var totalPages = Math.max(1, Math.ceil(total / ROWS_PER_PAGE));
    if (currentPage > totalPages) currentPage = totalPages;

    var start = (currentPage - 1) * ROWS_PER_PAGE;
    var end = start + ROWS_PER_PAGE;
    filteredRows.slice(start, end).forEach(function (row) {
      row.classList.remove('st-row--hidden');
    });

    var info = document.getElementById('stPagInfo');
    if (info) {
      if (total === 0) {
        info.textContent = 'Không có suất chiếu phù hợp';
      } else {
        var from = start + 1;
        var to = Math.min(end, total);
        info.textContent = 'Hiển thị ' + from + '–' + to + ' / ' + total;
      }
    }

    var prev = document.getElementById('stPrevBtn');
    var next = document.getElementById('stNextBtn');
    if (prev) prev.disabled = currentPage <= 1;
    if (next) next.disabled = currentPage >= totalPages || total === 0;
  }

  window.prevPage = function () {
    if (currentPage > 1) {
      currentPage--;
      renderPage();
      saveUiState();
    }
  };

  window.nextPage = function () {
    var totalPages = Math.max(1, Math.ceil(filteredRows.length / ROWS_PER_PAGE));
    if (currentPage < totalPages) {
      currentPage++;
      renderPage();
      saveUiState();
    }
  };

  function renderCalendar() {
    var grid = document.getElementById('stCalGrid');
    var label = document.getElementById('stCalDateLabel');
    if (!grid) return;

    if (!calendarDate) {
      var dateEl = document.getElementById('stFilterDate');
      calendarDate = (dateEl && dateEl.value) ? dateEl.value : today;
    }
    if (label) label.textContent = formatViDate(calendarDate);

    var roomFilter = document.getElementById('stFilterRoom');
    var visibleRooms = rooms.filter(function (r) {
      return !roomFilter || !roomFilter.value || roomFilter.value === r.id;
    });
    if (visibleRooms.length === 0) {
      grid.innerHTML = '<div class="mm-empty" style="padding:24px">Không có phòng hoạt động.</div>';
      return;
    }

    var dayRows = filteredRows.filter(function (row) {
      return row.dataset.date === calendarDate;
    });

    var hours = [];
    for (var h = CAL_START_HOUR; h <= CAL_END_HOUR; h++) hours.push(h);

    grid.style.gridTemplateColumns = '64px repeat(' + visibleRooms.length + ', minmax(160px, 1fr))';
    var html = '';
    html += '<div class="st-cal-corner">Giờ</div>';
    visibleRooms.forEach(function (r) {
      html += '<div class="st-cal-room-head">' + escapeHtml(r.name) + '</div>';
    });

    hours.forEach(function (hour) {
      html += '<div class="st-cal-hour">' + pad(hour) + ':00</div>';
      visibleRooms.forEach(function (room) {
        var blocks = dayRows.filter(function (row) {
          return row.dataset.roomId === room.id
            && parseInt(row.dataset.startHour || '0', 10) === hour;
        });
        var cellClass = 'st-cal-cell' + (blocks.length ? '' : ' is-empty');
        html += '<div class="' + cellClass + '">';
        blocks.forEach(function (row) {
          var st = (row.dataset.status || '').toLowerCase();
          var sid = row.dataset.id || '';
          html +=
            '<button type="button" class="st-cal-block st-cal-block--' + st + '" data-id="' + escapeHtml(sid) + '"' +
              ' onclick="openEditShowtimeById(this.getAttribute(\'data-id\'))">' +
              '<span class="st-cal-block-title">' + escapeHtml(row.dataset.titleRaw || '') + '</span>' +
              '<span class="st-cal-block-meta">' +
                escapeHtml(row.dataset.startHm || '') + '–' + escapeHtml(row.dataset.endHm || '') +
                ' · ' + escapeHtml(row.dataset.sold || '0') + '/' + escapeHtml(row.dataset.capacity || '0') +
              '</span>' +
            '</button>';
        });
        html += '</div>';
      });
    });

    grid.innerHTML = html;
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function parseLocalDateTime(value) {
    if (!value) return null;
    var m = String(value).match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/);
    if (!m) return null;
    return new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], 0, 0);
  }

  function resolveLiveStatus(row) {
    var current = (row.dataset.status || '').toUpperCase();
    if (current === 'CANCELLED') return 'CANCELLED';
    var start = parseLocalDateTime(row.dataset.startLocal);
    var end = parseLocalDateTime(row.dataset.endLocal);
    if (!start || !end) return current || 'SCHEDULED';
    var now = Date.now();
    if (now >= end.getTime()) return 'FINISHED';
    if (now >= start.getTime()) return 'SHOWING';
    return 'SCHEDULED';
  }

  function statusBadgeHtml(status) {
    var map = {
      SCHEDULED: { cls: 'st-badge st-badge--scheduled', text: 'Đã lên lịch' },
      SHOWING: { cls: 'st-badge st-badge--showing', text: 'Đang chiếu' },
      CANCELLED: { cls: 'st-badge st-badge--cancelled', text: 'Huỷ' },
      FINISHED: { cls: 'st-badge st-badge--finished', text: 'Đã kết thúc' }
    };
    var info = map[status] || map.FINISHED;
    return '<span class="' + info.cls + '">' + info.text + '</span>';
  }

  /** Cập nhật data-status + badge theo đồng hồ máy khách (CANCELLED giữ nguyên). */
  function syncLiveStatuses() {
    var changed = false;
    document.querySelectorAll('#stTableBody .st-row').forEach(function (row) {
      var next = resolveLiveStatus(row);
      var prev = (row.dataset.status || '').toUpperCase();
      if (next === prev) return;
      row.dataset.status = next;
      var cell = row.querySelector('.st-status-cell');
      if (cell) cell.innerHTML = statusBadgeHtml(next);
      changed = true;
    });
    if (!changed) return;
    if (viewMode === 'calendar') {
      applyFilters();
    } else if (statusFilter) {
      applyFilters();
    }
  }

  [createModal, editModal, copyModal, cancelModal].forEach(function (modal) {
    if (!modal) return;
    modal.addEventListener('click', function (e) {
      if (e.target !== modal) return;
      if (modal === createModal) closeCreateModal();
      else if (modal === editModal) closeEditModal();
      else if (modal === copyModal) closeCopyModal();
      else if (modal === cancelModal) closeCancelReasonModal();
    });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if (cancelModal && cancelModal.classList.contains('open')) closeCancelReasonModal();
    else if (createModal && createModal.classList.contains('open')) closeCreateModal();
    else if (editModal && editModal.classList.contains('open')) closeEditModal();
    else if (copyModal && copyModal.classList.contains('open')) closeCopyModal();
  });

  document.querySelectorAll('.st-status-select').forEach(function (sel) {
    sel.addEventListener('change', function () {
      var st = (sel.value || '').toLowerCase();
      sel.className = 'st-status-select st-status-select--' + st;
    });
  });

  bindDurationHint('createMovieId', 'createDurationHint');
  bindDurationHint('editMovieId', 'editDurationHint');

  calendarDate = today;

  var restored = restoreUiState();

  if (pageRoot) {
    if (pageRoot.getAttribute('data-open-edit') === 'true') {
      // Lỗi validate sau POST — form đã prefill từ server
      var idEl = document.getElementById('editShowtimeId');
      var cancelId = document.getElementById('stCancelShowtimeId');
      if (cancelId && idEl) cancelId.value = idEl.value || '';
      var row = idEl && idEl.value
        ? document.querySelector('#stTableBody .st-row[data-id="' + idEl.value + '"]')
        : null;
      setEditStatusBadge(row ? (row.dataset.status || 'SCHEDULED') : 'SCHEDULED');
      var lockNote = document.getElementById('editLockNote');
      var isLocked = !!(lockNote && !lockNote.hasAttribute('hidden'));
      var lockCountEl = document.getElementById('editLockCount');
      setEditLocked(isLocked, parseInt((lockCountEl && lockCountEl.textContent) || '0', 10) || 0);
      syncEditDurationHint();
      openModal(editModal);
    } else if (pageRoot.getAttribute('data-open-create') === 'true') openModal(createModal);
  }

  restoringUi = !!restored;
  // Đồng bộ màu theo giờ máy khách ngay khi load/F5 (không poll liên tục)
  syncLiveStatuses();
  applyFilters();
  if (restored) {
    currentPage = Math.max(1, parseInt(restored.currentPage, 10) || 1);
    if (viewMode === 'calendar') renderCalendar();
    else renderPage();
    restoringUi = false;
    saveUiState();
  }
})();
