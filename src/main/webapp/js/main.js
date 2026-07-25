/* ============================================================
   ÉpCine — main.js
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {
  initHeroSlider();
  initMovieTabs();
  initHeaderScroll();
  initMoviesAjaxPagination();
  scrollToMoviesIfNeeded();
});

/* ── Header scroll effect ───────────────────────────────────── */
function initHeaderScroll() {
  const header = document.querySelector('.site-header');
  if (!header) return;
  window.addEventListener('scroll', () => {
    header.classList.toggle('scrolled', window.scrollY > 20);
  }, { passive: true });
}

/* ── Hero background: hiển thị ngay, backdrop lỗi thì fallback poster ── */
function setHeroBackground(heroImg, backdrop, poster) {
  if (!heroImg) return;
  const fallback = poster || backdrop;
  if (!fallback) return;

  // Hiển thị ngay để tránh nền đen khi chờ load
  heroImg.src = backdrop || poster;
  heroImg.onerror = () => {
    if (poster && heroImg.src !== poster) heroImg.src = poster;
  };

  if (!backdrop || backdrop === poster) return;

  const probe = new Image();
  probe.onload = () => { heroImg.src = backdrop; };
  probe.onerror = () => { if (poster) heroImg.src = poster; };
  probe.src = backdrop;
}

/* ── Hero Slider ─────────────────────────────────────────────── */
function initHeroSlider() {
  const slides   = document.querySelectorAll('.hero-slide');
  const dots     = document.querySelectorAll('.dot');
  const heroImg  = document.querySelector('.hero-bg-img');
  const phoneImg = document.querySelector('.phone-frame img');

  if (!slides.length) return;

  if (heroImg?.dataset.fallback) {
    const fb = heroImg.dataset.fallback;
    heroImg.onerror = () => { if (heroImg.src !== fb) heroImg.src = fb; };
  }

  let current = 0;
  let timer   = null;

  function goTo(index) {
    // Ẩn slide cũ
    slides[current].style.display   = 'none';
    slides[current].style.position  = 'absolute';
    dots[current]?.classList.remove('active');

    current = (index + slides.length) % slides.length;

    // Hiện slide mới
    const slide = slides[current];
    slide.style.display  = 'flex';
    slide.style.position = 'relative';
    dots[current]?.classList.add('active');

    const backdrop = slide.dataset.backdrop || '';
    const poster   = slide.dataset.poster   || '';
    setHeroBackground(heroImg, backdrop, poster);

    const slidePoster = slide.querySelector('.phone-frame img');
    if (slidePoster && poster) slidePoster.src = poster;
    else if (phoneImg && poster) phoneImg.src = poster;
  }

  function startAuto() {
    clearInterval(timer);
    timer = setInterval(() => goTo(current + 1), 2500);
  }

  dots.forEach((dot, i) => {
    dot.addEventListener('click', () => { goTo(i); startAuto(); });
  });

  const nextBtn = document.getElementById('heroNextBtn');
  nextBtn?.addEventListener('click', () => { goTo(current + 1); startAuto(); });

  // Pause khi hover vào hero
  const hero = document.querySelector('.hero');
  hero?.addEventListener('mouseenter', () => clearInterval(timer));
  hero?.addEventListener('mouseleave', startAuto);

  // Init
  goTo(0);
  startAuto();
}

/* ── Movie Tabs ──────────────────────────────────────────────── */
function initMovieTabs(root = document) {
  root.querySelectorAll('.movies-section, .movies-page').forEach(section => {
    if (section.dataset.tabsBound === '1') return;
    section.dataset.tabsBound = '1';

    const tabBtns = section.querySelectorAll('.tab-btn');
    const panels  = section.querySelectorAll('.tab-panel');
    if (!tabBtns.length) return;

    tabBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        const target = btn.dataset.tab;

        tabBtns.forEach(b => b.classList.remove('active'));
        panels.forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        section.querySelector('#' + target)?.classList.add('active');
      });
    });
  });
}

/**
 * Phân trang danh sách phim (home / movies) qua fetch —
 * chỉ thay khối phim, giữ vị trí cuộn (không nhảy lên đầu trang).
 */
function initMoviesAjaxPagination() {
  if (document.documentElement.dataset.moviesAjaxBound === '1') return;
  document.documentElement.dataset.moviesAjaxBound = '1';

  document.addEventListener('click', (e) => {
    const link = e.target.closest('a.movies-page-btn');
    if (!link) return;
    const section = link.closest('.movies-section, .movies-page');
    if (!section) return;
    e.preventDefault();
    loadMoviesPage(section, link.href, true);
  });

  window.addEventListener('popstate', () => {
    const section = document.querySelector('.movies-section, .movies-page');
    if (!section) return;
    loadMoviesPage(section, location.href, false);
  });
}

let moviesPageLoading = false;

async function loadMoviesPage(section, url, pushHistory) {
  if (!section || !url || moviesPageLoading) return;
  moviesPageLoading = true;

  const scrollY = window.scrollY;
  const selector = section.classList.contains('movies-section')
    ? '.movies-section'
    : '.movies-page';

  section.classList.add('is-paging');

  try {
    const fetchUrl = String(url).split('#')[0];
    const res = await fetch(fetchUrl, {
      credentials: 'same-origin',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'text/html'
      },
      cache: 'no-store'
    });
    if (!res.ok) throw new Error('HTTP ' + res.status);

    const html = await res.text();
    const doc = new DOMParser().parseFromString(html, 'text/html');
    const next = doc.querySelector(selector);
    if (!next) throw new Error('missing section');

    section.replaceWith(next);
    initMovieTabs(document);
    if (pushHistory && window.history && window.history.pushState) {
      window.history.pushState({ moviesAjax: true }, '', url);
    }
    window.scrollTo(0, scrollY);
  } catch (err) {
    window.location.href = url;
  } finally {
    moviesPageLoading = false;
  }
}

/** Fallback: full reload với #home-movies / query page* thì cuộn tới danh sách phim. */
function scrollToMoviesIfNeeded() {
  const hash = (location.hash || '').replace('#', '');
  const params = new URLSearchParams(location.search);
  const paged = ['pageShowing', 'pageComing', 'pageEarly'].some((k) => {
    const v = parseInt(params.get(k) || '1', 10);
    return v > 1;
  });
  if (!hash && !paged && !params.get('tab')) return;

  const el = document.getElementById(hash)
    || document.querySelector('.movies-section, .movies-page');
  if (!el) return;
  requestAnimationFrame(() => {
    el.scrollIntoView({ behavior: 'auto', block: 'start' });
  });
}
