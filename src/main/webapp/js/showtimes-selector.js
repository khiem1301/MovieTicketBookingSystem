/* FR-11 — Tab chọn ngày suất chiếu (zero reload) */
(function () {
  'use strict';

  const tabs = document.querySelectorAll('.st-date-tab');
  const panels = document.querySelectorAll('.st-day-panel');
  if (!tabs.length || !panels.length) return;

  tabs.forEach(function (tab) {
    tab.addEventListener('click', function () {
      const date = tab.getAttribute('data-date');
      if (!date) return;

      tabs.forEach(function (t) {
        t.classList.remove('st-date-tab--active');
        t.setAttribute('aria-selected', 'false');
      });
      tab.classList.add('st-date-tab--active');
      tab.setAttribute('aria-selected', 'true');

      panels.forEach(function (panel) {
        const isActive = panel.getAttribute('data-date') === date;
        panel.classList.toggle('st-day-panel--active', isActive);
        if (isActive) {
          panel.removeAttribute('hidden');
        } else {
          panel.setAttribute('hidden', '');
        }
      });
    });
  });
})();
