package controller.auth;

import dal.PasswordResetTokenDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import utils.AuthConstants;

import java.io.IOException;
import java.util.Optional;

/**
 * FR-01 — Activate account after user clicks verification link in email.
 */
@WebServlet(urlPatterns = {"/verify-email"})
public class VerifyEmailServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String token = trim(req.getParameter("token"));
        if (token == null || token.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/login?verify=invalid");
            return;
        }

        try {
            PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
            Optional<PasswordResetTokenDAO.TokenRecord> found =
                    tokenDAO.findValidByToken(token, AuthConstants.TOKEN_PURPOSE_REGISTER);
            if (found.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/login?verify=invalid");
                return;
            }

            UserDAO userDAO = new UserDAO();
            Optional<User> user = userDAO.findById(found.get().userId());
            if (user.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/login?verify=invalid");
                return;
            }

            userDAO.updateStatus(user.get().getId(), "ACTIVE");
            tokenDAO.markUsed(found.get().id());
            resp.sendRedirect(req.getContextPath() + "/login?verified=1");
        } catch (RuntimeException ex) {
            log("VerifyEmailServlet: error", ex);
            resp.sendRedirect(req.getContextPath() + "/login?verify=error");
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
