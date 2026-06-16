package controller.admin;

import dal.UserDAO;
import dal.UserStatusLogDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import model.entity.UserStatusLog;
import utils.AdminAuthUtil;
import utils.EmailUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

@WebServlet(urlPatterns = {"/admin/users/detail"})
public class UserDetailServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/user-detail.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String userId = trim(req.getParameter("id"));
        if (userId == null) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Không tìm thấy người dùng.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        Optional<User> found = new UserDAO().findById(userId);
        if (found.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Người dùng không tồn tại.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
            return;
        }

        User user = found.get();
        String currentUserId = SessionUtil.getLoggedUser(req).getId();

        boolean userHasEmail = user.getEmail() != null && !user.getEmail().isBlank();
        boolean emailConfigured = EmailUtil.isConfigured();
        UserStatusLog latestLock = null;
        if ("BANNED".equals(user.getStatus())) {
            try {
                latestLock = new UserStatusLogDAO().findLatestLockByUserId(userId).orElse(null);
            } catch (RuntimeException ignored) {
                // Bảng UserStatusLog chưa có — bỏ qua
            }
        }

        req.setAttribute("user", user);
        req.setAttribute("isSelf", userId.equals(currentUserId));
        req.setAttribute("userHasEmail", userHasEmail);
        req.setAttribute("emailConfigured", emailConfigured);
        req.setAttribute("canSendLockEmail", userHasEmail && emailConfigured);
        req.setAttribute("latestLock", latestLock);
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
