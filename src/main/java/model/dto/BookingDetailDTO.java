package model.dto;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.List;

public class BookingDetailDTO {
    private String bookingId;
    private String bookingCode;
    private String customerName;
    private String customerPhone;
    private String bookingStatus;
    private String paymentStatus;
    private BigDecimal totalAmount;
    private BigDecimal finalAmount;
    private BigDecimal vatRate;
    private String movieTitle;
    private String moviePosterUrl;
    private String roomName;
    private Timestamp startTime;
    private List<SeatItem> seats;
    private List<TicketItem> tickets;
    private String linkedUserId;
    private String linkedUserEmail;

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

    /** FR-18 — Thông tin vé điện tử sau khi xác nhận thanh toán. */
    public static class TicketItem {
        private final String ticketCode;
        private final String qrCode;
        private final String seatCode;

        public TicketItem(String ticketCode, String qrCode, String seatCode) {
            this.ticketCode = ticketCode;
            this.qrCode = qrCode;
            this.seatCode = seatCode;
        }

        public String getTicketCode() { return ticketCode; }
        public String getQrCode()     { return qrCode; }
        public String getSeatCode()   { return seatCode; }
    }

    public String getBookingId()     { return bookingId; }
    public void setBookingId(String v)   { this.bookingId = v; }

    public String getBookingCode()   { return bookingCode; }
    public void setBookingCode(String v) { this.bookingCode = v; }

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

    public List<TicketItem> getTickets() { return tickets; }
    public void setTickets(List<TicketItem> v){ this.tickets = v; }

    public String getLinkedUserId() { return linkedUserId; }
    public void setLinkedUserId(String v){ this.linkedUserId = v; }

    public String getLinkedUserEmail() { return linkedUserEmail; }
    public void setLinkedUserEmail(String v){ this.linkedUserEmail = v; }
}
