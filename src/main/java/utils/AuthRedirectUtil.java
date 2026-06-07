package utils;

import jakarta.servlet.http.HttpServletRequest;

public final class AuthRedirectUtil {

    private AuthRedirectUtil() {}

    public static String resolvePostLoginRedirect(HttpServletRequest req, String role) {
        String redirect = trim(req.getParameter("redirect"));
        if (isSafeRedirect(redirect)) {
            return req.getContextPath() + redirect;
        }
        return defaultRedirectForRole(req, role);
    }

    public static String resolvePostLoginRedirect(HttpServletRequest req, String role, String redirectParam) {
        if (isSafeRedirect(redirectParam)) {
            return req.getContextPath() + redirectParam;
        }
        return defaultRedirectForRole(req, role);
    }

    public static String defaultRedirectForRole(HttpServletRequest req, String role) {
        String ctx = req.getContextPath();
        return switch (role) {
            case "STAFF"   -> ctx + "/staff/counter";
            case "MANAGER" -> ctx + "/manager/dashboard";
            default        -> ctx + "/home";
        };
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
