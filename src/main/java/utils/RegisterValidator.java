package utils;

import dal.UserDAO;
import model.dto.RegisterForm;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
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

        boolean hasEmail = !isBlank(form.getEmail());
        boolean hasPhone = !isBlank(form.getPhoneNumber());
        if (!hasEmail && !hasPhone) {
            errors.add("Vui lòng nhập email hoặc số điện thoại.");
        }

        if (hasEmail) {
            String email = form.getEmail().trim().toLowerCase();
            form.setEmail(email);
            if (!EMAIL_PATTERN.matcher(email).matches()) {
                errors.add("Email không đúng định dạng.");
            } else if (userDAO.existsByEmail(email)) {
                errors.add("Email đã được sử dụng.");
            }
        }

        if (hasPhone) {
            String phone = normalizePhone(form.getPhoneNumber().trim());
            form.setPhoneNumber(phone);
            if (!PHONE_PATTERN.matcher(phone).matches()) {
                errors.add("Số điện thoại không hợp lệ (VD: 0901234567).");
            } else if (userDAO.existsByPhone(phone)) {
                errors.add("Số điện thoại đã được sử dụng.");
            }
        }

        if (form.getPassword() == null || form.getPassword().length() < 8) {
            errors.add("Mật khẩu phải có ít nhất 8 ký tự.");
        }
        if (form.getConfirmPassword() == null
                || !form.getConfirmPassword().equals(form.getPassword())) {
            errors.add("Xác nhận mật khẩu không khớp.");
        }

        return errors;
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

    private static String normalizePhone(String phone) {
        if (phone.startsWith("+84")) {
            return "0" + phone.substring(3);
        }
        return phone;
    }

    private static boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
