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
    public static final int PROFILE_SECURITY_VERIFY_MINUTES = 15;

    public static final String TOKEN_PURPOSE_REGISTER = "REGISTER_VERIFY";
    public static final String TOKEN_PURPOSE_PASSWORD_RESET = "PASSWORD_RESET";
    public static final String TOKEN_PURPOSE_PROFILE_SECURITY = "PROFILE_SECURITY";

    public static final String SMTP_NOT_CONFIGURED_MSG =
            "Chưa cấu hình gửi email (SMTP). Vui lòng liên hệ quản trị viên hệ thống.";

    private AuthConstants() {
    }
}

