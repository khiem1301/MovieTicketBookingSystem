package utils;

import dal.UserStatusLogDAO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import model.entity.UserStatusLog;

import java.util.Optional;

public final class AccountLockUtil {

    public static final String SESSION_LOCK_REASON = "authLockReason";
    public static final String BANNED_LOGIN_MESSAGE =
            "Tài khoản đã bị khóa. Vui lòng liên hệ rạp để được hỗ trợ.";

    private AccountLockUtil() {
    }

    public static Optional<String> findLockReason(String userId) {
        if (userId == null || userId.isBlank()) {
            return Optional.empty();
        }
        try {
            return new UserStatusLogDAO().findLatestLockByUserId(userId)
                    .map(UserStatusLog::getReason)
                    .filter(reason -> reason != null && !reason.isBlank());
        } catch (RuntimeException ex) {
            return Optional.empty();
        }
    }

    public static void stashLockReasonForLogin(HttpServletRequest req, String userId) {
        findLockReason(userId).ifPresent(reason ->
                req.getSession(true).setAttribute(SESSION_LOCK_REASON, reason));
    }

    public static String consumeLockReason(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute(SESSION_LOCK_REASON);
        session.removeAttribute(SESSION_LOCK_REASON);
        return (value instanceof String reason && !reason.isBlank()) ? reason : null;
    }
}
