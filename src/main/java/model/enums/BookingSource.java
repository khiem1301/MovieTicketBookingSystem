package model.enums;

/**
 * FR-39 — Booking Source Management
 * Phân biệt đơn đặt vé online (khách tự đặt) và offline (staff đặt tại quầy).
 */
public enum BookingSource {
    ONLINE, OFFLINE;

    public static BookingSource fromString(String value) {
        if (value == null) return null;
        try {
            return valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
