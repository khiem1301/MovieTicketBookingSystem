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
        <p class="admin-page-subtitle">Tạo tài khoản Staff/Manager, khóa và đặt lại mật khẩu</p>
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
      <form class="admin-filter" method="get" action="${pageContext.request.contextPath}/admin/users">
        <div class="admin-field admin-field--grow">
          <label class="admin-label" for="q">Tìm kiếm</label>
          <input type="text" id="q" name="q" class="admin-input"
                 placeholder="Họ tên, email, username, SĐT..."
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
        <button type="submit" class="admin-btn admin-btn--ghost">Lọc</button>
        <a href="${pageContext.request.contextPath}/admin/users" class="admin-btn admin-btn--ghost">Xóa lọc</a>
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
                        @<c:out value="${user.username}"/>
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

          <c:if test="${totalPages > 1}">
            <div class="admin-pagination">
              <span>Trang <c:out value="${currentPage}"/> / <c:out value="${totalPages}"/></span>
              <div class="admin-btn-group">
                <c:if test="${currentPage > 1}">
                  <a class="admin-btn admin-btn--ghost admin-btn--sm"
                     href="${pageContext.request.contextPath}/admin/users?page=${currentPage - 1}&q=${filterQ}&role=${filterRole}&status=${filterStatus}">
                    ← Trước
                  </a>
                </c:if>
                <c:if test="${currentPage < totalPages}">
                  <a class="admin-btn admin-btn--ghost admin-btn--sm"
                     href="${pageContext.request.contextPath}/admin/users?page=${currentPage + 1}&q=${filterQ}&role=${filterRole}&status=${filterStatus}">
                    Sau →
                  </a>
                </c:if>
              </div>
            </div>
          </c:if>
        </c:when>
        <c:otherwise>
          <div class="admin-empty">Không tìm thấy người dùng nào.</div>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
