(function (global) {
  'use strict';

  var PRESET_TYPE_KEYS = ['regular', 'vip', 'couple', 'sweetbox'];
  var PRESET_COLORS = {
    regular: '#cccccc',
    vip: '#ffd700',
    couple: '#e50914',
    sweetbox: '#0072d7'
  };

  function normalizeType(name) {
    return (name || '').toLowerCase();
  }

  function colorForType(key) {
    var normalized = normalizeType(key);
    if (PRESET_COLORS[normalized]) return PRESET_COLORS[normalized];
    var hash = 0;
    for (var i = 0; i < normalized.length; i++) {
      hash = normalized.charCodeAt(i) + ((hash << 5) - hash);
    }
    return 'hsl(' + (Math.abs(hash) % 360) + ', 52%, 48%)';
  }

  function applySwatchColors(root) {
    var scope = root || document;
    scope.querySelectorAll('.slt-type-swatch[data-type-key]').forEach(function (el) {
      var key = normalizeType(el.dataset.typeKey);
      el.style.background = colorForType(key);
      if (key === 'vip') {
        el.style.boxShadow = '0 0 10px rgba(255, 215, 0, 0.25)';
      } else {
        el.style.boxShadow = '';
      }
    });
  }

  global.SeatTypeColors = {
    PRESET_TYPE_KEYS: PRESET_TYPE_KEYS,
    PRESET_COLORS: PRESET_COLORS,
    normalizeType: normalizeType,
    colorForType: colorForType,
    applySwatchColors: applySwatchColors
  };
})(window);
