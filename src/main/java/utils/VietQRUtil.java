package utils;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * FR-16 — Tạo URL mã QR VietQR (img.vietqr.io) và nội dung chuyển khoản.
 */
public final class VietQRUtil {

    private static final int MAX_TRANSFER_CONTENT_LEN = 25;

    private VietQRUtil() {}

    /** Nội dung chuyển khoản — dùng mã đơn để đối soát. */
    public static String transferContent(String bookingCode) {
        if (bookingCode == null || bookingCode.isBlank()) {
            return "THANHTOAN";
        }
        String cleaned = bookingCode.trim().toUpperCase().replaceAll("[^A-Z0-9]", "");
        if (cleaned.length() > MAX_TRANSFER_CONTENT_LEN) {
            return cleaned.substring(0, MAX_TRANSFER_CONTENT_LEN);
        }
        return cleaned.isBlank() ? "THANHTOAN" : cleaned;
    }

    /** URL ảnh QR động (số tiền + nội dung đã nhúng). */
    public static String qrImageUrl(BigDecimal amountVnd, String transferContent) {
        long amount = amountVnd != null ? amountVnd.longValue() : 0L;
        if (amount <= 0) {
            throw new IllegalArgumentException("Số tiền VietQR không hợp lệ");
        }
        String path = VietQRConfig.imageBaseUrl()
                + "/" + VietQRConfig.bankBin()
                + "-" + VietQRConfig.accountNumber()
                + "-" + VietQRConfig.template()
                + ".png";
        StringBuilder url = new StringBuilder(path);
        url.append("?amount=").append(amount);
        url.append("&addInfo=").append(encode(transferContent));
        url.append("&accountName=").append(encode(VietQRConfig.accountName()));
        return url.toString();
    }

    private static String encode(String value) {
        return URLEncoder.encode(value != null ? value : "", StandardCharsets.UTF_8);
    }
}
