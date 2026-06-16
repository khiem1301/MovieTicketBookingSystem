package utils;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

public final class UserLockValidator {

    public static final int REASON_MIN_LENGTH = 10;
    public static final int REASON_MAX_LENGTH = 500;

    private static final Pattern MULTI_SPACE = Pattern.compile("\\s{2,}");

    private UserLockValidator() {
    }

    public static String normalizeReason(String raw) {
        if (raw == null) {
            return "";
        }
        return MULTI_SPACE.matcher(raw.trim()).replaceAll(" ");
    }

    public static List<String> validateLockReason(String rawReason) {
        List<String> errors = new ArrayList<>();
        String reason = normalizeReason(rawReason);
        if (reason.isEmpty()) {
            errors.add("Lý do khóa không được để trống.");
            return errors;
        }
        if (reason.length() < REASON_MIN_LENGTH) {
            errors.add("Lý do khóa phải có ít nhất " + REASON_MIN_LENGTH + " ký tự.");
        }
        if (reason.length() > REASON_MAX_LENGTH) {
            errors.add("Lý do khóa không được vượt quá " + REASON_MAX_LENGTH + " ký tự.");
        }
        return errors;
    }

    public static boolean wantsSendEmail(String sendEmailParam) {
        return "on".equalsIgnoreCase(trim(sendEmailParam)) || "true".equalsIgnoreCase(trim(sendEmailParam));
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }
}
