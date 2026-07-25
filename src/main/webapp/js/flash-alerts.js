/**
 * Flash alerts dùng chung — hiện 5s rồi fade + gỡ khỏi DOM.
 * Bỏ qua: [data-flash-persist], [hidden], display:none, .ck-alert--warn (trạng thái cố định).
 */
(function (global) {
  'use strict';

  var SHOW_MS = 5000;
  var FADE_MS = 400;

  var SELECTOR = [
    '.admin-alert--success', '.admin-alert--error',
    '.mm-alert--success', '.mm-alert--error',
    '.genre-alert--success', '.genre-alert--error',
    '.mgr-alert--success', '.mgr-alert--error',
    '.promo-alert--success', '.promo-alert--error',
    '.profile-alert--success', '.profile-alert--error', '.profile-alert--warn',
    '.auth-alert--success', '.auth-alert--error',
    '.pos-alert--error', '.pos-alert--info',
    '.ck-alert--error', '.ck-alert--info',
    '.mi-review-alert--success', '.mi-review-alert--error',
    '.alert--success', '.alert--error'
  ].join(', ');

  function isPersist(el) {
    if (!el || el.getAttribute('data-flash-persist') === 'true') return true;
    if (el.hasAttribute('hidden') || el.hidden) return true;
    if (el.classList.contains('ck-alert--warn')) return true;
    try {
      if (global.getComputedStyle(el).display === 'none') return true;
    } catch (e) { /* ignore */ }
    return false;
  }

  function dismiss(el) {
    if (!el || el.dataset.flashDismissing === '1') return;
    el.dataset.flashDismissing = '1';
    el.style.transition = 'opacity ' + (FADE_MS / 1000) + 's ease';
    el.style.opacity = '0';
    setTimeout(function () {
      if (el.parentNode) {
        el.parentNode.removeChild(el);
      }
    }, FADE_MS);
  }

  function schedule(el, delayMs) {
    if (!el || isPersist(el) || el.dataset.flashScheduled === '1') return;
    el.dataset.flashScheduled = '1';
    var wait = typeof delayMs === 'number' ? delayMs : SHOW_MS;
    setTimeout(function () {
      dismiss(el);
    }, wait);
  }

  function scan(root) {
    var scope = root && root.querySelectorAll ? root : document;
    scope.querySelectorAll(SELECTOR).forEach(function (el) {
      schedule(el);
    });
  }

  global.FlashAlerts = {
    SHOW_MS: SHOW_MS,
    FADE_MS: FADE_MS,
    schedule: schedule,
    dismiss: dismiss,
    scan: scan
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () { scan(document); });
  } else {
    scan(document);
  }
})(window);
