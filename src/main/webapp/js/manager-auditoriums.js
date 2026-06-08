(function () {
  'use strict';

  var grid = document.getElementById('audRoomGrid');
  if (!grid) return;

  var cards = Array.prototype.slice.call(
    grid.querySelectorAll('.aud-room-card:not(.aud-room-card--add)')
  );
  var filters = document.querySelectorAll('.aud-filter');
  var detailName = document.getElementById('audDetailName');
  var detailCapacity = document.getElementById('audDetailCapacity');
  var detailProjection = document.getElementById('audDetailProjection');
  var detailAudio = document.getElementById('audDetailAudio');
  var detailRatio = document.getElementById('audDetailRatio');
  var zoneStandard = document.getElementById('audZoneStandard');

  function statusLabel(status) {
    if (status === 'ACTIVE') return 'Hoạt động';
    if (status === 'MAINTENANCE') return 'Bảo trì';
    return 'Ngưng';
  }

  function selectCard(card) {
    cards.forEach(function (c) {
      c.classList.toggle('aud-room-card--selected', c === card);
    });

    if (!card || !detailName) return;

    detailName.textContent = card.dataset.name || '';
    if (detailCapacity) detailCapacity.textContent = card.dataset.capacity || '0';
    if (detailProjection) detailProjection.textContent = card.dataset.projection || '—';
    if (detailAudio) detailAudio.textContent = card.dataset.audio || '—';
    if (detailRatio) detailRatio.textContent = card.dataset.screenRatio || '—';
    if (zoneStandard) zoneStandard.textContent = (card.dataset.capacity || '0') + ' ghế';
  }

  function applyFilter(filter) {
    cards.forEach(function (card) {
      var status = card.dataset.status;
      var show = filter === 'ALL'
        || (filter === 'ACTIVE' && status === 'ACTIVE')
        || (filter === 'MAINTENANCE' && (status === 'MAINTENANCE' || status === 'INACTIVE'));
      card.classList.toggle('aud-room-card--hidden', !show);
    });
  }

  cards.forEach(function (card) {
    card.addEventListener('click', function () {
      selectCard(card);
    });
    card.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        selectCard(card);
      }
    });
  });

  filters.forEach(function (btn) {
    btn.addEventListener('click', function () {
      filters.forEach(function (b) { b.classList.remove('aud-filter--active'); });
      btn.classList.add('aud-filter--active');
      applyFilter(btn.dataset.filter || 'ALL');
    });
  });

  var selected = grid.querySelector('.aud-room-card--selected');
  if (selected) selectCard(selected);
})();
