package model.entity;

import java.math.BigDecimal;

public class SeatType {
    private String id;
    private String typeName;
    private BigDecimal priceMultiplier;
    private String description;
    private int seatSpan = 1;

    public SeatType() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTypeName() { return typeName; }
    public void setTypeName(String typeName) { this.typeName = typeName; }

    public BigDecimal getPriceMultiplier() { return priceMultiplier; }
    public void setPriceMultiplier(BigDecimal priceMultiplier) { this.priceMultiplier = priceMultiplier; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    /** Số ô chiếm trên layout: 1 = ghế đơn, 2 = ghế đôi (2 ô liền nhau). */
    public int getSeatSpan() { return seatSpan; }
    public void setSeatSpan(int seatSpan) { this.seatSpan = seatSpan; }
}
