package utils;

import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
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
                && !user.contains("your.email");
    }

    public static int verificationExpiryMinutes() {
        return VERIFY_TOKEN_MINUTES;
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

    public static String buildVerifyUrl(String contextPath, String token) {
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
        return base + "/verify-email?token=" + token;
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
