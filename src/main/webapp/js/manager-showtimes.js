(function () {
  'use strict';

  var movieSelect = document.getElementById('movieId');
  var hintEl = document.getElementById('stDurationHint');

  function updateDurationHint() {
    if (!movieSelect || !hintEl) return;
    var opt = movieSelect.options[movieSelect.selectedIndex];
    var dur = opt && opt.dataset.duration ? parseInt(opt.dataset.duration, 10) : 0;
    if (dur > 0) {
      hintEl.textContent = 'Th\u1eddi l\u01b0\u1ee3ng phim: ' + dur + ' ph\u00fat \u2014 gi\u1edd k\u1ebft th\u00fac t\u1ef1 t\u00ednh.';
    } else {
      hintEl.textContent = '';
    }
  }

  if (movieSelect) {
    movieSelect.addEventListener('change', updateDurationHint);
    updateDurationHint();
  }

  var filterMovie = document.getElementById('stFilterMovie');
  var filterRoom = document.getElementById('stFilterRoom');
  var filterDate = document.getElementById('stFilterDate');
  var filterStatus = document.getElementById('stFilterStatus');
  var countEl = document.getElementById('stVisibleCount');
  var rows = document.querySelectorAll('.st-row');

  function applyFilters() {
    var movieId = filterMovie ? filterMovie.value : '';
    var roomId = filterRoom ? filterRoom.value : '';
    var date = filterDate ? filterDate.value : '';
    var status = filterStatus ? filterStatus.value : '';
    var visible = 0;

    rows.forEach(function (row) {
      var show = true;
      if (movieId && row.dataset.movieId !== movieId) show = false;
      if (roomId && row.dataset.roomId !== roomId) show = false;
      if (date && row.dataset.date !== date) show = false;
      if (status && row.dataset.status !== status) show = false;
      row.classList.toggle('st-row--hidden', !show);
      if (show) visible++;
    });

    if (countEl) countEl.textContent = String(visible);
  }

  [filterMovie, filterRoom, filterDate, filterStatus].forEach(function (el) {
    if (el) el.addEventListener('change', applyFilters);
  });
})();
