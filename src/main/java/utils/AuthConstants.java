package utils;

public final class AuthConstants {

    public static final String SESSION_USER = "authUser";
    public static final String SESSION_ROLE = "authRole";

    public static final String ROLE_CUSTOMER = "CUSTOMER";
    public static final String ROLE_STAFF = "STAFF";
    public static final String ROLE_MANAGER = "MANAGER";
    public static final String ROLE_ADMIN = "ADMIN";

    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_INACTIVE = "INACTIVE";
    public static final String STATUS_BANNED = "BANNED";

    public static final int EMAIL_VERIFY_EXPIRY_HOURS = 24;
    public static final int PASSWORD_RESET_EXPIRY_MINUTES = 30;

    private AuthConstants() {
    }
}

