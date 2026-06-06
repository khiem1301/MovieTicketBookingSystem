package utils;

import jakarta.servlet.http.HttpSession;
import model.entity.User;

public final class SessionUtil {

    private static final int REMEMBER_ME_SECONDS = 7 * 24 * 60 * 60;
    private static final int DEFAULT_SESSION_SECONDS = 30 * 60;

    private SessionUtil() {
    }

    public static void login(HttpSession session, User user, boolean rememberMe) {
        User sessionUser = copyForSession(user);
        session.setAttribute(AuthConstants.SESSION_USER, sessionUser);
        session.setAttribute(AuthConstants.SESSION_ROLE, user.getRoleName());
        session.setMaxInactiveInterval(rememberMe ? REMEMBER_ME_SECONDS : DEFAULT_SESSION_SECONDS);
    }

    public static User getAuthUser(HttpSession session) {
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(AuthConstants.SESSION_USER);
        return value instanceof User ? (User) value : null;
    }

    public static String getAuthRole(HttpSession session) {
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(AuthConstants.SESSION_ROLE);
        return value instanceof String ? (String) value : null;
    }

    public static boolean isLoggedIn(HttpSession session) {
        return getAuthUser(session) != null;
    }

    public static void logout(HttpSession session) {
        if (session != null) {
            session.invalidate();
        }
    }

    private static User copyForSession(User source) {
        User user = new User();
        user.setId(source.getId());
        user.setRoleId(source.getRoleId());
        user.setRoleName(source.getRoleName());
        user.setEmail(source.getEmail());
        user.setUsername(source.getUsername());
        user.setPhoneNumber(source.getPhoneNumber());
        user.setFullName(source.getFullName());
        user.setDateOfBirth(source.getDateOfBirth());
        user.setAvatarUrl(source.getAvatarUrl());
        user.setStatus(source.getStatus());
        user.setLoyaltyPoints(source.getLoyaltyPoints());
        user.setLastLoginAt(source.getLastLoginAt());
        user.setCreatedAt(source.getCreatedAt());
        return user;
    }
}
