package filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import util.AppConstants;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * Filter phân quyền theo URL pattern và role.
 *
 * Quy tắc mặc định:
 *   /admin/*   → chỉ ADMIN
 *   /manager/* → MANAGER, ADMIN
 *   /staff/*   → STAFF, MANAGER, ADMIN
 *
 * Nếu role không đủ quyền → forward về trang 403.
 */
@WebFilter(urlPatterns = {"/admin/*", "/manager/*", "/staff/*"})
public class RoleFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req     = (HttpServletRequest)  request;
        HttpServletResponse res     = (HttpServletResponse) response;
        HttpSession         session = req.getSession(false);

        String role = (session != null)
                ? (String) session.getAttribute(AppConstants.SESSION_ROLE)
                : null;

        String path = req.getServletPath();
        Set<String> allowed = getAllowedRoles(path);

        if (allowed != null && !allowed.contains(role)) {
            req.getRequestDispatcher(AppConstants.VIEW_403).forward(req, res);
            return;
        }

        chain.doFilter(request, response);
    }

    private Set<String> getAllowedRoles(String path) {
        if (path.startsWith("/admin"))   return roles(AppConstants.ROLE_ADMIN);
        if (path.startsWith("/manager")) return roles(AppConstants.ROLE_MANAGER, AppConstants.ROLE_ADMIN);
        if (path.startsWith("/staff"))   return roles(AppConstants.ROLE_STAFF,   AppConstants.ROLE_MANAGER, AppConstants.ROLE_ADMIN);
        return null;
    }

    private Set<String> roles(String... r) {
        return new HashSet<>(Arrays.asList(r));
    }
}
