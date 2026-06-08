package utils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public final class SystemConfigValidator {

    private SystemConfigValidator() {}

    public static List<String> validateLoyaltyConfig(Map<String, String> values) {
        List<String> errors = new ArrayList<>();

        parsePositiveInt(values.get(ConfigKeys.LOYALTY_EARN_RATE), "Tỷ lệ tích điểm", errors, true);
        parsePositiveInt(values.get(ConfigKeys.LOYALTY_REDEEM_RATE), "Số điểm đổi 10.000đ", errors, false);
        Integer minRedeem = parsePositiveInt(values.get(ConfigKeys.LOYALTY_MIN_REDEEM), "Điểm tối thiểu mỗi đơn", errors, false);
        Integer maxRedeem = parsePositiveInt(values.get(ConfigKeys.LOYALTY_MAX_REDEEM_PER_ORDER), "Điểm tối đa mỗi đơn", errors, false);

        if (minRedeem != null && maxRedeem != null && minRedeem > maxRedeem) {
            errors.add("Điểm tối thiểu không được lớn hơn điểm tối đa mỗi đơn.");
        }

        return errors;
    }

    public static Map<String, String> normalizeLoyaltyValues(Map<String, String> raw) {
        Map<String, String> normalized = new LinkedHashMap<>();
        for (String key : ConfigKeys.LOYALTY_KEYS) {
            String value = raw.get(key);
            if (value != null) {
                normalized.put(key, value.trim());
            }
        }
        return normalized;
    }

    private static Integer parsePositiveInt(String raw, String label, List<String> errors, boolean allowZero) {
        if (raw == null || raw.isBlank()) {
            errors.add(label + " không được để trống.");
            return null;
        }
        try {
            int value = Integer.parseInt(raw.trim());
            if (value < 0 || (!allowZero && value == 0)) {
                errors.add(label + " phải là số nguyên " + (allowZero ? "≥ 0" : "> 0") + ".");
                return null;
            }
            return value;
        } catch (NumberFormatException ex) {
            errors.add(label + " phải là số nguyên hợp lệ.");
            return null;
        }
    }
}
