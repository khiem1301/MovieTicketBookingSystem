package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AccessControl;
import utils.RememberMeUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/**
 * FR-29 — Require login for protected URLs; restore session from remember-me token.
 */
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        String path = AccessControl.normalizePath(req);

        if (!AccessControl.requiresAuthentication(path)) {
            chain.doFilter(request, response);
            return;
        }

        if (SessionUtil.getLoggedUser(req) == null) {
            RememberMeUtil.tryAutoLogin(req, resp);
        }

        if (SessionUtil.getLoggedUser(req) == null) {
            String redirectTarget = path;
            String query = req.getQueryString();
            if (query != null && !query.isBlank()) {
                redirectTarget = path + "?" + query;
            }
            String encoded = URLEncoder.encode(redirectTarget, StandardCharsets.UTF_8);

            if (SessionUtil.hadPreviousLogin(req)) {
                SessionUtil.clearHadLoginCookie(resp);
                resp.sendRedirect(req.getContextPath() + "/session-expired?redirect=" + encoded);
            } else {
                resp.sendRedirect(req.getContextPath() + "/login?redirect=" + encoded);
            }
            return;
        }

        chain.doFilter(request, response);
    }
}
