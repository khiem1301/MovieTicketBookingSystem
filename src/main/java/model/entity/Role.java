package model.entity;

import java.sql.Timestamp;

public class Role {
    private String id;
    private String roleName;
    private String description;
    private Timestamp createdAt;

    public Role() {}

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getRoleName() { return roleName; }
    public void setRoleName(String roleName) { this.roleName = roleName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
