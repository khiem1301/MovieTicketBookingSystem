<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Thể loại — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="mgr-page">

  <div class="mgr-breadcrumb">
    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
    <span>›</span>
    <span>Quản lý Thể loại</span>
  </div>

  <h1 class="mgr-title">Quản lý Thể loại</h1>

  <c:if test="${param.success == 'created'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã thêm thể loại thành công!</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã cập nhật thể loại thành công!</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã xóa thể loại thành công!</div>
  </c:if>

  <div class="mgr-grid">

    <%-- Cột trái: Form tạo mới hoặc chỉnh sửa --%>
    <div class="mgr-card">

      <c:choose>
        <c:when test="${not empty editGenre}">
          <h2 class="mgr-card-title">
            <span class="mgr-card-title-icon">✏️</span> Sửa thể loại
          </h2>

          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>

          <form method="post"
                action="${pageContext.request.contextPath}/manager/genres"
                class="mgr-form">
            <input type="hidden" name="action" value="update"/>
            <input type="hidden" name="id"     value="<c:out value='${editGenre.id}'/>"/>

            <div class="mgr-form-group">
              <label for="genreName">
                Tên thể loại <span class="required">*</span>
              </label>
              <input id="genreName" type="text" name="genreName"
                     value="<c:out value='${not empty inputValue ? inputValue : editGenre.genreName}'/>"
                     maxlength="100" autocomplete="off" required/>
              <span class="mgr-hint">Không phân biệt hoa thường khi kiểm tra trùng.</span>
            </div>

            <div class="mgr-form-actions">
              <button type="submit" class="btn btn-primary mgr-submit">
                💾 Lưu thay đổi
              </button>
              <a href="${pageContext.request.contextPath}/manager/genres"
                 class="btn btn-ghost mgr-submit">
                Hủy
              </a>
            </div>
          </form>
        </c:when>

        <c:otherwise>
          <h2 class="mgr-card-title">
            <span class="mgr-card-title-icon">＋</span> Thêm thể loại mới
          </h2>

          <c:if test="${not empty error}">
            <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
          </c:if>

          <form method="post"
                action="${pageContext.request.contextPath}/manager/genres"
                class="mgr-form">

            <div class="mgr-form-group">
              <label for="genreName">
                Tên thể loại <span class="required">*</span>
              </label>
              <input id="genreName" type="text" name="genreName"
                     value="<c:out value='${inputValue}'/>"
                     placeholder="VD: Khoa học viễn tưởng"
                     maxlength="100" autocomplete="off" required/>
              <span class="mgr-hint">Không phân biệt hoa thường khi kiểm tra trùng.</span>
            </div>

            <button type="submit" class="btn btn-primary mgr-submit">
              + Thêm thể loại
            </button>
          </form>
        </c:otherwise>
      </c:choose>

    </div>

    <%-- Cột phải: Danh sách thể loại --%>
    <div class="mgr-card">
      <h2 class="mgr-card-title">
        Danh sách thể loại
        <span class="mgr-count">${fn:length(genreList)}</span>
      </h2>

      <c:choose>
        <c:when test="${empty genreList}">
          <p class="mgr-empty">Chưa có thể loại nào.</p>
        </c:when>
        <c:otherwise>
          <table class="mgr-table">
            <thead>
              <tr>
                <th style="width:44px">#</th>
                <th>Tên thể loại</th>
                <th style="width:120px">Ngày tạo</th>
                <th style="width:110px">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="g" items="${genreList}" varStatus="st">
                <tr class="${editGenre.id == g.id ? 'mgr-row--editing' : ''}">

                  <td class="mgr-td-num">${st.count}</td>

                  <td>
                    <c:out value="${g.genreName}"/>
                    <c:if test="${editGenre.id == g.id}">
                      <span class="mgr-editing-badge">đang sửa</span>
                    </c:if>
                  </td>

                  <td class="mgr-td-date">
                    <fmt:formatDate value="${g.createdAt}" pattern="dd/MM/yyyy"/>
                  </td>

                  <td class="mgr-td-actions">
                    <div class="mgr-action-group">
                      <c:choose>
                        <c:when test="${genreIdsInUse.contains(g.id)}">
                          <span class="mgr-btn mgr-btn--disabled"
                                title="Đang có phim sử dụng — không thể sửa hoặc xóa">🔒</span>
                        </c:when>
                        <c:otherwise>
                          <a href="${pageContext.request.contextPath}/manager/genres?action=edit&id=<c:out value='${g.id}'/>"
                             class="mgr-btn mgr-btn--edit"
                             title="Sửa thể loại">✏️</a>
                          <form method="post"
                                action="${pageContext.request.contextPath}/manager/genres"
                                class="mgr-inline-form"
                                onsubmit="return confirm('Xóa thể loại &quot;<c:out value='${g.genreName}'/>&quot;?');">
                            <input type="hidden" name="action" value="delete"/>
                            <input type="hidden" name="id" value="<c:out value='${g.id}'/>"/>
                            <button type="submit" class="mgr-btn mgr-btn--delete" title="Xóa thể loại">🗑️</button>
                          </form>
                        </c:otherwise>
                      </c:choose>
                    </div>
                  </td>

                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</div>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
