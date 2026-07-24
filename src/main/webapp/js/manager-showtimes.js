(function () {
  'use strict';

  var ROWS_PER_PAGE = 8;
  var currentPage = 1;
  var statusFilter = '';
  var filteredRows = [];

  var createModal = document.getElementById('stCreateModal');
  var editModal = document.getElementById('stEditModal');
  var pageRoot = document.querySelector('.st-page');

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
    if ((!createModal || !createModal.classList.contains('open'))
        && (!editModal || !editModal.classList.contains('open'))) {
      document.body.classList.remove('st-modal-open');
    }
  }

  window.openCreateModal = function () {
    closeModal(editModal);
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

  window.setStatusTab = function (btn) {
    document.querySelectorAll('.mm-tabs .mm-tab').forEach(function (t) {
      t.classList.remove('active');
    });
    btn.classList.add('active');
    statusFilter = btn.getAttribute('data-filter') || '';
    currentPage = 1;
    applyFilters();
  };

  window.applyFilters = function () {
    var searchEl = document.getElementById('stSearch');
    var movieEl = document.getElementById('stFilterMovie');
    var roomEl = document.getElementById('stFilterRoom');
    var dateEl = document.getElementById('stFilterDate');

    var q = searchEl ? searchEl.value.trim().toLowerCase() : '';
    var movieId = movieEl ? movieEl.value : '';
    var roomId = roomEl ? roomEl.value : '';
    var date = dateEl ? dateEl.value : '';

    var rows = Array.prototype.slice.call(document.querySelectorAll('#stTableBody .st-row'));
    filteredRows = rows.filter(function (row) {
      if (q && (row.dataset.title || '').indexOf(q) < 0) return false;
      if (movieId && row.dataset.movieId !== movieId) return false;
      if (roomId && row.dataset.roomId !== roomId) return false;
      if (date && row.dataset.date !== date) return false;
      if (statusFilter && row.dataset.status !== statusFilter) return false;
      return true;
    });

    currentPage = 1;
    renderPage();
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

  [createModal, editModal].forEach(function (modal) {
    if (!modal) return;
    modal.addEventListener('click', function (e) {
      if (e.target === modal) {
        if (modal === createModal) closeCreateModal();
        else closeEditModal();
      }
    });
  });

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if (createModal && createModal.classList.contains('open')) closeCreateModal();
    else if (editModal && editModal.classList.contains('open')) closeEditModal();
  });

  bindDurationHint('createMovieId', 'createDurationHint');
  bindDurationHint('editMovieId', 'editDurationHint');

  if (pageRoot) {
    if (pageRoot.getAttribute('data-open-edit') === 'true') openModal(editModal);
    else if (pageRoot.getAttribute('data-open-create') === 'true') openModal(createModal);
  }

  applyFilters();
})();
