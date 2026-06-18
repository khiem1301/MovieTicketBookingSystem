package controller;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import utils.ProfileSecurityUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * FR-04 / FR-05 stub — Trang tài khoản (card bảo mật đổi mật khẩu).
 */
@WebServlet(urlPatterns = {"/profile"})
public class ProfileServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/common/profile.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/profile");
            return;
        }

        String userId = SessionUtil.getLoggedUser(req).getId();
        Optional<User> found = new UserDAO().findById(userId);
        if (found.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        req.setAttribute("user", found.get());
        req.setAttribute("securityVerified", ProfileSecurityUtil.isVerified(req));

        Object flashErrors = req.getSession().getAttribute("passwordChangeErrors");
        if (flashErrors instanceof List<?> list && !list.isEmpty()) {
            req.setAttribute("passwordChangeErrors", list);
            req.getSession().removeAttribute("passwordChangeErrors");
        }

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
