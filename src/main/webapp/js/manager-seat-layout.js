(function () {
  'use strict';

  var cfg = window.SLT_CONFIG || {};
  var i18n = cfg.i18n || {};
  var gridEl = document.getElementById('sltGrid');
  if (!gridEl) return;

  function t(key, vars) {
    var s = i18n[key];
    if (!s) return key;
    if (vars) {
      Object.keys(vars).forEach(function (k) {
        s = s.split('{' + k + '}').join(String(vars[k]));
      });
    }
    return s;
  }

  var TYPE_META = {};

  var STC = window.SeatTypeColors || {};
  var PRESET_TYPE_KEYS = STC.PRESET_TYPE_KEYS || ['regular', 'vip', 'couple', 'sweetbox'];
  var WIDE_TYPE_KEYS = { couple: true, sweetbox: true };
  var ICON_TYPE_KEYS = { couple: 'favorite', sweetbox: 'weekend' };
  var PRESET_COLORS = STC.PRESET_COLORS || {
    regular: '#cccccc',
    vip: '#ffd700',
    couple: '#e50914',
    sweetbox: '#0072d7'
  };

  function colorForType(key) {
    if (STC.colorForType) return STC.colorForType(key);
    if (PRESET_COLORS[key]) return PRESET_COLORS[key];
    var hash = 0;
    for (var i = 0; i < key.length; i++) {
      hash = key.charCodeAt(i) + ((hash << 5) - hash);
    }
    return 'hsl(' + (Math.abs(hash) % 360) + ', 52%, 48%)';
  }

  function initTypeMetaFromSidebar() {
    var container = document.getElementById('sltSeatTypes');
    if (STC.applySwatchColors) {
      STC.applySwatchColors(container || document);
    }
    document.querySelectorAll('.slt-type-card').forEach(function (card) {
      var key = normalizeType(card.dataset.typeKey || 'regular');
      var span = parseInt(card.dataset.seatSpan || '1', 10);
      if (isNaN(span) || span < 1) span = 1;
      var nameEl = card.querySelector('.slt-type-name');
      TYPE_META[key] = {
        css: key,
        seatSpan: span,
        wide: span >= 2 || card.dataset.wide === 'true' || !!WIDE_TYPE_KEYS[key],
        icon: ICON_TYPE_KEYS[key] || '',
        color: colorForType(key),
        label: nameEl ? nameEl.textContent.trim() : key
      };
    });
  }

  function getTypeMeta(typeKey) {
    var key = normalizeType(typeKey);
    if (!TYPE_META[key]) {
      TYPE_META[key] = {
        css: key,
        seatSpan: WIDE_TYPE_KEYS[key] ? 2 : 1,
        wide: !!WIDE_TYPE_KEYS[key],
        icon: ICON_TYPE_KEYS[key] || '',
        color: colorForType(key),
        label: key
      };
    }
    return TYPE_META[key];
  }

  function applySeatElementStyle(seatEl, meta) {
    seatEl.className = 'slt-seat';
    if (PRESET_TYPE_KEYS.indexOf(meta.css) >= 0) {
      seatEl.classList.add('slt-seat--' + meta.css);
    } else {
      seatEl.classList.add('slt-seat--custom');
      seatEl.style.background = meta.color;
      seatEl.style.color = '#fff';
    }
    if (meta.wide) seatEl.classList.add('slt-seat--wide');
  }

  function applyHintTemplate(template, vars) {
    var s = template || '';
    if (vars) {
      Object.keys(vars).forEach(function (k) {
        s = s.split('{' + k + '}').join(String(vars[k]));
      });
    }
    return s;
  }

  function updateActiveTypeUI() {
    var hint = document.getElementById('sltActiveTypeHint');
    var meta = getTypeMeta(state.activeType);
    if (hint) {
      if (state.tool === 'add') {
        hint.textContent = applyHintTemplate(hint.dataset.hintAdd, {
          label: meta.label || state.activeType
        });
        hint.classList.add('slt-active-type-hint--visible');
      } else if (state.tool === 'delete') {
        hint.textContent = hint.dataset.hintDelete || '';
        hint.classList.add('slt-active-type-hint--visible');
      } else {
        hint.classList.remove('slt-active-type-hint--visible');
      }
    }
  }

  var state = {
    rows: [],
    tool: 'select',
    activeType: null,
    selected: null,
    dirty: false
  };

  var seatCountEl = document.getElementById('sltSeatCount');
  var rowCountEl = document.getElementById('sltRowCount');
  var capacityEl = document.getElementById('sltCapacityDisplay');
  var placedMetaEl = document.getElementById('sltPlacedMeta');
  var saveBtn = document.getElementById('sltSave');

  function uid() {
    return 'c' + Math.random().toString(36).slice(2, 9);
  }

  function normalizeType(name) {
    return (name || '').toLowerCase();
  }

  function prepareRows(rawRows) {
    return rawRows.map(function (row) {
      return {
        label: row.label,
        cells: (row.cells || []).map(function (cell) {
          if (cell.kind === 'gap') {
            return { kind: 'gap', id: cell.id || uid() };
          }
          return {
            kind: 'seat',
            id: cell.id || uid(),
            type: normalizeType(cell.type),
            code: cell.code || ''
          };
        })
      };
    });
  }

  function cloneRows(rows) {
    return rows.map(function (row) {
      return {
        label: row.label,
        cells: row.cells.map(function (cell) {
          if (cell.kind === 'gap') return { kind: 'gap', id: cell.id };
          return { kind: 'seat', id: cell.id, type: cell.type, code: cell.code };
        })
      };
    });
  }

  function demoLayout() {
    return [
      {
        label: 'A',
        cells: [
          { kind: 'seat', id: uid(), type: 'regular', code: 'A1' },
          { kind: 'seat', id: uid(), type: 'regular', code: 'A2' },
          { kind: 'seat', id: uid(), type: 'regular', code: 'A3' },
          { kind: 'gap', id: uid() },
          { kind: 'seat', id: uid(), type: 'regular', code: 'A4' },
          { kind: 'seat', id: uid(), type: 'regular', code: 'A5' }
        ]
      },
      {
        label: 'B',
        cells: [
          { kind: 'seat', id: uid(), type: 'vip', code: 'B1' },
          { kind: 'seat', id: uid(), type: 'vip', code: 'B2' },
          { kind: 'seat', id: uid(), type: 'vip', code: 'B3' },
          { kind: 'gap', id: uid() },
          { kind: 'seat', id: uid(), type: 'vip', code: 'B4' },
          { kind: 'seat', id: uid(), type: 'vip', code: 'B5' }
        ]
      },
      {
        label: 'C',
        cells: [
          { kind: 'seat', id: uid(), type: 'couple', code: 'C1' },
          { kind: 'gap', id: uid() },
          { kind: 'seat', id: uid(), type: 'couple', code: 'C2' }
        ]
      }
    ];
  }

  function emptyLayout() {
    return [
      { label: 'A', cells: [] },
      { label: 'B', cells: [] },
      { label: 'C', cells: [] }
    ];
  }

  function countSeats() {
    var n = 0;
    state.rows.forEach(function (row) {
      row.cells.forEach(function (cell) {
        if (cell.kind === 'seat') n++;
      });
    });
    return n;
  }

  function updateCounts() {
    var n = countSeats();
    if (seatCountEl) seatCountEl.textContent = String(n);
    if (rowCountEl) rowCountEl.textContent = String(state.rows.length);
    if (capacityEl) capacityEl.textContent = String(n);
    if (placedMetaEl) placedMetaEl.textContent = t('placedMeta', { n: n });
  }

  function nextRowLabel() {
    var maxCode = 64;
    state.rows.forEach(function (row) {
      var label = (row.label || '').trim().toUpperCase();
      if (label.length === 1 && label >= 'A' && label <= 'Z') {
        var code = label.charCodeAt(0);
        if (code > maxCode) maxCode = code;
      }
    });
    if (maxCode >= 90) return null;
    return String.fromCharCode(maxCode + 1);
  }

  function rowHasSeats(rowIdx) {
    return state.rows[rowIdx].cells.some(function (cell) {
      return cell.kind === 'seat';
    });
  }

  function addRow() {
    var label = nextRowLabel();
    if (!label) {
      alert(t('maxRows'));
      return;
    }
    state.rows.push({ label: label, cells: [] });
    state.selected = null;
    markDirty();
    render();

    var rows = gridEl.querySelectorAll('.slt-row');
    var lastRow = rows[rows.length - 1];
    if (lastRow && lastRow.scrollIntoView) {
      lastRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  function removeRow(rowIdx) {
    if (state.rows.length <= 1) {
      alert(t('minRows'));
      return;
    }

    var row = state.rows[rowIdx];
    if (rowHasSeats(rowIdx)) {
      if (!confirm(t('confirmRemoveRow', { label: row.label }))) {
        return;
      }
    }

    state.rows.splice(rowIdx, 1);
    state.selected = null;
    markDirty();
    render();
  }

  function onRemoveRowClick(e) {
    e.stopPropagation();
    removeRow(parseInt(e.currentTarget.dataset.row, 10));
  }

  function markDirty() {
    state.dirty = true;
    updateCounts();
    if ((cfg.dbSeatCount || 0) === 0) {
      saveDraftLocally();
    }
  }

  function storageKey() {
    return 'epcine_slt_draft_' + (cfg.roomId || 'unknown');
  }

  function loadLayout() {
    if (cfg.layoutJson && cfg.layoutJson.rows && cfg.layoutJson.rows.length) {
      return prepareRows(cfg.layoutJson.rows);
    }

    if ((cfg.dbSeatCount || 0) === 0) {
      try {
        var raw = localStorage.getItem(storageKey());
        if (raw) {
          var parsed = JSON.parse(raw);
          if (parsed && parsed.rows) return prepareRows(parsed.rows);
        }
      } catch (e) { /* ignore */ }
      return demoLayout();
    }

    return emptyLayout();
  }

  function submitToBackend() {
    var n = countSeats();
    if (n === 0) {
      if (!confirm(t('confirmSaveEmpty'))) {
        return;
      }
    } else if (!confirm(t('confirmSave', { n: n }))) {
      return;
    }

    var form = document.getElementById('sltSaveForm');
    var input = document.getElementById('sltLayoutJsonInput');
    if (!form || !input) return;

    input.value = JSON.stringify({ rows: state.rows });
    try { localStorage.removeItem(storageKey()); } catch (e) { /* ignore */ }
    form.submit();
  }

  function saveDraftLocally() {
    try {
      localStorage.setItem(storageKey(), JSON.stringify({ rows: state.rows }));
    } catch (e) { /* ignore */ }
  }

  function emptyRowHint() {
    if (state.tool === 'gap') return t('emptyGap');
    if (state.tool === 'add') return t('emptyAdd');
    if (state.tool === 'delete') return t('emptyDelete');
    return t('emptySelect');
  }

  function deleteCellAt(rowIdx, colIdx) {
    if (state.tool !== 'delete') return false;
    var row = state.rows[rowIdx];
    if (!row || !row.cells[colIdx]) return false;
    row.cells.splice(colIdx, 1);
    if (state.selected && state.selected.row === rowIdx && state.selected.col === colIdx) {
      state.selected = null;
    }
    return true;
  }

  function applyCellClick(rowIdx, colIdx) {
    var row = state.rows[rowIdx];
    if (!row) return false;
    var cell = row.cells[colIdx];
    if (!cell) return false;

    if (state.tool === 'select') {
      if (cell.kind === 'gap') return false;
      state.selected = { row: rowIdx, col: colIdx };
      return true;
    }

    if (state.tool === 'delete') {
      return deleteCellAt(rowIdx, colIdx);
    }

    if (state.tool === 'gap') {
      if (cell.kind === 'gap') {
        row.cells.splice(colIdx + 1, 0, { kind: 'gap', id: uid() });
      } else {
        row.cells.splice(colIdx, 0, { kind: 'gap', id: uid() });
      }
      return true;
    }

    if (state.tool === 'add') {
      if (cell.kind === 'gap') return false;
      cell.type = state.activeType;
      return true;
    }

    return false;
  }

  function applyDeleteKey() {
    if (state.tool !== 'delete' || !state.selected) return false;
    return deleteCellAt(state.selected.row, state.selected.col);
  }

  function appendGap(rowIdx) {
    state.rows[rowIdx].cells.push({ kind: 'gap', id: uid() });
    markDirty();
    render();
  }

  function appendSeat(rowIdx) {
    if (!ensureActiveTypeSelected()) {
      alert(t('alertSelectTypeSidebar'));
      return;
    }
    state.rows[rowIdx].cells.push({
      kind: 'seat',
      id: uid(),
      type: state.activeType,
      code: nextSeatCode(rowIdx)
    });
    markDirty();
    render();
  }

  function onEmptyRowClick(e) {
    var rowIdx = parseInt(e.currentTarget.dataset.row, 10);
    if (state.tool === 'gap') {
      appendGap(rowIdx);
      return;
    }
    if (state.tool === 'add') {
      appendSeat(rowIdx);
    }
  }

  function onAppendClick(e) {
    e.stopPropagation();
    var rowIdx = parseInt(e.currentTarget.dataset.row, 10);
    if (state.tool === 'gap') {
      appendGap(rowIdx);
      return;
    }
    if (state.tool === 'add') {
      appendSeat(rowIdx);
    }
  }

  function render() {
    gridEl.innerHTML = '';

    state.rows.forEach(function (row, rowIdx) {
      var rowEl = document.createElement('div');
      rowEl.className = 'slt-row';

      var labelEl = document.createElement('span');
      labelEl.className = 'slt-row-label';
      labelEl.textContent = row.label;
      rowEl.appendChild(labelEl);

      var cellsEl = document.createElement('div');
      cellsEl.className = 'slt-row-cells';

      row.cells.forEach(function (cell, cellIdx) {
        if (cell.kind === 'gap') {
          var gapEl = document.createElement('div');
          gapEl.className = 'slt-gap';
          if (state.tool === 'delete') gapEl.classList.add('slt-cell--deletable');
          gapEl.dataset.row = String(rowIdx);
          gapEl.dataset.col = String(cellIdx);
          gapEl.title = state.tool === 'delete' ? t('deleteGap') : t('gapTitle');
          gapEl.addEventListener('click', onCellClick);
          cellsEl.appendChild(gapEl);
          return;
        }

        var meta = getTypeMeta(cell.type);
        var seatEl = document.createElement('button');
        seatEl.type = 'button';
        applySeatElementStyle(seatEl, meta);
        if (state.tool === 'delete') seatEl.classList.add('slt-cell--deletable');
        if (state.selected && state.selected.row === rowIdx && state.selected.col === cellIdx) {
          seatEl.classList.add('slt-seat--selected');
        }
        seatEl.dataset.row = String(rowIdx);
        seatEl.dataset.col = String(cellIdx);
        seatEl.title = state.tool === 'delete'
          ? (cell.code ? cell.code + ' \u2014 ' + t('deleteSeat') : t('deleteSeat'))
          : (cell.code || '');

        if (meta.icon) {
          var icon = document.createElement('span');
          icon.className = 'material-symbols-outlined slt-seat-icon';
          icon.textContent = meta.icon;
          seatEl.appendChild(icon);
        } else if (document.getElementById('sltAutoNumber') && document.getElementById('sltAutoNumber').checked && cell.code) {
          seatEl.textContent = cell.code.replace(/^[A-Z]/, '');
        }

        seatEl.addEventListener('click', onCellClick);
        cellsEl.appendChild(seatEl);
      });

      if (row.cells.length === 0) {
        var emptyEl = document.createElement('button');
        emptyEl.type = 'button';
        emptyEl.className = 'slt-row-empty';
        emptyEl.dataset.row = String(rowIdx);
        emptyEl.textContent = emptyRowHint();
        emptyEl.addEventListener('click', onEmptyRowClick);
        cellsEl.appendChild(emptyEl);
      } else if (state.tool === 'gap' || state.tool === 'add') {
        var appendEl = document.createElement('button');
        appendEl.type = 'button';
        appendEl.className = 'slt-row-append';
        appendEl.dataset.row = String(rowIdx);
        appendEl.title = state.tool === 'gap' ? t('appendGap') : t('appendSeat');
        appendEl.innerHTML = '<span class="material-symbols-outlined">add</span>';
        appendEl.addEventListener('click', onAppendClick);
        cellsEl.appendChild(appendEl);
      }

      rowEl.appendChild(cellsEl);

      if (state.rows.length > 1) {
        var removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'slt-row-remove';
        removeBtn.dataset.row = String(rowIdx);
        removeBtn.title = t('removeRow', { label: row.label });
        removeBtn.innerHTML = '<span class="material-symbols-outlined">close</span>';
        removeBtn.addEventListener('click', onRemoveRowClick);
        rowEl.appendChild(removeBtn);
      }

      gridEl.appendChild(rowEl);
    });

    updateCounts();
    updateActiveTypeUI();
  }

  function onCellClick(e) {
    e.stopPropagation();
    e.preventDefault();

    if (state.tool === 'add' && !ensureActiveTypeSelected()) {
      alert(t('alertNoSeatType'));
      return;
    }

    var rowIdx = parseInt(e.currentTarget.dataset.row, 10);
    var colIdx = parseInt(e.currentTarget.dataset.col, 10);
    if (!applyCellClick(rowIdx, colIdx)) {
      return;
    }

    markDirty();
    render();
  }

  function nextSeatCode(rowIdx) {
    var row = state.rows[rowIdx];
    var label = row.label;
    var max = 0;
    row.cells.forEach(function (c) {
      if (c.kind === 'seat' && c.code) {
        var num = parseInt(c.code.replace(/^[A-Z]+/, ''), 10);
        if (!isNaN(num) && num > max) max = num;
      }
    });
    return label + (max + 1);
  }

  function addSeatToRow(rowIdx) {
    var code = nextSeatCode(rowIdx);
    state.rows[rowIdx].cells.push({
      kind: 'seat', id: uid(), type: state.activeType, code: code
    });
    markDirty();
    render();
  }

  function ensureActiveTypeSelected() {
    var activeCard = document.querySelector('.slt-type-card--active');
    if (activeCard) {
      state.activeType = normalizeType(activeCard.dataset.typeKey || 'regular');
      return !!state.activeType;
    }
    var firstCard = document.querySelector('.slt-type-card');
    if (firstCard) {
      firstCard.classList.add('slt-type-card--active');
      state.activeType = normalizeType(firstCard.dataset.typeKey || 'regular');
      return true;
    }
    return false;
  }

  function bindTools() {
    document.querySelectorAll('.slt-tool').forEach(function (btn) {
      btn.addEventListener('click', function () {
        document.querySelectorAll('.slt-tool').forEach(function (b) {
          b.classList.remove('slt-tool--active');
        });
        btn.classList.add('slt-tool--active');
        state.tool = btn.dataset.tool || 'select';
        if (state.tool === 'add') {
          ensureActiveTypeSelected();
        }
        render();
      });
    });
  }

  function bindTypes() {
    document.querySelectorAll('.slt-type-card').forEach(function (card) {
      card.addEventListener('click', function () {
        document.querySelectorAll('.slt-type-card').forEach(function (c) {
          c.classList.remove('slt-type-card--active');
        });
        card.classList.add('slt-type-card--active');
        state.activeType = normalizeType(card.dataset.typeKey || 'regular');
        updateActiveTypeUI();
      });
    });
  }

  function bindActions() {
    var clearBtn = document.getElementById('sltClear');
    var discardBtn = document.getElementById('sltDiscard');
    var initialRows = cloneRows(state.rows);

    if (clearBtn) {
      clearBtn.addEventListener('click', function () {
        if (!confirm(t('confirmClear'))) return;
        state.rows = emptyLayout();
        state.selected = null;
        markDirty();
        render();
      });
    }

    if (discardBtn) {
      discardBtn.addEventListener('click', function () {
        if (!confirm(t('confirmDiscard'))) return;
        state.rows = cloneRows(initialRows);
        state.selected = null;
        state.dirty = false;
        render();
      });
    }

    if (saveBtn) {
      saveBtn.addEventListener('click', submitToBackend);
    }

    var addRowBtn = document.getElementById('sltAddRowFooter');
    if (addRowBtn) addRowBtn.addEventListener('click', addRow);

    document.addEventListener('keydown', function (e) {
      if (e.key !== 'Delete') return;
      if (state.tool !== 'delete') return;
      if (!applyDeleteKey()) return;
      e.preventDefault();
      markDirty();
      render();
    });
  }

  initTypeMetaFromSidebar();
  ensureActiveTypeSelected();
  state.rows = loadLayout();
  bindTools();
  bindTypes();
  bindActions();
  render();

  if ((cfg.dbSeatCount || 0) === 0 && !cfg.layoutJson) {
    saveDraftLocally();
  }
})();
