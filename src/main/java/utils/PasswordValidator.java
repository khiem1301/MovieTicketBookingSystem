package utils;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Pattern;

/**
 * FR-04 — Quy tắc mật khẩu thống nhất (8–16 ký tự, hoa/thường/số/ký tự đặc biệt).
 */
public final class PasswordValidator {

    public static final String HINT =
            "8–16 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.";

    private static final Pattern STRONG_PASSWORD = Pattern.compile(
            "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&#^()_+\\-=\\[\\]{};:'\",.<>/\\\\|`~])\\S{8,16}$");

    private PasswordValidator() {}

    public static List<String> validate(String password, String confirmPassword) {
        List<String> errors = new ArrayList<>();
        validateSingle(password).ifPresent(errors::add);
        if (confirmPassword == null || confirmPassword.isBlank()) {
            errors.add("Xác nhận mật khẩu không được để trống.");
        } else if (password != null && !confirmPassword.equals(password)) {
            errors.add("Xác nhận mật khẩu không khớp.");
        }
        return errors;
    }

    public static Optional<String> validateSingle(String password) {
        if (password == null || password.isBlank()) {
            return Optional.of("Mật khẩu không được để trống.");
        }
        if (password.length() < 8) {
            return Optional.of("Mật khẩu phải có ít nhất 8 ký tự.");
        }
        if (password.length() > 16) {
            return Optional.of("Mật khẩu không được vượt quá 16 ký tự.");
        }
        if (!STRONG_PASSWORD.matcher(password).matches()) {
            return Optional.of("Mật khẩu phải có chữ hoa, chữ thường, số và ký tự đặc biệt (" + HINT + ")");
        }
        return Optional.empty();
    }
}
