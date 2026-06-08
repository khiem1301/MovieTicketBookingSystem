package utils;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class ConfigKeys {

    public static final String LOYALTY_EARN_RATE            = "loyalty_earn_rate";
    public static final String LOYALTY_REDEEM_RATE          = "loyalty_redeem_rate";
    public static final String LOYALTY_MIN_REDEEM           = "loyalty_min_redeem";
    public static final String LOYALTY_MAX_REDEEM_PER_ORDER = "loyalty_max_redeem_per_order";

    public static final List<String> LOYALTY_KEYS = List.of(
            LOYALTY_EARN_RATE,
            LOYALTY_REDEEM_RATE,
            LOYALTY_MIN_REDEEM,
            LOYALTY_MAX_REDEEM_PER_ORDER
    );

    private static final Map<String, String> LABELS = new LinkedHashMap<>();

    static {
        LABELS.put(LOYALTY_EARN_RATE, "Tỷ lệ tích điểm (điểm / 1.000đ chi tiêu)");
        LABELS.put(LOYALTY_REDEEM_RATE, "Số điểm để đổi 10.000đ giảm giá");
        LABELS.put(LOYALTY_MIN_REDEEM, "Điểm tối thiểu mỗi đơn");
        LABELS.put(LOYALTY_MAX_REDEEM_PER_ORDER, "Điểm tối đa mỗi đơn");
    }

    private ConfigKeys() {}

    public static String labelFor(String key) {
        return LABELS.getOrDefault(key, key);
    }

    public static boolean isKnownKey(String key) {
        return LABELS.containsKey(key);
    }
}
