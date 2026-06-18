package utils;

import dal.UserDAO;
import model.dto.RegisterForm;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

public final class RegisterValidator {

    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    private static final Pattern PHONE_PATTERN =
            Pattern.compile("^(0|\\+84)[0-9]{8,10}$");

    private RegisterValidator() {}

    public static List<String> validate(RegisterForm form, UserDAO userDAO) {
        List<String> errors = new ArrayList<>();

        if (isBlank(form.getFullName())) {
            errors.add("Họ tên không được để trống.");
        } else if (form.getFullName().trim().length() > 255) {
            errors.add("Họ tên không được vượt quá 255 ký tự.");
        }

        if (form.getDateOfBirth() == null) {
            errors.add("Ngày sinh không được để trống.");
        } else if (form.getDateOfBirth().toLocalDate().isAfter(LocalDate.now())) {
            errors.add("Ngày sinh không được là ngày trong tương lai.");
        }

        if (isBlank(form.getEmail())) {
            errors.add("Email không được để trống.");
        } else {
            String email = form.getEmail().trim().toLowerCase();
            form.setEmail(email);
            if (!EMAIL_PATTERN.matcher(email).matches()) {
                errors.add("Email không đúng định dạng.");
            } else if (userDAO.existsByEmail(email)) {
                errors.add("Email đã được sử dụng.");
            }
        }

        Optional<String> phoneError = validatePhone(form.getPhoneNumber(), userDAO);
        if (phoneError.isPresent()) {
            errors.add(phoneError.get());
        } else {
            form.setPhoneNumber(normalizePhone(form.getPhoneNumber().trim()));
        }

        errors.addAll(PasswordValidator.validate(form.getPassword(), form.getConfirmPassword()));

        return errors;
    }

    /**
     * Validates phone number: required, format, and duplicate check.
     * Returns normalized phone via the mutable holder when valid.
     */
    public static Optional<String> validatePhone(String rawPhone, UserDAO userDAO) {
        if (isBlank(rawPhone)) {
            return Optional.of("Số điện thoại không được để trống.");
        }
        String phone = normalizePhone(rawPhone.trim());
        if (!PHONE_PATTERN.matcher(phone).matches()) {
            return Optional.of("Số điện thoại không hợp lệ (VD: 0901234567).");
        }
        if (userDAO.existsByPhone(phone)) {
            return Optional.of("Số điện thoại đã được sử dụng.");
        }
        return Optional.empty();
    }

    public static String generateUsername(UserDAO userDAO, String email, String phone) {
        String base;
        if (email != null && !email.isBlank()) {
            base = email.split("@")[0].replaceAll("[^a-zA-Z0-9_]", "");
        } else {
            base = "user" + phone.replaceAll("\\D", "");
        }
        if (base.length() < 3) {
            base = "user" + base;
        }
        base = base.toLowerCase();
        if (base.length() > 20) {
            base = base.substring(0, 20);
        }

        String candidate = base;
        int suffix = 1;
        while (userDAO.existsByUsername(candidate)) {
            candidate = base + suffix++;
        }
        return candidate;
    }

    public static String normalizePhone(String phone) {
        if (phone.startsWith("+84")) {
            return "0" + phone.substring(3);
        }
        return phone;
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
