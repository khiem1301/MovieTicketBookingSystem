package utils;

/**
 * Lọc thống kê theo kênh bán vé ({@code Bookings.booking_source}),
 * không phải hình thức thanh toán (tiền mặt / chuyển khoản).
 */
public final class TicketChannelUtil {

    public static final String CHANNEL_ALL = "all";
    /** Khách đặt trên web — {@code ONLINE}. */
    public static final String CHANNEL_ONLINE = "online";
    /** Nhân viên bán tại quầy — {@code OFFLINE}. */
    public static final String CHANNEL_OFFLINE = "offline";

    private TicketChannelUtil() {
    }

    public static String normalizeChannel(String raw) {
        if (raw == null || raw.isBlank()) {
            return CHANNEL_ALL;
        }
        return switch (raw.trim().toLowerCase()) {
            case CHANNEL_ONLINE, "web", "customer" -> CHANNEL_ONLINE;
            case CHANNEL_OFFLINE, "staff", "counter" -> CHANNEL_OFFLINE;
            default -> CHANNEL_ALL;
        };
    }

    public static boolean isAll(String channel) {
        return CHANNEL_ALL.equals(normalizeChannel(channel));
    }

    public static String channelLabel(String channel) {
        return switch (normalizeChannel(channel)) {
            case CHANNEL_ONLINE -> "Web online (khách hàng)";
            case CHANNEL_OFFLINE -> "Quầy trực tiếp (staff)";
            default -> "Tất cả kênh";
        };
    }

    /**
     * SQL fragment: {@code AND [alias.]booking_source = 'ONLINE'|'OFFLINE'} hoặc rỗng.
     * @param tableAlias ví dụ {@code "b"} hoặc {@code null}/{@code ""} nếu không alias
     */
    public static String buildSourceSql(String tableAlias, String channel) {
        String normalized = normalizeChannel(channel);
        if (CHANNEL_ALL.equals(normalized)) {
            return "";
        }
        String col = (tableAlias == null || tableAlias.isBlank())
                ? "booking_source"
                : tableAlias + ".booking_source";
        String value = CHANNEL_ONLINE.equals(normalized) ? "ONLINE" : "OFFLINE";
        return " AND " + col + " = '" + value + "' ";
    }
}
