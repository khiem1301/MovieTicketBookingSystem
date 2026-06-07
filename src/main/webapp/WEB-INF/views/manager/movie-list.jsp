<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản lý Phim — ÉPCINE"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<div class="mgr-page">

  <div class="mgr-breadcrumb">
    <a href="${pageContext.request.contextPath}/home">Trang chủ</a>
    <span>›</span>
    <span>Quản lý Phim</span>
  </div>

  <h1 class="mgr-title">Quản lý Phim</h1>

  <c:if test="${param.success == 'created'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã thêm phim thành công!</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mgr-alert mgr-alert--success">✓ Đã cập nhật phim thành công!</div>
  </c:if>

  <div class="mgr-movie-grid">

    <%-- Form tạo / sửa --%>
    <div class="mgr-card mgr-card--form">

      <c:choose>
        <c:when test="${not empty editMovie}">
          <c:set var="m" value="${not empty formMovie ? formMovie : editMovie}"/>
          <h2 class="mgr-card-title">
            <span class="mgr-card-title-icon">✏️</span> Sửa phim
          </h2>
        </c:when>
        <c:otherwise>
          <c:set var="m" value="${formMovie}"/>
          <h2 class="mgr-card-title">
            <span class="mgr-card-title-icon">＋</span> Thêm phim mới
          </h2>
        </c:otherwise>
      </c:choose>

      <c:if test="${not empty error}">
        <div class="mgr-alert mgr-alert--error"><c:out value="${error}"/></div>
      </c:if>

      <form method="post"
            action="${pageContext.request.contextPath}/manager/movies"
            class="mgr-form mgr-form--movie"
            enctype="multipart/form-data">
        <input type="hidden" name="action"
               value="${not empty editMovie ? 'update' : 'create'}"/>
        <c:if test="${not empty editMovie}">
          <input type="hidden" name="id" value="<c:out value='${editMovie.id}'/>"/>
          <input type="hidden" name="existingPosterUrl"
                 value="<c:out value='${editMovie.posterUrl}'/>"/>
          <input type="hidden" name="existingBackdropUrl"
                 value="<c:out value='${editMovie.backdropUrl}'/>"/>
        </c:if>

        <div class="mgr-form-group">
          <label for="title">Tên phim <span class="required">*</span></label>
          <input id="title" type="text" name="title" maxlength="255" required
                 value="<c:out value='${m.title}'/>"/>
        </div>

        <div class="mgr-form-group">
          <label for="slug">Slug <span class="required">*</span></label>
          <input id="slug" type="text" name="slug" maxlength="255" required
                 value="<c:out value='${m.slug}'/>"
                 placeholder="VD: avengers-doomsday"/>
          <span class="mgr-hint">Duy nhất, dùng cho URL. Không trùng với phim khác.</span>
        </div>

        <div class="mgr-form-group">
          <label for="description">Mô tả</label>
          <textarea id="description" name="description" rows="3"
                    maxlength="4000"><c:out value='${m.description}'/></textarea>
        </div>

        <div class="mgr-form-row">
          <div class="mgr-form-group">
            <label for="durationMinutes">Thời lượng (phút) <span class="required">*</span></label>
            <input id="durationMinutes" type="number" name="durationMinutes"
                   min="1" max="999" required
                   value="<c:if test='${not empty m and m.durationMinutes > 0}'><c:out value='${m.durationMinutes}'/></c:if>"/>
          </div>
          <div class="mgr-form-group">
            <label for="releaseDate">Ngày khởi chiếu</label>
            <input id="releaseDate" type="date" name="releaseDate"
                   value="<c:if test='${not empty m.releaseDate}'><fmt:formatDate value='${m.releaseDate}' pattern='yyyy-MM-dd'/></c:if>"/>
          </div>
        </div>

        <div class="mgr-form-row">
          <div class="mgr-form-group">
            <label for="status">Trạng thái <span class="required">*</span></label>
            <select id="status" name="status" required>
              <option value="COMING_SOON" <c:if test="${empty m or m.status == 'COMING_SOON'}">selected</c:if>>Sắp chiếu</option>
              <option value="NOW_SHOWING" <c:if test="${m.status == 'NOW_SHOWING'}">selected</c:if>>Đang chiếu</option>
              <option value="ENDED"       <c:if test="${m.status == 'ENDED'}">selected</c:if>>Đã kết thúc</option>
            </select>
          </div>
          <div class="mgr-form-group">
            <label for="ageRating">Độ tuổi</label>
            <select id="ageRating" name="ageRating">
              <option value=""  <c:if test="${empty m or empty m.ageRating}">selected</c:if>>— Không chọn —</option>
              <option value="P"   <c:if test="${m.ageRating == 'P'}">selected</c:if>>P</option>
              <option value="K"   <c:if test="${m.ageRating == 'K'}">selected</c:if>>K</option>
              <option value="T13" <c:if test="${m.ageRating == 'T13'}">selected</c:if>>T13</option>
              <option value="T16" <c:if test="${m.ageRating == 'T16'}">selected</c:if>>T16</option>
              <option value="T18" <c:if test="${m.ageRating == 'T18'}">selected</c:if>>T18</option>
              <option value="C"   <c:if test="${m.ageRating == 'C'}">selected</c:if>>C</option>
            </select>
          </div>
        </div>

        <div class="mgr-form-group">
          <label for="director">Đạo diễn</label>
          <input id="director" type="text" name="director" maxlength="255"
                 value="<c:out value='${m.director}'/>"/>
        </div>

        <div class="mgr-form-row">
          <div class="mgr-form-group">
            <label for="language">Ngôn ngữ</label>
            <input id="language" type="text" name="language" maxlength="50"
                   value="<c:out value='${m.language}'/>"/>
          </div>
          <div class="mgr-form-group">
            <label for="subtitle">Phụ đề</label>
            <input id="subtitle" type="text" name="subtitle" maxlength="50"
                   value="<c:out value='${m.subtitle}'/>"/>
          </div>
        </div>

        <div class="mgr-form-group">
          <label for="trailerUrl">URL Trailer</label>
          <input id="trailerUrl" type="url" name="trailerUrl"
                 value="<c:out value='${m.trailerUrl}'/>"/>
        </div>

        <%-- Poster: upload hoặc URL --%>
        <div class="mgr-form-group">
          <label>Poster (ảnh dọc)</label>
          <c:if test="${not empty m.posterUrl}">
            <span class="mgr-hint">
              <c:choose>
                <c:when test="${not empty editMovie}">Ảnh hiện tại</c:when>
                <c:otherwise>Xem trước</c:otherwise>
              </c:choose>
            </span>
            <c:set var="posterPreview" value="${m.posterUrl}"/>
            <c:if test="${not fn:startsWith(posterPreview, 'http')}">
              <c:set var="posterPreview" value="${pageContext.request.contextPath}/${posterPreview}"/>
            </c:if>
            <img id="posterPreview" class="mgr-img-preview"
                 src="<c:out value='${posterPreview}'/>" alt="Poster"/>
          </c:if>
          <c:if test="${empty m.posterUrl}">
            <img id="posterPreview" class="mgr-img-preview" alt="Poster" hidden/>
          </c:if>
          <label class="mgr-file-label" for="posterFile">
            <c:choose>
              <c:when test="${not empty editMovie}">Chọn file poster mới</c:when>
              <c:otherwise>Tải ảnh lên</c:otherwise>
            </c:choose>
          </label>
          <input id="posterFile" type="file" name="posterFile"
                 accept="image/jpeg,image/png,image/webp" class="mgr-file-input"/>
          <span class="mgr-hint">JPG, PNG, WEBP — tối đa 5 MB. File mới được ưu tiên hơn URL.</span>
          <label for="posterUrl" class="mgr-hint" style="margin-top:8px;">
            <c:choose>
              <c:when test="${not empty editMovie}">Hoặc nhập URL poster mới:</c:when>
              <c:otherwise>Hoặc dán URL:</c:otherwise>
            </c:choose>
          </label>
          <input id="posterUrl" type="text" name="posterUrl"
                 placeholder="${not empty editMovie
                   ? 'https://... — để trống nếu giữ ảnh cũ'
                   : 'https://... hoặc để trống nếu đã tải ảnh'}"
                 value="<c:out value='${posterUrlInput}'/>"/>
        </div>

        <%-- Backdrop: upload hoặc URL --%>
        <div class="mgr-form-group">
          <label>Backdrop (ảnh nền ngang)</label>
          <c:if test="${not empty m.backdropUrl}">
            <span class="mgr-hint">
              <c:choose>
                <c:when test="${not empty editMovie}">Ảnh hiện tại</c:when>
                <c:otherwise>Xem trước</c:otherwise>
              </c:choose>
            </span>
            <c:set var="backdropPreview" value="${m.backdropUrl}"/>
            <c:if test="${not fn:startsWith(backdropPreview, 'http')}">
              <c:set var="backdropPreview" value="${pageContext.request.contextPath}/${backdropPreview}"/>
            </c:if>
            <img id="backdropPreview" class="mgr-img-preview mgr-img-preview--wide"
                 src="<c:out value='${backdropPreview}'/>" alt="Backdrop"/>
          </c:if>
          <c:if test="${empty m.backdropUrl}">
            <img id="backdropPreview" class="mgr-img-preview mgr-img-preview--wide"
                 alt="Backdrop" hidden/>
          </c:if>
          <label class="mgr-file-label" for="backdropFile">
            <c:choose>
              <c:when test="${not empty editMovie}">Chọn file backdrop mới</c:when>
              <c:otherwise>Tải ảnh lên</c:otherwise>
            </c:choose>
          </label>
          <input id="backdropFile" type="file" name="backdropFile"
                 accept="image/jpeg,image/png,image/webp" class="mgr-file-input"/>
          <span class="mgr-hint">JPG, PNG, WEBP — tối đa 5 MB. File mới được ưu tiên hơn URL.</span>
          <label for="backdropUrl" class="mgr-hint" style="margin-top:8px;">
            <c:choose>
              <c:when test="${not empty editMovie}">Hoặc nhập URL backdrop mới:</c:when>
              <c:otherwise>Hoặc dán URL:</c:otherwise>
            </c:choose>
          </label>
          <input id="backdropUrl" type="text" name="backdropUrl"
                 placeholder="${not empty editMovie
                   ? 'https://... — để trống nếu giữ ảnh cũ'
                   : 'https://... hoặc để trống nếu đã tải ảnh'}"
                 value="<c:out value='${backdropUrlInput}'/>"/>
        </div>

        <div class="mgr-form-group">
          <label>Thể loại</label>
          <div class="mgr-genre-grid">
            <c:forEach var="genre" items="${genreList}">
              <label class="mgr-genre-check">
                <input type="checkbox" name="genreIds" value="<c:out value='${genre.id}'/>"
                  <c:if test="${not empty selectedGenreIds and selectedGenreIds.contains(genre.id)}">checked</c:if>/>
                <c:out value="${genre.genreName}"/>
              </label>
            </c:forEach>
          </div>
        </div>

        <div class="mgr-form-actions">
          <button type="submit" class="btn btn-primary mgr-submit">
            <c:choose>
              <c:when test="${not empty editMovie}">💾 Lưu thay đổi</c:when>
              <c:otherwise>+ Thêm phim</c:otherwise>
            </c:choose>
          </button>
          <c:if test="${not empty editMovie}">
            <a href="${pageContext.request.contextPath}/manager/movies"
               class="btn btn-ghost mgr-submit">Hủy</a>
          </c:if>
        </div>
      </form>
    </div>

    <%-- Danh sách phim --%>
    <div class="mgr-card">
      <h2 class="mgr-card-title">
        Danh sách phim
        <span class="mgr-count">${fn:length(movieList)}</span>
      </h2>

      <c:choose>
        <c:when test="${empty movieList}">
          <p class="mgr-empty">Chưa có phim nào.</p>
        </c:when>
        <c:otherwise>
          <div class="mgr-table-wrap">
            <table class="mgr-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Tên phim</th>
                  <th>Trạng thái</th>
                  <th>Thời lượng</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="mv" items="${movieList}" varStatus="st">
                  <tr class="${editMovie.id == mv.id ? 'mgr-row--editing' : ''}">
                    <td class="mgr-td-num">${st.count}</td>
                    <td>
                      <c:out value="${mv.title}"/>
                      <div class="mgr-slug"><c:out value="${mv.slug}"/></div>
                    </td>
                    <td>
                      <c:choose>
                        <c:when test="${mv.status == 'NOW_SHOWING'}">
                          <span class="mgr-status mgr-status--valid">Đang chiếu</span>
                        </c:when>
                        <c:when test="${mv.status == 'COMING_SOON'}">
                          <span class="mgr-status mgr-status--pending">Sắp chiếu</span>
                        </c:when>
                        <c:otherwise>
                          <span class="mgr-status mgr-status--invalid">Đã kết thúc</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="mgr-td-date">${mv.durationMinutes} phút</td>
                    <td>
                      <a href="${pageContext.request.contextPath}/manager/movies?action=edit&id=<c:out value='${mv.id}'/>"
                         class="mgr-btn mgr-btn--edit" title="Sửa phim">✏️</a>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </div>
        </c:otherwise>
      </c:choose>
    </div>

  </div>
</div>

<script>
(function () {
  var ctx = '<c:out value="${pageContext.request.contextPath}"/>';

  function resolveSrc(url) {
    if (!url) return '';
    return /^https?:\/\//i.test(url) ? url : (ctx + '/' + url.replace(/^\//, ''));
  }

  function bindImagePreview(fileId, previewId, urlId) {
    var fileInput = document.getElementById(fileId);
    var preview = document.getElementById(previewId);
    var urlInput = document.getElementById(urlId);
    if (!fileInput || !preview) return;

    fileInput.addEventListener('change', function () {
      var file = this.files && this.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function (e) {
        preview.src = e.target.result;
        preview.hidden = false;
      };
      reader.readAsDataURL(file);
    });

    if (urlInput) {
      urlInput.addEventListener('input', function () {
        var url = this.value.trim();
        if (!url) return;
        preview.src = resolveSrc(url);
        preview.hidden = false;
      });
    }
  }

  bindImagePreview('posterFile', 'posterPreview', 'posterUrl');
  bindImagePreview('backdropFile', 'backdropPreview', 'backdropUrl');
})();
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
