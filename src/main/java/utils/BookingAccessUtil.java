package utils;

import model.dto.BookingDetailDTO;
import model.entity.Booking;

/**
 * FR-15 — Kiểm tra quyền truy cập đơn đặt vé theo chủ sở hữu.
 */
public final class BookingAccessUtil {

    private BookingAccessUtil() {
    }

    public static boolean isOwner(BookingDetailDTO detail, String userId) {
        if (detail == null || userId == null || userId.isBlank()) {
            return false;
        }
        return userId.equals(detail.getUserId());
    }

    public static boolean isOwner(Booking booking, String userId) {
        if (booking == null || userId == null || userId.isBlank()) {
            return false;
        }
        return userId.equals(booking.getUserId());
    }
}
