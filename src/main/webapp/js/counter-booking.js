/* ============================================================
   Counter Booking — FR-35 / FR-38
   Xử lý chọn ghế, tính tiền, cập nhật form.
   ============================================================ */

(function () {
  'use strict';

  const seatMap        = document.getElementById('seatMap');
  const selectedList   = document.getElementById('selectedSeatsList');
  const subtotalEl     = document.getElementById('subtotalDisplay');
  const totalEl        = document.getElementById('totalDisplay');
  const confirmBtn     = document.getElementById('confirmBtn');
  const bookingForm    = document.getElementById('bookingForm');

  if (!seatMap) return; // Chỉ chạy ở bước 3

  // ── Seat selection ──────────────────────────────────────────
  seatMap.addEventListener('click', function (e) {
    const btn = e.target.closest('.seat-btn.seat--available, .seat-btn.seat--selected');
    if (!btn) return;
    btn.classList.toggle('seat--available');
    btn.classList.toggle('seat--selected');
    refreshOrderPanel();
  });

  function getSelectedSeats() {
    return Array.from(seatMap.querySelectorAll('.seat-btn.seat--selected'));
  }

  function refreshOrderPanel() {
    const selected = getSelectedSeats();

    // Cập nhật danh sách ghế
    if (selected.length === 0) {
      selectedList.innerHTML = '<p class="text-muted">Ch\u01b0a ch\u1ecdn gh\u1ebf n\u00e0o.</p>';
    } else {
      selectedList.innerHTML = selected.map(btn => {
        const price = parseFloat(btn.dataset.price) || 0;
        return `<div class="seat-order-item">
          <span>${btn.dataset.seatCode} <small style="color:var(--text-dim)">(${btn.dataset.seatType})</small></span>
          <span class="seat-price">${formatVnd(price)}</span>
        </div>`;
      }).join('');
    }

    // Tính tổng
    const subtotal = selected.reduce((sum, btn) => sum + (parseFloat(btn.dataset.price) || 0), 0);
    if (subtotalEl) subtotalEl.textContent = formatVnd(subtotal);
    if (totalEl)    totalEl.textContent    = formatVnd(subtotal);

    // Enable/disable nút xác nhận
    if (confirmBtn) confirmBtn.disabled = selected.length === 0;

    // Đồng bộ hidden inputs
    syncHiddenInputs(selected);
  }

  function syncHiddenInputs(selected) {
    if (!bookingForm) return;

    // Xóa inputs cũ
    bookingForm.querySelectorAll('input[name="seatIds"], input[name="seatPrices"]')
               .forEach(el => el.remove());

    selected.forEach(btn => {
      appendHidden('seatIds',   btn.dataset.seatId);
      appendHidden('seatPrices', btn.dataset.price);
    });
  }

  function appendHidden(name, value) {
    const input = document.createElement('input');
    input.type  = 'hidden';
    input.name  = name;
    input.value = value;
    bookingForm.appendChild(input);
  }

  // ── Customer type toggle (FR-38) ────────────────────────────
  function toggleCustomerType(value) {
    const memberNote = document.getElementById('memberNote');
    if (memberNote) {
      memberNote.style.display = (value === 'member') ? 'block' : 'none';
    }
  }
  window.toggleCustomerType = toggleCustomerType;

  // ── Form submit validation ───────────────────────────────────
  if (bookingForm) {
    bookingForm.addEventListener('submit', function (e) {
      const selected = getSelectedSeats();
      if (selected.length === 0) {
        e.preventDefault();
        alert('Vui l\u00f2ng ch\u1ecdn \u00edt nh\u1ea5t m\u1ed9t gh\u1ebf tr\u01b0\u1edbc khi \u0111\u1eb7t v\u00e9.');
      }
    });
  }

  // ── Utility ─────────────────────────────────────────────────
  function formatVnd(amount) {
    return new Intl.NumberFormat('vi-VN').format(Math.round(amount)) + ' ₫';
  }

}());
