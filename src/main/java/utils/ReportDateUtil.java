package utils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;

public final class ReportDateUtil {

    public static final String RANGE_7D = "7d";
    public static final String RANGE_30D = "30d";
    public static final String RANGE_MONTH = "month";
    public static final String RANGE_ALL = "all";
    public static final String RANGE_CUSTOM = "custom";

    private static final int MAX_CUSTOM_DAYS = 365;
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    private ReportDateUtil() {
    }

    public record DateRange(
            LocalDateTime fromInclusive,
            LocalDateTime toExclusive,
            String rangeKey,
            String label,
            boolean customApplied
    ) {
        public boolean hasBounds() {
            return fromInclusive != null && toExclusive != null;
        }
    }

    public record ResolveResult(DateRange range, String warning) {
    }

    public static ResolveResult resolve(String range, String fromStr, String toStr) {
        String from = trim(fromStr);
        String to = trim(toStr);

        if (!from.isEmpty() && !to.isEmpty()) {
            try {
                LocalDate fromDate = LocalDate.parse(from, DATE_FMT);
                LocalDate toDate = LocalDate.parse(to, DATE_FMT);
                if (fromDate.isAfter(toDate)) {
                    return fallback(RANGE_7D, "Ngày bắt đầu phải trước hoặc bằng ngày kết thúc. Đã dùng 7 ngày gần nhất.");
                }
                long days = ChronoUnit.DAYS.between(fromDate, toDate) + 1;
                if (days > MAX_CUSTOM_DAYS) {
                    return fallback(RANGE_7D, "Khoảng thời gian tối đa " + MAX_CUSTOM_DAYS + " ngày. Đã dùng 7 ngày gần nhất.");
                }
                LocalDateTime fromInclusive = fromDate.atStartOfDay();
                LocalDateTime toExclusive = toDate.plusDays(1).atStartOfDay();
                String label = "Từ " + from + " đến " + to;
                return new ResolveResult(
                        new DateRange(fromInclusive, toExclusive, RANGE_CUSTOM, label, true),
                        null
                );
            } catch (DateTimeParseException ex) {
                return fallback(RANGE_7D, "Định dạng ngày không hợp lệ. Đã dùng 7 ngày gần nhất.");
            }
        }

        String key = normalizeRange(range);
        return new ResolveResult(buildPreset(key), null);
    }

    public static DateRange currentMonth() {
        LocalDate today = LocalDate.now();
        LocalDateTime from = today.withDayOfMonth(1).atStartOfDay();
        LocalDateTime to = today.plusMonths(1).withDayOfMonth(1).atStartOfDay();
        return new DateRange(from, to, RANGE_MONTH, "Tháng " + today.getMonthValue() + "/" + today.getYear(), false);
    }

    private static ResolveResult fallback(String rangeKey, String warning) {
        return new ResolveResult(buildPreset(rangeKey), warning);
    }

    private static String normalizeRange(String range) {
        if (range == null) {
            return RANGE_7D;
        }
        return switch (range.trim().toLowerCase()) {
            case RANGE_30D, RANGE_MONTH, RANGE_ALL -> range.trim().toLowerCase();
            default -> RANGE_7D;
        };
    }

    private static DateRange buildPreset(String key) {
        LocalDate today = LocalDate.now();
        return switch (key) {
            case RANGE_30D -> {
                LocalDateTime from = today.minusDays(29).atStartOfDay();
                LocalDateTime to = today.plusDays(1).atStartOfDay();
                yield new DateRange(from, to, RANGE_30D, "30 ngày gần nhất", false);
            }
            case RANGE_MONTH -> currentMonth();
            case RANGE_ALL -> new DateRange(null, null, RANGE_ALL, "Toàn bộ thời gian", false);
            default -> {
                LocalDateTime from = today.minusDays(6).atStartOfDay();
                LocalDateTime to = today.plusDays(1).atStartOfDay();
                yield new DateRange(from, to, RANGE_7D, "7 ngày gần nhất", false);
            }
        };
    }

    private static String trim(String value) {
        return value == null ? "" : value.trim();
    }
}
