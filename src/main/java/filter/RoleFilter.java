package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AccessControl;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Optional;
import java.util.Set;

/**
 * FR-29 — Block URLs when the logged-in user's role is not allowed.
 */
public class RoleFilter implements Filter {

    private static final String FORBIDDEN_VIEW = "/WEB-INF/views/error/403.jsp";

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

        Optional<Set<String>> allowedRoles = AccessControl.requiredRoles(path);
        if (allowedRoles.isEmpty()) {
            chain.doFilter(request, response);
            return;
        }

        String userRole = SessionUtil.getUserRole(req);
        if (userRole != null && allowedRoles.get().contains(userRole)) {
            chain.doFilter(request, response);
            return;
        }

        req.setAttribute("requestedPath", path);
        req.setAttribute("userRole", userRole);
        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
        req.getRequestDispatcher(FORBIDDEN_VIEW).forward(req, resp);
    }
}
