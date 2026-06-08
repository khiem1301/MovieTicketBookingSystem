(function () {
  'use strict';

  var grid = document.getElementById('audRoomGrid');
  if (!grid) return;

  var ctx = grid.dataset.ctx || '';
  var cards = Array.prototype.slice.call(
    grid.querySelectorAll('.aud-room-card:not(.aud-room-card--add)')
  );
  var filters = document.querySelectorAll('.aud-filter');
  var detailName = document.getElementById('audDetailName');
  var detailCapacity = document.getElementById('audDetailCapacity');
  var detailProjection = document.getElementById('audDetailProjection');
  var detailAudio = document.getElementById('audDetailAudio');
  var detailRatio = document.getElementById('audDetailRatio');
  var detailLink = document.getElementById('audDetailLink');

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
    if (detailLink && card.dataset.id) {
      detailLink.href = ctx + '/manager/rooms/detail?id=' + encodeURIComponent(card.dataset.id);
    }
  }

  function applyFilter(filter) {
    cards.forEach(function (card) {
      var status = card.dataset.status;
      var show = filter === 'ALL'
        || (filter === 'ACTIVE' && status === 'ACTIVE')
        || (filter === 'MAINTENANCE' && status === 'MAINTENANCE')
        || (filter === 'INACTIVE' && status === 'INACTIVE');
      card.classList.toggle('aud-room-card--hidden', !show);
    });
  }

  var addRoomInput = document.getElementById('audAddRoomInput');
  var addCard = document.getElementById('audAddRoomCard');
  if (addCard && addRoomInput) {
    addCard.addEventListener('click', function (e) {
      if (e.target.closest('button[type="submit"]') || e.target.closest('input')) return;
      addRoomInput.focus();
    });
  }

  cards.forEach(function (card) {
    card.addEventListener('click', function (e) {
      if (e.target.closest('.aud-status-form') || e.target.closest('.aud-btn--detail')) return;
      selectCard(card);
    });
    card.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') {
        if (e.target.closest('.aud-btn--detail')) return;
        e.preventDefault();
        selectCard(card);
      }
    });

    var toggle = card.querySelector('.aud-status-select');
    if (toggle) {
      toggle.addEventListener('click', function (e) {
        e.stopPropagation();
      });
    }
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
