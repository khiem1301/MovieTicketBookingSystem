<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản Lý Thể Loại — ÉPCINE"/>
<c:set var="extraCss"  value="manager-genres"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="genre-page">

  <%-- Toast alerts --%>
  <c:if test="${param.success == 'created'}">
    <div class="genre-alert genre-alert--success">Thêm thể loại thành công.</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="genre-alert genre-alert--success">Cập nhật thể loại thành công.</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="genre-alert genre-alert--success">Xóa thể loại thành công.</div>
  </c:if>
  <c:if test="${param.success == 'status-updated'}">
    <div class="genre-alert genre-alert--success">Cập nhật trạng thái thể loại thành công.</div>
  </c:if>

  <%-- Page Header --%>
  <div class="genre-header">
    <div class="genre-header-left">
      <h1>Quản Lý Thể Loại</h1>
      <p>Tổ chức và quản lý hệ thống phân loại phim của rạp.</p>
    </div>
    <div class="genre-header-right">
      <div class="genre-search">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input type="text" id="genreSearch" placeholder="Tìm kiếm thể loại…" oninput="applyFilters()"/>
      </div>
      <button class="btn-add-genre" onclick="openAddModal()">+ Thêm Thể Loại</button>
    </div>
  </div>

  <%-- Filter Bar --%>
  <div class="genre-filter-bar">
    <div class="genre-tabs">
      <button class="genre-tab active" data-filter="all"      onclick="setTab(this)">Tất Cả</button>
      <button class="genre-tab"        data-filter="active"   onclick="setTab(this)">Hoạt Động</button>
      <button class="genre-tab"        data-filter="inactive" onclick="setTab(this)">Ngừng Hoạt Động</button>
    </div>
    <div class="genre-filter-icons">
      <div class="genre-filter-icon" title="Xuất CSV" onclick="exportCSV()">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/>
          <polyline points="7 10 12 15 17 10"/>
          <line x1="12" y1="15" x2="12" y2="3"/>
        </svg>
      </div>
    </div>
  </div>

  <%-- Table --%>
  <div class="genre-table-wrap">
    <c:choose>
      <c:when test="${empty genreList}">
        <div class="genre-empty">Không tìm thấy thể loại nào. Bấm <strong>+ Thêm Thể Loại</strong> để tạo mới.</div>
      </c:when>
      <c:otherwise>
        <table class="genre-table">
          <thead>
            <tr>
              <th>Tên Thể Loại</th>
              <th>Slug</th>
              <th>Số Phim</th>
              <th>Trạng Thái</th>
              <th>Thao Tác</th>
            </tr>
          </thead>
          <tbody id="genreTableBody">
            <c:forEach var="g" items="${genreList}">
              <c:set var="inUse"          value="${genreIdsInUse.contains(g.id)}"/>
              <c:set var="hasActiveMov"   value="${genreIdsWithActiveMovies.contains(g.id)}"/>
              <c:set var="movieCount"     value="${movieCountMap[g.id] != null ? movieCountMap[g.id] : 0}"/>
              <c:set var="slug"           value="${fn:replace(fn:toLowerCase(g.genreName), ' ', '-')}"/>
              <tr data-name="${fn:toLowerCase(g.genreName)}"
                  data-status="${g.active ? 'active' : 'inactive'}"
                  data-description="<c:out value='${g.description}'/>">

                <td class="genre-name-cell"><c:out value="${g.genreName}"/></td>

                <td><span class="genre-slug-badge"><c:out value="${slug}"/></span></td>

                <td>${movieCount} phim</td>

                <td>
                  <c:choose>
                    <c:when test="${g.active}">
                      <span class="status-badge status-badge--active">Hoạt Động</span>
                    </c:when>
                    <c:otherwise>
                      <span class="status-badge status-badge--inactive">Ngừng Hoạt Động</span>
                    </c:otherwise>
                  </c:choose>
                </td>

                <td>
                  <div class="genre-actions">
                    <%-- Edit name: disabled khi thể loại đang có phim gắn vào --%>
                    <c:choose>
                      <c:when test="${inUse}">
                        <button class="genre-action-btn genre-action-btn--disabled"
                                title="Không thể sửa — thể loại đang được sử dụng">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                               stroke="currentColor" stroke-width="2"
                               stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 20h9"/>
                            <path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                          </svg>
                        </button>
                      </c:when>
                      <c:otherwise>
                        <button class="genre-action-btn genre-action-btn--edit" title="Sửa thể loại"
                                onclick="openEditModal('<c:out value="${g.id}"/>', '<c:out value="${g.genreName}"/>', this.closest('tr'))">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                               stroke="currentColor" stroke-width="2"
                               stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 20h9"/>
                            <path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                          </svg>
                        </button>
                      </c:otherwise>
                    </c:choose>

                    <%-- Toggle status: disabled khi có phim đang chiếu / sắp chiếu --%>
                    <c:choose>
                      <c:when test="${hasActiveMov}">
                        <button class="genre-action-btn genre-action-btn--disabled"
                                title="Không thể đổi trạng thái — thể loại có phim đang chiếu hoặc sắp chiếu">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                               stroke="currentColor" stroke-width="2"
                               stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="8" x2="12" y2="12"/>
                            <line x1="12" y1="16" x2="12.01" y2="16"/>
                          </svg>
                        </button>
                      </c:when>
                      <c:otherwise>
                        <form method="post"
                              action="${pageContext.request.contextPath}/manager/genres"
                              style="display:inline"
                              onsubmit="return confirm('${g.active ? 'Ngừng hoạt động' : 'Kích hoạt'} thể loại &quot;<c:out value="${g.genreName}"/>&quot;?');">
                          <input type="hidden" name="action" value="toggle-status"/>
                          <input type="hidden" name="id"     value="<c:out value='${g.id}'/>"/>
                          <c:choose>
                            <c:when test="${g.active}">
                              <button type="submit"
                                      class="genre-action-btn genre-action-btn--deactivate"
                                      title="Ngừng hoạt động thể loại">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                     stroke="currentColor" stroke-width="2"
                                     stroke-linecap="round" stroke-linejoin="round">
                                  <circle cx="12" cy="12" r="10"/>
                                  <line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/>
                                </svg>
                              </button>
                            </c:when>
                            <c:otherwise>
                              <button type="submit"
                                      class="genre-action-btn genre-action-btn--activate"
                                      title="Kích hoạt thể loại">
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                     stroke="currentColor" stroke-width="2"
                                     stroke-linecap="round" stroke-linejoin="round">
                                  <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
                                  <polyline points="22 4 12 14.01 9 11.01"/>
                                </svg>
                              </button>
                            </c:otherwise>
                          </c:choose>
                        </form>
                      </c:otherwise>
                    </c:choose>

                    <%-- Delete: disabled khi thể loại đang có phim gắn vào --%>
                    <c:choose>
                      <c:when test="${inUse}">
                        <button class="genre-action-btn genre-action-btn--disabled"
                                title="Không thể xóa — thể loại đang được sử dụng">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                               stroke="currentColor" stroke-width="2"
                               stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="3 6 5 6 21 6"/>
                            <path d="M19 6l-1 14H6L5 6"/>
                            <path d="M10 11v6M14 11v6M9 6V4h6v2"/>
                          </svg>
                        </button>
                      </c:when>
                      <c:otherwise>
                        <form method="post"
                              action="${pageContext.request.contextPath}/manager/genres"
                              style="display:inline"
                              onsubmit="return confirm('Xóa thể loại &quot;<c:out value="${g.genreName}"/>&quot;? Hành động này không thể hoàn tác.');">
                          <input type="hidden" name="action" value="delete"/>
                          <input type="hidden" name="id"     value="<c:out value='${g.id}'/>"/>
                          <button type="submit" class="genre-action-btn genre-action-btn--delete" title="Xóa thể loại">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                                 stroke="currentColor" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                              <polyline points="3 6 5 6 21 6"/>
                              <path d="M19 6l-1 14H6L5 6"/>
                              <path d="M10 11v6M14 11v6M9 6V4h6v2"/>
                            </svg>
                          </button>
                        </form>
                      </c:otherwise>
                    </c:choose>
                  </div>
                </td>

              </tr>
            </c:forEach>
          </tbody>
        </table>

        <div class="genre-pagination">
          <span class="genre-pagination-info" id="paginationInfo"></span>
          <div class="genre-pagination-pages" id="paginationPages"></div>
        </div>
      </c:otherwise>
    </c:choose>
  </div>

</div>

<%-- ── Add Genre Modal ───────────────────────────────────────── --%>
<div class="genre-modal-backdrop" id="addModal">
  <div class="genre-modal">
    <div class="genre-modal-header">
      <h2>Thêm Thể Loại</h2>
      <button class="genre-modal-close" onclick="closeAddModal()">✕</button>
    </div>
    <div class="genre-modal-body">
      <c:if test="${not empty error and empty editGenre}">
        <div class="genre-alert genre-alert--error" style="margin-bottom:16px">
          <c:out value="${error}"/>
        </div>
      </c:if>
      <form method="post" action="${pageContext.request.contextPath}/manager/genres">
        <label for="addGenreName">Tên Thể Loại <span class="required">*</span></label>
        <input id="addGenreName" type="text" name="genreName" maxlength="100"
               value="<c:out value='${inputValue}'/>"
               placeholder="VD: Khoa Học Viễn Tưởng"
               autocomplete="off"/>
        <p class="genre-hint">Không phân biệt hoa thường khi kiểm tra trùng tên.</p>

        <label for="addDescription" style="margin-top:14px;display:block">Mô tả <span class="required">*</span></label>
        <textarea id="addDescription" name="description" rows="3" required maxlength="500"
                  placeholder="Mô tả ngắn về thể loại…"
                  style="resize:vertical"><c:out value='${descriptionValue}'/></textarea>
        <p class="genre-hint">Tối đa 500 ký tự. Hiển thị khi chọn thể loại cho phim.</p>

        <label style="margin-top:12px;display:block">Trạng Thái <span class="required">*</span></label>
        <div class="genre-status-toggle" role="radiogroup" aria-label="Trạng Thái">
          <label class="genre-status-option genre-status-option--active">
            <input type="radio" name="isActive" value="true" checked/>
            <span class="genre-status-dot"></span>
            <span>Hoạt Động</span>
          </label>
          <label class="genre-status-option genre-status-option--inactive">
            <input type="radio" name="isActive" value="false"/>
            <span class="genre-status-dot"></span>
            <span>Ngừng Hoạt Động</span>
          </label>
        </div>

        <div class="genre-modal-actions">
          <button type="submit" class="btn-modal-primary">Thêm Thể Loại</button>
          <button type="button" class="btn-modal-cancel" onclick="closeAddModal()">Hủy</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ── Edit Genre Modal ──────────────────────────────────────── --%>
<div class="genre-modal-backdrop" id="editModal">
  <div class="genre-modal">
    <div class="genre-modal-header">
      <h2>Sửa Thể Loại</h2>
      <button class="genre-modal-close" onclick="closeEditModal()">✕</button>
    </div>
    <div class="genre-modal-body">
      <c:if test="${not empty error and not empty editGenre}">
        <div class="genre-alert genre-alert--error" style="margin-bottom:16px">
          <c:out value="${error}"/>
        </div>
      </c:if>
      <form method="post" action="${pageContext.request.contextPath}/manager/genres">
        <input type="hidden" name="action" value="update"/>
        <input type="hidden" name="id"     id="editGenreId"/>
        <label for="editGenreName">Tên Thể Loại <span class="required">*</span></label>
        <input id="editGenreName" type="text" name="genreName" maxlength="100"
               autocomplete="off"/>
        <p class="genre-hint">Không phân biệt hoa thường khi kiểm tra trùng tên.</p>

        <label for="editDescription" style="margin-top:14px;display:block">Mô tả <span class="required">*</span></label>
        <textarea id="editDescription" name="description" rows="3" required maxlength="500"
                  placeholder="Mô tả ngắn về thể loại…"
                  style="resize:vertical"></textarea>
        <p class="genre-hint">Tối đa 500 ký tự. Hiển thị khi chọn thể loại cho phim.</p>

        <div class="genre-modal-actions">
          <button type="submit" class="btn-modal-primary">Lưu Thay Đổi</button>
          <button type="button" class="btn-modal-cancel" onclick="closeEditModal()">Hủy</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
  const ROWS_PER_PAGE = 6;
  let currentPage  = 1;
  let currentFilter = 'all';
  let filteredRows  = [];

  function getAllRows() {
    return Array.from(document.querySelectorAll('#genreTableBody tr'));
  }

  function applyFilters() {
    const search = (document.getElementById('genreSearch').value || '').toLowerCase().trim();
    filteredRows = getAllRows().filter(row => {
      const name   = row.dataset.name   || '';
      const status = row.dataset.status || '';
      const matchSearch = !search || name.includes(search);
      const matchFilter = currentFilter === 'all' || status === currentFilter;
      return matchSearch && matchFilter;
    });
    currentPage = 1;
    renderPage();
  }

  function renderPage() {
    const total      = filteredRows.length;
    const totalPages = Math.max(1, Math.ceil(total / ROWS_PER_PAGE));
    if (currentPage > totalPages) currentPage = totalPages;

    const start = (currentPage - 1) * ROWS_PER_PAGE;
    const end   = Math.min(start + ROWS_PER_PAGE, total);

    getAllRows().forEach(r => r.style.display = 'none');
    filteredRows.forEach((r, i) => {
      r.style.display = (i >= start && i < end) ? '' : 'none';
    });

    const infoEl = document.getElementById('paginationInfo');
    if (infoEl) {
      infoEl.textContent = total === 0
        ? 'Không có kết quả'
        : 'Hiển thị ' + (start + 1) + ' đến ' + end + ' trong ' + total + ' kết quả';
    }

    renderPagination(totalPages);
  }

  function renderPagination(totalPages) {
    const pages = document.getElementById('paginationPages');
    if (!pages) return;
    pages.innerHTML = '';

    const prev = makePageBtn('‹', currentPage === 1, () => { currentPage--; renderPage(); });
    pages.appendChild(prev);

    const maxVisible = 5;
    let startP = Math.max(1, currentPage - 2);
    let endP   = Math.min(totalPages, startP + maxVisible - 1);
    if (endP - startP < maxVisible - 1) startP = Math.max(1, endP - maxVisible + 1);

    for (let p = startP; p <= endP; p++) {
      const btn = makePageBtn(p, false, ((pg) => () => { currentPage = pg; renderPage(); })(p));
      if (p === currentPage) btn.classList.add('active');
      pages.appendChild(btn);
    }

    const next = makePageBtn('›', currentPage === totalPages, () => { currentPage++; renderPage(); });
    pages.appendChild(next);
  }

  function makePageBtn(label, disabled, onClick) {
    const btn = document.createElement('button');
    btn.className   = 'genre-page-btn';
    btn.textContent = label;
    btn.disabled    = disabled;
    btn.onclick     = onClick;
    return btn;
  }

  function setTab(btn) {
    document.querySelectorAll('.genre-tab').forEach(t => t.classList.remove('active'));
    btn.classList.add('active');
    currentFilter = btn.dataset.filter;
    applyFilters();
  }

  /* ── Modals ────────────────────────────────────────────── */
  function openAddModal() {
    document.getElementById('addModal').classList.add('open');
    document.getElementById('addGenreName').focus();
  }
  function closeAddModal() {
    document.getElementById('addModal').classList.remove('open');
  }
  function openEditModal(id, name, row) {
    document.getElementById('editGenreId').value       = id;
    document.getElementById('editGenreName').value     = name;
    document.getElementById('editDescription').value   = row ? (row.dataset.description || '') : '';
    document.getElementById('editModal').classList.add('open');
    document.getElementById('editGenreName').focus();
  }
  function closeEditModal() {
    document.getElementById('editModal').classList.remove('open');
  }

  ['addModal','editModal'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.addEventListener('click', function(e) {
      if (e.target === this) this.classList.remove('open');
    });
  });

  /* ── Export CSV ────────────────────────────────────────── */
  function exportCSV() {
    let csv = 'Ten The Loai,Slug,So Phim,Trang Thai\n';
    filteredRows.forEach(row => {
      const cells = row.querySelectorAll('td');
      const name  = cells[0].textContent.trim().replace(/"/g, '""');
      const slug  = cells[1].textContent.trim().replace(/"/g, '""');
      const count = cells[2].textContent.trim();
      const status = cells[3].textContent.trim();
      csv += '"' + name + '","' + slug + '","' + count + '","' + status + '"\n';
    });
    const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href = url; a.download = 'genres.csv'; a.click();
    URL.revokeObjectURL(url);
  }

  /* ── Init ──────────────────────────────────────────────── */
  document.addEventListener('DOMContentLoaded', () => {
    applyFilters();

    <c:if test="${not empty editGenre}">
    (function() {
      var fakeRow = { dataset: { description: '<c:out value="${descriptionValue != null ? descriptionValue : editGenre.description}"/>' } };
      openEditModal('<c:out value="${editGenre.id}"/>', '<c:out value="${editGenre.genreName}"/>', fakeRow);
    })();
    </c:if>

    <c:if test="${not empty error and empty editGenre}">
    openAddModal();
    </c:if>
  });
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
