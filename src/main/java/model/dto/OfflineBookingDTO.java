package model.dto;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * Sprint 3 — Lịch sử đặt vé tại quầy (OFFLINE).
 * Dùng cho trang /staff/history.
 */
public class OfflineBookingDTO {

    private String bookingId;
    private String bookingCode;
    private String customerName;
    private String customerPhone;
    private String movieTitle;
    private String roomName;
    private Timestamp startTime;
    private Timestamp bookedAt;
    private int seatCount;
    private BigDecimal totalAmount;
    private BigDecimal finalAmount;
    private String bookingStatus;
    private String paymentStatus;
    private String staffName;
    private String userId;

    public String getBookingId()     { return bookingId; }
    public String getBookingCode()   { return bookingCode; }
    public String getCustomerName()  { return customerName; }
    public String getCustomerPhone() { return customerPhone; }
    public String getMovieTitle()    { return movieTitle; }
    public String getRoomName()      { return roomName; }
    public Timestamp getStartTime()  { return startTime; }
    public Timestamp getBookedAt()   { return bookedAt; }
    public int getSeatCount()        { return seatCount; }
    public BigDecimal getTotalAmount()  { return totalAmount; }
    public BigDecimal getFinalAmount()  { return finalAmount; }
    public String getBookingStatus() { return bookingStatus; }
    public String getPaymentStatus() { return paymentStatus; }
    public String getStaffName()     { return staffName; }
    public String getUserId()        { return userId; }

    public void setBookingId(String bookingId)       { this.bookingId = bookingId; }
    public void setBookingCode(String bookingCode)   { this.bookingCode = bookingCode; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    public void setCustomerPhone(String customerPhone) { this.customerPhone = customerPhone; }
    public void setMovieTitle(String movieTitle)     { this.movieTitle = movieTitle; }
    public void setRoomName(String roomName)         { this.roomName = roomName; }
    public void setStartTime(Timestamp startTime)    { this.startTime = startTime; }
    public void setBookedAt(Timestamp bookedAt)      { this.bookedAt = bookedAt; }
    public void setSeatCount(int seatCount)          { this.seatCount = seatCount; }
    public void setTotalAmount(BigDecimal totalAmount)  { this.totalAmount = totalAmount; }
    public void setFinalAmount(BigDecimal finalAmount)  { this.finalAmount = finalAmount; }
    public void setBookingStatus(String bookingStatus) { this.bookingStatus = bookingStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }
    public void setStaffName(String staffName)       { this.staffName = staffName; }
    public void setUserId(String userId)             { this.userId = userId; }
}
