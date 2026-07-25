(function () {
  'use strict';

  var ROWS_PER_PAGE = 8;
  var CAL_START_HOUR = 8;
  var CAL_END_HOUR = 23;
  var MAX_BULK_TIMES = 12;

  var currentPage = 1;
  var statusFilter = '';
  var dateRange = '7'; // '7' | 'today' | 'all' | 'custom'
  var viewMode = 'list';
  var calendarDate = '';
  var filteredRows = [];

  var pageRoot = document.querySelector('.st-page');
  var createModal = document.getElementById('stCreateModal');
  var editModal = document.getElementById('stEditModal');
  var bulkModal = document.getElementById('stBulkModal');
  var copyModal = document.getElementById('stCopyModal');
  var cancelModal = document.getElementById('stCancelModal');
  var today = pageRoot ? (pageRoot.getAttribute('data-today') || isoToday()) : isoToday();
  var ctx = pageRoot ? (pageRoot.getAttribute('data-ctx') || '') : '';

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
    return [createModal, editModal, bulkModal, copyModal, cancelModal].some(function (m) {
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
    closeModal(bulkModal);
    closeModal(copyModal);
    openModal(createModal);
  };

  window.closeCreateModal = function () {
    closeModal(createModal);
  };

  window.closeEditModal = function () {
    closeModal(editModal);
    if (window.location.search.indexOf('action=edit') >= 0) {
      window.location.href = window.location.pathname;
    }
  };

  window.openBulkModal = function () {
    closeModal(createModal);
    closeModal(editModal);
    closeModal(copyModal);
    ensureBulkTimeRows();
    openModal(bulkModal);
  };

  window.closeBulkModal = function () {
    closeModal(bulkModal);
  };

  window.openCopyModal = function () {
    closeModal(createModal);
    closeModal(editModal);
    closeModal(bulkModal);
    var to = document.getElementById('copyToDate');
    if (to && !to.value) to.value = addDays(today, 1);
    openModal(copyModal);
  };

  window.openCancelReasonModal = function () {
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

  function ensureBulkTimeRows() {
    var list = document.getElementById('bulkTimeList');
    if (!list) return;
    if (list.children.length === 0) {
      addBulkTimeRow('09:00');
      addBulkTimeRow('14:00');
      addBulkTimeRow('19:00');
    }
  }

  window.addBulkTimeRow = function (preset) {
    var list = document.getElementById('bulkTimeList');
    if (!list) return;
    if (list.children.length >= MAX_BULK_TIMES) return;

    var row = document.createElement('div');
    row.className = 'st-bulk-time-row';
    row.innerHTML =
      '<input type="time" name="startTimes" required value="' + (preset || '') + '"/>' +
      '<button type="button" class="st-bulk-time-remove" title="Xóa giờ" aria-label="Xóa giờ">✕</button>';
    row.querySelector('.st-bulk-time-remove').addEventListener('click', function () {
      if (list.children.length <= 1) return;
      row.remove();
    });
    list.appendChild(row);
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

    currentPage = 1;
    if (viewMode === 'calendar') renderCalendar();
    else renderPage();
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
    }
  };

  window.nextPage = function () {
    var totalPages = Math.max(1, Math.ceil(filteredRows.length / ROWS_PER_PAGE));
    if (currentPage < totalPages) {
      currentPage++;
      renderPage();
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
          var href = ctx + '/manager/showtimes?action=edit&id=' + encodeURIComponent(row.dataset.id || '');
          html +=
            '<a class="st-cal-block st-cal-block--' + st + '" href="' + href + '">' +
              '<span class="st-cal-block-title">' + escapeHtml(row.dataset.titleRaw || '') + '</span>' +
              '<span class="st-cal-block-meta">' +
                escapeHtml(row.dataset.startHm || '') + '–' + escapeHtml(row.dataset.endHm || '') +
                ' · ' + escapeHtml(row.dataset.sold || '0') + '/' + escapeHtml(row.dataset.capacity || '0') +
              '</span>' +
            '</a>';
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

  [createModal, editModal, bulkModal, copyModal, cancelModal].forEach(function (modal) {
    if (!modal) return;
    modal.addEventListener('click', function (e) {
      if (e.target !== modal) return;
      if (modal === createModal) closeCreateModal();
      else if (modal === editModal) closeEditModal();
      else if (modal === bulkModal) closeBulkModal();
      else if (modal === copyModal) closeCopyModal();
      else if (modal === cancelModal) closeCancelReasonModal();
    });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if (cancelModal && cancelModal.classList.contains('open')) closeCancelReasonModal();
    else if (createModal && createModal.classList.contains('open')) closeCreateModal();
    else if (editModal && editModal.classList.contains('open')) closeEditModal();
    else if (bulkModal && bulkModal.classList.contains('open')) closeBulkModal();
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
  bindDurationHint('bulkMovieId', 'createDurationHint');

  calendarDate = today;

  if (pageRoot) {
    if (pageRoot.getAttribute('data-open-edit') === 'true') openModal(editModal);
    else if (pageRoot.getAttribute('data-open-create') === 'true') openModal(createModal);
    else if (pageRoot.getAttribute('data-open-bulk') === 'true') {
      ensureBulkTimeRows();
      openModal(bulkModal);
    }
  }

  applyFilters();
})();
