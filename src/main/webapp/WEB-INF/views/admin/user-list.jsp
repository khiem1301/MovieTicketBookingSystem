<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>

<c:set var="pageTitle" value="Quản lý người dùng — ÉPCINE"/>
<c:set var="extraCss" value="admin"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<main class="admin-page">
  <div class="container">

    <nav class="admin-breadcrumb">
      <a href="${pageContext.request.contextPath}/admin/dashboard">Bảng điều khiển</a>
      <span class="admin-breadcrumb-sep">/</span>
      <span>Quản lý người dùng</span>
    </nav>

    <div class="admin-page-header">
      <div>
        <h1 class="admin-page-title">Quản lý người dùng</h1>
        <p class="admin-page-subtitle">Tạo tài khoản Staff/Manager và khóa tài khoản</p>
      </div>
      <a href="${pageContext.request.contextPath}/admin/users/create" class="admin-btn admin-btn--primary">
        + Tạo tài khoản
      </a>
    </div>

    <c:if test="${not empty flashSuccess}">
      <div class="admin-alert admin-alert--success" role="status">
        <c:out value="${flashSuccess}"/>
      </div>
    </c:if>
    <c:if test="${not empty flashError}">
      <div class="admin-alert admin-alert--error" role="alert">
        <c:out value="${flashError}"/>
      </div>
    </c:if>

    <div class="admin-card">
      <div class="admin-filter" id="userFilterForm">
        <div class="admin-field admin-field--grow">
          <label class="admin-label" for="userKeyword">Tìm kiếm</label>
          <input type="search" id="userKeyword" class="admin-input"
                 placeholder="Họ tên, email, username, SĐT..."
                 autocomplete="off"/>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="role">Vai trò</label>
          <select id="role" class="admin-select">
            <option value="">Tất cả</option>
            <c:forEach var="role" items="${roles}">
              <option value="${role.roleName}"><c:out value="${role.roleName}"/></option>
            </c:forEach>
          </select>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="status">Trạng thái</label>
          <select id="status" class="admin-select">
            <option value="">Tất cả</option>
            <option value="ACTIVE">ACTIVE</option>
            <option value="INACTIVE">INACTIVE</option>
            <option value="BANNED">BANNED</option>
          </select>
        </div>
        <button type="button" id="userFilterReset" class="admin-btn admin-btn--ghost">Xóa lọc</button>
      </div>

      <c:choose>
        <c:when test="${not empty users}">
          <div class="admin-table-wrap">
            <table class="admin-table">
              <thead>
                <tr>
                  <th>Họ tên</th>
                  <th>Email / Username</th>
                  <th>SĐT</th>
                  <th>Vai trò</th>
                  <th>Trạng thái</th>
                  <th>Đăng nhập cuối</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody id="usersTableBody">
                <c:forEach var="user" items="${users}">
                  <c:set var="searchBlob" value="${user.fullName} ${user.email} ${user.username} ${user.phoneNumber}"/>
                  <tr data-search="<c:out value='${fn:toLowerCase(searchBlob)}'/>"
                      data-role="<c:out value='${user.roleName}'/>"
                      data-status="<c:out value='${user.status}'/>">
                    <td><c:out value="${user.fullName}"/></td>
                    <td class="cell-muted">
                      <c:if test="${not empty user.email}">
                        <c:out value="${user.email}"/><br/>
                      </c:if>
                      <c:if test="${not empty user.username}">
                        <c:out value="${user.username}"/>
                      </c:if>
                    </td>
                    <td class="cell-muted"><c:out value="${user.phoneNumber}"/></td>
                    <td>
                      <span class="admin-badge admin-badge--role">
                        <c:out value="${user.roleName}"/>
                      </span>
                    </td>
                    <td>
                      <c:choose>
                        <c:when test="${user.status == 'ACTIVE'}">
                          <span class="admin-badge admin-badge--active">Active</span>
                        </c:when>
                        <c:when test="${user.status == 'BANNED'}">
                          <span class="admin-badge admin-badge--banned">Banned</span>
                        </c:when>
                        <c:otherwise>
                          <span class="admin-badge admin-badge--inactive">Inactive</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="cell-muted">
                      <c:choose>
                        <c:when test="${not empty user.lastLoginAt}">
                          <fmt:formatDate value="${user.lastLoginAt}" pattern="dd/MM/yyyy HH:mm"/>
                        </c:when>
                        <c:otherwise>—</c:otherwise>
                      </c:choose>
                    </td>
                    <td>
                      <a href="${pageContext.request.contextPath}/admin/users/detail?id=${user.id}"
                         class="admin-btn admin-btn--ghost admin-btn--sm">
                        Chi tiết
                      </a>
                    </td>
                  </tr>
                </c:forEach>
                <tr id="userEmptyRow" style="display:none">
                  <td colspan="7" class="admin-empty">Không tìm thấy người dùng nào.</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="admin-pagination" id="userPagination">
            <span class="admin-pagination-info" id="userPagInfo"></span>
            <div class="admin-btn-group">
              <button type="button" id="userPrevBtn" class="admin-btn admin-btn--ghost admin-btn--sm admin-pagination-nav">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                  <path d="M15 18l-6-6 6-6" stroke="currentColor" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Trước
              </button>
              <button type="button" id="userNextBtn" class="admin-btn admin-btn--ghost admin-btn--sm admin-pagination-nav">
                Sau
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                  <path d="M9 18l6-6-6-6" stroke="currentColor" stroke-width="2.25" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </button>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <div class="admin-empty">Không tìm thấy người dùng nào.</div>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</main>

<script>
(function () {
  var tbody = document.getElementById('usersTableBody');
  if (!tbody) return;

  var PAGE_SIZE = 10;
  var page = 1;
  var visibleRows = [];

  var keywordInput = document.getElementById('userKeyword');
  var roleSelect    = document.getElementById('role');
  var statusSelect  = document.getElementById('status');
  var resetBtn      = document.getElementById('userFilterReset');
  var emptyRow      = document.getElementById('userEmptyRow');
  var pagInfo       = document.getElementById('userPagInfo');
  var prevBtn       = document.getElementById('userPrevBtn');
  var nextBtn       = document.getElementById('userNextBtn');

  function getAllRows() {
    return Array.from(tbody.querySelectorAll('tr')).filter(function (r) { return r !== emptyRow; });
  }

  function applyFilters() {
    var kw     = (keywordInput.value || '').toLowerCase().trim();
    var role   = roleSelect.value;
    var status = statusSelect.value;

    visibleRows = getAllRows().filter(function (r) {
      return (!kw || (r.dataset.search || '').indexOf(kw) !== -1) &&
             (!role || r.dataset.role === role) &&
             (!status || r.dataset.status === status);
    });
    page = 1;
    renderPage();
  }

  function renderPage() {
    var total = visibleRows.length;
    var pages = Math.max(1, Math.ceil(total / PAGE_SIZE));
    if (page > pages) page = pages;
    var s = (page - 1) * PAGE_SIZE, e = Math.min(s + PAGE_SIZE, total);

    getAllRows().forEach(function (r) { r.style.display = 'none'; });
    visibleRows.forEach(function (r, i) { r.style.display = (i >= s && i < e) ? '' : 'none'; });

    if (emptyRow) emptyRow.style.display = total === 0 ? '' : 'none';
    if (pagInfo) {
      pagInfo.textContent = total === 0
        ? 'Không có kết quả'
        : 'Hiển thị ' + (s + 1) + ' đến ' + e + ' trong ' + total + ' tài khoản';
    }
    if (prevBtn) prevBtn.disabled = page <= 1;
    if (nextBtn) nextBtn.disabled = page >= pages;
  }

  keywordInput.addEventListener('input', applyFilters);
  roleSelect.addEventListener('change', applyFilters);
  statusSelect.addEventListener('change', applyFilters);

  if (resetBtn) {
    resetBtn.addEventListener('click', function () {
      keywordInput.value = '';
      roleSelect.value = '';
      statusSelect.value = '';
      applyFilters();
    });
  }

  if (prevBtn) prevBtn.addEventListener('click', function () { if (page > 1) { page--; renderPage(); } });
  if (nextBtn) nextBtn.addEventListener('click', function () { page++; renderPage(); });

  applyFilters();
}());
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
