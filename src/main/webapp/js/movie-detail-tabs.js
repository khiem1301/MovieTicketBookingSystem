/* Tab "Thông tin phim" / "Đánh giá" trên trang chi tiết phim (zero reload) */
(function () {
  'use strict';

  const tabs = document.querySelectorAll('.dt-tab');
  const panels = document.querySelectorAll('.dt-tab-panel');
  if (!tabs.length || !panels.length) return;

  function activate(name) {
    tabs.forEach(function (t) {
      const isActive = t.getAttribute('data-dt-tab') === name;
      t.classList.toggle('dt-tab--active', isActive);
      t.setAttribute('aria-selected', String(isActive));
    });
    panels.forEach(function (panel) {
      const isActive = panel.getAttribute('data-dt-panel') === name;
      panel.classList.toggle('dt-tab-panel--active', isActive);
      if (isActive) {
        panel.removeAttribute('hidden');
      } else {
        panel.setAttribute('hidden', '');
      }
    });
  }

  tabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      const name = tab.getAttribute('data-dt-tab');
      if (name) activate(name);
    });
  });

  const search = window.location.search || '';
  const needsReviewsTab = window.location.hash === '#movie-reviews-section' ||
    search.indexOf('reviewError') !== -1 ||
    search.indexOf('reviewSuccess') !== -1 ||
    search.indexOf('reviewPage') !== -1;
  if (needsReviewsTab) {
    activate('reviews');
  }
})();
