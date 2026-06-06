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

/* ── Hero Slider ─────────────────────────────────────────────── */
function initHeroSlider() {
  const slides = document.querySelectorAll('.hero-slide');
  const dots   = document.querySelectorAll('.dot');

  if (!slides.length) return;

  slides.forEach(slide => {
    const img = slide.querySelector('.hero-backdrop-img');
    if (!img) return;
    const backdrop = slide.dataset.backdrop || '';
    const poster   = slide.dataset.poster   || '';
    if (!backdrop || backdrop === poster) return;
    const probe = new Image();
    probe.onerror = () => { if (poster) img.src = poster; };
    probe.src = backdrop;
  });

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
