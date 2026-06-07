package controller.admin;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import utils.AdminAuthUtil;
import utils.PasswordUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

@WebServlet(urlPatterns = {"/admin/users/reset-password"})
public class UserResetPasswordServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String userId = trim(req.getParameter("userId"));
        String newPassword = req.getParameter("newPassword");

        if (userId == null) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Yêu cầu không hợp lệ.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        String currentUserId = SessionUtil.getLoggedUser(req).getId();
        if (userId.equals(currentUserId)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể đặt lại mật khẩu tài khoản của chính bạn tại đây.");
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
            return;
        }

        if (newPassword == null || newPassword.length() < 8) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Mật khẩu mới phải có ít nhất 8 ký tự.");
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
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
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Không thể đặt lại mật khẩu tài khoản Admin.");
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
            return;
        }

        userDAO.updatePasswordHash(userId, PasswordUtil.hash(newPassword));
        AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                "Đã đặt lại mật khẩu cho " + user.getFullName() + ".");

        resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
