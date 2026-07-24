/**
 * Admin flash alerts — hiện 10s rồi tự ẩn (success + error).
 */
(function () {
  'use strict';

  var SHOW_MS = 10000;
  var FADE_MS = 400;

  function dismiss(el) {
    if (!el || el.dataset.adminAlertDismissing === '1') return;
    el.dataset.adminAlertDismissing = '1';
    el.style.transition = 'opacity ' + (FADE_MS / 1000) + 's ease';
    el.style.opacity = '0';
    setTimeout(function () {
      if (el.parentNode) {
        el.parentNode.removeChild(el);
      }
    }, FADE_MS);
  }

  function schedule(el) {
    setTimeout(function () {
      dismiss(el);
    }, SHOW_MS);
  }

  document
    .querySelectorAll('.admin-alert--success, .admin-alert--error')
    .forEach(schedule);
})();
