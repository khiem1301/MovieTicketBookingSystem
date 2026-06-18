package controller.auth;

import dal.PasswordResetTokenDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AuthConstants;
import utils.PasswordUtil;
import utils.PasswordValidator;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * FR-04 — Đặt lại mật khẩu qua token trong email.
 */
@WebServlet(urlPatterns = {"/reset-password"})
public class ResetPasswordServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/auth/reset-password.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String token = trim(req.getParameter("token"));
        if (token == null || token.isBlank() || !isTokenValid(token)) {
            resp.sendRedirect(req.getContextPath() + "/login?reset=invalid");
            return;
        }

        req.setAttribute("token", token);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String token = trim(req.getParameter("token"));
        String newPassword = req.getParameter("newPassword");
        String confirmPassword = req.getParameter("confirmPassword");

        if (token == null || token.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/login?reset=invalid");
            return;
        }

        PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
        Optional<PasswordResetTokenDAO.TokenRecord> found = tokenDAO.findValidByToken(
                token, AuthConstants.TOKEN_PURPOSE_PASSWORD_RESET);
        if (found.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/login?reset=invalid");
            return;
        }

        List<String> errors = PasswordValidator.validate(newPassword, confirmPassword);
        if (!errors.isEmpty()) {
            req.setAttribute("token", token);
            req.setAttribute("errors", errors);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        try {
            new UserDAO().updatePasswordHash(found.get().userId(),
                    PasswordUtil.hash(newPassword));
            tokenDAO.markUsed(found.get().id());
            resp.sendRedirect(req.getContextPath() + "/login?reset=success");
        } catch (RuntimeException ex) {
            log("ResetPasswordServlet: error", ex);
            req.setAttribute("token", token);
            req.setAttribute("errors", List.of("Không thể cập nhật mật khẩu. Vui lòng thử lại sau."));
            req.getRequestDispatcher(VIEW).forward(req, resp);
        }
    }

    private boolean isTokenValid(String token) {
        PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
        return tokenDAO.findValidByToken(token, AuthConstants.TOKEN_PURPOSE_PASSWORD_RESET)
                .isPresent();
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
