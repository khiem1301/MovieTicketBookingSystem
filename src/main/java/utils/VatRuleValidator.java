package utils;

import model.dto.VatRuleForm;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public final class VatRuleValidator {

    private static final BigDecimal MIN_RATE = BigDecimal.ZERO;
    private static final BigDecimal MAX_RATE = new BigDecimal("100");

    private VatRuleValidator() {}

    public static List<String> validate(VatRuleForm form) {
        List<String> errors = new ArrayList<>();

        String ruleName = form.getRuleName() == null ? "" : form.getRuleName().trim();
        if (ruleName.isEmpty()) {
            errors.add("Tên quy tắc không được để trống.");
        } else if (ruleName.length() > 100) {
            errors.add("Tên quy tắc không được vượt quá 100 ký tự.");
        }

        BigDecimal rate = parseRate(form.getVatRate(), errors);
        if (rate != null && (rate.compareTo(MIN_RATE) < 0 || rate.compareTo(MAX_RATE) > 0)) {
            errors.add("Thuế suất VAT phải từ 0% đến 100%.");
        }

        if (form.getStartDate() == null) {
            errors.add("Ngày bắt đầu áp dụng không được để trống.");
        } else {
            LocalDate start = form.getStartDate().toLocalDate();
            if (start.isBefore(LocalDate.now())) {
                errors.add("Ngày bắt đầu áp dụng không được là ngày trong quá khứ.");
            }
        }

        return errors;
    }

    private static BigDecimal parseRate(String raw, List<String> errors) {
        if (raw == null || raw.isBlank()) {
            errors.add("Thuế suất VAT không được để trống.");
            return null;
        }
        try {
            return new BigDecimal(raw.trim());
        } catch (NumberFormatException ex) {
            errors.add("Thuế suất VAT phải là số hợp lệ (VD: 8 hoặc 10.00).");
            return null;
        }
    }
}
