<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<footer class="site-footer">
  <div class="footer-inner">

    <%-- Left: branding --%>
    <div class="footer-brand">
      <div class="footer-logo-wrap">
        <img src="${pageContext.request.contextPath}/images/logo.png"
             alt="ÉpCine" class="footer-logo-img"
             onerror="this.style.display='none'; this.nextElementSibling.style.display='block'"/>
        <span class="footer-logo" style="display:none;">ÉpCine</span>
      </div>
      <div class="footer-tagline">Trải nghiệm rạp chiếu cao cấp của bạn</div>
      <p class="footer-desc">
        Đặt vé trực tuyến, chọn ghế yêu thích và tận hưởng những bộ phim hay nhất
        trong không gian rạp chiếu chuyên nghiệp.
      </p>
    </div>

    <%-- Right: contact info --%>
    <div class="footer-contact">
      <%-- Địa chỉ --%>
      <div class="contact-row">
        <svg class="contact-icon" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
        <span>
          Trường Đại học FPT Hà Nội, Khu Công nghệ cao Hòa Lạc,
          Km29 Đại lộ Thăng Long, Thạch Thất, Hà Nội.
        </span>
      </div>

      <%-- Điện thoại --%>
      <div class="contact-row">
        <svg class="contact-icon" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 12a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 1.19h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L7.91 8.77a16 16 0 0 0 6.29 6.29l1.84-1.84a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/>
        </svg>
        <div>
          <strong>0987 654 321</strong>
          <div class="contact-note">Thứ 2 – Chủ nhật &nbsp;08:00 – 23:00</div>
        </div>
      </div>

      <%-- Email --%>
      <div class="contact-row">
        <svg class="contact-icon" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
          <polyline points="22,6 12,13 2,6"/>
        </svg>
        <span>epcine88@gmail.com</span>
      </div>

      <%-- Giờ mở cửa --%>
      <div class="contact-row">
        <svg class="contact-icon" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"/>
          <polyline points="12 6 12 12 16 14"/>
        </svg>
        <span>08:00 – 23:00 (Tất cả các ngày)</span>
      </div>

      <%-- Directions button --%>
      <a class="btn-directions"
         href="https://maps.google.com/?q=FPT+University+Hoa+Lac+Ha+Noi"
         target="_blank" rel="noopener noreferrer">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polygon points="3 11 22 2 13 21 11 13 3 11"/>
        </svg>
        Chỉ đường
      </a>
    </div>

  </div>

  <div class="footer-bottom">
    <span>&copy; 2026 ÉPCINE. Bản quyền thuộc về ÉPCINE.</span>
    <span>SWP391 &mdash; Đại học FPT</span>
  </div>
</footer>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/main.js"></script>
<c:if test="${extraCss == 'admin' || extraCss2 == 'admin'}">
  <script charset="UTF-8" src="${pageContext.request.contextPath}/js/admin.js?v=1"></script>
</c:if>
</body>
</html>
