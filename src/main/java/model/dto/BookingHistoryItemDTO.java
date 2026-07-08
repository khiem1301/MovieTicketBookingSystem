package model.dto;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * FR-15 — Một dòng trong danh sách lịch sử đặt vé (customer).
 */
public class BookingHistoryItemDTO {

    private String bookingId;
    private String bookingCode;
    private Timestamp bookedAt;
    private String movieTitle;
    private String moviePosterUrl;
    private Timestamp startTime;
    private String roomName;
    private String bookingSource;
    private String bookingStatus;
    private String paymentStatus;
    private BigDecimal finalAmount;
    private int seatCount;
    private String seatCodesSummary;
    private Timestamp expiredAt;

    public String getBookingId() { return bookingId; }
    public void setBookingId(String bookingId) { this.bookingId = bookingId; }

    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String bookingCode) { this.bookingCode = bookingCode; }

    public Timestamp getBookedAt() { return bookedAt; }
    public void setBookedAt(Timestamp bookedAt) { this.bookedAt = bookedAt; }

    public String getMovieTitle() { return movieTitle; }
    public void setMovieTitle(String movieTitle) { this.movieTitle = movieTitle; }

    public String getMoviePosterUrl() { return moviePosterUrl; }
    public void setMoviePosterUrl(String moviePosterUrl) { this.moviePosterUrl = moviePosterUrl; }

    public Timestamp getStartTime() { return startTime; }
    public void setStartTime(Timestamp startTime) { this.startTime = startTime; }

    public String getRoomName() { return roomName; }
    public void setRoomName(String roomName) { this.roomName = roomName; }

    public String getBookingSource() { return bookingSource; }
    public void setBookingSource(String bookingSource) { this.bookingSource = bookingSource; }

    public String getBookingStatus() { return bookingStatus; }
    public void setBookingStatus(String bookingStatus) { this.bookingStatus = bookingStatus; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public BigDecimal getFinalAmount() { return finalAmount; }
    public void setFinalAmount(BigDecimal finalAmount) { this.finalAmount = finalAmount; }

    public int getSeatCount() { return seatCount; }
    public void setSeatCount(int seatCount) { this.seatCount = seatCount; }

    public String getSeatCodesSummary() { return seatCodesSummary; }
    public void setSeatCodesSummary(String seatCodesSummary) { this.seatCodesSummary = seatCodesSummary; }

    public Timestamp getExpiredAt() { return expiredAt; }
    public void setExpiredAt(Timestamp expiredAt) { this.expiredAt = expiredAt; }

    public boolean isOnline() {
        return "ONLINE".equalsIgnoreCase(bookingSource);
    }

    public boolean isPendingPayment() {
        return "PENDING".equalsIgnoreCase(bookingStatus);
    }

    public boolean isConfirmedPaid() {
        return "CONFIRMED".equalsIgnoreCase(bookingStatus)
                && "PAID".equalsIgnoreCase(paymentStatus);
    }

    public boolean isExpiredPending() {
        if (!isPendingPayment() || expiredAt == null) {
            return false;
        }
        return expiredAt.before(new Timestamp(System.currentTimeMillis()));
    }
}
