package model.dto;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;

public class BookingDetailDTO {
    private String bookingId;
    private String bookingCode;
    private String userId;
    private String showtimeId;
    private String bookingSource;
    private Timestamp expiredAt;
    private String customerName;
    private String customerPhone;
    private String bookingStatus;
    private String paymentStatus;
    private BigDecimal totalAmount;
    private BigDecimal discountAmount;
    private BigDecimal vatAmount;
    private BigDecimal finalAmount;
    private BigDecimal vatRate;
    private String movieTitle;
    private String moviePosterUrl;
    private String roomName;
    private Timestamp startTime;
    private List<SeatItem> seats;
    private String appliedPromoCode;
    private String appliedPromoTitle;

    public static class SeatItem {
        private final String seatCode;
        private final String seatType;
        private final BigDecimal price;

        public SeatItem(String seatCode, String seatType, BigDecimal price) {
            this.seatCode = seatCode;
            this.seatType = seatType;
            this.price = price;
        }

        public String getSeatCode()  { return seatCode; }
        public String getSeatType()  { return seatType; }
        public BigDecimal getPrice() { return price; }
    }

    public String getBookingId()     { return bookingId; }
    public void setBookingId(String v)   { this.bookingId = v; }

    public String getBookingCode()   { return bookingCode; }
    public void setBookingCode(String v) { this.bookingCode = v; }

    public String getUserId()        { return userId; }
    public void setUserId(String v)  { this.userId = v; }

    public String getShowtimeId()    { return showtimeId; }
    public void setShowtimeId(String v) { this.showtimeId = v; }

    public String getBookingSource() { return bookingSource; }
    public void setBookingSource(String v) { this.bookingSource = v; }

    public Timestamp getExpiredAt()  { return expiredAt; }
    public void setExpiredAt(Timestamp v) { this.expiredAt = v; }

    public String getCustomerName()  { return customerName; }
    public void setCustomerName(String v){ this.customerName = v; }

    public String getCustomerPhone() { return customerPhone; }
    public void setCustomerPhone(String v){ this.customerPhone = v; }

    public String getBookingStatus() { return bookingStatus; }
    public void setBookingStatus(String v){ this.bookingStatus = v; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String v){ this.paymentStatus = v; }

    public BigDecimal getTotalAmount()  { return totalAmount; }
    public void setTotalAmount(BigDecimal v){ this.totalAmount = v; }

    public BigDecimal getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(BigDecimal v) { this.discountAmount = v; }

    public BigDecimal getVatAmount() { return vatAmount; }
    public void setVatAmount(BigDecimal v) { this.vatAmount = v; }

    public BigDecimal getFinalAmount()  { return finalAmount; }
    public void setFinalAmount(BigDecimal v){ this.finalAmount = v; }

    public BigDecimal getVatRate()   { return vatRate; }
    public void setVatRate(BigDecimal v){ this.vatRate = v; }

    public String getMovieTitle()    { return movieTitle; }
    public void setMovieTitle(String v)  { this.movieTitle = v; }

    public String getMoviePosterUrl(){ return moviePosterUrl; }
    public void setMoviePosterUrl(String v){ this.moviePosterUrl = v; }

    public String getRoomName()      { return roomName; }
    public void setRoomName(String v){ this.roomName = v; }

    public Timestamp getStartTime()  { return startTime; }
    public void setStartTime(Timestamp v){ this.startTime = v; }

    public List<SeatItem> getSeats() { return seats; }
    public void setSeats(List<SeatItem> v){ this.seats = v; }

    public String getAppliedPromoCode() { return appliedPromoCode; }
    public void setAppliedPromoCode(String v) { this.appliedPromoCode = v; }

    public String getAppliedPromoTitle() { return appliedPromoTitle; }
    public void setAppliedPromoTitle(String v) { this.appliedPromoTitle = v; }

    public boolean hasAppliedPromo() {
        return appliedPromoCode != null && !appliedPromoCode.isBlank();
    }
}
