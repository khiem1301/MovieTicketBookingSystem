package model.dto;

import model.entity.User;

public class SessionUser {
    private String id;
    private String fullName;
    private String email;
    private String avatarUrl;
    private int loyaltyPoints;

    public SessionUser() {}

    public static SessionUser from(User user) {
        SessionUser sessionUser = new SessionUser();
        sessionUser.setId(user.getId());
        sessionUser.setFullName(user.getFullName());
        sessionUser.setEmail(user.getEmail());
        sessionUser.setAvatarUrl(user.getAvatarUrl());
        sessionUser.setLoyaltyPoints(user.getLoyaltyPoints());
        return sessionUser;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public int getLoyaltyPoints() { return loyaltyPoints; }
    public void setLoyaltyPoints(int loyaltyPoints) { this.loyaltyPoints = loyaltyPoints; }
}
