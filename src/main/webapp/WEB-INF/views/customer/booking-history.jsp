<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<c:set var="pageTitle" value="Lịch sử đặt vé — ÉPCINE"/>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%@ include file="/WEB-INF/views/common/header.jsp" %>
<link rel="stylesheet" href="${ctx}/css/booking-history.css"/>

<main class="bh-page container">
  <header class="bh-hero">
    <h1 class="bh-hero__title">Lịch sử đặt vé</h1>
    <p class="bh-hero__sub">Xem và quản lý các đơn đặt vé của bạn — tìm kiếm theo tên phim hoặc mã đơn.</p>
  </header>

  <section class="bh-toolbar" aria-label="Tìm kiếm và lọc">
    <form class="bh-search" method="get" action="${ctx}/booking-history">
      <input type="hidden" name="status" value="${activeStatus}"/>
      <label class="bh-search__wrap">
        <span class="bh-search__icon" aria-hidden="true">🔍</span>
        <input type="search" name="q" class="bh-search__input"
               placeholder="Tìm theo tên phim hoặc mã đơn…"
               value="<c:out value='${searchQuery}'/>"
               maxlength="100"/>
      </label>
      <button type="submit" class="bh-search__btn">Tìm</button>
    </form>

    <div class="bh-chips" role="tablist" aria-label="Lọc trạng thái">
      <c:set var="chips" value="ALL:PENDING:CONFIRMED:CANCELLED:EXPIRED:REFUNDED"/>
      <c:set var="chipLabels" value="Tất cả:Chờ TT:Đã TT:Đã hủy:Hết hạn:Đã hoàn"/>
      <c:forTokens var="chip" items="${chips}" delims=":" varStatus="st">
        <c:forTokens var="label" items="${chipLabels}" delims=":" varStatus="ls">
          <c:if test="${st.index == ls.index}">
            <c:url var="chipUrl" value="/booking-history">
              <c:param name="status" value="${chip}"/>
              <c:if test="${not empty searchQuery}">
                <c:param name="q" value="${searchQuery}"/>
              </c:if>
            </c:url>
            <a href="${chipUrl}"
               class="bh-chip${activeStatus == chip ? ' bh-chip--active' : ''}"
               role="tab"
               aria-selected="${activeStatus == chip}">
              <c:out value="${label}"/>
            </a>
          </c:if>
        </c:forTokens>
      </c:forTokens>
    </div>
  </section>

  <c:choose>
    <c:when test="${empty bookings}">
      <div class="bh-empty">
        <div class="bh-empty__icon" aria-hidden="true">🎬</div>
        <c:choose>
          <c:when test="${totalCount == 0 and empty searchQuery and activeStatus == 'ALL'}">
            <h2 class="bh-empty__title">Bạn chưa có đơn đặt vé nào</h2>
            <p class="bh-empty__text">Khám phá phim đang chiếu và đặt vé ngay hôm nay.</p>
            <a href="${ctx}/movies" class="bh-btn bh-btn--primary">Xem phim</a>
          </c:when>
          <c:otherwise>
            <h2 class="bh-empty__title">Không tìm thấy đơn phù hợp</h2>
            <p class="bh-empty__text">Thử đổi bộ lọc hoặc từ khóa tìm kiếm.</p>
            <a href="${ctx}/booking-history" class="bh-btn bh-btn--ghost">Xóa bộ lọc</a>
          </c:otherwise>
        </c:choose>
      </div>
    </c:when>
    <c:otherwise>
      <div class="bh-grid">
        <c:forEach var="b" items="${bookings}">
          <c:set var="poster" value="${b.moviePosterUrl}"/>
          <c:if test="${not empty poster and not fn:startsWith(poster,'http')}">
            <c:set var="poster" value="${ctx}/${poster}"/>
          </c:if>

          <c:set var="seatDisplay" value="${b.seatCodesSummary}"/>
          <c:if test="${fn:length(seatDisplay) > 48}">
            <c:set var="seatDisplay" value="${fn:substring(seatDisplay, 0, 45)}…"/>
          </c:if>

          <article class="bh-card${b.cancelledLike ? ' bh-card--muted' : ''}">
            <div class="bh-card__media">
              <c:choose>
                <c:when test="${not empty poster}">
                  <img src="<c:out value='${poster}'/>" alt="" class="bh-card__poster" loading="lazy"/>
                </c:when>
                <c:otherwise>
                  <div class="bh-card__poster bh-card__poster--placeholder" aria-hidden="true">🎞</div>
                </c:otherwise>
              </c:choose>
              <span class="bh-badge ${b.statusBadgeClass}">
                <c:out value="${b.displayStatusLabel}"/>
              </span>
            </div>

            <div class="bh-card__body">
              <h2 class="bh-card__title${b.cancelledLike ? ' bh-card__title--struck' : ''}">
                <c:out value="${b.movieTitle}"/>
              </h2>
              <p class="bh-card__meta">
                #<c:out value="${b.bookingCode}"/>
                · <fmt:formatDate value="${b.startTime}" pattern="dd/MM/yyyy • HH:mm"/>
              </p>
              <p class="bh-card__room">
                <c:out value="${b.roomName}"/>
                <c:if test="${not empty seatDisplay}">
                  · <c:out value="${seatDisplay}"/>
                </c:if>
              </p>
              <c:if test="${b.bookingSource == 'OFFLINE'}">
                <span class="bh-source">Tại quầy</span>
              </c:if>
              <c:if test="${b.bookingSource == 'ONLINE'}">
                <span class="bh-source bh-source--online">Online</span>
              </c:if>

              <div class="bh-card__footer">
                <span class="bh-card__price">
                  <fmt:formatNumber value="${b.finalAmount}" type="number" groupingUsed="true"/> ₫
                </span>
                <c:choose>
                  <c:when test="${b.payable}">
                    <a href="${ctx}/payment?bookingId=${b.bookingId}" class="bh-btn bh-btn--pay">
                      Thanh toán ngay →
                    </a>
                  </c:when>
                  <c:when test="${b.viewableTicket}">
                    <a href="${ctx}/payment/success?bookingId=${b.bookingId}" class="bh-btn bh-btn--primary">
                      Xem vé
                    </a>
                  </c:when>
                  <c:otherwise>
                    <span class="bh-card__note">
                      <c:choose>
                        <c:when test="${b.bookingStatus == 'CANCELLED'}">Đơn đã hủy</c:when>
                        <c:when test="${b.bookingStatus == 'EXPIRED'}">Đơn đã hết hạn</c:when>
                        <c:when test="${b.bookingStatus == 'REFUNDED'}">Đơn đã hoàn tiền</c:when>
                        <c:when test="${b.bookingStatus == 'PENDING' and not b.payable}">Đơn hết thời gian thanh toán</c:when>
                        <c:otherwise>—</c:otherwise>
                      </c:choose>
                    </span>
                  </c:otherwise>
                </c:choose>
              </div>
            </div>
          </article>
        </c:forEach>
      </div>

      <c:if test="${hasMore}">
        <div class="bh-load-more">
          <c:url var="nextUrl" value="/booking-history">
            <c:param name="status" value="${activeStatus}"/>
            <c:param name="page" value="${currentPage + 1}"/>
            <c:if test="${not empty searchQuery}">
              <c:param name="q" value="${searchQuery}"/>
            </c:if>
          </c:url>
          <a href="${nextUrl}" class="bh-load-more__btn">Xem thêm lịch sử ▾</a>
        </div>
      </c:if>
    </c:otherwise>
  </c:choose>
</main>

<%@ include file="/WEB-INF/views/common/footer.jsp" %>
