package utils;

import jakarta.servlet.http.HttpServletRequest;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Central URL access rules for AuthFilter and RoleFilter.
 * Teammates: put new screens under the correct prefix (/staff, /manager, /admin, customer paths).
 */
public final class AccessControl {

    private static final Set<String> PUBLIC_EXACT = Set.of(
            "/",
            "/home",
            "/login",
            "/register",
            "/register/pending",
            "/verify-email",
            "/register/google-complete",
            "/auth/google",
            "/auth/google/callback",
            "/logout",
            "/session-expired",
            "/index.jsp"
    );

    private static final List<String> PUBLIC_PREFIXES = List.of(
            "/movies",
            "/showtimes"
    );

    private static final List<String> CUSTOMER_PREFIXES = List.of(
            "/booking-history",
            "/loyalty",
            "/reviews/mine",
            "/checkout"
    );

    private static final Map<String, Set<String>> ROLE_PREFIXES = Map.of(
            "/admin/", Set.of("ADMIN"),
            "/manager/", Set.of("MANAGER"),
            "/staff/", Set.of("STAFF")
    );

    // Paths dưới prefix /admin/ mà MANAGER cũng được phép truy cập
    private static final Set<String> ADMIN_MANAGER_PATHS = Set.of(
            "/admin/promotions",
            "/admin/promotions/save",
            "/admin/promotions/delete",
            "/admin/promotions/toggle"
    );

    private static final Set<String> AUTH_ANY_EXACT = Set.of("/profile");

    private AccessControl() {}

    public static String normalizePath(HttpServletRequest request) {
        return normalizePath(request.getContextPath(), request.getRequestURI());
    }

    public static String normalizePath(String contextPath, String requestUri) {
        String path = requestUri.substring(contextPath.length());
        if (path.isEmpty()) {
            return "/";
        }
        int query = path.indexOf(';');
        if (query > 0) {
            path = path.substring(0, query);
        }
        return path;
    }

    public static boolean isStaticAsset(String path) {
        return path.startsWith("/css/")
                || path.startsWith("/js/")
                || path.startsWith("/images/")
                || path.startsWith("/favicon")
                || path.endsWith(".css")
                || path.endsWith(".js")
                || path.endsWith(".png")
                || path.endsWith(".jpg")
                || path.endsWith(".jpeg")
                || path.endsWith(".gif")
                || path.endsWith(".webp")
                || path.endsWith(".ico")
                || path.endsWith(".svg");
    }

    public static boolean isPublic(String path) {
        if (PUBLIC_EXACT.contains(path)) {
            return true;
        }
        for (String prefix : PUBLIC_PREFIXES) {
            if (matchesPrefix(path, prefix)) {
                return true;
            }
        }
        if (path.startsWith("/reviews") && !path.startsWith("/reviews/mine")) {
            return true;
        }
        return false;
    }

    public static boolean requiresAuthentication(String path) {
        if (isStaticAsset(path) || isPublic(path) || path.startsWith("/WEB-INF")) {
            return false;
        }
        return true;
    }

    /**
     * @return empty = any authenticated role; non-empty = role must be in the set
     */
    public static Optional<Set<String>> requiredRoles(String path) {
        // Kiểm tra exception paths trước (ưu tiên cao hơn prefix rules)
        if (ADMIN_MANAGER_PATHS.contains(path)) {
            return Optional.of(Set.of("ADMIN", "MANAGER"));
        }
        for (Map.Entry<String, Set<String>> entry : ROLE_PREFIXES.entrySet()) {
            String prefix = entry.getKey();
            String base = prefix.substring(0, prefix.length() - 1);
            if (path.startsWith(prefix) || path.equals(base)) {
                return Optional.of(entry.getValue());
            }
        }
        for (String prefix : CUSTOMER_PREFIXES) {
            if (matchesPrefix(path, prefix)) {
                return Optional.of(Set.of("CUSTOMER"));
            }
        }
        if (AUTH_ANY_EXACT.contains(path) || path.startsWith("/profile/")) {
            return Optional.empty();
        }
        return Optional.empty();
    }

    private static boolean matchesPrefix(String path, String prefix) {
        return path.equals(prefix) || path.startsWith(prefix + "/");
    }
}
