package controller;

import dal.PasswordResetTokenDAO;
import dal.UserDAO;
import jakarta.mail.MessagingException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import utils.AuthConstants;
import utils.EmailUtil;
import utils.PasswordUtil;
import utils.ProfileSecurityUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

/**
 * FR-04 — Xác minh danh tính trước khi đổi mật khẩu trên profile.
 */
@WebServlet(urlPatterns = {"/profile/security-verify"})
public class ProfileSecurityVerifyServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/common/profile-security-verify.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!requireLogin(req, resp)) {
            return;
        }

        if (ProfileSecurityUtil.isVerified(req)) {
            resp.sendRedirect(req.getContextPath() + "/profile");
            return;
        }

        forwardView(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        if (!requireLogin(req, resp)) {
            return;
        }

        if (ProfileSecurityUtil.isVerified(req)) {
            resp.sendRedirect(req.getContextPath() + "/profile");
            return;
        }

        String method = trim(req.getParameter("method"));
        if ("password".equals(method)) {
            handlePasswordVerify(req, resp);
        } else if ("email".equals(method)) {
            handleEmailVerify(req, resp);
        } else {
            req.setAttribute("errorMessage", "Yêu cầu không hợp lệ.");
            forwardView(req, resp);
        }
    }

    private void handlePasswordVerify(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String currentPassword = req.getParameter("currentPassword");
        if (currentPassword == null || currentPassword.isBlank()) {
            req.setAttribute("errorMessage", "Vui lòng nhập mật khẩu hiện tại.");
            req.setAttribute("activeTab", "password");
            forwardView(req, resp);
            return;
        }

        User user = loadCurrentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        if (!PasswordUtil.verify(currentPassword, user.getPasswordHash())) {
            req.setAttribute("errorMessage", "Mật khẩu hiện tại không đúng.");
            req.setAttribute("activeTab", "password");
            forwardView(req, resp);
            return;
        }

        ProfileSecurityUtil.markVerified(req);
        resp.sendRedirect(req.getContextPath() + "/profile?security=verified");
    }

    private void handleEmailVerify(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        try {
            EmailUtil.requireConfigured();
        } catch (MessagingException ex) {
            req.setAttribute("errorMessage", AuthConstants.SMTP_NOT_CONFIGURED_MSG);
            req.setAttribute("activeTab", "email");
            forwardView(req, resp);
            return;
        }

        User user = loadCurrentUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        try {
            PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
            tokenDAO.invalidateUnusedForUser(user.getId(),
                    AuthConstants.TOKEN_PURPOSE_PROFILE_SECURITY);
            String token = tokenDAO.insert(user.getId(),
                    AuthConstants.PROFILE_SECURITY_VERIFY_MINUTES,
                    AuthConstants.TOKEN_PURPOSE_PROFILE_SECURITY);
            String confirmUrl = EmailUtil.buildProfileSecurityUrl(req.getContextPath(), token);
            EmailUtil.sendProfileSecurityEmail(user.getEmail(), user.getFullName(), confirmUrl);

            req.setAttribute("infoMessage",
                    "Chúng tôi đã gửi link xác minh đến "
                            + maskEmail(user.getEmail())
                            + ". Link có hiệu lực "
                            + AuthConstants.PROFILE_SECURITY_VERIFY_MINUTES
                            + " phút.");
            req.setAttribute("activeTab", "email");
            forwardView(req, resp);
        } catch (MessagingException ex) {
            log("ProfileSecurityVerifyServlet: email failed", ex);
            req.setAttribute("errorMessage",
                    "Không thể gửi email. Vui lòng thử lại sau hoặc dùng xác minh bằng mật khẩu.");
            req.setAttribute("activeTab", "email");
            forwardView(req, resp);
        }
    }

    private boolean requireLogin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        if (SessionUtil.getLoggedUser(req) == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/profile/security-verify");
            return false;
        }
        return true;
    }

    private User loadCurrentUser(HttpServletRequest req) {
        String userId = SessionUtil.getLoggedUser(req).getId();
        Optional<User> found = new UserDAO().findById(userId);
        return found.orElse(null);
    }

    private void forwardView(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        User user = loadCurrentUser(req);
        if (user != null) {
            req.setAttribute("userEmail", user.getEmail());
        }
        if (req.getAttribute("activeTab") == null) {
            req.setAttribute("activeTab", "password");
        }
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) {
            return "email của bạn";
        }
        int at = email.indexOf('@');
        String local = email.substring(0, at);
        String domain = email.substring(at);
        if (local.length() <= 2) {
            return local.charAt(0) + "***" + domain;
        }
        return local.substring(0, 2) + "***" + domain;
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
