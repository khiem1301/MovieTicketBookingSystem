(function (global) {
  'use strict';

  var PRESET_TYPE_KEYS = ['regular', 'vip', 'couple', 'sweetbox'];

  /** Brand red — only for "selected seat", never for seat-type colors. */
  var RESERVED_SELECTION_COLOR = '#e50914';

  var PRESET_COLORS = {
    regular: '#cccccc',
    vip: '#ffd700',
    couple: '#ff4d94',
    sweetbox: '#0072d7'
  };

  var WIDE_TYPE_KEYS = { couple: true, sweetbox: true };

  // Hues near selection red (#e50914 ≈ 357°) are excluded for generated types.
  var SAFE_HUE_START = 25;
  var SAFE_HUE_SPAN = 320; // 25 .. 344

  function normalizeType(name) {
    var key = (name || '').toLowerCase().trim();
    if (key === 'standard' || !key) return 'regular';
    return key;
  }

  function colorForType(key) {
    var normalized = normalizeType(key);
    if (PRESET_COLORS[normalized]) return PRESET_COLORS[normalized];
    var hash = 0;
    for (var i = 0; i < normalized.length; i++) {
      hash = normalized.charCodeAt(i) + ((hash << 5) - hash);
    }
    var hue = SAFE_HUE_START + (Math.abs(hash) % SAFE_HUE_SPAN);
    return 'hsl(' + hue + ', 52%, 48%)';
  }

  function isWideType(key) {
    return !!WIDE_TYPE_KEYS[normalizeType(key)];
  }

  function isLightColor(color) {
    if (!color) return false;
    if (color.indexOf('hsl') === 0) {
      var parts = color.match(/[\d.]+/g);
      return !!(parts && parts.length >= 3 && parseFloat(parts[2]) > 55);
    }
    var hex = String(color).replace('#', '');
    if (hex.length === 3) {
      hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
    }
    if (hex.length !== 6) return false;
    var r = parseInt(hex.substr(0, 2), 16);
    var g = parseInt(hex.substr(2, 2), 16);
    var b = parseInt(hex.substr(4, 2), 16);
    return (0.299 * r + 0.587 * g + 0.114 * b) > 160;
  }

  function textColorFor(bg) {
    return isLightColor(bg) ? '#222222' : '#ffffff';
  }

  function applySwatchColors(root) {
    var scope = root || document;
    scope.querySelectorAll(
      '.slt-type-swatch[data-type-key], .ck-legend-swatch--type[data-type-key], .leg-dot[data-type-key]'
    ).forEach(function (el) {
      var key = normalizeType(el.dataset.typeKey);
      var color = colorForType(key);
      el.style.setProperty('background', color, 'important');
      el.style.setProperty('border-color', color, 'important');
      if (key === 'vip') {
        el.style.boxShadow = '0 0 10px rgba(255, 215, 0, 0.25)';
      } else {
        el.style.boxShadow = '';
      }
    });
  }

  function paintAvailableSeat(el) {
    var key = normalizeType(
      el.dataset.type || el.dataset.seatType || el.dataset.typeKey || 'regular'
    );
    var color = el.dataset.typeColor || colorForType(key);
    // Luôn tính contrast theo nền (giống staff POS) — không tin data-type-text có thể lệch
    var text = textColorFor(color);
    el.style.setProperty('background', color, 'important');
    el.style.setProperty('border-color', color, 'important');
    el.style.setProperty('color', text, 'important');
    var num = el.querySelector('.ck-seat-num, .pos-seat-code');
    if (num) {
      num.style.setProperty('color', text, 'important');
    }
    if (key === 'vip') {
      el.style.boxShadow = '0 0 10px rgba(255, 215, 0, 0.25)';
    } else {
      el.style.boxShadow = '';
    }
  }

  function clearSeatInlineStyle(el) {
    if (!el || !el.style) return;
    el.style.removeProperty('background');
    el.style.removeProperty('border-color');
    el.style.removeProperty('color');
    el.style.boxShadow = '';
    var num = el.querySelector('.ck-seat-num, .pos-seat-code');
    if (num && num.style) {
      num.style.removeProperty('color');
    }
  }

  function applyAvailableSeatColors(root) {
    var scope = root || document;
    scope.querySelectorAll('.ck-seat[data-type], .ck-seat[data-type-color]').forEach(function (el) {
      if (!el.classList.contains('ck-seat--available')) {
        clearSeatInlineStyle(el);
        return;
      }
      paintAvailableSeat(el);
    });
  }

  /** Staff POS seat map — available seats only (not selected/sold). */
  function applyPosSeatColors(root) {
    var scope = root || document;
    scope.querySelectorAll('.pos-seat-btn[data-seat-type]').forEach(function (el) {
      if (el.classList.contains('pos-seat--sold') || el.classList.contains('pos-seat--selected')) {
        clearSeatInlineStyle(el);
        return;
      }
      paintAvailableSeat(el);
    });
  }

  function applyAll(root) {
    applySwatchColors(root);
    applyAvailableSeatColors(root);
    applyPosSeatColors(root);
  }

  global.SeatTypeColors = {
    PRESET_TYPE_KEYS: PRESET_TYPE_KEYS,
    PRESET_COLORS: PRESET_COLORS,
    RESERVED_SELECTION_COLOR: RESERVED_SELECTION_COLOR,
    normalizeType: normalizeType,
    colorForType: colorForType,
    isWideType: isWideType,
    isLightColor: isLightColor,
    textColorFor: textColorFor,
    applySwatchColors: applySwatchColors,
    applyAvailableSeatColors: applyAvailableSeatColors,
    applyPosSeatColors: applyPosSeatColors,
    clearSeatInlineStyle: clearSeatInlineStyle,
    applyAll: applyAll
  };
})(window);
