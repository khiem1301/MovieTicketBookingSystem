package utils;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import model.dto.SessionUser;
import model.entity.User;

public final class SessionUtil {

    public static final String ATTR_LOGGED_USER = "loggedUser";
    public static final String ATTR_USER_ROLE   = "userRole";

    private SessionUtil() {}

    public static void setLoggedIn(HttpServletRequest request, User user) {
        HttpSession session = request.getSession(true);
        session.setAttribute(ATTR_LOGGED_USER, SessionUser.from(user));
        session.setAttribute(ATTR_USER_ROLE, user.getRoleName());
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
}
