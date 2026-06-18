package controller;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.PasswordUtil;
import utils.PasswordValidator;
import utils.ProfileSecurityUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.List;

/**
 * FR-04 — Đổi mật khẩu trên profile (sau xác minh bảo mật).
 */
@WebServlet(urlPatterns = {"/profile/password"})
public class ChangePasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        if (SessionUtil.getLoggedUser(req) == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/profile");
            return;
        }

        if (!ProfileSecurityUtil.isVerified(req)) {
            resp.sendRedirect(req.getContextPath() + "/profile?security=required");
            return;
        }

        String newPassword = req.getParameter("newPassword");
        String confirmPassword = req.getParameter("confirmPassword");
        List<String> errors = PasswordValidator.validate(newPassword, confirmPassword);
        if (!errors.isEmpty()) {
            req.getSession().setAttribute("passwordChangeErrors", errors);
            resp.sendRedirect(req.getContextPath() + "/profile?password=invalid");
            return;
        }

        try {
            String userId = SessionUtil.getLoggedUser(req).getId();
            new UserDAO().updatePasswordHash(userId, PasswordUtil.hash(newPassword));
            ProfileSecurityUtil.clearVerified(req);
            resp.sendRedirect(req.getContextPath() + "/profile?password=changed");
        } catch (RuntimeException ex) {
            log("ChangePasswordServlet: error", ex);
            req.getSession().setAttribute("passwordChangeErrors",
                    List.of("Không thể cập nhật mật khẩu. Vui lòng thử lại sau."));
            resp.sendRedirect(req.getContextPath() + "/profile?password=error");
        }
    }
}
