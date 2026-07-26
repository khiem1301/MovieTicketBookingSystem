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

import java.io.IOException;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/users"})
public class UserListServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/user-list.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        UserDAO userDAO = new UserDAO();
        List<User> users = userDAO.findAllOrdered();
        List<Role> roles = new RoleDAO().findAll();

        req.setAttribute("users", users);
        req.setAttribute("roles", roles);
        req.setAttribute("totalUsers", users.size());
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
