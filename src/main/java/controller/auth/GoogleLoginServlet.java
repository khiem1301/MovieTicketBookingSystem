package controller.auth;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.GoogleOAuthSession;
import utils.GoogleOAuthUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.UUID;

@WebServlet(urlPatterns = {"/auth/google"})
public class GoogleLoginServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        if (!GoogleOAuthUtil.isConfigured()) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        String state = UUID.randomUUID().toString();
        GoogleOAuthSession.saveState(req, state, req.getParameter("redirect"));

        resp.sendRedirect(GoogleOAuthUtil.buildAuthorizationUrl(state));
    }
}
