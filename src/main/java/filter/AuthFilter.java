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

@WebFilter(filterName = "filter.2.auth", urlPatterns = "/*")
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;

        String path = PathUtil.extractRequestPath(httpRequest);

        if (!PathUtil.requiresAuthentication(path)) {
            chain.doFilter(request, response);
            return;
        }

        HttpSession session = httpRequest.getSession(false);
        if (SessionUtil.isLoggedIn(session)) {
            chain.doFilter(request, response);
            return;
        }

        String loginUrl = PathUtil.buildLoginRedirectUrl(httpRequest.getContextPath(), path);
        httpResponse.sendRedirect(loginUrl);
    }
}
