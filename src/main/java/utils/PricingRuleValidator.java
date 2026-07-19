package utils;

import model.entity.PricingRule;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * FR-49 — Parse + validate form tạo/sửa quy tắc giá động.
 */
public final class PricingRuleValidator {

    private static final Set<String> CONDITION_TYPES = Set.of(
            "DAY_OF_WEEK", "TIME_RANGE", "DATE_RANGE", "SPECIFIC_DATE");
    private static final Set<String> ADJUSTMENT_TYPES = Set.of("PERCENTAGE", "FIXED_AMOUNT");
    private static final Set<String> STATUSES = Set.of("ACTIVE", "INACTIVE");

    private static final BigDecimal MAX_PERCENT = new BigDecimal("100");
    private static final BigDecimal MAX_FIXED = new BigDecimal("5000000");
    private static final int MAX_PRIORITY = 9999;

    private PricingRuleValidator() {}

    public static final class Result {
        private final List<String> errors = new ArrayList<>();
        private PricingRule rule;

        public boolean isValid() {
            return errors.isEmpty() && rule != null;
        }

        public List<String> getErrors() {
            return errors;
        }

        public PricingRule getRule() {
            return rule;
        }
    }

    /**
     * @param days checkbox values (1–7) từ form; có thể null
     */
    public static Result parseAndValidate(
            String ruleName,
            String conditionType,
            String[] days,
            String timeFromRaw,
            String timeToRaw,
            String dateFromRaw,
            String dateToRaw,
            String adjustmentType,
            String adjustmentValueRaw,
            String priorityRaw,
            String status) {

        Result result = new Result();
        PricingRule rule = new PricingRule();

        String name = ruleName == null ? "" : ruleName.trim();
        if (name.isEmpty()) {
            result.errors.add("Tên quy tắc không được để trống.");
        } else if (name.length() > 100) {
            result.errors.add("Tên quy tắc tối đa 100 ký tự.");
        } else {
            rule.setRuleName(name);
        }

        String condition = trimOrNull(conditionType);
        if (condition == null || !CONDITION_TYPES.contains(condition)) {
            result.errors.add("Loại điều kiện không hợp lệ.");
        } else {
            rule.setConditionType(condition);
        }

        String adjustment = trimOrNull(adjustmentType);
        if (adjustment == null || !ADJUSTMENT_TYPES.contains(adjustment)) {
            result.errors.add("Loại điều chỉnh không hợp lệ.");
        } else {
            rule.setAdjustmentType(adjustment);
        }

        BigDecimal value = parseAdjustmentValue(adjustmentValueRaw, adjustment, result.errors);
        if (value != null) {
            rule.setAdjustmentValue(value);
        }

        Integer priority = parsePriority(priorityRaw, result.errors);
        if (priority != null) {
            rule.setPriority(priority);
        }

        String statusVal = trimOrNull(status);
        if (statusVal == null || !STATUSES.contains(statusVal)) {
            result.errors.add("Trạng thái không hợp lệ.");
        } else {
            rule.setStatus(statusVal);
        }

        if (condition != null && CONDITION_TYPES.contains(condition)) {
            applyConditionFields(rule, condition, days, timeFromRaw, timeToRaw,
                    dateFromRaw, dateToRaw, result.errors);
        }

        if (result.errors.isEmpty()) {
            result.rule = rule;
        }
        return result;
    }

    private static void applyConditionFields(
            PricingRule rule,
            String condition,
            String[] days,
            String timeFromRaw,
            String timeToRaw,
            String dateFromRaw,
            String dateToRaw,
            List<String> errors) {

        rule.setDayOfWeek(null);
        rule.setTimeFrom(null);
        rule.setTimeTo(null);
        rule.setDateFrom(null);
        rule.setDateTo(null);

        switch (condition) {
            case "DAY_OF_WEEK" -> {
                String csv = buildDayOfWeekCsv(days, errors);
                if (csv != null) {
                    rule.setDayOfWeek(csv);
                }
            }
            case "TIME_RANGE" -> {
                Time from = parseTime(timeFromRaw, "Giờ bắt đầu", errors);
                Time to = parseTime(timeToRaw, "Giờ kết thúc", errors);
                if (from != null && to != null) {
                    if (from.equals(to)) {
                        errors.add("Khung giờ: giờ bắt đầu và kết thúc không được trùng nhau.");
                    } else {
                        rule.setTimeFrom(from);
                        rule.setTimeTo(to);
                    }
                }
            }
            case "DATE_RANGE" -> {
                Date from = parseDate(dateFromRaw, "Ngày bắt đầu", errors);
                Date to = parseDate(dateToRaw, "Ngày kết thúc", errors);
                if (from != null && to != null) {
                    if (to.toLocalDate().isBefore(from.toLocalDate())) {
                        errors.add("Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu.");
                    } else {
                        rule.setDateFrom(from);
                        rule.setDateTo(to);
                    }
                }
            }
            case "SPECIFIC_DATE" -> {
                Date from = parseDate(dateFromRaw, "Ngày áp dụng", errors);
                if (from != null) {
                    rule.setDateFrom(from);
                }
            }
            default -> { }
        }
    }

    private static String buildDayOfWeekCsv(String[] days, List<String> errors) {
        if (days == null || days.length == 0) {
            errors.add("Vui lòng chọn ít nhất một ngày trong tuần.");
            return null;
        }
        LinkedHashSet<Integer> unique = new LinkedHashSet<>();
        for (String raw : days) {
            if (raw == null || raw.isBlank()) continue;
            try {
                int d = Integer.parseInt(raw.trim());
                if (d < 1 || d > 7) {
                    errors.add("Ngày trong tuần phải nằm trong khoảng 1–7 (T2–CN).");
                    return null;
                }
                unique.add(d);
            } catch (NumberFormatException ex) {
                errors.add("Ngày trong tuần không hợp lệ.");
                return null;
            }
        }
        if (unique.isEmpty()) {
            errors.add("Vui lòng chọn ít nhất một ngày trong tuần.");
            return null;
        }
        StringBuilder sb = new StringBuilder();
        for (Integer d : unique) {
            if (sb.length() > 0) sb.append(',');
            sb.append(d);
        }
        return sb.toString();
    }

    private static BigDecimal parseAdjustmentValue(String raw, String adjustmentType, List<String> errors) {
        if (raw == null || raw.isBlank()) {
            errors.add("Giá trị điều chỉnh không được để trống.");
            return null;
        }
        BigDecimal value;
        try {
            value = new BigDecimal(raw.trim().replace(",", ""));
        } catch (NumberFormatException ex) {
            errors.add("Giá trị điều chỉnh phải là số hợp lệ.");
            return null;
        }
        if ("PERCENTAGE".equals(adjustmentType)) {
            if (value.compareTo(BigDecimal.ZERO) <= 0 || value.compareTo(MAX_PERCENT) > 0) {
                errors.add("Phần trăm điều chỉnh phải lớn hơn 0 và không vượt quá 100.");
                return null;
            }
        } else if ("FIXED_AMOUNT".equals(adjustmentType)) {
            if (value.compareTo(BigDecimal.ZERO) <= 0) {
                errors.add("Số tiền cố định phải lớn hơn 0.");
                return null;
            }
            if (value.compareTo(MAX_FIXED) > 0) {
                errors.add("Số tiền cố định tối đa 5.000.000đ.");
                return null;
            }
        }
        return value;
    }

    private static Integer parsePriority(String raw, List<String> errors) {
        if (raw == null || raw.isBlank()) {
            errors.add("Độ ưu tiên không được để trống.");
            return null;
        }
        try {
            int p = Integer.parseInt(raw.trim());
            if (p < 0) {
                errors.add("Độ ưu tiên phải là số nguyên ≥ 0.");
                return null;
            }
            if (p > MAX_PRIORITY) {
                errors.add("Độ ưu tiên tối đa " + MAX_PRIORITY + ".");
                return null;
            }
            return p;
        } catch (NumberFormatException ex) {
            errors.add("Độ ưu tiên phải là số nguyên hợp lệ.");
            return null;
        }
    }

    private static Time parseTime(String raw, String label, List<String> errors) {
        if (raw == null || raw.isBlank()) {
            errors.add(label + " không được để trống.");
            return null;
        }
        try {
            String normalized = raw.trim();
            if (normalized.length() == 5) {
                normalized = normalized + ":00";
            }
            LocalTime lt = LocalTime.parse(normalized);
            return Time.valueOf(lt);
        } catch (DateTimeParseException | IllegalArgumentException ex) {
            errors.add(label + " không đúng định dạng (HH:mm).");
            return null;
        }
    }

    private static Date parseDate(String raw, String label, List<String> errors) {
        if (raw == null || raw.isBlank()) {
            errors.add(label + " không được để trống.");
            return null;
        }
        try {
            LocalDate ld = LocalDate.parse(raw.trim());
            return Date.valueOf(ld);
        } catch (DateTimeParseException ex) {
            errors.add(label + " không đúng định dạng (yyyy-MM-dd).");
            return null;
        }
    }

    private static String trimOrNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }

    /** Tiện ích UI: danh sách ngày đã chọn từ CSV. */
    public static Set<String> daySetFromCsv(String csv) {
        if (csv == null || csv.isBlank()) return Set.of();
        return Arrays.stream(csv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(java.util.stream.Collectors.toCollection(LinkedHashSet::new));
    }
}
