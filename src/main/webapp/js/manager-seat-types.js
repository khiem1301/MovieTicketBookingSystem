(function () {
  'use strict';

  var ROWS_PER_PAGE = 8;
  var currentPage = 1;
  var spanFilter = '';
  var filteredRows = [];

  var createModal = document.getElementById('stCreateModal');
  var editModal = document.getElementById('stEditModal');
  var pageRoot = document.querySelector('.st-page');

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

  window.setSpanTab = function (btn) {
    document.querySelectorAll('.mm-tabs .mm-tab').forEach(function (t) {
      t.classList.remove('active');
    });
    btn.classList.add('active');
    spanFilter = btn.getAttribute('data-filter') || '';
    currentPage = 1;
    applyFilters();
  };

  window.applyFilters = function () {
    var searchEl = document.getElementById('stSearch');
    var q = searchEl ? searchEl.value.trim().toLowerCase() : '';

    var rows = Array.prototype.slice.call(document.querySelectorAll('#stTableBody .st-row'));
    filteredRows = rows.filter(function (row) {
      if (q && (row.dataset.name || '').indexOf(q) < 0
          && (row.dataset.desc || '').indexOf(q) < 0) {
        return false;
      }
      if (spanFilter && row.dataset.span !== spanFilter) return false;
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
        info.textContent = 'Không có loại ghế phù hợp';
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

  window.showSeatTypeDeleteBlocked = function (btn) {
    var name = btn.dataset.typeName || 'loại ghế này';
    var count = btn.dataset.usageCount || '0';
    alert('Không thể xóa "' + name + '" — đang có ' + count + ' ghế sử dụng trong layout phòng chiếu.');
  };

  function bindCharCounters() {
    document.querySelectorAll('[data-char-count]').forEach(function (input) {
      var countEl = document.getElementById(input.getAttribute('data-char-count'));
      var max = parseInt(input.getAttribute('data-char-max') || input.maxLength || '0', 10);
      if (!countEl || !max) return;
      function updateCount() {
        countEl.textContent = (input.value || '').length + '/' + max;
      }
      input.addEventListener('input', updateCount);
      updateCount();
    });
  }

  function bindMultiplierFormat() {
    document.querySelectorAll('input[name="priceMultiplier"]').forEach(function (multiplier) {
      multiplier.addEventListener('blur', function () {
        var raw = (multiplier.value || '').trim();
        if (!raw) return;
        var n = Number(raw);
        if (!isFinite(n) || n < 0.01 || n > 9.99) return;
        multiplier.value = n.toFixed(2);
      });
    });
  }

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

  bindCharCounters();
  bindMultiplierFormat();

  if (window.SeatTypeColors) {
    SeatTypeColors.applySwatchColors();
  }

  if (pageRoot) {
    if (pageRoot.getAttribute('data-open-edit') === 'true') openModal(editModal);
    else if (pageRoot.getAttribute('data-open-create') === 'true') openModal(createModal);
  }

  applyFilters();
})();
