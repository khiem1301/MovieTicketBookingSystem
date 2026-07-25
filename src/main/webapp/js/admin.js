/**
 * @deprecated Dùng flash-alerts.js (load từ footer). Giữ file để tránh 404 nếu cache cũ.
 */
(function () {
  'use strict';
  if (window.FlashAlerts && typeof window.FlashAlerts.scan === 'function') {
    window.FlashAlerts.scan(document);
  }
})();
