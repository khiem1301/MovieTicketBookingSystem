package controller.auth;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.SessionUtil;

import java.io.IOException;

@WebServlet(urlPatterns = {"/register/pending"})
public class RegisterPendingServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/auth/register-pending.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
