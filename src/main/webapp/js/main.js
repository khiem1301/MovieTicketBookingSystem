/* ============================================================
   ÉpCine — main.js
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {
  initHeroSlider();
  initMovieTabs();
  initHeaderScroll();
  initClickDropdowns();
});

/* ── Header scroll effect ───────────────────────────────────── */
function initHeaderScroll() {
  const header = document.querySelector('.site-header');
  if (!header) return;
  window.addEventListener('scroll', () => {
    header.classList.toggle('scrolled', window.scrollY > 20);
  }, { passive: true });
}

/* ── Click-toggle dropdowns (Đánh giá) ─────────────────────── */
function initClickDropdowns() {
  document.querySelectorAll('.nav-item--click').forEach(item => {
    const trigger = item.querySelector('[data-toggle]');
    if (!trigger) return;

    trigger.addEventListener('click', e => {
      e.preventDefault();
      const isOpen = item.classList.contains('open');

      // Đóng tất cả click-dropdown đang mở
      document.querySelectorAll('.nav-item--click.open').forEach(el => {
        el.classList.remove('open');
        const arrow = el.querySelector('.nav-arrow');
        if (arrow) arrow.style.transform = '';
      });

      // Toggle cái vừa click
      if (!isOpen) {
        item.classList.add('open');
        const arrow = item.querySelector('.nav-arrow');
        if (arrow) arrow.style.transform = 'rotate(180deg)';
      }
    });
  });

  // Click ra ngoài thì đóng
  document.addEventListener('click', e => {
    if (!e.target.closest('.nav-item--click')) {
      document.querySelectorAll('.nav-item--click.open').forEach(el => {
        el.classList.remove('open');
        const arrow = el.querySelector('.nav-arrow');
        if (arrow) arrow.style.transform = '';
      });
    }
  });
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
    timer = setInterval(() => goTo(current + 1), 5000);
  }

  dots.forEach((dot, i) => {
    dot.addEventListener('click', () => { goTo(i); startAuto(); });
  });

  // Pause khi hover vào hero
  const hero = document.querySelector('.hero');
  hero?.addEventListener('mouseenter', () => clearInterval(timer));
  hero?.addEventListener('mouseleave', startAuto);

  // Init
  goTo(0);
  startAuto();
}

/* ── Movie Tabs ──────────────────────────────────────────────── */
function initMovieTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  const panels  = document.querySelectorAll('.tab-panel');

  if (!tabBtns.length) return;

  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const target = btn.dataset.tab;

      tabBtns.forEach(b => b.classList.remove('active'));
      panels.forEach(p => p.classList.remove('active'));

      btn.classList.add('active');
      document.getElementById(target)?.classList.add('active');
    });
  });
}
