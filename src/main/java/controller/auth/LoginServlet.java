package controller.auth;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.entity.User;
import utils.AuthConstants;
import utils.PasswordUtil;
import utils.PathUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        if (SessionUtil.isLoggedIn(request.getSession(false))) {
            User user = SessionUtil.getAuthUser(request.getSession(false));
            response.sendRedirect(PathUtil.getHomeUrl(user.getRoleName(), request.getContextPath()));
            return;
        }

        prepareLoginView(request);
        request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");

        String identifier = trim(request.getParameter("identifier"));
        String password = request.getParameter("password");
        boolean rememberMe = "on".equals(request.getParameter("rememberMe"));
        String redirect = trim(request.getParameter("redirect"));

        request.setAttribute("identifier", identifier);
        request.setAttribute("rememberMe", rememberMe);
        request.setAttribute("redirect", redirect);

        if (identifier == null || identifier.isEmpty() || password == null || password.isEmpty()) {
            request.setAttribute("errorMessage", "Vui lòng nhập email/username và mật khẩu.");
            forwardLoginForm(request, response);
            return;
        }

        Optional<User> userOptional = userDAO.findByEmailOrUsername(identifier);

        if (userOptional.isEmpty() || !PasswordUtil.verify(password, userOptional.get().getPasswordHash())) {
            request.setAttribute("errorMessage", "Email/username hoặc mật khẩu không đúng.");
            forwardLoginForm(request, response);
            return;
        }

        User user = userOptional.get();
        String statusError = resolveStatusError(user.getStatus());

        if (statusError != null) {
            request.setAttribute("errorMessage", statusError);
            forwardLoginForm(request, response);
            return;
        }

        userDAO.updateLastLoginAt(user.getId());

        HttpSession session = request.getSession(true);
        SessionUtil.login(session, user, rememberMe);

        String targetUrl = PathUtil.resolveRedirect(redirect, request.getContextPath(), user.getRoleName());
        response.sendRedirect(targetUrl);
    }

    private String resolveStatusError(String status) {
        if (AuthConstants.STATUS_BANNED.equals(status)) {
            return "Tài khoản đã bị khóa. Vui lòng liên hệ quản trị viên.";
        }
        if (AuthConstants.STATUS_INACTIVE.equals(status)) {
            return "Tài khoản chưa được kích hoạt. Vui lòng xác thực email.";
        }
        return null;
    }

    private void forwardLoginForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        prepareLoginView(request);
        request.getRequestDispatcher("/WEB-INF/views/auth/login.jsp").forward(request, response);
    }

    private void prepareLoginView(HttpServletRequest request) {
        request.setAttribute("pageTitle", "Đăng nhập — CineReserve");

        if (request.getAttribute("redirect") == null) {
            String redirectParam = trim(request.getParameter("redirect"));
            if (redirectParam != null && PathUtil.isSafeRedirect(redirectParam, request.getContextPath())) {
                request.setAttribute("redirect", redirectParam);
            }
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
