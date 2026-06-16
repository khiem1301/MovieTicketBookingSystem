package controller.auth;

import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.GoogleSignupInfo;
import model.entity.User;
import utils.AccountLockUtil;
import utils.AuthRedirectUtil;
import utils.GoogleOAuthSession;
import utils.GoogleOAuthUtil;
import utils.RememberMeUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;

@WebServlet(urlPatterns = {"/auth/google/callback"})
public class GoogleCallbackServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String error = req.getParameter("error");
        if (error != null && !error.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/login?google=cancelled");
            return;
        }

        String state = req.getParameter("state");
        if (!GoogleOAuthSession.validateState(req, state)) {
            resp.sendRedirect(req.getContextPath() + "/login?google=invalid_state");
            return;
        }

        String code = req.getParameter("code");
        if (code == null || code.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/login?google=missing_code");
            return;
        }

        try {
            String accessToken = GoogleOAuthUtil.exchangeCodeForAccessToken(code);
            GoogleOAuthUtil.GoogleUserInfo profile = GoogleOAuthUtil.fetchUserInfo(accessToken);

            if (profile.email() == null || profile.email().isBlank()) {
                resp.sendRedirect(req.getContextPath() + "/login?google=no_email");
                return;
            }

            UserDAO userDAO = new UserDAO();
            Optional<User> existing = userDAO.findByEmail(profile.email().trim().toLowerCase());

            if (existing.isPresent()) {
                finishLogin(req, resp, userDAO, existing.get(), profile);
                return;
            }

            GoogleSignupInfo pending = new GoogleSignupInfo();
            pending.setSub(profile.sub());
            pending.setEmail(profile.email().trim().toLowerCase());
            pending.setName(profile.name());
            pending.setPicture(profile.picture());
            pending.setRedirect(GoogleOAuthSession.consumeRedirect(req));
            GoogleOAuthSession.savePendingSignup(req, pending);

            resp.sendRedirect(req.getContextPath() + "/register/google-complete");
        } catch (Exception ex) {
            log("GoogleCallbackServlet failed", ex);
            resp.sendRedirect(req.getContextPath() + "/login?google=error");
        }
    }

    private void finishLogin(HttpServletRequest req, HttpServletResponse resp,
                             UserDAO userDAO, User user,
                             GoogleOAuthUtil.GoogleUserInfo profile) throws IOException {
        if ("BANNED".equals(user.getStatus())) {
            AccountLockUtil.stashLockReasonForLogin(req, user.getId());
            resp.sendRedirect(req.getContextPath() + "/login?google=banned");
            return;
        }

        if ("INACTIVE".equals(user.getStatus())) {
            userDAO.updateStatus(user.getId(), "ACTIVE");
            user.setStatus("ACTIVE");
        }

        userDAO.updateGoogleProfile(user.getId(), profile.name(), profile.picture());
        userDAO.updateLastLoginAt(user.getId());

        SessionUtil.setLoggedIn(req, user);
        SessionUtil.markHadLogin(resp);
        RememberMeUtil.clearToken(resp);
        SessionUtil.clearRememberCookie(resp);

        String redirect = GoogleOAuthSession.consumeRedirect(req);
        String target = AuthRedirectUtil.resolvePostLoginRedirect(req, user.getRoleName(), redirect);
        resp.sendRedirect(target);
    }
}
