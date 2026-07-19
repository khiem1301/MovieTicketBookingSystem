package controller.admin;

import dal.RoleDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Role;
import model.entity.User;
import utils.AdminAuthUtil;
import utils.AuthConstants;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;
import java.util.Set;

@WebServlet(urlPatterns = {"/admin/users/update-role"})
public class UserRoleUpdateServlet extends HttpServlet {

    private static final Set<String> ALLOWED_ROLES = Set.of(
            AuthConstants.ROLE_CUSTOMER,
            AuthConstants.ROLE_STAFF,
            AuthConstants.ROLE_MANAGER
    );

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String userId = trim(req.getParameter("userId"));
        String roleName = trim(req.getParameter("roleName"));

        if (userId == null || roleName == null || !ALLOWED_ROLES.contains(roleName)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Yêu cầu không hợp lệ.");
            redirect(req, resp, userId);
            return;
        }

        String currentUserId = SessionUtil.getLoggedUser(req).getId();
        if (userId.equals(currentUserId)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể đổi vai trò của chính bạn.");
            redirect(req, resp, userId);
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
        if (AuthConstants.ROLE_ADMIN.equals(user.getRoleName())) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể đổi vai trò tài khoản Admin.");
            redirect(req, resp, userId);
            return;
        }

        if (roleName.equals(user.getRoleName())) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Vai trò không thay đổi.");
            redirect(req, resp, userId);
            return;
        }

        Optional<Role> role = new RoleDAO().findByName(roleName);
        if (role.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Vai trò không hợp lệ.");
            redirect(req, resp, userId);
            return;
        }

        userDAO.updateRoleId(userId, role.get().getId());
        AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                "Đã đổi vai trò của " + user.getFullName() + " thành " + roleName + ".");
        redirect(req, resp, userId);
    }

    private void redirect(HttpServletRequest req, HttpServletResponse resp, String userId)
            throws IOException {
        if (userId == null || userId.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } else {
            resp.sendRedirect(req.getContextPath() + "/admin/users/detail?id=" + userId);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
