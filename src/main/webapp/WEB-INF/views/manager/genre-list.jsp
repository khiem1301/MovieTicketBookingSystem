<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Genre Management — ÉPCINE"/>
<c:set var="extraCss"  value="manager-genres"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="genre-page">

  <%-- Toast alerts --%>
  <c:if test="${param.success == 'created'}">
    <div class="genre-alert genre-alert--success">Genre added successfully.</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="genre-alert genre-alert--success">Genre updated successfully.</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="genre-alert genre-alert--success">Genre deleted successfully.</div>
  </c:if>
  <c:if test="${param.success == 'status-updated'}">
    <div class="genre-alert genre-alert--success">Genre status updated successfully.</div>
  </c:if>

  <%-- Page Header --%>
  <div class="genre-header">
    <div class="genre-header-left">
      <h1>Genre Management</h1>
      <p>Organize and manage your cinema's movie categorization system.</p>
    </div>
    <div class="genre-header-right">
      <div class="genre-search">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2"
             stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input type="text" id="genreSearch" placeholder="Search genres…" oninput="applyFilters()"/>
      </div>
      <button class="btn-add-genre" onclick="openAddModal()">+ Add Genre</button>
    </div>
  </div>

  <%-- Filter Bar --%>
  <div class="genre-filter-bar">
    <div class="genre-tabs">
      <button class="genre-tab active" data-filter="all"      onclick="setTab(this)">All</button>
      <button class="genre-tab"        data-filter="active"   onclick="setTab(this)">Active</button>
      <button class="genre-tab"        data-filter="inactive" onclick="setTab(this)">Inactive</button>
    </div>
    <div class="genre-filter-icons">
      <div class="genre-filter-icon" title="Filter">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="4" y1="6" x2="20" y2="6"/>
          <line x1="8" y1="12" x2="16" y2="12"/>
          <line x1="11" y1="18" x2="13" y2="18"/>
        </svg>
      </div>
      <div class="genre-filter-icon" title="Export CSV" onclick="exportCSV()">
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
        <div class="genre-empty">No genres found. Click <strong>+ Add Genre</strong> to create one.</div>
      </c:when>
      <c:otherwise>
        <table class="genre-table">
          <thead>
            <tr>
              <th>Genre Name</th>
              <th>Slug</th>
              <th>Movie Count</th>
              <th>Status</th>
              <th>Actions</th>
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

                <td>${movieCount} movie${movieCount != 1 ? 's' : ''}</td>

                <td>
                  <c:choose>
                    <c:when test="${g.active}">
                      <span class="status-badge status-badge--active">Active</span>
                    </c:when>
                    <c:otherwise>
                      <span class="status-badge status-badge--inactive">Inactive</span>
                    </c:otherwise>
                  </c:choose>
                </td>

                <td>
                  <div class="genre-actions">
                    <%-- Edit name: disabled khi thể loại đang có phim gắn vào --%>
                    <c:choose>
                      <c:when test="${inUse}">
                        <button class="genre-action-btn genre-action-btn--disabled"
                                title="Cannot edit — genre is in use">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
                               stroke="currentColor" stroke-width="2"
                               stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 20h9"/>
                            <path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                          </svg>
                        </button>
                      </c:when>
                      <c:otherwise>
                        <button class="genre-action-btn genre-action-btn--edit" title="Edit genre"
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
                                title="Cannot change status — genre has now-showing or upcoming movies">
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
                              onsubmit="return confirm('${g.active ? 'Deactivate' : 'Activate'} genre &quot;<c:out value="${g.genreName}"/>&quot;?');">
                          <input type="hidden" name="action" value="toggle-status"/>
                          <input type="hidden" name="id"     value="<c:out value='${g.id}'/>"/>
                          <c:choose>
                            <c:when test="${g.active}">
                              <button type="submit"
                                      class="genre-action-btn genre-action-btn--deactivate"
                                      title="Deactivate genre">
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
                                      title="Activate genre">
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
                                title="Cannot delete — genre is in use">
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
                              onsubmit="return confirm('Delete genre &quot;<c:out value="${g.genreName}"/>&quot;? This cannot be undone.');">
                          <input type="hidden" name="action" value="delete"/>
                          <input type="hidden" name="id"     value="<c:out value='${g.id}'/>"/>
                          <button type="submit" class="genre-action-btn genre-action-btn--delete" title="Delete genre">
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
      <h2>Add Genre</h2>
      <button class="genre-modal-close" onclick="closeAddModal()">✕</button>
    </div>
    <div class="genre-modal-body">
      <c:if test="${not empty error and empty editGenre}">
        <div class="genre-alert genre-alert--error" style="margin-bottom:16px">
          <c:out value="${error}"/>
        </div>
      </c:if>
      <form method="post" action="${pageContext.request.contextPath}/manager/genres">
        <label for="addGenreName">Genre Name <span class="required">*</span></label>
        <input id="addGenreName" type="text" name="genreName"
               value="<c:out value='${inputValue}'/>"
               placeholder="e.g. Science Fiction"
               maxlength="100" autocomplete="off" required/>
        <p class="genre-hint">Name is case-insensitive when checking for duplicates.</p>

        <label for="addDescription" style="margin-top:14px;display:block">Mô tả</label>
        <textarea id="addDescription" name="description" rows="3" maxlength="500"
                  placeholder="Mô tả ngắn về thể loại…"
                  style="resize:vertical"><c:out value='${descriptionValue}'/></textarea>
        <p class="genre-hint">Tối đa 500 ký tự. Hiển thị khi chọn thể loại cho phim.</p>

        <label style="margin-top:12px;display:block">Status <span class="required">*</span></label>
        <div class="genre-status-radios">
          <label class="genre-status-radio">
            <input type="radio" name="isActive" value="true" checked/>
            <span class="status-badge status-badge--active">Active</span>
          </label>
          <label class="genre-status-radio">
            <input type="radio" name="isActive" value="false"/>
            <span class="status-badge status-badge--inactive">Inactive</span>
          </label>
        </div>

        <div class="genre-modal-actions">
          <button type="submit" class="btn-modal-primary">Add Genre</button>
          <button type="button" class="btn-modal-cancel" onclick="closeAddModal()">Cancel</button>
        </div>
      </form>
    </div>
  </div>
</div>

<%-- ── Edit Genre Modal ──────────────────────────────────────── --%>
<div class="genre-modal-backdrop" id="editModal">
  <div class="genre-modal">
    <div class="genre-modal-header">
      <h2>Edit Genre</h2>
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
        <label for="editGenreName">Genre Name <span class="required">*</span></label>
        <input id="editGenreName" type="text" name="genreName"
               maxlength="100" autocomplete="off" required/>
        <p class="genre-hint">Name is case-insensitive when checking for duplicates.</p>

        <label for="editDescription" style="margin-top:14px;display:block">Mô tả</label>
        <textarea id="editDescription" name="description" rows="3" maxlength="500"
                  placeholder="Mô tả ngắn về thể loại…"
                  style="resize:vertical"></textarea>
        <p class="genre-hint">Tối đa 500 ký tự. Hiển thị khi chọn thể loại cho phim.</p>

        <div class="genre-modal-actions">
          <button type="submit" class="btn-modal-primary">Save Changes</button>
          <button type="button" class="btn-modal-cancel" onclick="closeEditModal()">Cancel</button>
        </div>
      </form>
    </div>
  </div>
</div>

<script>
  const ROWS_PER_PAGE = 5;
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
        ? 'No results found'
        : 'Showing ' + (start + 1) + ' to ' + end + ' of ' + total + ' results';
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
    let csv = 'Genre Name,Slug,Movie Count,Status\n';
    filteredRows.forEach(row => {
      const cells = row.querySelectorAll('td');
      const name  = cells[0].textContent.trim().replace(/"/g, '""');
      const slug  = cells[1].textContent.trim().replace(/"/g, '""');
      const count = cells[2].textContent.trim();
      const status = cells[3].textContent.trim();
      csv += '"' + name + '","' + slug + '","' + count + '","' + status + '"\n';
    });
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
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
