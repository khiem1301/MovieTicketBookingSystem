package utils;

import java.io.InputStream;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * FR-16 — Cấu hình VietQR chuyển khoản ngân hàng (vietqr.properties).
 */
public final class VietQRConfig {

    private static final Logger LOG = Logger.getLogger(VietQRConfig.class.getName());
    private static final String PROPS_FILE = "vietqr.properties";

    private VietQRConfig() {}

    public static boolean isConfigured() {
        Properties props = loadProperties();
        if (props == null) {
            return false;
        }
        return !props.getProperty("vietqr.bank.bin", "").trim().isBlank()
                && !props.getProperty("vietqr.account.number", "").trim().isBlank()
                && !props.getProperty("vietqr.account.name", "").trim().isBlank();
    }

    public static String bankBin() {
        return require("vietqr.bank.bin");
    }

    public static String bankName() {
        String name = loadProperties().getProperty("vietqr.bank.name", "").trim();
        return name.isBlank() ? "Ngân hàng" : name;
    }

    public static String accountNumber() {
        return require("vietqr.account.number");
    }

    public static String accountName() {
        return require("vietqr.account.name");
    }

    /** compact, compact2, qr_only, print — xem img.vietqr.io */
    public static String template() {
        String t = loadProperties().getProperty("vietqr.template", "").trim();
        return t.isBlank() ? "compact2" : t;
    }

    public static String imageBaseUrl() {
        String url = loadProperties().getProperty("vietqr.image.base.url", "").trim();
        return url.isBlank() ? "https://img.vietqr.io/image" : url.replaceAll("/+$", "");
    }

    private static String require(String key) {
        String value = loadProperties().getProperty(key, "").trim();
        if (value.isBlank()) {
            throw new IllegalStateException("Thiếu cấu hình VietQR: " + key + " trong vietqr.properties");
        }
        return value;
    }

    private static Properties loadProperties() {
        Properties props = new Properties();
        try (InputStream in = VietQRConfig.class.getClassLoader().getResourceAsStream(PROPS_FILE)) {
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
