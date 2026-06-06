package util;

/**
 * Hằng số dùng chung toàn dự án.
 * Import: import util.AppConstants;
 */
public final class AppConstants {

    private AppConstants() {}

    // ── Roles ──────────────────────────────────────────────────────────
    public static final String ROLE_CUSTOMER = "CUSTOMER";
    public static final String ROLE_STAFF    = "STAFF";
    public static final String ROLE_MANAGER  = "MANAGER";
    public static final String ROLE_ADMIN    = "ADMIN";

    // ── Session attribute keys ─────────────────────────────────────────
    /** Lưu object User sau khi đăng nhập thành công */
    public static final String SESSION_USER = "currentUser";
    /** Lưu role string (CUSTOMER / STAFF / …) */
    public static final String SESSION_ROLE = "currentRole";

    // ── Request attribute keys ─────────────────────────────────────────
    public static final String ATTR_ERROR   = "errorMessage";
    public static final String ATTR_SUCCESS = "successMessage";

    // ── View paths (đặt trong WEB-INF/views để không truy cập trực tiếp)
    public static final String VIEW_HOME      = "/WEB-INF/views/home.jsp";
    public static final String VIEW_LOGIN     = "/WEB-INF/views/auth/login.jsp";
    public static final String VIEW_REGISTER  = "/WEB-INF/views/auth/register.jsp";
    public static final String VIEW_403       = "/WEB-INF/views/error/403.jsp";
    public static final String VIEW_404       = "/WEB-INF/views/error/404.jsp";
    public static final String VIEW_500       = "/WEB-INF/views/error/500.jsp";

    // ── Booking & payment status ───────────────────────────────────────
    public static final String STATUS_PENDING   = "PENDING";
    public static final String STATUS_CONFIRMED = "CONFIRMED";
    public static final String STATUS_CANCELLED = "CANCELLED";
    public static final String STATUS_COMPLETED = "COMPLETED";

    // ── User account status ────────────────────────────────────────────
    public static final String USER_ACTIVE = "ACTIVE";
    public static final String USER_LOCKED = "LOCKED";

    // ── Pagination ────────────────────────────────────────────────────
    public static final int DEFAULT_PAGE_SIZE = 10;
}
