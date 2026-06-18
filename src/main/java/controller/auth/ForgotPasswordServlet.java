package controller.auth;

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

import java.io.IOException;
import java.util.Optional;

/**
 * FR-04 — Quên mật khẩu (guest): gửi link đặt lại qua email.
 */
@WebServlet(urlPatterns = {"/forgot-password"})
public class ForgotPasswordServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/auth/forgot-password.jsp";
    private static final String GENERIC_SUCCESS =
            "Nếu email đã đăng ký, chúng tôi đã gửi link đặt lại mật khẩu. "
                    + "Vui lòng kiểm tra hộp thư (và thư mục spam).";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String email = trim(req.getParameter("email"));
        req.setAttribute("email", email);

        if (email == null || email.isBlank()) {
            req.setAttribute("errorMessage", "Vui lòng nhập email.");
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        try {
            EmailUtil.requireConfigured();
        } catch (MessagingException ex) {
            req.setAttribute("errorMessage", AuthConstants.SMTP_NOT_CONFIGURED_MSG);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        try {
            UserDAO userDAO = new UserDAO();
            Optional<User> found = userDAO.findByEmail(email);

            if (found.isPresent() && AuthConstants.STATUS_ACTIVE.equals(found.get().getStatus())) {
                User user = found.get();
                PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
                tokenDAO.invalidateUnusedForUser(user.getId(),
                        AuthConstants.TOKEN_PURPOSE_PASSWORD_RESET);
                String token = tokenDAO.insert(user.getId(),
                        AuthConstants.PASSWORD_RESET_EXPIRY_MINUTES,
                        AuthConstants.TOKEN_PURPOSE_PASSWORD_RESET);
                String resetUrl = EmailUtil.buildResetPasswordUrl(req.getContextPath(), token);
                EmailUtil.sendPasswordResetEmail(user.getEmail(), user.getFullName(), resetUrl);
            }

            req.setAttribute("successMessage", GENERIC_SUCCESS);
            req.getRequestDispatcher(VIEW).forward(req, resp);
        } catch (MessagingException ex) {
            log("ForgotPasswordServlet: email send failed", ex);
            req.setAttribute("errorMessage",
                    "Không thể gửi email. Vui lòng thử lại sau hoặc liên hệ quản trị viên.");
            req.getRequestDispatcher(VIEW).forward(req, resp);
        } catch (RuntimeException ex) {
            log("ForgotPasswordServlet: error", ex);
            req.setAttribute("errorMessage", "Không thể xử lý yêu cầu. Vui lòng thử lại sau.");
            req.getRequestDispatcher(VIEW).forward(req, resp);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
