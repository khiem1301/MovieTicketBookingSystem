package model.entity;

import java.sql.Timestamp;

public class SystemConfigLog {
    private String id;
    private String earnRate;
    private String redeemRate;
    private String minRedeem;
    private String maxRedeemPerOrder;
    private String previousEarnRate;
    private String previousRedeemRate;
    private String previousMinRedeem;
    private String previousMaxRedeemPerOrder;
    private String updatedBy;
    private String updatedByName;
    private Timestamp updatedAt;

    public SystemConfigLog() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getEarnRate() { return earnRate; }
    public void setEarnRate(String earnRate) { this.earnRate = earnRate; }

    public String getRedeemRate() { return redeemRate; }
    public void setRedeemRate(String redeemRate) { this.redeemRate = redeemRate; }

    public String getMinRedeem() { return minRedeem; }
    public void setMinRedeem(String minRedeem) { this.minRedeem = minRedeem; }

    public String getMaxRedeemPerOrder() { return maxRedeemPerOrder; }
    public void setMaxRedeemPerOrder(String maxRedeemPerOrder) { this.maxRedeemPerOrder = maxRedeemPerOrder; }

    public String getPreviousEarnRate() { return previousEarnRate; }
    public void setPreviousEarnRate(String previousEarnRate) { this.previousEarnRate = previousEarnRate; }

    public String getPreviousRedeemRate() { return previousRedeemRate; }
    public void setPreviousRedeemRate(String previousRedeemRate) { this.previousRedeemRate = previousRedeemRate; }

    public String getPreviousMinRedeem() { return previousMinRedeem; }
    public void setPreviousMinRedeem(String previousMinRedeem) { this.previousMinRedeem = previousMinRedeem; }

    public String getPreviousMaxRedeemPerOrder() { return previousMaxRedeemPerOrder; }
    public void setPreviousMaxRedeemPerOrder(String previousMaxRedeemPerOrder) {
        this.previousMaxRedeemPerOrder = previousMaxRedeemPerOrder;
    }

    public String getUpdatedBy() { return updatedBy; }
    public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }

    public String getUpdatedByName() { return updatedByName; }
    public void setUpdatedByName(String updatedByName) { this.updatedByName = updatedByName; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
}
