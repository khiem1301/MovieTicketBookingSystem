package controller;

import dal.PasswordResetTokenDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AuthConstants;
import utils.ProfileSecurityUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

/**
 * FR-04 — Xác nhận danh tính qua link email trên profile.
 */
@WebServlet(urlPatterns = {"/profile/security-verify/confirm"})
public class ProfileSecurityConfirmServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) == null) {
            String token = trim(req.getParameter("token"));
            String redirect = "/profile/security-verify";
            if (token != null) {
                redirect += "?token=" + token;
            }
            resp.sendRedirect(req.getContextPath() + "/login?redirect=" + redirect);
            return;
        }

        String token = trim(req.getParameter("token"));
        if (token == null || token.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/profile/security-verify?error=invalid");
            return;
        }

        try {
            PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
            Optional<PasswordResetTokenDAO.TokenRecord> found = tokenDAO.findValidByToken(
                    token, AuthConstants.TOKEN_PURPOSE_PROFILE_SECURITY);
            if (found.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/profile/security-verify?error=invalid");
                return;
            }

            String loggedUserId = SessionUtil.getLoggedUser(req).getId();
            if (!loggedUserId.equals(found.get().userId())) {
                resp.sendRedirect(req.getContextPath() + "/profile/security-verify?error=mismatch");
                return;
            }

            tokenDAO.markUsed(found.get().id());
            ProfileSecurityUtil.markVerified(req);
            resp.sendRedirect(req.getContextPath() + "/profile?security=verified");
        } catch (RuntimeException ex) {
            log("ProfileSecurityConfirmServlet: error", ex);
            resp.sendRedirect(req.getContextPath() + "/profile/security-verify?error=server");
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
