package model.entity;

import java.math.BigDecimal;

public class Seat {
    private String id;
    private String roomId;
    private String seatTypeId;
    private String seatTypeName;
    private BigDecimal priceMultiplier;
    private String seatRow;
    private int seatColumn;
    private String seatCode;
    private String status;
    /** Computed field: basePrice × priceMultiplier, gán bởi SeatDAO. */
    private BigDecimal ticketPrice;
    /** Computed field: true nếu ghế chưa bị đặt cho suất này. */
    private boolean available;

    public Seat() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getRoomId() { return roomId; }
    public void setRoomId(String roomId) { this.roomId = roomId; }

    public String getSeatTypeId() { return seatTypeId; }
    public void setSeatTypeId(String seatTypeId) { this.seatTypeId = seatTypeId; }

    public String getSeatTypeName() { return seatTypeName; }
    public void setSeatTypeName(String seatTypeName) { this.seatTypeName = seatTypeName; }

    public BigDecimal getPriceMultiplier() { return priceMultiplier; }
    public void setPriceMultiplier(BigDecimal priceMultiplier) { this.priceMultiplier = priceMultiplier; }

    public String getSeatRow() { return seatRow; }
    public void setSeatRow(String seatRow) { this.seatRow = seatRow; }

    public int getSeatColumn() { return seatColumn; }
    public void setSeatColumn(int seatColumn) { this.seatColumn = seatColumn; }

    public String getSeatCode() { return seatCode; }
    public void setSeatCode(String seatCode) { this.seatCode = seatCode; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public BigDecimal getTicketPrice() { return ticketPrice; }
    public void setTicketPrice(BigDecimal ticketPrice) { this.ticketPrice = ticketPrice; }

    public boolean isAvailable() { return available; }
    public void setAvailable(boolean available) { this.available = available; }
}
