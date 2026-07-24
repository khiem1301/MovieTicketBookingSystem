(function () {
  'use strict';

  function initRoomFilters() {
    var table = document.getElementById('audRoomTable');
    var filterBar = document.querySelector('.aud-list-page .aud-filters');
    if (!table || !filterBar) return;

    var rows = Array.prototype.slice.call(table.querySelectorAll('tbody tr.aud-room-row'));
    var filters = Array.prototype.slice.call(filterBar.querySelectorAll('.aud-filter'));
    var countEl = document.getElementById('audRoomCount');

    function applyFilter(filter) {
      var visible = 0;
      rows.forEach(function (row) {
        var status = row.getAttribute('data-status') || '';
        var show = filter === 'ALL'
          || (filter === 'ACTIVE' && status === 'ACTIVE')
          || (filter === 'INACTIVE' && status === 'INACTIVE');
        if (show) {
          row.style.display = '';
          row.classList.remove('aud-room-row--hidden');
          visible += 1;
        } else {
          row.style.display = 'none';
          row.classList.add('aud-room-row--hidden');
        }
      });
      if (countEl) countEl.textContent = String(visible);
    }

    filters.forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        filters.forEach(function (b) { b.classList.remove('aud-filter--active'); });
        btn.classList.add('aud-filter--active');
        applyFilter(btn.getAttribute('data-filter') || 'ALL');
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initRoomFilters);
  } else {
    initRoomFilters();
  }
})();
