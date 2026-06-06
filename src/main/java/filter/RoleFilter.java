package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import utils.PathUtil;
import utils.SessionUtil;

import java.io.IOException;

@WebFilter(filterName = "filter.3.role", urlPatterns = "/*")
public class RoleFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String path = PathUtil.extractRequestPath(httpRequest);
        String requiredRole = PathUtil.getRequiredRole(path);

        if (requiredRole == null) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = httpRequest.getSession(false);
        String currentRole = SessionUtil.getAuthRole(session);

        if (requiredRole.equals(currentRole)) {
            chain.doFilter(request, response);
            return;
        }

        httpResponse.setStatus(HttpServletResponse.SC_FORBIDDEN);
        httpRequest.setAttribute("requiredRole", requiredRole);
        httpRequest.setAttribute("currentRole", currentRole);
        httpRequest.getRequestDispatcher("/WEB-INF/views/error/403.jsp").forward(httpRequest, httpResponse);
    }
}
