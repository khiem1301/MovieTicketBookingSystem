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
import utils.AdminPaginationUtil;

import java.io.IOException;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/users"})
public class UserListServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/user-list.jsp";
    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String keyword  = trim(req.getParameter("q"));
        String roleName = trim(req.getParameter("role"));
        String status   = trim(req.getParameter("status"));
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        UserDAO userDAO = new UserDAO();
        int total = userDAO.countAll(keyword, roleName, status);
        int totalPages = AdminPaginationUtil.totalPages(total, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);

        int offset = AdminPaginationUtil.offset(page, PAGE_SIZE);
        List<User> users = userDAO.findAll(keyword, roleName, status, offset, PAGE_SIZE);
        List<Role> roles = new RoleDAO().findAll();

        req.setAttribute("users", users);
        req.setAttribute("roles", roles);
        req.setAttribute("filterQ", keyword);
        req.setAttribute("filterRole", roleName);
        req.setAttribute("filterStatus", status);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("totalUsers", total);
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", total);
        req.setAttribute("pgPath", req.getContextPath() + "/admin/users");
        req.setAttribute("pgQueryExtra",
                AdminPaginationUtil.queryParam("q", keyword)
                        + AdminPaginationUtil.queryParam("role", roleName)
                        + AdminPaginationUtil.queryParam("status", status));
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
