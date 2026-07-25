/**
 * AJAX phân trang danh sách manager — không reload / không nhảy đầu trang.
 *
 * Đánh dấu khối list: <div id="..." data-mgr-ajax-list> ... bảng + pagination ... </div>
 * Link phân trang dùng một trong các class:
 *   .admin-pagination-nav | .aud-pag-btn | .promo-page-btn | .bh-page-btn
 */
(function (global) {
  'use strict';

  var LINK_SEL = [
    'a.admin-pagination-nav',
    'a.aud-pag-btn',
    'a.promo-page-btn',
    'a.bh-page-btn'
  ].join(',');

  var loading = false;

  function findRoot(el) {
    return el && el.closest ? el.closest('[data-mgr-ajax-list]') : null;
  }

  function softScrollIntoView(el) {
    if (!el || !el.getBoundingClientRect) return;
    var rect = el.getBoundingClientRect();
    if (rect.top < 0 || rect.bottom > window.innerHeight) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  }

  /** Luôn cuộn về đầu khối list (dùng khi bảng dài — vd. voucher). */
  function scrollToListStart(el) {
    if (!el || !el.scrollIntoView) return;
    el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }

  function afterSwapScroll(next) {
    if (!next) return;
    if (next.getAttribute('data-mgr-ajax-scroll') === 'start') {
      scrollToListStart(next);
      return;
    }
    softScrollIntoView(next);
  }

  function swapList(root, href) {
    if (loading || !root || !href) return;
    loading = true;
    root.style.opacity = '0.55';
    root.style.pointerEvents = 'none';

    fetch(href, {
      credentials: 'same-origin',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'text/html'
      }
    })
      .then(function (res) {
        if (!res.ok) throw new Error('HTTP ' + res.status);
        if (res.redirected && /\/login(?:\?|$)/.test(res.url)) {
          window.location.href = res.url;
          return null;
        }
        return res.text();
      })
      .then(function (html) {
        if (html == null) return;
        var doc = new DOMParser().parseFromString(html, 'text/html');
        var next = (root.id && doc.getElementById(root.id))
          || doc.querySelector('[data-mgr-ajax-list]');
        if (!next) {
          window.location.href = href;
          return;
        }
        root.replaceWith(next);
        if (global.history && history.replaceState) {
          history.replaceState(null, '', href);
        }
        afterSwapScroll(next);
        try {
          document.dispatchEvent(new CustomEvent('mgr-ajax-list:loaded', {
            detail: { root: next, href: href }
          }));
        } catch (e) { /* IE ignore */ }
      })
      .catch(function () {
        window.location.href = href;
      })
      .finally(function () {
        loading = false;
      });
  }

  document.addEventListener('click', function (e) {
    var link = e.target.closest(LINK_SEL);
    if (!link) return;
    var root = findRoot(link);
    if (!root) return;
    // Số trang active không điều hướng
    if (link.classList.contains('is-active') || link.getAttribute('aria-current') === 'page') {
      e.preventDefault();
      return;
    }
    var href = link.getAttribute('href');
    if (!href || href === '#' || href.indexOf('javascript:') === 0) return;
    e.preventDefault();
    swapList(root, link.href);
  });

  global.MgrAjaxPagination = {
    refresh: swapList,
    linkSelector: LINK_SEL
  };
})(window);
