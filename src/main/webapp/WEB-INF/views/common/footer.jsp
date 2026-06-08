<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<footer class="site-footer">
  <div class="footer-inner">

    <%-- Left: branding + social --%>
    <div class="footer-brand">
      <div class="footer-logo-wrap">
        <img src="${pageContext.request.contextPath}/images/logo.png"
             alt="ÉpCine" class="footer-logo-img"
             onerror="this.style.display='none'; this.nextElementSibling.style.display='block'"/>
        <span class="footer-logo" style="display:none;">ÉpCine</span>
      </div>
      <div class="footer-tagline">Your Premium Cinema Experience</div>
      <p class="footer-desc">
        Book tickets online, choose your seat, and enjoy the best movies
        in a world-class cinema environment.
      </p>
      <div class="footer-socials">
        <%-- Facebook --%>
        <a class="social-link" href="#" aria-label="Facebook">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/>
          </svg>
        </a>
        <%-- Instagram --%>
        <a class="social-link" href="#" aria-label="Instagram">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="2" y="2" width="20" height="20" rx="5" ry="5"/>
            <path d="M16 11.37A4 4 0 1 1 12.63 8 4 4 0 0 1 16 11.37z"/>
            <line x1="17.5" y1="6.5" x2="17.51" y2="6.5"/>
          </svg>
        </a>
        <%-- YouTube --%>
        <a class="social-link" href="#" aria-label="YouTube">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M22.54 6.42a2.78 2.78 0 0 0-1.95-1.96C18.88 4 12 4 12 4s-6.88 0-8.59.46A2.78 2.78 0 0 0 1.46 6.42 29 29 0 0 0 1 12a29 29 0 0 0 .46 5.58A2.78 2.78 0 0 0 3.41 19.6C5.12 20 12 20 12 20s6.88 0 8.59-.46a2.78 2.78 0 0 0 1.95-1.95A29 29 0 0 0 23 12a29 29 0 0 0-.46-5.58z"/>
            <polygon points="9.75 15.02 15.5 12 9.75 8.98 9.75 15.02" fill="#111"/>
          </svg>
        </a>
        <%-- TikTok --%>
        <a class="social-link" href="#" aria-label="TikTok">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19.59 6.69a4.83 4.83 0 0 1-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 0 1-2.88 2.5 2.89 2.89 0 0 1-2.89-2.89 2.89 2.89 0 0 1 2.89-2.89c.28 0 .54.04.79.1V9.01a6.33 6.33 0 0 0-.79-.05 6.34 6.34 0 0 0-6.34 6.34 6.34 6.34 0 0 0 6.34 6.34 6.34 6.34 0 0 0 6.33-6.34V8.98a8.18 8.18 0 0 0 4.78 1.53V7.07a4.85 4.85 0 0 1-1.01-.38z"/>
          </svg>
        </a>
        <%-- Cinema/Film icon --%>
        <a class="social-link" href="#" aria-label="Website">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
               stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="2" y="2" width="20" height="20" rx="2.18" ry="2.18"/>
            <line x1="7" y1="2" x2="7" y2="22"/><line x1="17" y1="2" x2="17" y2="22"/>
            <line x1="2" y1="12" x2="22" y2="12"/>
            <line x1="2" y1="7" x2="7" y2="7"/><line x1="2" y1="17" x2="7" y2="17"/>
            <line x1="17" y1="17" x2="22" y2="17"/><line x1="17" y1="7" x2="22" y2="7"/>
          </svg>
        </a>
      </div>
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
          <div class="contact-note">Mon – Sun &nbsp;08:00 – 23:00</div>
        </div>
      </div>

      <%-- Email --%>
      <div class="contact-row">
        <svg class="contact-icon" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
          <polyline points="22,6 12,13 2,6"/>
        </svg>
        <span>epcine@gmail.com</span>
      </div>

      <%-- Giờ mở cửa --%>
      <div class="contact-row">
        <svg class="contact-icon" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"/>
          <polyline points="12 6 12 12 16 14"/>
        </svg>
        <span>08:00 – 23:00 (All days)</span>
      </div>

      <%-- Directions button --%>
      <a class="btn-directions"
         href="https://maps.google.com/?q=FPT+University+Hoa+Lac+Ha+Noi"
         target="_blank" rel="noopener noreferrer">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none"
             stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polygon points="3 11 22 2 13 21 11 13 3 11"/>
        </svg>
        Get Directions
      </a>
    </div>

  </div>

  <div class="footer-bottom">
    <span>&copy; 2026 ÉPCINE. All rights reserved.</span>
    <span>SWP391 &mdash; FPT University</span>
  </div>
</footer>

<script charset="UTF-8" src="${pageContext.request.contextPath}/js/main.js"></script>
</body>
</html>
