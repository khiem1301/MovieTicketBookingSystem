package controller.admin;

import dal.UserDAO;
import dal.UserStatusLogDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.mail.MessagingException;
import model.entity.User;
import model.entity.UserStatusLog;
import utils.AdminAuthUtil;
import utils.EmailUtil;
import utils.SessionUtil;
import utils.UserLockValidator;

import java.io.IOException;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

@WebServlet(urlPatterns = {"/admin/users/status"})
public class UserStatusServlet extends HttpServlet {

    private static final Logger LOG = Logger.getLogger(UserStatusServlet.class.getName());
    private static final Set<String> ALLOWED_ACTIONS = Set.of("lock", "unlock", "deactivate");

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String userId = trim(req.getParameter("userId"));
        String action = trim(req.getParameter("action"));

        if (userId == null || action == null || !ALLOWED_ACTIONS.contains(action)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Yêu cầu không hợp lệ.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        String currentUserId = SessionUtil.getLoggedUser(req).getId();
        if (userId.equals(currentUserId)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Không thể thay đổi trạng thái tài khoản của chính bạn.");
            redirectAfterAction(req, resp, userId);
            return;
        }

        UserDAO userDAO = new UserDAO();
        Optional<User> found = userDAO.findById(userId);
        if (found.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Người dùng không tồn tại.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        User user = found.get();
        if ("ADMIN".equals(user.getRoleName())) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Không thể thay đổi trạng thái tài khoản Admin.");
            redirectAfterAction(req, resp, userId);
            return;
        }

        if ("lock".equals(action)) {
            handleLock(req, resp, user, currentUserId, userDAO);
            return;
        }

        String previousStatus = user.getStatus();
        String newStatus = "deactivate".equals(action) ? "INACTIVE" : "ACTIVE";
        userDAO.updateStatus(userId, newStatus);
        saveStatusLog(userId, mapAction(action), previousStatus, newStatus, null,
                false, null, currentUserId);

        String message = "deactivate".equals(action)
                ? "Đã vô hiệu hóa tài khoản " + user.getFullName() + "."
                : "Đã kích hoạt lại tài khoản " + user.getFullName() + ".";
        AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS, message);
        redirectAfterAction(req, resp, userId);
    }

    private void handleLock(HttpServletRequest req, HttpServletResponse resp,
                            User user, String adminId, UserDAO userDAO)
            throws IOException {

        String userId = user.getId();
        String reason = UserLockValidator.normalizeReason(req.getParameter("reason"));
        List<String> errors = UserLockValidator.validateLockReason(reason);
        if (!errors.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, errors.get(0));
            redirectAfterAction(req, resp, userId);
            return;
        }

        if ("BANNED".equals(user.getStatus())) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Tài khoản đã bị khóa.");
            redirectAfterAction(req, resp, userId);
            return;
        }

        boolean wantsEmail = UserLockValidator.wantsSendEmail(req.getParameter("sendEmail"));
        String userEmail = trim(user.getEmail());
        boolean canSendEmail = wantsEmail
                && userEmail != null
                && EmailUtil.isConfigured();

        boolean emailSent = false;
        String emailError = null;

        if (canSendEmail) {
            try {
                EmailUtil.sendAccountLockedEmail(userEmail, user.getFullName(), reason);
                emailSent = true;
            } catch (MessagingException ex) {
                emailError = truncate(ex.getMessage(), 255);
                LOG.log(Level.WARNING, "Failed to send lock notification to " + userEmail, ex);
            }
        } else if (wantsEmail && userEmail == null) {
            emailError = "User không có email";
        } else if (wantsEmail) {
            emailError = "Chưa cấu hình SMTP";
        }

        userDAO.updateStatus(userId, "BANNED");
        saveStatusLog(userId, "LOCK", user.getStatus(), "BANNED", reason,
                emailSent, emailError, adminId);

        String message = "Đã khóa tài khoản " + user.getFullName() + ".";
        if (emailSent) {
            message += " Đã gửi email thông báo.";
        } else if (wantsEmail && emailError != null) {
            message += " Không gửi được email: " + emailError + ".";
        }
        AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS, message);
        redirectAfterAction(req, resp, userId);
    }

    private void saveStatusLog(String userId, String action, String previousStatus, String newStatus,
                               String reason, boolean emailSent, String emailError, String performedBy) {
        try {
            UserStatusLog log = new UserStatusLog();
            log.setUserId(userId);
            log.setAction(action);
            log.setPreviousStatus(previousStatus);
            log.setNewStatus(newStatus);
            log.setReason(reason);
            log.setEmailSent(emailSent);
            log.setEmailError(emailError);
            log.setPerformedBy(performedBy);
            new UserStatusLogDAO().insert(log);
        } catch (RuntimeException ex) {
            LOG.log(Level.WARNING, "UserStatusLog insert failed — status still updated", ex);
        }
    }

    private static String mapAction(String action) {
        return switch (action) {
            case "lock" -> "LOCK";
            case "deactivate" -> "DEACTIVATE";
            default -> "UNLOCK";
        };
    }

    private void redirectAfterAction(HttpServletRequest req, HttpServletResponse resp, String userId)
            throws IOException {
        String returnTo = trim(req.getParameter("returnTo"));
        if ("list".equals(returnTo)) {
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } else {
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
        }
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
