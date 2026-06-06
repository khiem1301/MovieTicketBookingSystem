package controller.auth;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;
import utils.AuthRedirectUtil;
import utils.PasswordUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

@WebServlet(urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/auth/login.jsp";
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) != null) {
            resp.sendRedirect(AuthRedirectUtil.defaultRedirectForRole(
                    req, SessionUtil.getUserRole(req)));
            return;
        }

        String remembered = SessionUtil.readRememberCookie(req);
        if (remembered != null) {
            req.setAttribute("identifier", remembered);
            req.setAttribute("rememberMe", true);
        }

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String identifier = trim(req.getParameter("identifier"));
        String password   = req.getParameter("password");
        boolean rememberMe = "on".equals(req.getParameter("rememberMe"));

        req.setAttribute("identifier", identifier);
        req.setAttribute("rememberMe", rememberMe);

        if (identifier == null || identifier.isBlank()) {
            forwardView(req, resp, "Vui lòng nhập email hoặc tên đăng nhập.");
            return;
        }
        if (password == null || password.isBlank()) {
            forwardView(req, resp, "Vui lòng nhập mật khẩu.");
            return;
        }

        try {
            UserDAO userDAO = new UserDAO();
            Optional<User> found = userDAO.findByEmailOrUsername(identifier);

            if (found.isEmpty() || !PasswordUtil.verify(password, found.get().getPasswordHash())) {
                forwardView(req, resp, "Email/tên đăng nhập hoặc mật khẩu không đúng.");
                return;
            }

            User user = found.get();

            if ("BANNED".equals(user.getStatus())) {
                forwardView(req, resp, "Tài khoản đã bị khóa. Vui lòng liên hệ rạp để được hỗ trợ.");
                return;
            }
            if ("INACTIVE".equals(user.getStatus())) {
                forwardView(req, resp,
                        "Tài khoản chưa được kích hoạt. Vui lòng xác thực email trước khi đăng nhập.");
                return;
            }

            userDAO.updateLastLoginAt(user.getId());
            SessionUtil.setLoggedIn(req, user);
            if (rememberMe) {
                SessionUtil.setRememberCookie(resp, identifier);
            } else {
                SessionUtil.clearRememberCookie(resp);
            }

            resp.sendRedirect(AuthRedirectUtil.resolvePostLoginRedirect(req, user.getRoleName()));

        } catch (RuntimeException ex) {
            log("LoginServlet: DB error", ex);
            forwardView(req, resp, "Không thể kết nối hệ thống. Vui lòng thử lại sau.");
        }
    }

    private void forwardView(HttpServletRequest req, HttpServletResponse resp, String errorMessage)
            throws ServletException, IOException {
        req.setAttribute("errorMessage", errorMessage);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
