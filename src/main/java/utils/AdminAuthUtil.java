package utils;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

public final class AdminAuthUtil {

    public static final String FLASH_SUCCESS = "flashSuccess";
    public static final String FLASH_ERROR   = "flashError";

    private AdminAuthUtil() {}

    public static boolean requireAdminOrManager(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String role = SessionUtil.getUserRole(req);
        if ("ADMIN".equals(role) || "MANAGER".equals(role)) {
            return true;
        }
        if (SessionUtil.getLoggedUser(req) == null) {
            String redirect = req.getRequestURI();
            String query = req.getQueryString();
            if (query != null && !query.isBlank()) redirect += "?" + query;
            resp.sendRedirect(req.getContextPath() + "/login?redirect="
                    + java.net.URLEncoder.encode(redirect, java.nio.charset.StandardCharsets.UTF_8));
        } else {
            setFlash(req, FLASH_ERROR, "Bạn không có quyền truy cập trang này.");
            resp.sendRedirect(req.getContextPath() + "/home");
        }
        return false;
    }

    public static boolean requireAdmin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if ("ADMIN".equals(SessionUtil.getUserRole(req))) {
            return true;
        }

        if (SessionUtil.getLoggedUser(req) == null) {
            String redirect = req.getRequestURI();
            String query = req.getQueryString();
            if (query != null && !query.isBlank()) {
                redirect += "?" + query;
            }
            String encoded = URLEncoder.encode(redirect, StandardCharsets.UTF_8);
            resp.sendRedirect(req.getContextPath() + "/login?redirect=" + encoded);
        } else {
            setFlash(req, FLASH_ERROR, "Bạn không có quyền truy cập trang quản trị.");
            resp.sendRedirect(req.getContextPath() + "/home");
        }
        return false;
    }

    public static void setFlash(HttpServletRequest req, String key, String message) {
        HttpSession session = req.getSession();
        session.setAttribute(key, message);
    }

    public static String consumeFlash(HttpServletRequest req, String key) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(key);
        session.removeAttribute(key);
        return (value instanceof String) ? (String) value : null;
    }
}
