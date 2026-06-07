package model.entity;

import java.math.BigDecimal;

public class SeatType {
    private String id;
    private String typeName;
    private BigDecimal priceMultiplier;
    private String description;

    public SeatType() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTypeName() { return typeName; }
    public void setTypeName(String typeName) { this.typeName = typeName; }

    public BigDecimal getPriceMultiplier() { return priceMultiplier; }
    public void setPriceMultiplier(BigDecimal priceMultiplier) { this.priceMultiplier = priceMultiplier; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
