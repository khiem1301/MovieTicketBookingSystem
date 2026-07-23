package utils;

import model.dto.BookingDetailDTO;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

import jakarta.mail.Authenticator;
import jakarta.mail.Message;
import jakarta.mail.MessagingException;
import jakarta.mail.PasswordAuthentication;
import jakarta.mail.Session;
import jakarta.mail.Transport;
import jakarta.mail.internet.InternetAddress;
import jakarta.mail.internet.MimeMessage;

public final class EmailUtil {

    private static final Logger LOG = Logger.getLogger(EmailUtil.class.getName());
    private static final String PROPS_FILE = "email.properties";
    private static final int VERIFY_TOKEN_MINUTES = 24 * 60;

    private EmailUtil() {}

    public static boolean isConfigured() {
        Properties props = loadProperties();
        if (props == null) {
            return false;
        }
        String user = props.getProperty("mail.smtp.username", "").trim();
        String pass = props.getProperty("mail.smtp.password", "").trim();
        return !user.isBlank()
                && !pass.isBlank()
                && !user.contains("your.email")
                && !pass.contains("<app-password");
    }

    public static int verificationExpiryMinutes() {
        return VERIFY_TOKEN_MINUTES;
    }

    public static void requireConfigured() throws MessagingException {
        if (!isConfigured()) {
            throw new MessagingException(
                    "Chưa cấu hình email SMTP. Sao chép email.properties.example và điền thông tin Gmail.");
        }
    }

    public static void sendPasswordResetEmail(String toEmail, String fullName, String resetUrl)
            throws MessagingException {
        String subject = "ÉPCINE — Đặt lại mật khẩu";
        String body = """
                Xin chào %s,

                Bạn (hoặc ai đó) đã yêu cầu đặt lại mật khẩu tài khoản ÉPCINE.

                Bấm vào liên kết sau (hiệu lực %d phút):
                %s

                Nếu bạn không yêu cầu, hãy bỏ qua email này.

                Trân trọng,
                ÉPCINE
                """.formatted(fullName, AuthConstants.PASSWORD_RESET_EXPIRY_MINUTES, resetUrl);
        sendPlainTextEmail(toEmail, subject, body);
    }

    public static void sendProfileSecurityEmail(String toEmail, String fullName, String confirmUrl)
            throws MessagingException {
        String subject = "ÉPCINE — Xác minh bảo mật tài khoản";
        String body = """
                Xin chào %s,

                Bạn đã yêu cầu xác minh danh tính để đổi mật khẩu trên ÉPCINE.

                Bấm vào liên kết sau (hiệu lực %d phút):
                %s

                Nếu bạn không thực hiện, hãy bỏ qua email này.

                Trân trọng,
                ÉPCINE
                """.formatted(fullName, AuthConstants.PROFILE_SECURITY_VERIFY_MINUTES, confirmUrl);
        sendPlainTextEmail(toEmail, subject, body);
    }

    public static void sendVerificationEmail(String toEmail, String fullName, String verifyUrl)
            throws MessagingException {
        String subject = "ÉPCINE — Xác thực tài khoản đăng ký";
        String body = """
                Xin chào %s,

                Cảm ơn bạn đã đăng ký tài khoản ÉPCINE.

                Vui lòng bấm vào liên kết sau để xác thực email (hiệu lực 24 giờ):
                %s

                Nếu bạn không đăng ký tài khoản, hãy bỏ qua email này.

                Trân trọng,
                ÉPCINE
                """.formatted(fullName, verifyUrl);
        sendPlainTextEmail(toEmail, subject, body);
    }

    public static void sendAccountLockedEmail(String toEmail, String fullName, String reason)
            throws MessagingException {
        String subject = "ÉPCINE — Thông báo tài khoản bị khóa";
        String body = """
                Xin chào %s,

                Tài khoản ÉPCINE của bạn đã bị khóa bởi quản trị viên hệ thống.

                Lý do:
                %s

                Bạn sẽ không thể đăng nhập cho đến khi tài khoản được mở khóa.
                Nếu có thắc mắc, vui lòng liên hệ bộ phận hỗ trợ của rạp.

                Trân trọng,
                ÉPCINE
                """.formatted(fullName, reason);
        sendPlainTextEmail(toEmail, subject, body);
    }

    public static void sendAccountUnlockedEmail(String toEmail, String fullName)
            throws MessagingException {
        String subject = "ÉPCINE — Tài khoản đã được mở khóa";
        String body = """
                Xin chào %s,

                Tài khoản ÉPCINE của bạn đã được mở khóa bởi quản trị viên hệ thống.

                Bạn có thể đăng nhập lại bình thường. Nếu có thắc mắc, vui lòng liên hệ bộ phận hỗ trợ của rạp.

                Trân trọng,
                ÉPCINE
                """.formatted(fullName);
        sendPlainTextEmail(toEmail, subject, body);
    }

    public static void sendReviewDeletedEmail(String toEmail, String fullName, String movieTitle, String reason)
            throws MessagingException {
        String subject = "ÉPCINE — Đánh giá của bạn đã bị gỡ";
        String body = """
                Xin chào %s,

                Đánh giá của bạn cho phim "%s" đã bị quản trị viên gỡ bỏ khỏi hệ thống ÉPCINE.

                Lý do:
                %s

                Nếu bạn cho rằng đây là nhầm lẫn, vui lòng liên hệ bộ phận hỗ trợ của rạp.

                Trân trọng,
                ÉPCINE
                """.formatted(fullName, movieTitle, reason);
        sendPlainTextEmail(toEmail, subject, body);
    }

    private static void sendPlainTextEmail(String toEmail, String subject, String body)
            throws MessagingException {
        Properties props = requireProperties();
        String fromEmail = props.getProperty("mail.from", props.getProperty("mail.smtp.username"));
        String fromName = props.getProperty("mail.from.name", "ÉPCINE");

        Properties mailProps = buildMailSessionProperties(props);
        Session session = Session.getInstance(mailProps, new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(
                        props.getProperty("mail.smtp.username"),
                        props.getProperty("mail.smtp.password"));
            }
        });

        MimeMessage message = new MimeMessage(session);
        try {
            message.setFrom(new InternetAddress(fromEmail, fromName, "UTF-8"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail, false));
            message.setSubject(subject, "UTF-8");
            // setContent + saveChanges ổn định hơn setText trên Gmail/Outlook (tiếng Việt + dấu É)
            message.setContent(body, "text/plain; charset=UTF-8");
            message.saveChanges();
        } catch (UnsupportedEncodingException ex) {
            throw new MessagingException("Không thể mã hóa nội dung email", ex);
        }
        Transport.send(message);
    }

    /**
     * FR-19 — Gửi email xác nhận đặt vé kèm QR (quét mở trang vé điện tử giống vé quầy).
     * Chỉ gửi nếu SMTP đã cấu hình; thất bại sẽ log cảnh báo thay vì ném exception.
     */
    public static void sendBookingConfirmationEmail(String toEmail, String customerName,
                                                    BookingDetailDTO detail) {
        if (!isConfigured() || toEmail == null || toEmail.isBlank() || detail == null) return;
        try {
            Properties props = requireProperties();
            String fromEmail = props.getProperty("mail.from", props.getProperty("mail.smtp.username"));
            String fromName  = props.getProperty("mail.from.name", "ÉPCINE");

            Properties mailProps = buildMailSessionProperties(props);
            Session session = Session.getInstance(mailProps, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(
                            props.getProperty("mail.smtp.username"),
                            props.getProperty("mail.smtp.password"));
                }
            });

            SimpleDateFormat dtFmt = new SimpleDateFormat("HH:mm  dd/MM/yyyy");
            SimpleDateFormat dayFmt = new SimpleDateFormat("EEE, dd/MM");
            SimpleDateFormat timeFmt = new SimpleDateFormat("HH:mm");
            String showDate = detail.getStartTime() != null
                    ? dtFmt.format(detail.getStartTime()) : "—";
            String dayLabel = detail.getStartTime() != null
                    ? dayFmt.format(detail.getStartTime()) : "—";
            String timeLabel = detail.getStartTime() != null
                    ? timeFmt.format(detail.getStartTime()) : "—";

            boolean online = "ONLINE".equalsIgnoreCase(detail.getBookingSource());
            String intro = online
                    ? "Đặt vé online của bạn tại ÉPCINE đã được thanh toán và xác nhận thành công."
                    : "Đặt vé của bạn tại quầy ÉPCINE đã được xác nhận thành công.";
            String outro = "Quét mã QR bên dưới để mở toàn bộ vé điện tử trên điện thoại khi vào rạp.";

            String bookingUrl = buildTicketViewUrl(detail.getBookingCode());
            String qrImg = buildQrImageUrl(bookingUrl);

            StringBuilder seatLinesHtml = new StringBuilder();
            if (detail.getTickets() != null) {
                for (BookingDetailDTO.TicketItem t : detail.getTickets()) {
                    seatLinesHtml.append("<li style=\"margin:4px 0\">Ghế <strong>")
                            .append(esc(t.getSeatCode()))
                            .append("</strong> — <span style=\"font-family:monospace;font-size:12px;color:#666\">")
                            .append(esc(t.getTicketCode()))
                            .append("</span></li>");
                }
            }

            int ticketCount = detail.getTickets() != null ? detail.getTickets().size() : 0;
            String qrBlock = """
                    <div style="max-width:360px;margin:0 auto 20px;border:1px solid #2a2a2a;border-radius:10px;overflow:hidden;background:#0a0a0a;font-family:Courier New,monospace;color:#e0e0e0;text-align:center">
                      <div style="background:#1a0a0a;padding:14px 20px;border-bottom:1px dashed #2a2a2a">
                        <div style="font-size:11px;font-weight:700;color:#e53935;letter-spacing:2px">ÉPCINE PREMIUM</div>
                        <div style="font-size:12px;color:#aaa;font-weight:700;margin-top:6px">%s</div>
                      </div>
                      <div style="padding:14px 20px 8px;font-size:18px;font-weight:700;color:#fff;text-transform:uppercase;letter-spacing:1px">%s</div>
                      <div style="padding:0 20px 12px;font-size:13px;color:#ccc">
                        %s · %s · %s<br/>
                        %d vé
                      </div>
                      <div style="padding:14px 20px 18px;border-top:1px dashed #1e1e1e">
                        <a href="%s" style="text-decoration:none">
                          <img src="%s" width="180" height="180" alt="QR đơn vé" style="display:block;margin:0 auto;border:0"/>
                        </a>
                        <div style="font-size:11px;font-weight:700;color:#e53935;letter-spacing:2px;margin-top:12px">QUÉT ĐỂ XEM VÉ</div>
                        <div style="font-size:11px;color:#888;margin-top:8px">
                          hoặc <a href="%s" style="color:#e53935">mở vé điện tử</a>
                        </div>
                      </div>
                    </div>
                    """.formatted(
                    esc(detail.getBookingCode()),
                    esc(detail.getMovieTitle()),
                    esc(dayLabel),
                    esc(timeLabel),
                    esc(detail.getRoomName()),
                    ticketCount,
                    esc(bookingUrl),
                    esc(qrImg),
                    esc(bookingUrl));

            String greet = customerName != null && !customerName.isBlank() ? customerName : "bạn";
            double amount = detail.getFinalAmount() != null ? detail.getFinalAmount().doubleValue() : 0.0;

            String seatsList = seatLinesHtml.length() > 0
                    ? "<ul style=\"padding-left:18px;margin:8px 0 0\">" + seatLinesHtml + "</ul>"
                    : "<p>(Chưa có mã vé)</p>";

            String htmlBody = """
                    <div style="font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:0 auto;color:#222;line-height:1.5">
                      <p>Xin chào <strong>%s</strong>,</p>
                      <p>%s</p>
                      <p style="background:#f5f5f5;padding:12px 16px;border-radius:8px;font-size:14px">
                        <strong>Mã đặt vé:</strong> %s<br/>
                        <strong>Phim:</strong> %s<br/>
                        <strong>Phòng:</strong> %s<br/>
                        <strong>Suất chiếu:</strong> %s<br/>
                        <strong>Tổng tiền:</strong> %,.0f ₫
                      </p>
                      <p style="font-weight:700;margin:24px 0 8px">Danh sách ghế</p>
                      %s
                      <p style="font-weight:700;margin:24px 0 12px">Mã QR vé điện tử (1 mã cho cả đơn)</p>
                      %s
                      <p style="font-size:14px;color:#555">%s</p>
                      <p>Trân trọng,<br/><strong>ÉPCINE</strong></p>
                    </div>
                    """.formatted(
                    esc(greet),
                    esc(intro),
                    esc(detail.getBookingCode()),
                    esc(detail.getMovieTitle()),
                    esc(detail.getRoomName()),
                    esc(showDate),
                    amount,
                    seatsList,
                    qrBlock,
                    esc(outro));

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromEmail, fromName, "UTF-8"));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail, false));
            message.setSubject("ÉPCINE — Xác nhận đặt vé " + detail.getBookingCode(), "UTF-8");
            message.setContent(htmlBody, "text/html; charset=UTF-8");
            message.saveChanges();
            Transport.send(message);

        } catch (Exception e) {
            LOG.log(Level.WARNING, "sendBookingConfirmationEmail failed to " + toEmail, e);
        }
    }

    /**
     * FR-19 — Gửi email xác nhận bất đồng bộ theo bookingId (dùng chung staff + customer).
     * Bỏ qua walk-in (không có userId / email).
     */
    public static void sendBookingConfirmationEmailAsync(String bookingId) {
        if (bookingId == null || bookingId.isBlank()) {
            return;
        }
        new Thread(() -> {
            try {
                BookingDetailDTO detail = new dal.BookingDAO().getDetailById(bookingId);
                if (detail == null || detail.getUserId() == null || detail.getUserId().isBlank()) {
                    return;
                }
                String email = new dal.UserDAO().findById(detail.getUserId())
                        .map(u -> u.getEmail())
                        .orElse(null);
                if (email == null || email.isBlank()) {
                    return;
                }
                detail.setLinkedUserEmail(email);
                String name = detail.getCustomerName();
                sendBookingConfirmationEmail(email, name, detail);
            } catch (Exception e) {
                LOG.log(Level.WARNING, "Async booking confirmation email failed for " + bookingId, e);
            }
        }, "epcine-booking-email-" + bookingId).start();
    }

    public static String buildVerifyUrl(String contextPath, String token) {
        return buildActionUrl(contextPath, "/verify-email", token);
    }

    public static String buildResetPasswordUrl(String contextPath, String token) {
        return buildActionUrl(contextPath, "/reset-password", token);
    }

    public static String buildProfileSecurityUrl(String contextPath, String token) {
        return buildActionUrl(contextPath, "/profile/security-verify/confirm", token);
    }

    /** URL công khai mở toàn bộ vé của đơn — dùng trong QR email (1 QR / 1 đơn). */
    public static String buildTicketViewUrl(String bookingCode) {
        String base = resolveAppBaseUrl("");
        String encoded = URLEncoder.encode(
                bookingCode != null ? bookingCode : "", StandardCharsets.UTF_8);
        return base + "/ticket?booking=" + encoded;
    }

    /** Ảnh QR (API công khai) encode nội dung — dùng trong HTML email. */
    public static String buildQrImageUrl(String content) {
        String data = URLEncoder.encode(
                content != null ? content : "", StandardCharsets.UTF_8);
        return "https://api.qrserver.com/v1/create-qr-code/?size=180x180&ecc=M&data=" + data;
    }

    private static String resolveAppBaseUrl(String contextPathFallback) {
        Properties props = loadProperties();
        String base = props != null
                ? props.getProperty("app.base.url", "").trim()
                : "";
        if (base.isBlank()) {
            base = contextPathFallback != null ? contextPathFallback : "";
        }
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
        return base;
    }

    private static String esc(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    private static String buildActionUrl(String contextPath, String path, String token) {
        String base = resolveAppBaseUrl(contextPath);
        return base + path + "?token=" + token;
    }

    private static Properties requireProperties() throws MessagingException {
        Properties props = loadProperties();
        if (props == null || !isConfigured()) {
            throw new MessagingException(
                    "Chưa cấu hình email.properties. Sao chép email.properties.example và điền SMTP.");
        }
        return props;
    }

    private static Properties buildMailSessionProperties(Properties fileProps) {
        Properties mailProps = new Properties();
        mailProps.putAll(fileProps);
        mailProps.putIfAbsent("mail.mime.charset", "UTF-8");
        mailProps.putIfAbsent("mail.mime.encodeparameters", "true");
        mailProps.putIfAbsent("mail.smtp.ssl.protocols", "TLSv1.2");
        mailProps.putIfAbsent("mail.smtp.ssl.trust", "smtp.gmail.com");
        mailProps.putIfAbsent("mail.smtp.connectiontimeout", "15000");
        mailProps.putIfAbsent("mail.smtp.timeout", "15000");
        mailProps.putIfAbsent("mail.smtp.writetimeout", "15000");
        return mailProps;
    }

    private static Properties loadProperties() {
        try (InputStream in = EmailUtil.class.getClassLoader().getResourceAsStream(PROPS_FILE)) {
            if (in == null) {
                return null;
            }
            Properties props = new Properties();
            props.load(in);
            return props;
        } catch (IOException ex) {
            LOG.log(Level.WARNING, "Cannot load email.properties", ex);
            return null;
        }
    }
}
