<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core"      %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt"       %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>

<c:set var="pageTitle" value="Quản Lý Phim — ÉPCINE"/>
<c:set var="extraCss"  value="manager-movies"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>

<%-- ════════════════════════════════════════════════════════════
     VIEW 1 — LIST
     ════════════════════════════════════════════════════════════ --%>
<div id="mmListView" class="mm-page">

  <c:if test="${param.success == 'created'}">
    <div class="mm-alert mm-alert--success">Thêm phim thành công.</div>
  </c:if>
  <c:if test="${param.success == 'updated'}">
    <div class="mm-alert mm-alert--success">Cập nhật phim thành công.</div>
  </c:if>
  <c:if test="${param.success == 'deleted'}">
    <div class="mm-alert mm-alert--success">Xóa phim thành công.</div>
  </c:if>
  <c:if test="${param.error == 'has-showtimes'}">
    <div class="mm-alert mm-alert--error">Không thể xóa — phim này đã có suất chiếu.</div>
  </c:if>

  <div class="mm-header">
    <div>
      <h1 class="mm-title">Quản Lý Phim</h1>
      <p class="mm-subtitle">Quản lý thư viện phim và thông tin chi tiết của rạp.</p>
    </div>
    <button class="mm-btn-add" onclick="showFormView()">+ Thêm Phim</button>
  </div>

  <div class="mm-card" id="mmMovieListTop">
    <div class="mm-toolbar">
      <div class="mm-search-wrap">
        <svg class="mm-search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
        </svg>
        <input type="text" id="movieSearch" placeholder="Tìm kiếm phim…" oninput="applyFilters()"/>
      </div>
      <div class="mm-filter-wrap">
        <span class="mm-filter-label">LỌC THEO:</span>
        <div class="mm-tabs">
          <button class="mm-tab active" data-filter="all"           onclick="setTab(this)">Tất Cả Phim</button>
          <button class="mm-tab"        data-filter="NOW_SHOWING"   onclick="setTab(this)">Đang Chiếu</button>
          <button class="mm-tab"        data-filter="EARLY_SHOWING" onclick="setTab(this)">Suất Chiếu Sớm</button>
          <button class="mm-tab"        data-filter="COMING_SOON"   onclick="setTab(this)">Sắp Chiếu</button>
        </div>
        <button class="mm-btn-advanced" onclick="exportMovies()" title="Tải xuống toàn bộ danh sách phim">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/>
            <polyline points="7 10 12 15 17 10"/>
            <line x1="12" y1="15" x2="12" y2="3"/>
          </svg>
          Tải Xuống
        </button>
      </div>
    </div>
    <c:choose>
      <c:when test="${empty movieList}">
        <div class="mm-empty">Không tìm thấy phim nào. Bấm <strong>+ Thêm Phim</strong> để thêm mới.</div>
      </c:when>
      <c:otherwise>
        <div class="mm-table-wrap">
          <table class="mm-table">
            <thead>
              <tr>
                <th>PHIM</th><th>THỂ LOẠI</th><th>THỜI LƯỢNG</th>
                <th>ĐỘ TUỔI</th><th>ĐÁNH GIÁ</th><th>TRẠNG THÁI</th><th>THAO TÁC</th>
              </tr>
            </thead>
            <tbody id="mmTableBody">
              <c:forEach var="mv" items="${movieList}">
                <c:set var="posterSrc" value=""/>
                <c:if test="${not empty mv.posterUrl}">
                  <c:choose>
                    <c:when test="${fn:startsWith(mv.posterUrl,'http')}"><c:set var="posterSrc" value="${mv.posterUrl}"/></c:when>
                    <c:otherwise><c:set var="posterSrc" value="${pageContext.request.contextPath}/${mv.posterUrl}"/></c:otherwise>
                  </c:choose>
                </c:if>
                <c:set var="durH" value="${(mv.durationMinutes - mv.durationMinutes mod 60) / 60}"/>
                <c:set var="durM" value="${mv.durationMinutes mod 60}"/>
                <c:set var="genreStr" value=""/>
                <c:forEach var="g" items="${mv.genres}" varStatus="gs">
                  <c:set var="genreStr" value="${genreStr}${gs.first ? '' : ', '}${g}"/>
                </c:forEach>

                <tr data-status="${mv.status}" data-title="${fn:toLowerCase(mv.title)}"
                    data-title-raw="<c:out value='${mv.title}'/>"
                    data-slug="<c:out value='${mv.slug}'/>"
                    data-genres="<c:out value='${genreStr}'/>"
                    data-duration="<c:out value='${mv.durationMinutes}'/>"
                    data-age="<c:out value='${mv.ageRating}'/>"
                    data-rating="<c:out value='${mv.averageRating}'/>"
                    data-director="<c:out value='${mv.director}'/>"
                    data-language="<c:out value='${mv.language}'/>"
                    data-subtitle="<c:out value='${mv.subtitle}'/>"
                    data-release="<c:if test='${not empty mv.releaseDate}'><fmt:formatDate value='${mv.releaseDate}' pattern='dd/MM/yyyy'/></c:if>">
                  <td class="mm-td-movie">
                    <c:choose>
                      <c:when test="${not empty posterSrc}">
                        <img class="mm-poster" src="<c:out value='${posterSrc}'/>" alt="" loading="lazy"/>
                      </c:when>
                      <c:otherwise>
                        <div class="mm-poster mm-poster--blank">
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                            <rect x="3" y="3" width="18" height="18" rx="2"/>
                            <circle cx="8.5" cy="8.5" r="1.5"/>
                            <polyline points="21 15 16 10 5 21"/>
                          </svg>
                        </div>
                      </c:otherwise>
                    </c:choose>
                    <span class="mm-movie-title"><c:out value="${mv.title}"/></span>
                  </td>
                  <td class="mm-td-genre">
                    <c:choose>
                      <c:when test="${not empty genreStr}"><c:out value="${genreStr}"/></c:when>
                      <c:otherwise><span class="mm-muted">—</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td class="mm-td-dur">
                    <c:choose>
                      <c:when test="${durH > 0}">${durH}h <c:if test="${durM > 0}">${durM}m</c:if></c:when>
                      <c:otherwise>${durM}m</c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty mv.ageRating}">
                        <span class="mm-age-badge"><c:out value="${mv.ageRating}"/></span>
                      </c:when>
                      <c:otherwise><span class="mm-muted">—</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${mv.averageRating != null and mv.averageRating > 0}">
                        <span class="mm-star-rating">
                          <svg width="13" height="13" viewBox="0 0 24 24" fill="#ffd740" stroke="none">
                            <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>
                          </svg>
                          <fmt:formatNumber value="${mv.averageRating}" maxFractionDigits="1"/>
                        </span>
                      </c:when>
                      <c:otherwise><span class="mm-muted">—</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${mv.status == 'NOW_SHOWING'}">
                        <span class="mm-status mm-status--now"><span class="mm-status-dot"></span>Đang Chiếu</span>
                      </c:when>
                      <c:when test="${mv.status == 'EARLY_SHOWING'}">
                        <span class="mm-status mm-status--early">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
                          </svg>
                          Suất Chiếu Sớm
                        </span>
                      </c:when>
                      <c:when test="${mv.status == 'COMING_SOON'}">
                        <span class="mm-status mm-status--soon">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/>
                            <line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>
                          </svg>
                          Sắp Chiếu
                        </span>
                      </c:when>
                      <c:otherwise><span class="mm-status mm-status--ended">Đã Kết Thúc</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td class="mm-td-actions">
                    <a href="${pageContext.request.contextPath}/manager/movies?action=edit&id=<c:out value='${mv.id}'/>"
                       class="mm-action-btn mm-action-btn--edit" title="Sửa">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 013 3L7 19l-4 1 1-4L16.5 3.5z"/>
                      </svg>
                    </a>
                    <c:if test="${not movieIdsWithShowtimes.contains(mv.id)}">
                      <form method="post"
                            action="${pageContext.request.contextPath}/manager/movies"
                            style="display:inline"
                            onsubmit="return confirmDelete(this)">
                        <input type="hidden" name="action" value="delete"/>
                        <input type="hidden" name="id"     value="<c:out value='${mv.id}'/>"/>
                        <input type="hidden" name="title"  value="<c:out value='${mv.title}'/>"/>
                        <button type="submit" class="mm-action-btn mm-action-btn--delete" title="Xóa">
                          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="3 6 5 6 21 6"/>
                            <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                            <path d="M10 11v6"/><path d="M14 11v6"/>
                            <path d="M9 6V4h6v2"/>
                          </svg>
                        </button>
                      </form>
                    </c:if>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
        <div class="mm-pagination">
          <span class="mm-pag-info" id="mmPagInfo"></span>
          <div class="mm-pag-btns">
            <button class="mm-pag-btn" id="mmPrevBtn" onclick="prevPage()">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
            </button>
            <button class="mm-pag-btn" id="mmNextBtn" onclick="nextPage()">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
            </button>
          </div>
        </div>
      </c:otherwise>
    </c:choose>
  </div>
</div>

<%-- ════════════════════════════════════════════════════════════
     VIEW 2 — ADD / EDIT FORM
     ════════════════════════════════════════════════════════════ --%>
<div id="mmFormView" class="mm-form-page" style="display:none">

  <c:set var="m" value="${not empty formMovie ? formMovie : editMovie}"/>
  <c:set var="isEdit" value="${not empty editMovie}"/>

  <%-- Form header --%>
  <div class="mm-fhdr">
    <button class="mm-back-btn" onclick="showListView()">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="15 18 9 12 15 6"/>
      </svg>
      QUAY LẠI DANH SÁCH
    </button>
    <h2 class="mm-fhdr-title">${isEdit ? 'Sửa Phim' : 'Thêm Phim Mới'}</h2>
    <div></div><%-- spacer --%>
  </div>
  <div class="mm-fhdr-line"></div>

  <c:if test="${not empty error}">
    <div class="mm-alert mm-alert--error" style="margin:0 40px 0">
      <c:out value="${error}"/>
    </div>
  </c:if>

  <form method="post"
        action="${pageContext.request.contextPath}/manager/movies"
        id="mmMovieForm"
        enctype="multipart/form-data">
    <input type="hidden" name="action" value="${isEdit ? 'update' : 'create'}"/>
    <c:if test="${isEdit}">
      <input type="hidden" name="id"                 value="<c:out value='${editMovie.id}'/>"/>
      <input type="hidden" name="existingPosterUrl"   value="<c:out value='${editMovie.posterUrl}'/>"/>
      <input type="hidden" name="existingBackdropUrl" value="<c:out value='${editMovie.backdropUrl}'/>"/>
    </c:if>

    <div class="mm-fbody">

      <%-- ── LEFT: Media Assets ───────────────────────────── --%>
      <div class="mm-fleft">
        <div class="mm-fsection-label">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
          HÌNH ẢNH
        </div>

        <%-- Poster --%>
        <div class="mm-asset-label">POSTER PHIM</div>
        <c:set var="pPrev" value="${m.posterUrl}"/>
        <c:if test="${not empty pPrev and not fn:startsWith(pPrev,'http')}">
          <c:set var="pPrev" value="${pageContext.request.contextPath}/${pPrev}"/>
        </c:if>
        <label class="mm-upload-zone mm-upload-zone--poster" for="posterFile" id="posterZone">
          <img id="posterPreview" class="mm-upload-preview mm-upload-preview--poster"
               src="${not empty pPrev ? pPrev : ''}" alt=""
               <c:if test="${empty m.posterUrl}">hidden</c:if>/>
          <div class="mm-upload-placeholder" id="posterPlaceholder" <c:if test="${not empty m.posterUrl}">style="display:none"</c:if>>
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>
              <polyline points="21 15 16 10 5 21"/><line x1="12" y1="8" x2="12" y2="16"/>
              <line x1="8" y1="12" x2="16" y2="12"/>
            </svg>
            <span class="mm-upload-txt">Tải Lên Poster</span>
            <span class="mm-upload-sub">Tỷ lệ 2:3 • JPG/PNG</span>
          </div>
        </label>
        <input id="posterFile" type="file" name="posterFile"
               accept="image/jpeg,image/png,image/webp" class="mm-file-hidden"/>

        <%-- Backdrop --%>
        <div class="mm-asset-label" style="margin-top:24px">ẢNH BÌA</div>
        <c:set var="bPrev" value="${m.backdropUrl}"/>
        <c:if test="${not empty bPrev and not fn:startsWith(bPrev,'http')}">
          <c:set var="bPrev" value="${pageContext.request.contextPath}/${bPrev}"/>
        </c:if>
        <label class="mm-upload-zone mm-upload-zone--banner" for="backdropFile" id="backdropZone">
          <img id="backdropPreview" class="mm-upload-preview mm-upload-preview--banner"
               src="${not empty bPrev ? bPrev : ''}" alt=""
               <c:if test="${empty m.backdropUrl}">hidden</c:if>/>
          <div class="mm-upload-placeholder" id="backdropPlaceholder" <c:if test="${not empty m.backdropUrl}">style="display:none"</c:if>>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <rect x="2" y="7" width="20" height="14" rx="2"/>
              <polyline points="2 17 7 12 11 16 15 11 22 17"/>
            </svg>
            <span class="mm-upload-txt">Ảnh bìa 16:9</span>
          </div>
        </label>
        <input id="backdropFile" type="file" name="backdropFile"
               accept="image/jpeg,image/png,image/webp" class="mm-file-hidden"/>
      </div>

      <%-- ── RIGHT: Form Fields ────────────────────────────── --%>
      <div class="mm-fright">

        <%-- Basic Information --%>
        <div class="mm-fsection">
          <div class="mm-fsection-label">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            THÔNG TIN CƠ BẢN
          </div>

          <div class="mm-field">
            <label class="mm-flabel">TÊN PHIM <span class="mm-req">*</span></label>
            <input type="text" name="title" maxlength="255"
                   placeholder="Nhập tên đầy đủ…"
                   value="<c:out value='${m.title}'/>"/>
          </div>

          <div class="mm-field-row">
            <div class="mm-field">
              <label class="mm-flabel">SLUG <span class="mm-req">*</span></label>
              <input type="text" id="slugField" name="slug" maxlength="255"
                     placeholder="tu-dong-tao-tu-ten-phim"
                     value="<c:out value='${m.slug}'/>"/>
            </div>
            <div class="mm-field">
              <label class="mm-flabel">THỜI LƯỢNG (PHÚT) <span class="mm-req">*</span></label>
              <input type="number" id="durationField" name="durationMinutes" min="60" max="600" maxlength="4"
                     placeholder="120"
                     value="<c:if test='${not empty m and m.durationMinutes > 0}'><c:out value='${m.durationMinutes}'/></c:if>"/>
            </div>
          </div>

          <div class="mm-field-row">
            <div class="mm-field">
              <label class="mm-flabel">TRẠNG THÁI <span class="mm-req">*</span></label>
              <select name="status" id="statusField">
                <option value="COMING_SOON"    <c:if test="${empty m or m.status == 'COMING_SOON'}">selected</c:if>>Sắp Chiếu</option>
                <option value="NOW_SHOWING"    <c:if test="${m.status == 'NOW_SHOWING'}">selected</c:if>>Đang Chiếu</option>
                <c:if test="${isEdit}">
                  <option value="ENDED"        <c:if test="${m.status == 'ENDED'}">selected</c:if>>Đã Kết Thúc</option>
                </c:if>
              </select>
            </div>
            <div class="mm-field">
              <label class="mm-flabel">ĐẠO DIỄN <span class="mm-req">*</span></label>
              <input type="text" name="director" maxlength="255"
                     placeholder="Tên đạo diễn"
                     value="<c:out value='${m.director}'/>"/>
            </div>
          </div>

          <div class="mm-field-row">
            <div class="mm-field">
              <label class="mm-flabel">NGÔN NGỮ <span class="mm-req">*</span></label>
              <input type="text" name="language" maxlength="50"
                     value="<c:out value='${m.language}'/>"/>
            </div>
            <div class="mm-field">
              <label class="mm-flabel">PHỤ ĐỀ <span class="mm-req">*</span></label>
              <input type="text" name="subtitle" maxlength="50"
                     value="<c:out value='${m.subtitle}'/>"/>
            </div>
          </div>
        </div>

        <%-- Content Details --%>
        <div class="mm-fsection">
          <div class="mm-fsection-label">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
            NỘI DUNG CHI TIẾT
          </div>

          <div class="mm-field">
            <label class="mm-flabel mm-flabel-row">
              <span>MÔ TẢ <span class="mm-req">*</span></span>
              <span class="mm-char-count" id="descriptionCount">0/4000</span>
            </label>
            <textarea name="description" id="descriptionField" rows="5" maxlength="4000"
                      placeholder="Viết mô tả hấp dẫn về phim…"><c:out value='${m.description}'/></textarea>
          </div>

          <div class="mm-field-row">
            <div class="mm-field">
              <label class="mm-flabel">ĐỘ TUỔI <span class="mm-req">*</span></label>
              <c:set var="cr" value="${m.ageRating}"/>
              <div class="mm-rating-pills">
                <label class="mm-rating-pill"><input type="radio" name="ageRating" value="P"   <c:if test="${cr == 'P'}">checked</c:if>/><span>P</span></label>
                <label class="mm-rating-pill"><input type="radio" name="ageRating" value="K"   <c:if test="${cr == 'K'}">checked</c:if>/><span>K</span></label>
                <label class="mm-rating-pill"><input type="radio" name="ageRating" value="T13" <c:if test="${cr == 'T13'}">checked</c:if>/><span>T13</span></label>
                <label class="mm-rating-pill"><input type="radio" name="ageRating" value="T16" <c:if test="${cr == 'T16'}">checked</c:if>/><span>T16</span></label>
                <label class="mm-rating-pill"><input type="radio" name="ageRating" value="T18" <c:if test="${cr == 'T18'}">checked</c:if>/><span>T18</span></label>
                <label class="mm-rating-pill"><input type="radio" name="ageRating" value="C"   <c:if test="${cr == 'C'}">checked</c:if>/><span>C</span></label>
              </div>
            </div>
            <div class="mm-field">
              <label class="mm-flabel">NGÀY PHÁT HÀNH <span class="mm-req">*</span></label>
              <input type="date" name="releaseDate" id="releaseDateField"
                     value="<c:if test='${not empty m.releaseDate}'><fmt:formatDate value='${m.releaseDate}' pattern='yyyy-MM-dd'/></c:if>"/>
            </div>
          </div>

          <div class="mm-field">
            <label class="mm-flabel">TRAILER URL <span class="mm-req">*</span></label>
            <div class="mm-url-field">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/>
                <path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/>
              </svg>
              <input type="text" name="trailerUrl" maxlength="500"
                     placeholder="https://youtube.com/watch?…"
                     value="<c:out value='${m.trailerUrl}'/>"/>
            </div>
          </div>

          <%-- Genres --%>
          <div class="mm-field">
            <label class="mm-flabel">THỂ LOẠI <span class="mm-req">*</span></label>
            <div class="mm-genre-pills">
              <c:forEach var="genre" items="${genreList}">
                <label class="mm-genre-pill">
                  <input type="checkbox" name="genreIds" value="<c:out value='${genre.id}'/>"
                    <c:if test="${not empty selectedGenreIds and selectedGenreIds.contains(genre.id)}">checked</c:if>/>
                  <span><c:out value="${genre.genreName}"/></span>
                </label>
              </c:forEach>
            </div>
          </div>
        </div>

      </div><%-- end mm-fright --%>
    </div><%-- end mm-fbody --%>

    <%-- Form Footer --%>
    <div class="mm-ffooter">
      <button type="button" class="mm-discard-btn" onclick="showListView()">Hủy Thay Đổi</button>
      <button type="submit" class="mm-publish-btn">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/>
          <polyline points="17 21 17 13 7 13 7 21"/>
          <polyline points="7 3 7 8 15 8"/>
        </svg>
        ${isEdit ? 'Lưu Thay Đổi' : 'Lưu & Đăng'}
      </button>
    </div>
  </form>
</div>

<script>
(function () {
  var ctx = '${pageContext.request.contextPath}';

  /* ── View toggle ─────────────────────────────────────────── */
  window.confirmDelete = function (form) {
    var title = form.querySelector('[name="title"]').value;
    return confirm('Xóa "' + title + '"?\nHành động này không thể hoàn tác.');
  };

  window.showFormView = function () {
    document.getElementById('mmListView').style.display = 'none';
    document.getElementById('mmFormView').style.display = 'block';
    window.scrollTo(0, 0);
  };
  window.showListView = function () {
    document.getElementById('mmFormView').style.display = 'none';
    document.getElementById('mmListView').style.display = 'block';
    window.scrollTo(0, 0);
  };

  /* ── Auto-show form when editing or error ────────────────── */
  <c:if test="${not empty editMovie or not empty formMovie or not empty error}">
  showFormView();
  </c:if>

  /* ── Slug auto-generate from title ──────────────────────── */
  var titleInput = document.querySelector('[name="title"]');
  var slugField  = document.getElementById('slugField');
  if (titleInput && slugField) {
    titleInput.addEventListener('input', function () {
      if (slugField.dataset.manual === 'true') return;
      slugField.value = this.value.trim()
        .toLowerCase()
        .normalize('NFD').replace(/[̀-ͯ]/g, '')
        .replace(/đ/g, 'd').replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-').replace(/-+/g, '-');
    });
    slugField.addEventListener('input', function () {
      this.dataset.manual = 'true';
    });
  }

  /* ── Giới hạn số ký tự thời lượng (maxlength không áp dụng cho type=number) */
  var durationField = document.getElementById('durationField');
  if (durationField) {
    durationField.addEventListener('input', function () {
      if (this.value.length > 4) this.value = this.value.slice(0, 4);
    });
  }

  /* ── Status phải khớp ngày phát hành ─────────────────────── */
  var releaseDateField = document.getElementById('releaseDateField');
  var statusField       = document.getElementById('statusField');
  if (releaseDateField && statusField) {
    var comingSoonOpt = statusField.querySelector('option[value="COMING_SOON"]');
    var nowShowingOpt = statusField.querySelector('option[value="NOW_SHOWING"]');
    var syncStatusOptions = function () {
      if (!releaseDateField.value) {
        comingSoonOpt.disabled = false;
        nowShowingOpt.disabled = false;
        return;
      }
      var today = new Date(); today.setHours(0, 0, 0, 0);
      var released = new Date(releaseDateField.value + 'T00:00:00') <= today;
      comingSoonOpt.disabled = released;
      nowShowingOpt.disabled = !released;
      if (released && statusField.value === 'COMING_SOON') statusField.value = 'NOW_SHOWING';
      if (!released && statusField.value === 'NOW_SHOWING') statusField.value = 'COMING_SOON';
    };
    releaseDateField.addEventListener('change', syncStatusOptions);
    syncStatusOptions();
  }

  /* ── Description char counter ────────────────────────────── */
  var descField = document.getElementById('descriptionField');
  var descCount = document.getElementById('descriptionCount');
  if (descField && descCount) {
    var descMax = descField.maxLength;
    var updateDescCount = function () {
      var len = descField.value.length;
      descCount.textContent = len + '/' + descMax;
      descCount.classList.toggle('mm-char-count-warn', len >= descMax);
    };
    descField.addEventListener('input', updateDescCount);
    updateDescCount();
  }

  /* ── Image preview ───────────────────────────────────────── */
  function resolveSrc(url) {
    return /^https?:\/\//i.test(url) ? url : (ctx + '/' + url.replace(/^\//, ''));
  }

  function bindPreview(fileId, previewId, placeholderId, urlName) {
    var fi = document.getElementById(fileId);
    var pi = document.getElementById(previewId);
    var ph = document.getElementById(placeholderId);
    var ui = document.querySelector('[name="' + urlName + '"]');
    if (!fi || !pi) return;

    function showPreview(src) {
      pi.src = src; pi.hidden = false;
      if (ph) ph.style.display = 'none';
    }

    fi.addEventListener('change', function () {
      var f = this.files && this.files[0];
      if (!f) return;
      var r = new FileReader();
      r.onload = function (e) { showPreview(e.target.result); };
      r.readAsDataURL(f);
    });

    if (ui) {
      ui.addEventListener('input', function () {
        var url = this.value.trim();
        if (url) showPreview(resolveSrc(url));
      });
    }
  }

  bindPreview('posterFile',   'posterPreview',   'posterPlaceholder',   'posterUrl');
  bindPreview('backdropFile', 'backdropPreview', 'backdropPlaceholder', 'backdropUrl');

  /* ── List filter & pagination ────────────────────────────── */
  var MM_PER = 14, mmPage = 1, mmFilter = 'all', mmRows = [];

  function getAllRows() { return Array.from(document.querySelectorAll('#mmTableBody tr')); }

  window.applyFilters = function () {
    var s = (document.getElementById('movieSearch').value || '').toLowerCase().trim();
    mmRows = getAllRows().filter(function (r) {
      return (!s || (r.dataset.title||'').includes(s)) &&
             (mmFilter === 'all' || r.dataset.status === mmFilter);
    });
    mmPage = 1; renderPage();
  };

  function renderPage(opts) {
    var total = mmRows.length, pages = Math.max(1, Math.ceil(total / MM_PER));
    if (mmPage > pages) mmPage = pages;
    var s = (mmPage - 1) * MM_PER, e = Math.min(s + MM_PER, total);
    getAllRows().forEach(function (r) { r.style.display = 'none'; });
    mmRows.forEach(function (r, i) { r.style.display = (i >= s && i < e) ? '' : 'none'; });
    var info = document.getElementById('mmPagInfo');
    if (info) info.textContent = total === 0 ? 'Không có kết quả' : 'Hiển thị ' + (s+1) + ' đến ' + e + ' trong ' + total + ' phim';
    var pb = document.getElementById('mmPrevBtn'), nb = document.getElementById('mmNextBtn');
    if (pb) pb.disabled = mmPage <= 1;
    if (nb) nb.disabled = mmPage >= pages;
    if (opts && opts.scrollTop) {
      var anchor = document.getElementById('mmMovieListTop');
      if (anchor && anchor.scrollIntoView) {
        anchor.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }
    }
  }

  window.exportMovies = function () {
    var header = ['Tên Phim','Slug','Thể Loại','Thời Lượng (phút)','Độ Tuổi','Đánh Giá',
                  'Đạo Diễn','Ngôn Ngữ','Phụ Đề','Ngày Phát Hành','Trạng Thái'];
    var colWidths = [220,160,160,110,70,70,160,90,120,110,110];
    var statusLabel = {
      NOW_SHOWING: 'Đang Chiếu', COMING_SOON: 'Sắp Chiếu',
      EARLY_SHOWING: 'Suất Chiếu Sớm', ENDED: 'Đã Kết Thúc'
    };
    var escHtml = function (v) {
      return String(v || '').replace(/&/g,'&amp;').replace(/</g,'&lt;')
                             .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    };

    var cols = colWidths.map(function (w) { return '<col style="width:' + w + 'px">'; }).join('');
    var thead = '<tr>' + header.map(function (h) {
      return '<th style="background:#e53935;color:#fff;font-weight:bold;padding:8px 10px;' +
             'border:1px solid #b71c1c;text-align:left;white-space:nowrap;">' + escHtml(h) + '</th>';
    }).join('') + '</tr>';

    var tbody = '';
    getAllRows().forEach(function (r, i) {
      var d = r.dataset;
      var vals = [d.titleRaw, d.slug, d.genres, d.duration, d.age, d.rating,
                  d.director, d.language, d.subtitle, d.release, statusLabel[d.status] || d.status];
      var bg = (i % 2 === 0) ? '#ffffff' : '#f6f6f6';
      tbody += '<tr>' + vals.map(function (v) {
        return '<td style="background:' + bg + ';padding:7px 10px;border:1px solid #ddd;' +
               'font-family:Calibri,Arial,sans-serif;font-size:13px;color:#222;">' + escHtml(v) + '</td>';
      }).join('') + '</tr>';
    });

    var html = '<html><head><meta charset="UTF-8"></head><body>' +
      '<table style="border-collapse:collapse;font-family:Calibri,Arial,sans-serif;">' +
      '<colgroup>' + cols + '</colgroup>' +
      '<thead>' + thead + '</thead>' +
      '<tbody>' + tbody + '</tbody>' +
      '</table></body></html>';

    var blob = new Blob(['﻿' + html], { type: 'application/vnd.ms-excel;charset=utf-8;' });
    var url  = URL.createObjectURL(blob);
    var a    = document.createElement('a');
    a.href = url; a.download = 'danh-sach-phim.xls'; a.click();
    URL.revokeObjectURL(url);
  };

  window.setTab = function (btn) {
    document.querySelectorAll('.mm-tab').forEach(function (t) { t.classList.remove('active'); });
    btn.classList.add('active'); mmFilter = btn.dataset.filter; applyFilters();
  };
  window.prevPage = function () { if (mmPage > 1) { mmPage--; renderPage({ scrollTop: true }); } };
  window.nextPage = function () { mmPage++; renderPage({ scrollTop: true }); };

  document.addEventListener('DOMContentLoaded', applyFilters);
})();
</script>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
