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
      <form class="admin-filter" id="userFilterForm" method="get" action="${pageContext.request.contextPath}/admin/users">
        <div class="admin-field admin-field--grow">
          <label class="admin-label" for="userKeyword">Tìm kiếm</label>
          <input type="search" id="userKeyword" name="keyword" class="admin-input"
                 placeholder="Họ tên, email, username, SĐT..."
                 autocomplete="off"
                 value="<c:out value='${filterQ}'/>"/>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="role">Vai trò</label>
          <select id="role" name="role" class="admin-select">
            <option value="">Tất cả</option>
            <c:forEach var="role" items="${roles}">
              <option value="${role.roleName}"
                      <c:if test="${filterRole == role.roleName}">selected</c:if>>
                <c:out value="${role.roleName}"/>
              </option>
            </c:forEach>
          </select>
        </div>
        <div class="admin-field">
          <label class="admin-label" for="status">Trạng thái</label>
          <select id="status" name="status" class="admin-select">
            <option value="">Tất cả</option>
            <option value="ACTIVE"   <c:if test="${filterStatus == 'ACTIVE'}">selected</c:if>>ACTIVE</option>
            <option value="INACTIVE" <c:if test="${filterStatus == 'INACTIVE'}">selected</c:if>>INACTIVE</option>
            <option value="BANNED"   <c:if test="${filterStatus == 'BANNED'}">selected</c:if>>BANNED</option>
          </select>
        </div>
        <button type="button" id="userFilterReset" class="admin-btn admin-btn--ghost">Xóa lọc</button>
      </form>

      <p class="admin-stats">Tổng: <strong><c:out value="${totalUsers}"/></strong> tài khoản</p>

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
              <tbody>
                <c:forEach var="user" items="${users}">
                  <tr>
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
              </tbody>
            </table>
          </div>

          <c:set var="pgCurrent" value="${currentPage}"/>
          <c:set var="pgTotal" value="${totalPages}"/>
          <c:set var="pgTotalItems" value="${totalUsers}"/>
          <%@ include file="/WEB-INF/views/admin/pagination.jspf" %>
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
  var form = document.getElementById('userFilterForm');
  if (!form) return;

  var keywordInput = document.getElementById('userKeyword');
  var roleSelect = document.getElementById('role');
  var statusSelect = document.getElementById('status');
  var resetBtn = document.getElementById('userFilterReset');
  var debounceTimer = null;
  var DEBOUNCE_MS = 350;

  function submitFilters() {
    if (typeof form.requestSubmit === 'function') {
      form.requestSubmit();
    } else {
      form.submit();
    }
  }

  if (keywordInput) {
    keywordInput.addEventListener('input', function () {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(submitFilters, DEBOUNCE_MS);
    });
    keywordInput.addEventListener('keydown', function (event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        clearTimeout(debounceTimer);
        submitFilters();
      }
    });
  }

  if (roleSelect) {
    roleSelect.addEventListener('change', submitFilters);
  }

  if (statusSelect) {
    statusSelect.addEventListener('change', submitFilters);
  }

  if (resetBtn) {
    resetBtn.addEventListener('click', function () {
      window.location.href = '${pageContext.request.contextPath}/admin/users';
    });
  }
}());
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
