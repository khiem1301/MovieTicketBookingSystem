package utils;

import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * FR-16 — Cấu hình SePay webhook (tự xác nhận VietQR khi có tiền vào).
 */
public final class SePayConfig {

    private static final Logger LOG = Logger.getLogger(SePayConfig.class.getName());
    private static final String PROPS_FILE = "sepay.properties";

    private SePayConfig() {}

    public static boolean isEnabled() {
        Properties props = loadProperties();
        if (props == null) {
            return false;
        }
        String enabled = props.getProperty("sepay.enabled", "false").trim();
        if (!"true".equalsIgnoreCase(enabled) && !"1".equals(enabled)) {
            return false;
        }
        String apiKey = props.getProperty("sepay.webhook.api.key", "").trim();
        return !apiKey.isBlank()
                && !apiKey.contains("YOUR_SEPAY")
                && !apiKey.contains("YOUR_");
    }

    public static String webhookApiKey() {
        return require("sepay.webhook.api.key");
    }

    /** STK lọc (tuỳ chọn). */
    public static String accountNumber() {
        Properties props = loadProperties();
        if (props == null) {
            return "";
        }
        return props.getProperty("sepay.account.number", "").trim();
    }

    public static boolean matchesApiKey(String authorizationHeader) {
        if (!isEnabled() || authorizationHeader == null) {
            return false;
        }
        String expected = webhookApiKey();
        String header = authorizationHeader.trim();
        // SePay: Authorization: Apikey <key>
        String prefix = "Apikey ";
        if (header.regionMatches(true, 0, prefix, 0, prefix.length())) {
            return expected.equals(header.substring(prefix.length()).trim());
        }
        // Một số client gửi đúng key thuần
        return expected.equals(header);
    }

    private static String require(String key) {
        Properties props = loadProperties();
        String value = props != null ? props.getProperty(key, "").trim() : "";
        if (value.isBlank()) {
            throw new IllegalStateException("Thiếu cấu hình SePay: " + key);
        }
        return value;
    }

    private static Properties loadProperties() {
        Properties props = new Properties();
        try (InputStream in = SePayConfig.class.getClassLoader().getResourceAsStream(PROPS_FILE)) {
            if (in == null) {
                return props;
            }
            props.load(in);
            return props;
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Không đọc được " + PROPS_FILE, e);
            return props;
        }
    }
}
