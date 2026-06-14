package model.entity;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;

public class PricingRule {
    private String id;
    private String ruleName;
    private String conditionType;
    private String dayOfWeek;
    private Time timeFrom;
    private Time timeTo;
    private Date dateFrom;
    private Date dateTo;
    private String adjustmentType;
    private BigDecimal adjustmentValue;
    private int priority;
    private String status;
    private Timestamp createdAt;

    public PricingRule() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getRuleName() { return ruleName; }
    public void setRuleName(String ruleName) { this.ruleName = ruleName; }

    public String getConditionType() { return conditionType; }
    public void setConditionType(String conditionType) { this.conditionType = conditionType; }

    public String getDayOfWeek() { return dayOfWeek; }
    public void setDayOfWeek(String dayOfWeek) { this.dayOfWeek = dayOfWeek; }

    public Time getTimeFrom() { return timeFrom; }
    public void setTimeFrom(Time timeFrom) { this.timeFrom = timeFrom; }

    public Time getTimeTo() { return timeTo; }
    public void setTimeTo(Time timeTo) { this.timeTo = timeTo; }

    public Date getDateFrom() { return dateFrom; }
    public void setDateFrom(Date dateFrom) { this.dateFrom = dateFrom; }

    public Date getDateTo() { return dateTo; }
    public void setDateTo(Date dateTo) { this.dateTo = dateTo; }

    public String getAdjustmentType() { return adjustmentType; }
    public void setAdjustmentType(String adjustmentType) { this.adjustmentType = adjustmentType; }

    public BigDecimal getAdjustmentValue() { return adjustmentValue; }
    public void setAdjustmentValue(BigDecimal adjustmentValue) { this.adjustmentValue = adjustmentValue; }

    public int getPriority() { return priority; }
    public void setPriority(int priority) { this.priority = priority; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
