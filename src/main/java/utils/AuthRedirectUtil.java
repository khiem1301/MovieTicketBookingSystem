package utils;

import jakarta.servlet.http.HttpServletRequest;

public final class AuthRedirectUtil {

    public static final String STAFF_HOME = "/staff/counter";
    public static final String DEFAULT_HOME = "/home";

    private AuthRedirectUtil() {}

    public static String resolvePostLoginRedirect(HttpServletRequest req, String role) {
        String redirect = trim(req.getParameter("redirect"));
        return resolvePostLoginRedirect(req, role, redirect);
    }

    public static String resolvePostLoginRedirect(HttpServletRequest req, String role, String redirectParam) {
        if (isSafeRedirect(redirectParam) && isAllowedLandingForRole(role, redirectParam)) {
            return req.getContextPath() + redirectParam;
        }
        return defaultRedirectForRole(req, role);
    }

    public static String defaultRedirectForRole(HttpServletRequest req, String role) {
        if ("STAFF".equals(role)) {
            return req.getContextPath() + STAFF_HOME;
        }
        if ("ADMIN".equals(role)) {
            return req.getContextPath() + "/admin/dashboard";
        }
        // MANAGER → /home (xem giao diện khách); quản lý phim vào từ menu
        return req.getContextPath() + DEFAULT_HOME;
    }

    /**
     * Chặn redirect sang URL thuộc role khác (vd. ADMIN không được ?redirect=/manager/...).
     */
    public static boolean isAllowedLandingForRole(String role, String redirect) {
        if (redirect == null || redirect.isBlank()) {
            return false;
        }
        String path = redirect;
        int q = path.indexOf('?');
        if (q >= 0) {
            path = path.substring(0, q);
        }

        if ("STAFF".equals(role)) {
            if ("/".equals(path) || "/home".equals(path) || "/index.jsp".equals(path)) {
                return false;
            }
        }

        var required = AccessControl.requiredRoles(path);
        if (required.isEmpty()) {
            return true;
        }
        return role != null && required.get().contains(role);
    }

    public static boolean isSafeRedirect(String redirect) {
        return redirect != null
                && redirect.startsWith("/")
                && !redirect.startsWith("//")
                && !redirect.contains("://");
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
