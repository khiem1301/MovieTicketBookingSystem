package utils;

import model.entity.Showtime;

import java.sql.Timestamp;
import java.util.concurrent.TimeUnit;

/**
 * Cửa sổ đặt vé: cho phép mua muộn tối đa {@link #LATE_BOOKING_GRACE_MINUTES}
 * sau giờ bắt đầu (customer + staff). Suất CANCELLED / FINISHED / đã hết phim vẫn chặn.
 */
public final class ShowtimeBookingWindow {

    /** Số phút sau start_time vẫn còn được đặt vé. */
    public static final int LATE_BOOKING_GRACE_MINUTES = 30;

    private ShowtimeBookingWindow() {
    }

    /** Hạn chót đặt vé = start_time + grace. */
    public static Timestamp bookingDeadline(Timestamp startTime) {
        if (startTime == null) return null;
        return new Timestamp(startTime.getTime()
                + TimeUnit.MINUTES.toMillis(LATE_BOOKING_GRACE_MINUTES));
    }

    /**
     * Suất còn đặt được nếu:
     * - không CANCELLED / FINISHED
     * - chưa qua end_time
     * - now &lt; start_time + 30 phút
     */
    public static boolean isBookable(Showtime showtime) {
        return unbookableReason(showtime) == null;
    }

    /** @return null nếu đặt được; ngược lại message lỗi tiếng Việt */
    public static String unbookableReason(Showtime showtime) {
        if (showtime == null) {
            return "Suất chiếu không tồn tại.";
        }
        String status = showtime.getStatus();
        if ("CANCELLED".equals(status)) {
            return "Suất chiếu đã bị hủy.";
        }
        if ("FINISHED".equals(status)) {
            return "Suất chiếu đã kết thúc.";
        }

        Timestamp start = showtime.getStartTime();
        Timestamp end = showtime.getEndTime();
        long now = System.currentTimeMillis();

        if (end != null && end.getTime() <= now) {
            return "Suất chiếu đã kết thúc.";
        }
        if (start == null) {
            return "Suất chiếu không khả dụng.";
        }
        Timestamp deadline = bookingDeadline(start);
        if (deadline != null && now >= deadline.getTime()) {
            return "Đã quá " + LATE_BOOKING_GRACE_MINUTES
                    + " phút sau giờ bắt đầu — không thể đặt vé.";
        }
        return null;
    }
}
