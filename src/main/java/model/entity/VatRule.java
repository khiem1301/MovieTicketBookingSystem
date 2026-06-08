package model.entity;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class VatRule {
    private String id;
    private String ruleName;
    private BigDecimal vatRate;
    private Timestamp startDate;
    private Timestamp endDate;
    private String status;
    private Timestamp createdAt;

    public VatRule() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getRuleName() { return ruleName; }
    public void setRuleName(String ruleName) { this.ruleName = ruleName; }

    public BigDecimal getVatRate() { return vatRate; }
    public void setVatRate(BigDecimal vatRate) { this.vatRate = vatRate; }

    public Timestamp getStartDate() { return startDate; }
    public void setStartDate(Timestamp startDate) { this.startDate = startDate; }

    public Timestamp getEndDate() { return endDate; }
    public void setEndDate(Timestamp endDate) { this.endDate = endDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
