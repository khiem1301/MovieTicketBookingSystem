package controller.admin;

import dal.RoleDAO;
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
import utils.IdParamUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

@WebServlet(urlPatterns = {"/admin/users/detail"})
public class UserDetailServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/user-detail.jsp";
    private static final String NOT_FOUND_VIEW = "/WEB-INF/views/error/404.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String userId = IdParamUtil.normalize(req.getParameter("id"));
        if (!IdParamUtil.isValidUuid(userId)) {
            showNotFound(req, resp);
            return;
        }

        Optional<User> found;
        try {
            found = new UserDAO().findById(userId);
        } catch (RuntimeException ex) {
            showNotFound(req, resp);
            return;
        }
        if (found.isEmpty()) {
            showNotFound(req, resp);
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
        req.setAttribute("canEditRole", !userId.equals(currentUserId) && !"ADMIN".equals(user.getRoleName()));
        req.setAttribute("editableRoles", new RoleDAO().findEditableByAdmin());
        req.setAttribute("userHasEmail", userHasEmail);
        req.setAttribute("emailConfigured", emailConfigured);
        req.setAttribute("canSendLockEmail", userHasEmail && emailConfigured);
        req.setAttribute("latestLock", latestLock);
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private void showNotFound(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
        req.getRequestDispatcher(NOT_FOUND_VIEW).forward(req, resp);
    }
}
