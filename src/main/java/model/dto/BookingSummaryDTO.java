package model.dto;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * FR-15 — Một dòng tóm tắt đơn trên trang lịch sử đặt vé.
 */
public class BookingSummaryDTO {

    private String bookingId;
    private String bookingCode;
    private String bookingSource;
    private String bookingStatus;
    private String paymentStatus;
    private Timestamp bookedAt;
    private Timestamp expiredAt;
    private Timestamp startTime;
    private String movieTitle;
    private String moviePosterUrl;
    private String roomName;
    private BigDecimal finalAmount;
    private int seatCount;
    private String seatCodesSummary;

    public boolean isPayable() {
        if (!"PENDING".equals(bookingStatus) || !"UNPAID".equals(paymentStatus)) {
            return false;
        }
        if (expiredAt == null) {
            return true;
        }
        return expiredAt.after(new Timestamp(System.currentTimeMillis()));
    }

    public boolean isViewableTicket() {
        return "CONFIRMED".equals(bookingStatus) && "PAID".equals(paymentStatus);
    }

    public String getDisplayStatusLabel() {
        if (isViewableTicket()) {
            return "ĐÃ THANH TOÁN";
        }
        if (isPayable()) {
            return "CHỜ THANH TOÁN";
        }
        return switch (bookingStatus != null ? bookingStatus : "") {
            case "CANCELLED" -> "ĐÃ HỦY";
            case "EXPIRED" -> "HẾT HẠN";
            case "REFUNDED" -> "ĐÃ HOÀN";
            case "PENDING" -> "CHỜ THANH TOÁN";
            case "CONFIRMED" -> "ĐÃ XÁC NHẬN";
            default -> bookingStatus != null ? bookingStatus : "—";
        };
    }

    public String getStatusBadgeClass() {
        if (isViewableTicket()) {
            return "bh-badge--paid";
        }
        if (isPayable()) {
            return "bh-badge--pending";
        }
        return switch (bookingStatus != null ? bookingStatus : "") {
            case "CANCELLED" -> "bh-badge--cancelled";
            case "EXPIRED" -> "bh-badge--expired";
            case "REFUNDED" -> "bh-badge--refunded";
            default -> "bh-badge--default";
        };
    }

    public boolean isCancelledLike() {
        return "CANCELLED".equals(bookingStatus)
                || "EXPIRED".equals(bookingStatus)
                || "REFUNDED".equals(bookingStatus);
    }

    public String getBookingId() { return bookingId; }
    public void setBookingId(String bookingId) { this.bookingId = bookingId; }

    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String bookingCode) { this.bookingCode = bookingCode; }

    public String getBookingSource() { return bookingSource; }
    public void setBookingSource(String bookingSource) { this.bookingSource = bookingSource; }

    public String getBookingStatus() { return bookingStatus; }
    public void setBookingStatus(String bookingStatus) { this.bookingStatus = bookingStatus; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public Timestamp getBookedAt() { return bookedAt; }
    public void setBookedAt(Timestamp bookedAt) { this.bookedAt = bookedAt; }

    public Timestamp getExpiredAt() { return expiredAt; }
    public void setExpiredAt(Timestamp expiredAt) { this.expiredAt = expiredAt; }

    public Timestamp getStartTime() { return startTime; }
    public void setStartTime(Timestamp startTime) { this.startTime = startTime; }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public String getMoviePosterUrl() { return moviePosterUrl; }
    public void setMoviePosterUrl(String moviePosterUrl) { this.moviePosterUrl = moviePosterUrl; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public BigDecimal getFinalAmount() { return finalAmount; }
    public void setFinalAmount(BigDecimal finalAmount) { this.finalAmount = finalAmount; }

    public int getSeatCount() { return seatCount; }
    public void setSeatCount(int seatCount) { this.seatCount = seatCount; }

    public String getSeatCodesSummary() { return seatCodesSummary; }
    public void setSeatCodesSummary(String seatCodesSummary) { this.seatCodesSummary = seatCodesSummary; }
}
