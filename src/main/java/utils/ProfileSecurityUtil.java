package utils;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

/**
 * FR-04 — Cờ session sau khi xác minh bảo mật trước đổi mật khẩu trên profile.
 */
public final class ProfileSecurityUtil {

    public static final String SESSION_VERIFIED_AT = "profileSecurityVerifiedAt";

    private ProfileSecurityUtil() {}

    public static void markVerified(HttpServletRequest request) {
        HttpSession session = request.getSession(true);
        session.setAttribute(SESSION_VERIFIED_AT, Instant.now().toEpochMilli());
    }

    public static void clearVerified(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            session.removeAttribute(SESSION_VERIFIED_AT);
        }
    }

    public static boolean isVerified(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return false;
        }
        Object raw = session.getAttribute(SESSION_VERIFIED_AT);
        if (!(raw instanceof Long verifiedAt)) {
            return false;
        }
        Instant expiry = Instant.ofEpochMilli(verifiedAt)
                .plus(AuthConstants.PROFILE_SECURITY_VERIFY_MINUTES, ChronoUnit.MINUTES);
        if (Instant.now().isAfter(expiry)) {
            session.removeAttribute(SESSION_VERIFIED_AT);
            return false;
        }
        return true;
    }
}
