package controller.admin;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AdminAuthUtil;
import utils.SessionUtil;

import java.io.IOException;

@WebServlet(urlPatterns = {"/admin/dashboard"})
public class AdminDashboardServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/dashboard.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        UserDAO userDAO = new UserDAO();
        req.setAttribute("adminName", SessionUtil.getLoggedUser(req).getFullName());
        req.setAttribute("totalUsers",   userDAO.countAll(null, null, null));
        req.setAttribute("activeUsers",  userDAO.countAll(null, null, "ACTIVE"));
        req.setAttribute("staffCount",   userDAO.countAll(null, "STAFF", null));
        req.setAttribute("managerCount", userDAO.countAll(null, "MANAGER", null));
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError",   AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
