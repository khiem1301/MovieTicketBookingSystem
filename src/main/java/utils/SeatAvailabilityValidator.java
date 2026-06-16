package utils;

import java.sql.Date;
import java.time.LocalDate;
import java.time.Period;
import java.util.Optional;

/**
 * FR-13 — Validate tuổi xem phim trước khi giữ ghế online.
 * P / K: không kiểm tra. T13 / T16 / T18: tính từ Users.date_of_birth.
 */
public final class SeatAvailabilityValidator {

    private SeatAvailabilityValidator() {}

    public static Optional<String> validateAge(String ageRating, Date dateOfBirth) {
        if (ageRating == null || ageRating.isBlank()) {
            return Optional.empty();
        }

        String rating = ageRating.trim().toUpperCase();
        if ("P".equals(rating) || "K".equals(rating)) {
            return Optional.empty();
        }

        int minAge = minAgeForRating(rating);
        if (minAge <= 0) {
            return Optional.empty();
        }

        if (dateOfBirth == null) {
            return Optional.of("Vui lòng cập nhật ngày sinh trong hồ sơ để đặt vé phim "
                    + rating + ".");
        }

        int age = Period.between(dateOfBirth.toLocalDate(), LocalDate.now()).getYears();
        if (age < minAge) {
            return Optional.of("Phim " + rating + " yêu cầu người xem từ " + minAge
                    + " tuổi trở lên. Bạn chưa đủ điều kiện đặt vé suất này.");
        }

        return Optional.empty();
    }

    private static int minAgeForRating(String rating) {
        return switch (rating) {
            case "T13" -> 13;
            case "T16" -> 16;
            case "T18" -> 18;
            default -> 0;
        };
    }
}
