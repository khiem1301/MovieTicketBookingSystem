package model.entity;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Promotion {
    private String id;
    private String code;
    private String title;
    private String description;
    private String discountType;       // PERCENTAGE | FIXED_AMOUNT
    private BigDecimal discountValue;
    private BigDecimal maxDiscountAmount;
    private BigDecimal minOrderAmount;
    private Timestamp startDate;
    private Timestamp endDate;
    private Integer usageLimit;
    private int usedCount;
    private String status;             // ACTIVE | INACTIVE | EXPIRED
    private Timestamp createdAt;

    public Promotion() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getCode() { return code; }
    public void setCode(String code) { this.code = code; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getDiscountType() { return discountType; }
    public void setDiscountType(String discountType) { this.discountType = discountType; }

    public BigDecimal getDiscountValue() { return discountValue; }
    public void setDiscountValue(BigDecimal discountValue) { this.discountValue = discountValue; }

    public BigDecimal getMaxDiscountAmount() { return maxDiscountAmount; }
    public void setMaxDiscountAmount(BigDecimal maxDiscountAmount) { this.maxDiscountAmount = maxDiscountAmount; }

    public BigDecimal getMinOrderAmount() { return minOrderAmount; }
    public void setMinOrderAmount(BigDecimal minOrderAmount) { this.minOrderAmount = minOrderAmount; }

    public Timestamp getStartDate() { return startDate; }
    public void setStartDate(Timestamp startDate) { this.startDate = startDate; }

    public Timestamp getEndDate() { return endDate; }
    public void setEndDate(Timestamp endDate) { this.endDate = endDate; }

    public Integer getUsageLimit() { return usageLimit; }
    public void setUsageLimit(Integer usageLimit) { this.usageLimit = usageLimit; }

    public int getUsedCount() { return usedCount; }
    public void setUsedCount(int usedCount) { this.usedCount = usedCount; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    /** true nếu đã quá ngày kết thúc */
    public boolean isExpired() {
        return endDate != null && endDate.before(new java.util.Date());
    }

    /** true nếu ACTIVE nhưng chưa đến start_date */
    public boolean isScheduled() {
        return "ACTIVE".equals(status)
            && startDate != null
            && startDate.getTime() > System.currentTimeMillis();
    }

    /** true nếu đang trong khoảng hiệu lực và trạng thái ACTIVE */
    public boolean isCurrentlyValid() {
        long now = System.currentTimeMillis();
        return "ACTIVE".equals(status)
            && startDate != null && startDate.getTime() <= now
            && endDate   != null && endDate.getTime()   >= now;
    }
}
