package utils;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import model.dto.GoogleSignupInfo;

public final class GoogleOAuthSession {

    public static final String ATTR_STATE = "google_oauth_state";
    public static final String ATTR_REDIRECT = "google_oauth_redirect";
    public static final String ATTR_PENDING_SIGNUP = "google_pending_signup";

    private GoogleOAuthSession() {}

    public static void saveState(HttpServletRequest request, String state, String redirect) {
        HttpSession session = request.getSession(true);
        session.setAttribute(ATTR_STATE, state);
        if (AuthRedirectUtil.isSafeRedirect(redirect)) {
            session.setAttribute(ATTR_REDIRECT, redirect);
        } else {
            session.removeAttribute(ATTR_REDIRECT);
        }
    }

    public static boolean validateState(HttpServletRequest request, String state) {
        HttpSession session = request.getSession(false);
        if (session == null || state == null || state.isBlank()) {
            return false;
        }
        Object saved = session.getAttribute(ATTR_STATE);
        session.removeAttribute(ATTR_STATE);
        return state.equals(saved);
    }

    public static String consumeRedirect(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(ATTR_REDIRECT);
        session.removeAttribute(ATTR_REDIRECT);
        return (value instanceof String) ? (String) value : null;
    }

    public static void savePendingSignup(HttpServletRequest request, GoogleSignupInfo info) {
        request.getSession(true).setAttribute(ATTR_PENDING_SIGNUP, info);
    }

    public static GoogleSignupInfo getPendingSignup(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(ATTR_PENDING_SIGNUP);
        return (value instanceof GoogleSignupInfo) ? (GoogleSignupInfo) value : null;
    }

    public static void clearPendingSignup(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.removeAttribute(ATTR_PENDING_SIGNUP);
        }
    }
}
