package utils;

import java.util.regex.Pattern;

public final class IdParamUtil {

    /** UUID chuẩn 8-4-4-4-12 (đúng độ dài từng nhóm — không dùng UUID.fromString vì Java chấp nhận thiếu ký tự). */
    private static final Pattern UUID_PATTERN = Pattern.compile(
            "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    );

    private IdParamUtil() {}

    public static String normalize(String value) {
        return value == null ? null : value.trim();
    }

    public static boolean isValidUuid(String value) {
        String normalized = normalize(value);
        return normalized != null && UUID_PATTERN.matcher(normalized).matches();
    }
}
