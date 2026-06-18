package utils;

import model.dto.BookingDetailDTO;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
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
            message.setSubject(subject, "UTF-8");
            message.setText(body, "UTF-8");
        } catch (UnsupportedEncodingException ex) {
            throw new MessagingException("Không thể mã hóa nội dung email", ex);
        }
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
        Transport.send(message);
    }

    /**
     * FR-19 — Gửi email xác nhận đặt vé kèm mã vé điện tử.
     * Chỉ gửi nếu SMTP đã cấu hình; thất bại sẽ log cảnh báo thay vì ném exception.
     */
    public static void sendBookingConfirmationEmail(String toEmail, String customerName,
                                                    BookingDetailDTO detail) {
        if (!isConfigured() || toEmail == null || toEmail.isBlank()) return;
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
            String showDate = detail.getStartTime() != null
                    ? dtFmt.format(detail.getStartTime()) : "—";

            StringBuilder seatLines = new StringBuilder();
            if (detail.getTickets() != null) {
                for (BookingDetailDTO.TicketItem t : detail.getTickets()) {
                    seatLines.append("  Ghế ").append(t.getSeatCode())
                             .append("  |  Mã vé: ").append(t.getTicketCode()).append("\n");
                }
            } else if (detail.getSeats() != null) {
                for (BookingDetailDTO.SeatItem s : detail.getSeats()) {
                    seatLines.append("  ").append(s.getSeatCode()).append("\n");
                }
            }

            String body = """
                    Xin chào %s,

                    Đặt vé của bạn tại quầy ÉPCINE đã được xác nhận thành công.

                    ─────────────────────────────
                    Mã đặt vé : %s
                    Phim      : %s
                    Phòng     : %s
                    Suất chiếu: %s
                    ─────────────────────────────
                    Danh sách vé:
                    %s
                    Tổng tiền : %,.0f ₫
                    ─────────────────────────────

                    Vui lòng xuất trình mã vé tại quầy khi vào rạp.

                    Trân trọng,
                    ÉPCINE
                    """.formatted(
                    customerName,
                    detail.getBookingCode(),
                    detail.getMovieTitle(),
                    detail.getRoomName(),
                    showDate,
                    seatLines,
                    detail.getFinalAmount() != null ? detail.getFinalAmount().doubleValue() : 0.0);

            MimeMessage message = new MimeMessage(session);
            message.setFrom(new InternetAddress(fromEmail, fromName, "UTF-8"));
            message.setSubject("ÉPCINE — Xác nhận đặt vé " + detail.getBookingCode(), "UTF-8");
            message.setText(body, "UTF-8");
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toEmail));
            Transport.send(message);

        } catch (Exception e) {
            LOG.log(Level.WARNING, "sendBookingConfirmationEmail failed to " + toEmail, e);
        }
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

    private static String buildActionUrl(String contextPath, String path, String token) {
        Properties props = loadProperties();
        String base = props != null
                ? props.getProperty("app.base.url", "").trim()
                : "";
        if (base.isBlank()) {
            base = contextPath;
        }
        if (base.endsWith("/")) {
            base = base.substring(0, base.length() - 1);
        }
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
