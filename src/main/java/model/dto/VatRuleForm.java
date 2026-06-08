package model.dto;

import java.sql.Date;

public class VatRuleForm {
    private String ruleId;
    private String ruleName;
    private String vatRate;
    private Date startDate;

    public VatRuleForm() {}

    public String getRuleId() { return ruleId; }
    public void setRuleId(String ruleId) { this.ruleId = ruleId; }

    public String getRuleName() { return ruleName; }
    public void setRuleName(String ruleName) { this.ruleName = ruleName; }

    public String getVatRate() { return vatRate; }
    public void setVatRate(String vatRate) { this.vatRate = vatRate; }

    public Date getStartDate() { return startDate; }
    public void setStartDate(Date startDate) { this.startDate = startDate; }
}
