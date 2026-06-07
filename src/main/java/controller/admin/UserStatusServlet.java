package controller.admin;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import utils.AdminAuthUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;
import java.util.Set;

@WebServlet(urlPatterns = {"/admin/users/status"})
public class UserStatusServlet extends HttpServlet {

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
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Không thể thay đổi trạng thái tài khoản Admin.");
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
            return;
        }

        String newStatus = switch (action) {
            case "lock" -> "BANNED";
            case "deactivate" -> "INACTIVE";
            default -> "ACTIVE";
        };

        userDAO.updateStatus(userId, newStatus);

        String message = switch (action) {
            case "lock" -> "Đã khóa tài khoản " + user.getFullName() + ".";
            case "deactivate" -> "Đã vô hiệu hóa tài khoản " + user.getFullName() + ".";
            default -> "Đã kích hoạt lại tài khoản " + user.getFullName() + ".";
        };
        AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS, message);

        String returnTo = trim(req.getParameter("returnTo"));
        if ("list".equals(returnTo)) {
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } else {
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
