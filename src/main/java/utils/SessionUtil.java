package utils;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.dto.SessionUser;
import model.entity.User;

public final class SessionUtil {

    public static final String ATTR_LOGGED_USER = "loggedUser";
    public static final String ATTR_USER_ROLE   = "userRole";
    public static final String COOKIE_REMEMBER  = "epcine_remember_id";

    private SessionUtil() {}

    public static void setLoggedIn(HttpServletRequest request, User user) {
        HttpSession session = request.getSession(true);
        session.setAttribute(ATTR_LOGGED_USER, SessionUser.from(user));
        session.setAttribute(ATTR_USER_ROLE, user.getRoleName());
    }

    public static void logout(HttpServletRequest request, HttpServletResponse response) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.invalidate();
        }
        clearRememberCookie(response);
    }

    public static SessionUser getLoggedUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(ATTR_LOGGED_USER);
        return (value instanceof SessionUser) ? (SessionUser) value : null;
    }

    public static String getUserRole(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(ATTR_USER_ROLE);
        return (value instanceof String) ? (String) value : null;
    }

    public static void setRememberCookie(HttpServletResponse response, String identifier) {
        Cookie cookie = new Cookie(COOKIE_REMEMBER, identifier);
        cookie.setPath("/");
        cookie.setMaxAge(30 * 24 * 60 * 60);
        cookie.setHttpOnly(true);
        response.addCookie(cookie);
    }

    public static void clearRememberCookie(HttpServletResponse response) {
        Cookie cookie = new Cookie(COOKIE_REMEMBER, "");
        cookie.setPath("/");
        cookie.setMaxAge(0);
        cookie.setHttpOnly(true);
        response.addCookie(cookie);
    }

    public static String readRememberCookie(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        for (Cookie cookie : cookies) {
            if (COOKIE_REMEMBER.equals(cookie.getName())) {
                String value = cookie.getValue();
                return (value != null && !value.isBlank()) ? value : null;
            }
        }
        return null;
    }
}
