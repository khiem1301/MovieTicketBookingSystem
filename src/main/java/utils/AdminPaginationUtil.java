package utils;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

public final class AdminPaginationUtil {

    public static final int DEFAULT_PAGE_SIZE = 10;

    private AdminPaginationUtil() {
    }

    public static int parsePage(String raw) {
        if (raw == null || raw.isBlank()) {
            return 1;
        }
        try {
            return Math.max(1, Integer.parseInt(raw.trim()));
        } catch (NumberFormatException ex) {
            return 1;
        }
    }

    public static int totalPages(int totalItems, int pageSize) {
        if (totalItems <= 0) {
            return 1;
        }
        return Math.max(1, (int) Math.ceil((double) totalItems / pageSize));
    }

    public static int clampPage(int page, int totalPages) {
        return Math.min(Math.max(1, page), Math.max(1, totalPages));
    }

    public static int offset(int page, int pageSize) {
        return (page - 1) * pageSize;
    }

    public static int rankStart(int page, int pageSize) {
        return offset(page, pageSize) + 1;
    }

    public static String queryParam(String name, String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        return "&" + name + "=" + URLEncoder.encode(value.trim(), StandardCharsets.UTF_8);
    }
}
