package utils;

import model.entity.PricingRule;
import model.entity.Showtime;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * FR-11 / FR-50 — Tính giá hiệu quả sau khi áp các PricingRules ACTIVE.
 * Công thức: base_price × (1 + Σ% / 100) + Σfixed
 */
public final class PricingCalculator {

    private PricingCalculator() {}

    public static BigDecimal calculateEffectivePrice(Showtime showtime, List<PricingRule> rules) {
        if (showtime == null || showtime.getBasePrice() == null) {
            return BigDecimal.ZERO;
        }
        if (rules == null || rules.isEmpty()) {
            return showtime.getBasePrice();
        }

        Timestamp start = showtime.getStartTime();
        if (start == null) {
            return showtime.getBasePrice();
        }

        LocalDate showDate = start.toLocalDateTime().toLocalDate();
        LocalTime showTime = start.toLocalDateTime().toLocalTime();
        int dayOfWeek = start.toLocalDateTime().getDayOfWeek().getValue();

        BigDecimal sumPercent = BigDecimal.ZERO;
        BigDecimal sumFixed = BigDecimal.ZERO;

        for (PricingRule rule : rules) {
            if (!"ACTIVE".equals(rule.getStatus()) || !matches(rule, showDate, showTime, dayOfWeek)) {
                continue;
            }
            BigDecimal value = rule.getAdjustmentValue() != null ? rule.getAdjustmentValue() : BigDecimal.ZERO;
            if ("PERCENTAGE".equals(rule.getAdjustmentType())) {
                sumPercent = sumPercent.add(value);
            } else if ("FIXED_AMOUNT".equals(rule.getAdjustmentType())) {
                sumFixed = sumFixed.add(value);
            }
        }

        BigDecimal base = showtime.getBasePrice();
        BigDecimal multiplier = BigDecimal.ONE.add(sumPercent.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP));
        return base.multiply(multiplier).add(sumFixed).setScale(0, RoundingMode.HALF_UP);
    }

    public static void applyToShowtimes(List<Showtime> showtimes, List<PricingRule> rules) {
        if (showtimes == null) return;
        for (Showtime showtime : showtimes) {
            showtime.setEffectivePrice(calculateEffectivePrice(showtime, rules));
        }
    }

    private static boolean matches(PricingRule rule, LocalDate showDate, LocalTime showTime, int dayOfWeek) {
        return switch (rule.getConditionType()) {
            case "DAY_OF_WEEK" -> matchesDayOfWeek(rule.getDayOfWeek(), dayOfWeek);
            case "TIME_RANGE" -> matchesTimeRange(rule.getTimeFrom(), rule.getTimeTo(), showTime);
            case "DATE_RANGE" -> matchesDateRange(rule.getDateFrom(), rule.getDateTo(), showDate);
            case "SPECIFIC_DATE" -> matchesSpecificDate(rule.getDateFrom(), showDate);
            default -> false;
        };
    }

    private static boolean matchesDayOfWeek(String dayOfWeekCsv, int dayOfWeek) {
        if (dayOfWeekCsv == null || dayOfWeekCsv.isBlank()) return false;
        Set<Integer> days = Arrays.stream(dayOfWeekCsv.split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::parseInt)
                .collect(Collectors.toSet());
        return days.contains(dayOfWeek);
    }

    private static boolean matchesTimeRange(Time timeFrom, Time timeTo, LocalTime showTime) {
        if (timeFrom == null || timeTo == null) return false;
        LocalTime from = timeFrom.toLocalTime();
        LocalTime to = timeTo.toLocalTime();
        if (!from.isAfter(to)) {
            return !showTime.isBefore(from) && !showTime.isAfter(to);
        }
        return !showTime.isBefore(from) || !showTime.isAfter(to);
    }

    private static boolean matchesDateRange(Date dateFrom, Date dateTo, LocalDate showDate) {
        if (dateFrom == null) return false;
        LocalDate from = dateFrom.toLocalDate();
        LocalDate to = dateTo != null ? dateTo.toLocalDate() : from;
        return !showDate.isBefore(from) && !showDate.isAfter(to);
    }

    private static boolean matchesSpecificDate(Date dateFrom, LocalDate showDate) {
        if (dateFrom == null) return false;
        return showDate.equals(dateFrom.toLocalDate());
    }
}
