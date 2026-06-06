package model;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Entity tương ứng bảng [users] trong DB.
 * Mẫu để team tạo các entity khác (Movie, Booking, Seat, …).
 */
public class User {

    private int           userId;
    private String        email;
    private String        phoneNumber;
    private String        passwordHash;
    private String        fullName;
    private String        role;          // CUSTOMER / STAFF / MANAGER / ADMIN
    private String        status;        // ACTIVE / LOCKED
    private int           loyaltyPoints;
    private String        avatarUrl;
    private LocalDate     dateOfBirth;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public User() {}

    // ── Getters & Setters ──────────────────────────────────────────────

    public int getUserId()                      { return userId; }
    public void setUserId(int userId)           { this.userId = userId; }

    public String getEmail()                    { return email; }
    public void setEmail(String email)          { this.email = email; }

    public String getPhoneNumber()              { return phoneNumber; }
    public void setPhoneNumber(String v)        { this.phoneNumber = v; }

    public String getPasswordHash()             { return passwordHash; }
    public void setPasswordHash(String v)       { this.passwordHash = v; }

    public String getFullName()                 { return fullName; }
    public void setFullName(String fullName)    { this.fullName = fullName; }

    public String getRole()                     { return role; }
    public void setRole(String role)            { this.role = role; }

    public String getStatus()                   { return status; }
    public void setStatus(String status)        { this.status = status; }

    public int getLoyaltyPoints()               { return loyaltyPoints; }
    public void setLoyaltyPoints(int v)         { this.loyaltyPoints = v; }

    public String getAvatarUrl()                { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl)  { this.avatarUrl = avatarUrl; }

    public LocalDate getDateOfBirth()           { return dateOfBirth; }
    public void setDateOfBirth(LocalDate v)     { this.dateOfBirth = v; }

    public LocalDateTime getCreatedAt()         { return createdAt; }
    public void setCreatedAt(LocalDateTime v)   { this.createdAt = v; }

    public LocalDateTime getUpdatedAt()         { return updatedAt; }
    public void setUpdatedAt(LocalDateTime v)   { this.updatedAt = v; }

    // ── Helper ────────────────────────────────────────────────────────

    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(status);
    }

    @Override
    public String toString() {
        return "User{id=" + userId + ", email='" + email + "', role='" + role + "'}";
    }
}
