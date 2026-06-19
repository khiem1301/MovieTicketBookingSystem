package utils;

import dal.UserDAO;

import java.util.ArrayList;
import java.util.List;

/**
 * FR-05 — Validate cập nhật thông tin profile.
 */
public final class ProfileValidator {

    private ProfileValidator() {}

    public static List<String> validate(String fullName, String phoneNumber, String username,
                                        String excludeUserId, UserDAO userDAO) {
        List<String> errors = new ArrayList<>();

        if (fullName == null || fullName.isBlank()) {
            errors.add("Họ tên không được để trống.");
        } else if (fullName.trim().length() > 255) {
            errors.add("Họ tên không được vượt quá 255 ký tự.");
        }

        RegisterValidator.validatePhone(phoneNumber, userDAO, excludeUserId).ifPresent(errors::add);
        RegisterValidator.validateUsername(username, userDAO, excludeUserId).ifPresent(errors::add);

        return errors;
    }
}
