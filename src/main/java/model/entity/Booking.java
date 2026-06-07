package model.entity;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Booking {
    private String id;
    private String bookingCode;
    private String userId;
    private String showtimeId;
    private String bookingSource;        // 'ONLINE' | 'OFFLINE'
    private String createdByStaffId;
    private String customerName;
    private String customerPhone;
    private BigDecimal vatRateSnapshot;
    private BigDecimal totalAmount;
    private BigDecimal discountAmount;
    private BigDecimal finalAmount;
    private String bookingStatus;        // PENDING | CONFIRMED | CANCELLED | EXPIRED | REFUNDED
    private String paymentStatus;        // UNPAID | PAID | FAILED
    private Timestamp bookedAt;
    private Timestamp expiredAt;

    public Booking() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getBookingCode() { return bookingCode; }
    public void setBookingCode(String bookingCode) { this.bookingCode = bookingCode; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getShowtimeId() { return showtimeId; }
    public void setShowtimeId(String showtimeId) { this.showtimeId = showtimeId; }

    public String getBookingSource() { return bookingSource; }
    public void setBookingSource(String bookingSource) { this.bookingSource = bookingSource; }

    public String getCreatedByStaffId() { return createdByStaffId; }
    public void setCreatedByStaffId(String createdByStaffId) { this.createdByStaffId = createdByStaffId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getCustomerPhone() { return customerPhone; }
    public void setCustomerPhone(String customerPhone) { this.customerPhone = customerPhone; }

    public BigDecimal getVatRateSnapshot() { return vatRateSnapshot; }
    public void setVatRateSnapshot(BigDecimal vatRateSnapshot) { this.vatRateSnapshot = vatRateSnapshot; }

    public BigDecimal getTotalAmount() { return totalAmount; }
    public void setTotalAmount(BigDecimal totalAmount) { this.totalAmount = totalAmount; }

    public BigDecimal getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(BigDecimal discountAmount) { this.discountAmount = discountAmount; }

    public BigDecimal getFinalAmount() { return finalAmount; }
    public void setFinalAmount(BigDecimal finalAmount) { this.finalAmount = finalAmount; }

    public String getBookingStatus() { return bookingStatus; }
    public void setBookingStatus(String bookingStatus) { this.bookingStatus = bookingStatus; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public Timestamp getBookedAt() { return bookedAt; }
    public void setBookedAt(Timestamp bookedAt) { this.bookedAt = bookedAt; }

    public Timestamp getExpiredAt() { return expiredAt; }
    public void setExpiredAt(Timestamp expiredAt) { this.expiredAt = expiredAt; }
}
