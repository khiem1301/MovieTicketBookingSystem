package model.entity;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class ShowtimeIncident {
    private String id;
    private String showtimeId;
    private String description;
    private BigDecimal refundPointsRate;
    private String compensationDiscountType;
    private BigDecimal compensationDiscountValue;
    private int compensationValidDays;
    private Timestamp processedAt;
    private String createdBy;
    private Timestamp createdAt;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getShowtimeId() { return showtimeId; }
    public void setShowtimeId(String showtimeId) { this.showtimeId = showtimeId; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getRefundPointsRate() { return refundPointsRate; }
    public void setRefundPointsRate(BigDecimal refundPointsRate) { this.refundPointsRate = refundPointsRate; }

    public String getCompensationDiscountType() { return compensationDiscountType; }
    public void setCompensationDiscountType(String compensationDiscountType) {
        this.compensationDiscountType = compensationDiscountType;
    }

    public BigDecimal getCompensationDiscountValue() { return compensationDiscountValue; }
    public void setCompensationDiscountValue(BigDecimal compensationDiscountValue) {
        this.compensationDiscountValue = compensationDiscountValue;
    }

    public int getCompensationValidDays() { return compensationValidDays; }
    public void setCompensationValidDays(int compensationValidDays) {
        this.compensationValidDays = compensationValidDays;
    }

    public Timestamp getProcessedAt() { return processedAt; }
    public void setProcessedAt(Timestamp processedAt) { this.processedAt = processedAt; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
