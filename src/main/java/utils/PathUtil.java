package utils;

import jakarta.servlet.http.HttpServletRequest;

import java.util.Set;

public final class PathUtil {

    private static final Set<String> PUBLIC_EXACT_PATHS = Set.of(
            "/",
            "/index.jsp",
            "/login",
            "/register",
            "/register/success",
            "/verify-email",
            "/forgot-password",
            "/reset-password",
            "/logout"
    );

    private static final Set<String> PUBLIC_PREFIXES = Set.of(
            "/css/",
            "/js/",
            "/images/"
    );

    private static final Set<String> AUTHENTICATED_ANY_ROLE_PATHS = Set.of(
            "/change-password"
    );

    private PathUtil() {
    }

    public static boolean isPublicPath(String path) {
        if (path == null || path.isBlank()) {
            return true;
        }

        String normalized = normalizePath(path);

        if (PUBLIC_EXACT_PATHS.contains(normalized)) {
            return true;
        }

        for (String prefix : PUBLIC_PREFIXES) {
            if (normalized.startsWith(prefix)) {
                return true;
            }
        }

        return false;
    }

    public static boolean requiresAuthentication(String path) {
        if (path == null || path.isBlank()) {
            return false;
        }

        String normalized = normalizePath(path);

        if (isPublicPath(normalized)) {
            return false;
        }

        if (AUTHENTICATED_ANY_ROLE_PATHS.contains(normalized)) {
            return true;
        }

        return getRequiredRole(normalized) != null;
    }

    public static String getRequiredRole(String path) {
        if (path == null || path.isBlank()) {
            return null;
        }

        String normalized = normalizePath(path);

        if (normalized.startsWith("/customer/") || "/customer".equals(normalized)) {
            return AuthConstants.ROLE_CUSTOMER;
        }
        if (normalized.startsWith("/staff/") || "/staff".equals(normalized)) {
            return AuthConstants.ROLE_STAFF;
        }
        if (normalized.startsWith("/manager/") || "/manager".equals(normalized)) {
            return AuthConstants.ROLE_MANAGER;
        }
        if (normalized.startsWith("/admin/") || "/admin".equals(normalized)) {
            return AuthConstants.ROLE_ADMIN;
        }

        return null;
    }

    public static boolean isRoleAllowed(String path, String roleName) {
        String requiredRole = getRequiredRole(path);
        if (requiredRole == null) {
            return true;
        }
        return requiredRole.equals(roleName);
    }

    public static String extractRequestPath(HttpServletRequest request) {
        String uri = request.getRequestURI();
        String contextPath = request.getContextPath();

        String path = uri;
        if (contextPath != null && !contextPath.isEmpty() && uri.startsWith(contextPath)) {
            path = uri.substring(contextPath.length());
        }

        if (path.isEmpty()) {
            path = "/";
        }

        String query = request.getQueryString();
        if (query != null && !query.isBlank()) {
            path = path + "?" + query;
        }

        return path;
    }

    public static String buildLoginRedirectUrl(String contextPath, String returnPath) {
        String base = normalizeContextPath(contextPath);
        String loginPath = base + "/login";

        if (returnPath == null || returnPath.isBlank() || "/".equals(returnPath) || isPublicPath(returnPath)) {
            return loginPath;
        }

        return loginPath + "?redirect=" + urlEncode(returnPath);
    }

    public static String getHomeUrl(String roleName, String contextPath) {
        String base = normalizeContextPath(contextPath);

        if (roleName == null) {
            return base + "/";
        }

        return switch (roleName) {
            case AuthConstants.ROLE_STAFF -> base + "/staff/home";
            case AuthConstants.ROLE_MANAGER -> base + "/manager/home";
            case AuthConstants.ROLE_ADMIN -> base + "/admin/home";
            default -> base + "/";
        };
    }

    public static String resolveRedirect(String redirect, String contextPath, String roleName) {
        if (!isSafeRedirect(redirect, contextPath)) {
            return getHomeUrl(roleName, contextPath);
        }

        String base = normalizeContextPath(contextPath);
        if (!base.isEmpty() && redirect.startsWith(base)) {
            return redirect;
        }

        return base + redirect;
    }

    public static boolean isSafeRedirect(String redirect, String contextPath) {
        if (redirect == null || redirect.isBlank()) {
            return false;
        }

        String path = toPathOnly(redirect, contextPath);
        int queryIndex = path.indexOf('?');
        String pathOnly = queryIndex >= 0 ? path.substring(0, queryIndex) : path;

        if (!pathOnly.startsWith("/")) {
            return false;
        }

        if (isPublicPath(pathOnly)) {
            return false;
        }

        return !pathOnly.equals("/login")
                && !pathOnly.startsWith("/register")
                && !pathOnly.equals("/logout");
    }

    private static String toPathOnly(String redirect, String contextPath) {
        String base = normalizeContextPath(contextPath);

        if (!base.isEmpty() && redirect.startsWith(base)) {
            String remainder = redirect.substring(base.length());
            return remainder.isEmpty() ? "/" : remainder;
        }

        return redirect;
    }

    private static String normalizeContextPath(String contextPath) {
        if (contextPath == null || contextPath.isBlank()) {
            return "";
        }
        return contextPath.endsWith("/") ? contextPath.substring(0, contextPath.length() - 1) : contextPath;
    }

    private static String normalizePath(String path) {
        if (path == null || path.isBlank()) {
            return "/";
        }

        int queryIndex = path.indexOf('?');
        String pathOnly = queryIndex >= 0 ? path.substring(0, queryIndex) : path;

        if (pathOnly.isEmpty()) {
            pathOnly = "/";
        }

        if (pathOnly.length() > 1 && pathOnly.endsWith("/")) {
            pathOnly = pathOnly.substring(0, pathOnly.length() - 1);
        }

        if (queryIndex >= 0) {
            return pathOnly + path.substring(queryIndex);
        }

        return pathOnly;
    }

    private static String urlEncode(String value) {
        return java.net.URLEncoder.encode(value, java.nio.charset.StandardCharsets.UTF_8);
    }
}
